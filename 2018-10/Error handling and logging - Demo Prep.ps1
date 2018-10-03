<#
    PowerShell Error Handling and Logging
    Twin Ports Systems Manager User Group - 9/27/2018
    MN PowerShell Automation Group - 10/9/2018
    
    Tim Curwick
    
    Prep Code

    Mocked functions and variable to support Demo Code
#>
$LogFolder  = 'D:\PowerShell'
$FileBase   = 'TPSMUGDemo'
$DateString = (Get-Date).ToString( 'MM-dd-yyyy.HH.mm')
$LogFile    = "$LogFolder\$FileBase.$DateString.log"

$EmpIDs = @(
    '113'
    '182' )

function Get-MyValue { return $Null }

function Get-ADUser ( $Filter, $Properties )
    {
    Return @(
        [pscustomobject]@{ Mail = 'Tim.Curwick@RBAConsulting.com'; DistinguishedName = 'CN=Tim Curwick,OU=Users,OU=MSP,DC=RBAConsulting,DC=local' }
        [pscustomobject]@{ Mail = $Null; DistinguishedName = 'CN=krbtgt,CN=Users,DC=RBAConsulting,DC=local' } )
    }

function Query-HRapi ( $ID )
    {
    If ( ( $Script:Count++ ) % 2 -eq 0 )
        {
        return @{ Name = 'Joe Cool' }
        }
    }

function Do-Stuff ( [ValidateNotNullOrEmpty()]$To ) {}

function Invoke-RestMethod2 ( $Uri ) {}

#  Run Polaris as administrator in separate PowerShell session
<#
Import-Module C:\Users\TCurwick\Documents\GitHub\Polaris\Polaris.psd1
Import-Module C:\Users\TCurwick\Documents\GitHub\PolarisEnhancement.psd1 -WarningAction SilentlyContinue

$Polaris = Start-Polaris -Port 80 -MinRunspaces 1 -MaxRunspaces 10
#>
