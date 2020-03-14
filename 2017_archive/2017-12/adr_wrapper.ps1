<#
.SYNOPSIS
    Runs ADRs and distribute and undistribute content per threshold.
.DESCRIPTION
    This script performs several functions:
        -Runs targeted ADR
        -Removes expired updates
        -Places update content in appropriate update package
            -The threshold for where the content is places is based on being installed on
                80% of endpoints. If the update is installed on less than 80% of endpoints it'll be placed in the 'current'
                tagged update package and the distributed widely. If installed on 80% or more of endpoints updates will
                be removed from the 'current' tagged update package and placed in central distriution points. Since all our
                update packages (except for current) allow fallback, remote endpoints will be able to download old updates
                over the WAN.

.PARAMETER SiteCode
    Mandatory parameter site code is used to target the appropriate site
.PARAMETER ADRName
    Mandatory parameter to target which ADR to run and clean up
.EXAMPLE
    .\adr_wrapper.ps1 -SiteCode pri -ADRName WindowsClient

    good example

.NOTES
    Configuartion Manager console is required to be installed to leverage location to import modules and run cmdlets
    Must be run from SMS Provider (this could be adjusted using -computername for some remote WMI calls)
#>

Param
(
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,

    [Parameter(Mandatory=$true)]
    [string]$ADRName
)

Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) # Import the ConfigurationManager.psd1 module 
$startingLocation = Get-Location

#region functions
function removeUpdate
{
<#
.SYNOPSIS
    Removes passed updates from software update group and package.
.DESCRIPTION
    Uses SCCM cmdlets and straight WMI calls to remove a software update from a software update group and software update package by the passed software update CI_ID.

.PARAMETER update
    Mandatory parameter update is used to idenitify the update to be removed from the software update group

#>

Param
(
    [Parameter(Mandatory=$true)]
    [Microsoft.ConfigurationManagement.ManagementProvider.IResultObject]$update
)
    #### Remove Update from SUGs
    $sugs = Get-CMSoftwareUpdateGroup

    try
    {
        if($sugs -ne $null)
        {
            foreach($sug in $sugs)
            {
                $sugUpdates = $sug.Updates
                for($i = 0; $i -lt $sugUpdates.Count; $i++)
                {
                    if($sugUpdates[$i] -eq $update.CI_ID)
                    {
                        Set-CMSoftwareUpdateGroup -Id $sug.CI_ID -RemoveSoftwareUpdate $update
                        break #no need to keep looking in this sug, move to the next one
                    }
                }
            }    
        }
    }
    catch
    {
        Write-Error "Unable to remove update from Software Update Group."
        return
    }
    Remove-Variable -Name sugs
    Remove-Variable -Name sugupdates

    #### Remove Update from Pkgs
    try
    {
        $updateCI_ID = $update.CI_ID
        $updateContent = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query "SELECT SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from `
            SMS_PackageToContent JOIN SMS_CIToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID in ($($updateCI_ID))"`
             -ComputerName $SiteServer -ErrorAction Stop
        foreach ($content in $updateContent)
        {
            $contentID = $content | Select-Object -ExpandProperty ContentID
            $packageID = $content | Select-Object -ExpandProperty PackageID
            $DeploymentPackage = [wmi]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($packageID)'"
            $ReturnValue = $DeploymentPackage.RemoveContent($contentID, $false)
            if ($ReturnValue.ReturnValue -ne 0)
            {
                throw "Unable to remove content from pkg"
            }
        }

        Remove-Variable -Name updateCI_ID
        Remove-Variable -Name updateContent
        Remove-Variable -Name contentID
        Remove-Variable -Name packageID
        Remove-Variable -Name ReturnValue
    }
    catch
    {
        Write-Error "Unable to remove content from a software deployment package. Verify permissions of user running script."
        return
    }

    Remove-Variable -Name update
}

function addUpdateToCurrent
{
Param
(
    [Parameter(Mandatory=$true)]
    [Microsoft.ConfigurationManagement.ManagementProvider.IResultObject]$update
    ,
    [Parameter(Mandatory=$true)]
    [string]$currentPkgID
)
    try
    {
        $deploymentPkgName = (Get-CMSoftwareUpdateDeploymentPackage -Id $currentPkgID).Name
        Save-CMSoftwareUpdate -SoftwareUpdate $update -DeploymentPackageName $deploymentPkgName -SoftwareUpdateLanguage "en-us" -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Error "Could not add $($update.LocalizedDisplayName) to $currentPkgID"
        return
    }
}

function removeUpdatefromCurrent
{
Param
(
    [Parameter(Mandatory=$true)]
    [Microsoft.ConfigurationManagement.ManagementProvider.IResultObject]$update
    ,
    [Parameter(Mandatory=$true)]
    [string]$currentPkgID
)

    try
    {
        $updateCI_ID = $update.CI_ID
        $updateContent = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query "SELECT SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from `
            SMS_PackageToContent JOIN SMS_CIToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID in ($($updateCI_ID)) `
            and SMS_PackageToContent.PackageID='$($currentPkgID)'" -ComputerName $SiteServer -ErrorAction Stop
        foreach ($content in $updateContent)
        {
            $contentID = $content | Select-Object -ExpandProperty ContentID
            $packageID = $content | Select-Object -ExpandProperty PackageID
            $DeploymentPackage = [wmi]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($packageID)'"
            $ReturnValue = $DeploymentPackage.RemoveContent($contentID, $false)
            if ($ReturnValue.ReturnValue -ne 0)
            {
                throw "Unable to remove content from pkg"
            }
        }

        Remove-Variable -Name updateCI_ID
        Remove-Variable -Name updateContent
        Remove-Variable -Name contentID
        Remove-Variable -Name packageID
        Remove-Variable -Name ReturnValue
    }
    catch
    {
        Write-Error "Unable to remove content from a software deployment package. Verify permissions of user running script."
        return
    }

   Remove-Variable -Name update
    Remove-Variable -Name currentPkgID
}
#endregion functions

#region Connect to SCCM Site
try 
{
    $pathSiteCode = $SiteCode + ":"
    Set-Location $pathSiteCode -ErrorAction Stop # Set the current location to be the site code.
}
catch
{
    Write-Error "Unable to connect to Site $SiteCode"
    return
}
#endregion Connect to SCCM Site

#region Locate ADR Name
$ADR = $null
$CMPSSuppressFastNotUsedCheck = $true

try
{
    $ADR = Get-CMSoftwareUpdateAutoDeploymentRule -Name $ADRName
    if ($ADR -eq $null) { throw "No results" }
}
catch
{
    Write-Error "Unable to find an ADR with the name $ADRName"
    return
}
Write-Host "Located $($ADR.Name) with ID: $($ADR.AutoDeploymentID). Validating its settings."
#endregion Locate ADR Name

#region Validate ADR Conforms to expected norms
$ADRPackageCurrent = $null
$ADRPackageRollup = $null
$ADRNonConforming = $false

#### Test ADR
## 1. Rules filter out updates not required by any devices
$testResult = $false

try
{
    $([XML]$ADR.UpdateRuleXML).UpdateXML.UpdateXMLDescriptionItems.ChildNodes | ForEach-Object `
    {
        if($_.PropertyName -eq "NumMissing") # Property we want to test
        {
            if($_.InnerText -eq ">=1") { $testResult = $true }
        }
    }
}
catch
{
    Write-Error "Cannot validate ADR rule. Edit the rule in the GUI, save it, and try again."
    return
}

if($testResult -eq $false) { $ADRNonConforming = $true }
Remove-Variable -Name testResult

#### Test Packages
## 1. Rollup Package is located and has a conforming name
$testResult = $false

try
{
    $ADRPackageRollup = Get-CMSoftwareUpdateDeploymentPackage -Id $([XML]$ADR.ContentTemplate).ContentActionXML.PackageID
    if($ADRPackageRollup -eq $null) { throw "Package Not Found" }
    if($ADRPackageRollup.Name -eq $($ADR.Name + "-Rollup")) { $testResult = $true }
}
catch
{
    Write-Error "Cannot validate rollup package. Ensure it is properly defined."
    return
}
if($testResult -eq $false) { Write-Error "Rollup Package is named improperly. No remediation will take place automatically." }
Remove-Variable -Name testResult

## 2. Current Package is located and has a conforming name
$testResult = $false

try
{
    $ADRPackageCurrent = Get-CMSoftwareUpdateDeploymentPackage -Name $($ADR.Name + "-Current")
    if($ADRPackageCurrent -eq $null) { throw "Package Not Found" }
    else { $testResult = $true }
}
catch
{
    Write-Error "Cannot validate current package. Ensure it exists and the ADR name is valid."
    return
}
if($testResult -eq $false) { Write-Error "Current Package is not found or named improperly. A new rollup package will be created." }
Remove-Variable -Name testResult

Write-Host "ADR and Packages are conforming. Continuing to evaluate contents..."
#endregion Validate ADR Conforms to expected norms

#region Modify ADR and Software Update Packages if Non-Conforming
#### Fix ADR - Not yet implemented. Fix through the GUI
if($ADRNonConforming)
{
    Write-Error "The ADR is not set to include updates where 1 or more computers require them. Fix this in the GUI and retry."
    return
}

#### Fix Current Package
if($ADRPackageCurrent -eq $null) # Need to implement
{
    Write-Error "Current Package does not exist. It cannot be automatically fixed at this time."
    return
}

#### Fix Rollup Package
if($ADRPackageRollup -eq $null) # Need to implement
{
    Write-Error "Not yet implented to create a new package. Do so in the GUI with the name $($ADR.Name + "-Rollup") and try again."
    return
}

#endregion Modify ADR and Software Update Packages if Non-Conforming

#region Trigger ADR
$ADRid = $ADR.AutoDeploymentID
$ADRlastexecute = $ADR.LastRunTime

Write-Host "Triggering ADR to run..." -NoNewline

try
{
    Invoke-CMSoftwareUpdateAutoDeploymentRule -Id $ADRid

    $running = $true
    do
    {
        Write-Host "waiting..." -NoNewline
        Start-Sleep -Seconds 30
        $ADRtemp = Get-CMSoftwareUpdateAutoDeploymentRule -Id $ADRid -Fast
        if(($ADRtemp.LastRunTime -gt $ADRlastexecute) -and ($ADRtemp.LastErrorCode -eq 0))
        {
            $running = $false
            $ADR = Get-CMSoftwareUpdateAutoDeploymentRule -Id $ADRid
        }

        if(($ADRtemp.LastRunTime -gt $ADRlastexecute) -and ($ADRtemp.LastErrorCode -ne 0))
        {
            throw "ADR failed"
        }
        
    } while ($running)
}
catch
{
    Write-Error "Unable to execute ADR. Check status message of ADR and related logs."
    return
}

Write-Host "Done."
#endregion Trigger ADR

#region Clean expired content from SUGs and Update Packages and Update Current pkg
#### Get list of updates in Software Update Package Rollup
Write-Host "Attempting to remove expired updates the packages..." -NoNewline

$updates = $null
try
{
    $SiteServer = $(Get-CMSite -SiteCode $SiteCode).ServerName
    $updates = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT DISTINCT su.* FROM SMS_SoftwareUpdate AS su JOIN SMS_CIToContent AS cc `
     ON  SU.CI_ID = CC.CI_ID JOIN SMS_PackageToContent AS pc ON pc.ContentID=cc.ContentID  WHERE  pc.PackageID='$($ADRPackageRollup.PackageID)' AND su.IsContentProvisioned=1"
}
catch
{
    Write-Error "Unable to retrieve list of updates in the Rollup package. Continuing without cleanup of expired content."
}
if($updates -ne $null) 
{
    foreach($update in $updates)
    {
        if(($update.IsExpired) -or ($update.NumMissing -eq 0))
        {
            removeUpdate -update $(Get-CMSoftwareUpdate -Name $update.LocalizedDisplayName -ArticleId $update.ArticleID -BulletinId $update.BulletinID)
        }

        else
        {
            if($update.PercentCompliant -lt 80)
            {
                try
                {
                        $SiteServer = $(Get-CMSite -SiteCode $SiteCode).ServerName
                        $testExists = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT DISTINCT su.* FROM SMS_SoftwareUpdate AS su JOIN SMS_CIToContent AS cc `
                            ON  SU.CI_ID = CC.CI_ID JOIN SMS_PackageToContent AS pc ON pc.ContentID=cc.ContentID  WHERE  pc.PackageID='$($ADRPackageCurrent.PackageID)' AND su.CI_ID='$($update.CI_ID)1' AND su.IsContentProvisioned=1"
                    
                        if($testExists -eq $null)
                        {                         
                            addUpdateToCurrent -update $(Get-CMSoftwareUpdate -Name $update.LocalizedDisplayName -ArticleId $update.ArticleID -BulletinId $update.BulletinID) -currentPkgID $ADRPackageCurrent.PackageID
                        }

                        Remove-Variable -Name testExists
                }
                catch
                {
                    Write-Error "Cannot add update to the current package"
                    return
                }
            }
        }
    }
}
Remove-Variable -Name updates
#### Get list of updates in Software Update Package Current
$updates = $null
try
{
    $SiteServer = $(Get-CMSite -SiteCode $SiteCode).ServerName
    $updates = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT DISTINCT su.* FROM SMS_SoftwareUpdate AS su JOIN SMS_CIToContent AS cc `
     ON  SU.CI_ID = CC.CI_ID JOIN SMS_PackageToContent AS pc ON pc.ContentID=cc.ContentID  WHERE  pc.PackageID='$($ADRPackageCurrent.PackageID)' AND su.IsContentProvisioned=1"
}
catch
{
    Write-Error "Unable to retrieve list of updates in the Current package. Continuing without cleanup of expired content."
}
if($updates -ne $null) 
{
    foreach($update in $updates)
    {
        if($update.IsExpired)
        {
            removeUpdate -update $(Get-CMSoftwareUpdate -Name $update.LocalizedDisplayName -ArticleId $update.ArticleID -BulletinId $update.BulletinID)
        }
        else
        {
            if($update.PercentCompliant -gt 80)
            {
                removeUpdatefromCurrent -update $(Get-CMSoftwareUpdate -Name $update.LocalizedDisplayName -ArticleId $update.ArticleID -BulletinId $update.BulletinID) -currentPkgID $($ADRPackageCurrent.PackageID)
            }
        }
    }
}
Remove-Variable -Name updates

$(Get-WmiObject -ComputerName $SiteServer -Namespace root\sms\site_$($SiteCode) -query "Select * from SMS_SoftwareUpdatesPackage where PackageID = '$($ADRPackageCurrent.PackageID)'").RefreshPkgSource() | Out-Null
$(Get-WmiObject -ComputerName $SiteServer -Namespace root\sms\site_$($SiteCode) -query "Select * from SMS_SoftwareUpdatesPackage where PackageID = '$($ADRPackageRollup.PackageID)'").RefreshPkgSource() | Out-Null

Write-Host "Done."
#endregion Clean expired content from SUGs and Update Packages and Update Current pkg

Set-Location $startingLocation
