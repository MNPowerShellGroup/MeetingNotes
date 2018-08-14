# Pass computer name to this script and it will REMOTELY uninstall the sccm client and re-install the sccm client
#
# will need to be ran with credentials that have admin rights on the remote PC
# useage C:\temp\CM_CLIENT_REINSTALL-APD.PS1 xComputernamex
 
 param(
        [parameter(Mandatory=$true)]
        [string[]]$ComputerName
        )

function ClientUninstall
    {
        param(
        [parameter(Mandatory=$true)]
        [string[]]$ComputerName
        )
        try 
            {
            $ClientUnInstallERRreturn = Invoke-Command -ComputerName $computername -ScriptBlock {
                # do not run on SCCM site systems, abort if detected
                if (test-path HKLM:\SOFTWARE\Microsoft\SMS\Identification) { Write-Verbose "SCCM Site system detected, aborting" ; exit }
                try 
                    {
                    $VerbosePreference = "continue"
                    $ErrorActionPreference = "continue"
                    # if ccmsetup exe is running, kill it
                    if ($(get-process | Where-Object {$_.name -eq "CCMsetup"})) {
                        "Stopping CCMsetup Service"
                        stop-process -ProcessName "CCMsetup" -force -WarningAction SilentlyContinue
                        }
                    # if ccmsetup is running, kill it
                    if ($(get-service | Where-Object {$_.name -eq "CCMsetup"}).Status -eq "Running") {
                        Write-Output "Stopping CCMESETUP Service"
                        stop-service "CCMsetup" -force -WarningAction SilentlyContinue
                        }
                    # if ccmexec is running, kill it
                    if ($(get-service | Where-Object {$_.name -eq "CCMexec"}).Status -eq "Running") {
                        Write-Verbose "Stopping CCMExec Service"
                        stop-service "CCMexec" -force -WarningAction SilentlyContinue
                        }
                    Write-Verbose "copy ccmsetup to ccmsetup folder"
                    if ($(test-path -Path "C:\temp\ccmsetup.exe")) {
                        remove-item "C:\temp\ccmsetup.exe" -force 
                        }
                    $URL = "http://tcttsapd001p.hq.target.com/CCM_CLIENT/ccmsetup.exe"
                    $OUT = "C:\temp\ccmsetup.exe"
                    $GetCCMSETUP = New-Object System.Net.WebClient
                    try
                        { 
                        $GetCCMSETUP.DownloadFile($URL, $OUT)
                        }
                    catch
                        {
                        Write-Verbose "CCMsetup download failed"
                        $_.exception.message
                        }
                    if ($(test-path -PathType Container "C:\windows\ccmsetup") -eq $false) { 
                        $run = New-Item "C:\windows\ccmsetup" -type directory
                        Write-Verbose $run
                        }
                    Copy-Item "c:\temp\ccmsetup.exe" "C:\windows\ccmsetup\" -Force
                    Write-Verbose "running ccmsetup uninstall"
                    CMD /c "C:\windows\ccmsetup\ccmsetup.exe /uninstall"

                    # wait for ccmsetup to complete
                    $CCMsetupRunning = $true
                    $SleepCount = 0
                    DO
                        {
                        if (!$(get-process | Where-Object {$_.name -eq "ccmsetup"})) {
                            $CCMsetupRunning = $False
                            }
                        if ($CCMsetupRunning -eq $true) {
                            Start-sleep 5
                            Write-Verbose "Sleeping 5 seconds...total:$($SleepCount * 5) seconds"
                            $SleepCount++
                            }
                        if ($SleepCount -gt 60) {
                            $CCMsetupRunning = $false
                            }
                        } While ($CCMsetupRunning -eq $true)
                    # cleanup previous install registry and wmi

                    if (test-path -path "C:\Windows\SMSCFG.INI"){
                        Write-Verbose "remove-item C:\Windows\SMSCFG.INI"
                        remove-item "C:\Windows\SMSCFG.INI"
                        }
                    if (test-path HKLM:\software\microsoft\sms){
                        Write-Verbose "SMS REG exist"
                        try 
                            {
                            remove-item -path HKLM:software\microsoft\sms -Recurse -Force -ErrorAction SilentlyContinue
                            }
                        catch 
                            {
                            Write-Verbose "SMS"
                            $_.exception.message
                            }
                        }
                    if (test-path HKLM:\software\microsoft\ccm){
                        Write-Verbose "CCM REG exist"
                        try
                            {
                            remove-item -path HKLM:software\microsoft\ccm -Recurse -Force -ErrorAction SilentlyContinue
                            }
                        catch
                            {
                            Write-Verbose "CCM"
                            $_.exception.message
                            }
                        }
                    if (test-path HKLM:\software\microsoft\ccmsetup){
                        Write-Verbose "CCMSETUP REG exist"
                        try
                            {
                            remove-item -path HKLM:software\microsoft\ccmsetup -Recurse -Force
                            }
                        catch
                            {
                            Write-Verbose "CCMSETUP"
                            $_.exception.message
                            }
                        }
                    if (test-path HKLM:\software\microsoft\Systemcertificates\SMS\Certificates)
                        {
                        Write-Verbose "SystemCert REG exist"
                        try
                            {
                            remove-item -path HKLM:\software\microsoft\Systemcertificates\SMS\Certificates -Recurse -Force
                            }
                        catch
                            {
                            Write-Verbose "Systemcertificates"
                            $_.exception.message
                            } 
                        }
                    $MKpath = "C:\Users\All Users\Microsoft\Crypto\RSA\MachineKeys"
                    if (test-path $MKpath) {
                        TRY {
                            write-verbose "Adding NT Authority\System full control to $MKpath"
                            $Acl = (get-item $MKpath).GetAccessControl('Access')
                            $objUserSystem = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)
                            $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($objUserSystem, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
                            $Acl.SetAccessRule($Ar)
                            Set-Acl -path $MKpath -AclObject $Acl
                            }
                        CATCH {
                            write-verbose "error setting machinekeys ACL"
                            $_.exception.message
                            }
                    }
                    Write-Verbose "cleanup files"
                    if (test-path -PathType Container "C:\windows\ccmsetup") {
                        remove-item -path C:\windows\ccmsetup -Recurse -Exclude ccmsetup.exe -Force -ErrorAction SilentlyContinue
                        }
                    if (test-path -PathType Container "C:\windows\ccm") {
                        remove-item -path C:\windows\ccm -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    if (test-path -PathType Container "C:\windows\ccmcache") {
                        remove-item -path "C:\windows\ccmcache" -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    Write-Verbose "remove WMI"
                    get-wmiobject -query "select * from __Namespace where name='CCM'" -namespace "Root" | remove-wmiobject
                    }
            catch
                {
                $_.exception.message
                }
            }
        }
        catch 
            {
            $ClientUnInstallERRreturn = $_.exception.message
            }
    # if no errors are returned, set Pass and Details variables
    if ($ClientUnInstallERRreturn -eq $null) 
        {
        $ClientUnInstallPASS = $true
        $StageMSGDetails =   "Pass"
        Write-Debug "CLIENTINSTALLPASS: $ClientUnInstallPASS`r`n"
        $true
        }
    else
        {
        $ClientUnInstallPASS =   $false
        $StageMSGDetails = $ClientUnInstallERRreturn
        Write-Warning "ERROR RETURNED: $ClientUnInstallERRreturn`r`n"
        $false
        }

    # Log output to CMClientRemediationState State DB, and script arrays
    $ClientUnInstallresults = New-Object psobject
    $ClientUnInstallresults | Add-Member -MemberType NoteProperty -name "ComputerName" -Value "$computername"
    $ClientUnInstallresults | Add-Member -MemberType NoteProperty -name "StageName" -Value "ClientUnInstall"
    $ClientUnInstallresults | Add-Member -MemberType NoteProperty -name "StagePass" -Value "$ClientUnInstallPASS"
    $ClientUnInstallresults | Add-Member -MemberType NoteProperty -name "StageMSGDetails" -Value "$StageMSGDetails"
    $ClientUnInstallresults | Add-Member -MemberType NoteProperty -name "TimeStamp" -Value "$(get-date -Format $DateFormat)"
    
    # format string array, replace "'" or DB insert fails
    $PSArgsArray = @([string]$ClientUnInstallresults.ComputerName, [string]$ClientUnInstallresults.StageName, [string]$ClientUnInstallresults.StagePass, ([string]$ClientUnInstallresults.StageMSGDetails).Replace("'",""), [string]$ClientUnInstallresults.TimeStamp)
    # join string for SQL table insert
    $writeoutput = "'" + [string]::join("','",$PSArgsArray) + "'"
    #WriteLog -LogData $writeoutput -logdb "CMClientRemediationState"
    Write-Verbose $writeoutput
    }

function ClientInstall
    {
    param(
    [parameter(Mandatory=$true)]
    [string[]]$ComputerName
    )
    Write-Debug "$computername client install"
    $ClientInstallPASS =      $null
    $ClientInstallERRreturn = $null
    # do not run on SCCM site systems, abort if detected
    if (test-path HKLM:\SOFTWARE\Microsoft\SMS\Identification) { Write-Verbose "SCCM Site system detected, aborting" ; exit } 
    try 
        {
        $ClientInstallERRreturn = Invoke-Command -ComputerName $computername -ScriptBlock {
            $VerbosePreference = "continue"
            #$ErrorActionPreference = "Continue"
            try
                {
                if ($(get-process | Where-Object {$_.name -eq "CCMexec"}))
                    {
                    Write-Verbose "Stopping CCMExec process"
                    Stop-Process -ProcessName "CCMexec" -force -WarningAction SilentlyContinue
                    }
                if ($(get-process | Where-Object {$_.name -eq "ccmsetup"}))
                    {
                    Write-Verbose "Stopping CCMsetup process"
                    Stop-Process -ProcessName "CCMsetup" -force -WarningAction SilentlyContinue
                    }
                if ($(get-service | Where-Object {$_.name -eq "CCMsetup"}).Status -eq "Running")
                    {
                    Write-Verbose "Stopping CCMESETUP Service"
                    Stop-Service "CCMsetup" -force -WarningAction SilentlyContinue
                    }
                Write-Verbose "Downloading CCMSETUP.EXE to ccmsetup folder"
                if ($(test-path -Path "C:\temp\ccmsetup.exe"))
                    {
                    remove-item "C:\temp\ccmsetup.exe" -force | Out-Null
                    }
                if (!$(Test-Path -PathType Container "C:\temp"))
                    {
                    New-Item "C:\temp" -type directory | Out-Null
                    }
                $URL = "http://tcttsapd001p.hq.target.com/CCM_CLIENT/ccmsetup.exe"
                $OUT = "C:\temp\ccmsetup.exe"
                $GetCCMSETUP = New-Object System.Net.WebClient
                    try
                        { 
                        $GetCCMSETUP.DownloadFile($URL, $OUT)
                        }
                    catch
                        {
                        Write-Verbose "CCMsetup download failed"
                        $_.exception.message
                        }
                if (!$(Test-Path -PathType Container "C:\windows\ccmsetup"))
                    {
                    New-Item "C:\windows\ccmsetup" -type directory | Out-Null
                    }
                Copy-Item "c:\temp\ccmsetup.exe" -Destination "C:\windows\ccmsetup" -Force | Out-Null
                # run CCMsetup.exe 
                Write-Verbose "Running CCMSETUP.EXE"
                CMD /c "C:\WINDOWS\ccmsetup\ccmsetup.exe SMSSITECODE=APD SMSSLP=tcttsapd001p.HQ.TARGET.COM /mp:tcttsapd001p.HQ.TARGET.COM /BITSPriority:High"

                # wait for ccmsetup to complete
                $CCMsetupRunning = $true
                $SleepCount = 0
                DO {
                   if (!$(get-process | Where-Object {$_.name -eq "ccmsetup"})) {$CCMsetupRunning = $False}
                        if ($CCMsetupRunning -eq $true) {
                       Start-sleep 5
                       Write-Verbose "Sleeping 5 seconds...total:$($SleepCount * 5) seconds"
                       $SleepCount++
                       }
                   if ($SleepCount -gt 60) {$CCMsetupRunning = $false}
                    } While ($CCMsetupRunning -eq $true)
                    }
                catch
                    {
                    $_.exception.message
                    }
            }
        }
    catch
        {
        $ClientInstallERRreturn = $_.exception.message
        }

    # if no errors are returned, set Pass and Details variables
    if ($ClientInstallERRreturn -eq $null) 
        {
        $ClientInstallPASS = $true
        $StageMSGDetails =   "Pass"
        Write-Debug "CLIENTINSTALLPASS: $ClientInstallPASS`r`n"
        $true
        }
    else
        {
        $ClientInstallPASS =   $false
        $StageMSGDetails = $ClientInstallERRreturn
        Write-Warning "ERROR RETURNED: $ClientInstallERRreturn`r`n"
        $false
        }

    # Log output to CMClientRemediationState State DB, and script arrays
    $ClientInstallresults = New-Object psobject
    $ClientInstallresults | Add-Member -MemberType NoteProperty -name "ComputerName" -Value "$computername"
    $ClientInstallresults | Add-Member -MemberType NoteProperty -name "StageName" -Value "ClientInstall"
    $ClientInstallresults | Add-Member -MemberType NoteProperty -name "StagePass" -Value "$ClientInstallPASS"
    $ClientInstallresults | Add-Member -MemberType NoteProperty -name "StageMSGDetails" -Value "$StageMSGDetails"
    $ClientInstallresults | Add-Member -MemberType NoteProperty -name "TimeStamp" -Value "$(get-date -Format $DateFormat)"
    
    # format string array, replace "'" or DB insert fails
    $PSArgsArray = @([string]$ClientInstallresults.ComputerName, [string]$ClientInstallresults.StageName, [string]$ClientInstallresults.StagePass, ([string]$ClientInstallresults.StageMSGDetails).Replace("'",""), [string]$ClientInstallresults.TimeStamp)
    # join string for SQL table insert
    $writeoutput = "'" + [string]::join("','",$PSArgsArray) + "'"
    #WriteLog -LogData $writeoutput -logdb "CMClientRemediationState"
    Write-Verbose $writeoutput
    }

$VerbosePreference = 'continue'
$DebugPreference = 'continue'
    
$uninstallresult = ClientUninstall $computername
$uninstallresult = ClientUninstall $computername

if ($uninstallresult) {$installresult = ClientInstall $computername} 