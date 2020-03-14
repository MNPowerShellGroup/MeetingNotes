<#
    PowerShell Error Handling and Logging
    Twin Ports Systems Manager User Group - 9/27/2018
    MN PowerShell Automation Group - 10/9/2018
    
    Tim Curwick
        
    Demo Code

    Some of this demo code can be run as is.
    More code can be run if the Prep Code file is run first.
    Some code requires Polaris be running in a separate PowerShell session.
    Some code is just for presentation and discussion.
#>


##  Error "handling" by robust code

#  Error if $String is $Null or not a string

$String = Get-MyValue

$String.Replace( 'Server1', 'Server2' )

#  No error if $String is $Null or not a string

$String = Get-MyValue

([string]$String).Replace( 'Server1', 'Server2' )



#  Error if Mail property is $Null
$DNbyEmail = @{}
Get-ADUser -Filter * -Properties Mail |
    ForEach-Object {
        $DNbyEmail[$_.Mail] = $_.DistinguishedName }


#  No error if mail property is $Null
$DNbyEmail = @{}
Get-ADUser -Filter * -Properties Mail |
    ForEach-Object {
        If ( $_.Mail )
            {
            $DNbyEmail[$_.Mail] = $_.DistinguishedName
            }
        }

$Email = 'Tim.Curwick@RBAConsulting.com'
$DNbyEmail[$Email]



##  Code to handle problems before they become "errors"

#  Error if $User is $Null
ForEach ( $EmpID in $EmpIDs )
    {
    $User = Query-HRapi -ID $EmpID

    Do-Stuff -To $User
    }


#  No error if $User is $Null
ForEach ( $EmpID in $EmpIDs )
    {
    $User = $Null
    $User = Query-HRapi -ID $EmpID

    If ( $User )
        {
        Do-Stuff -To $User
        }
    Else
        {
        Write-Log -Text "EmpID [$EmpID] not found in HR API"
        }
    }



# Build log file path  (DNR in demo)
$LogFolder  = 'D:\PowerShell'
$FileBase   = 'TPSMUGDemo'
$DateString = (Get-Date).ToString( 'MM-dd-yyyy.HH.mm')
$LogFile    = "$LogFolder\$FileBase.$DateString.log"



##  Simple Write-Log function

function Write-Log
    {
    [cmdletbinding()]
    Param (
        [string]$Text )

    ##  Assumes $LogFile defined in higher scope
    
    #  Prepend date/time
    $Entry = (Get-Date).ToString( 'M/d/yyyy HH:mm:ss - ' ) + $Text

    #  Write entry to log file
    $Entry | Out-File -FilePath $LogFile -Encoding UTF8 -Append

    #  Write entry to screen
    Write-Verbose -Message $Entry -Verbose
    }

$EmpID = '113'
Write-Log -Text "EmpID [$EmpID] not found in HR API"



##  Simple Write-Log function for CSV log

function Write-Log
    {
    [cmdletbinding()]
    Param (
        [string]$Text )

    ##  Assumes $LogFile defined in higher scope
    
    #  Build log entry
    $Entry = [pscustomobject]@{
        Date   = (Get-Date).ToString( 'M/d/yyyy HH:mm:ss' )
        Server = $Env:ComputerName
        Text   = $Text }

    #  Export entry to log file
    $Entry | Export-CSV -Path $LogFile -Encoding UTF8 -Append -NoTypeInformation

    #  Write entry to screen
    Write-Verbose -Message ( $Entry.PSObject.Properties.Value -join ' - ' ) -Verbose
    }



##  Logging sample


Write-Log -Text 'Start processing employees.'

#  For each employee in employee ID list
#    Process employee
ForEach ( $EmpID in $EmpIDs )
    {
    Write-Log -Text "`$EmpID [$EmpID]"

    #  Query HR API for user data
    Write-Log -Text "Querying HR API for user data."
    $User = $Null
    $User = Query-HRapi -ID $EmpID

    Write-Log -Text "`$User.Name [$($User.Name)]"

    #  If HR user data found
    #    Do stuff to user
    If ( $User )
        {
        #  Do stuff to user
        Write-Log -Text "Doing stuff to user."
        Do-Stuff -To $User

        #  Log success
        Write-Log -Text "Successfully did stuff to user."
        }
    
    #  Else (user not found in HR API)
    #    Log it
    Else
        {
        Write-Log -Text "EmpID [$EmpID] not found in HR API"
        }
    }

Write-Log -Text 'End processing employees.'



##  Try/Catch/Finally

try
    {
    Try-Stuff
    }

catch
    {
    Handle-Error
    }

finally
    {
    Final-Tasks
    }



##  Try/Catch as SilentlyContinue

try { Do-Stuff } catch {}



##  Error action examples

$Path = 'D:\DoesNotExist'

#  Error
$File = Get-Item -Path $Path

#  No error
$File = Get-Item -Path $Path -ErrorAction SilentlyContinue

$Path = ''

#  Error
$File = Get-Item -Path $Path -ErrorAction SilentlyContinue

#  No error
$File = try { Get-Item -Path $Path -ErrorAction SilentlyContinue } catch {}



$RS = [runspacefactory]::CreateRunspacePool( 1, 1 )
$RS.Open()

#  Error
$RS.Open()

#  No error
try { $RS.Open() } catch {}



##  Simple try/catch

ForEach ( $i in 0..2 )
    {
    try
        {
        Write-Log -Text "`$i [$i]"
        $Result = 1/$i
        Write-Log -Text "`$Result [$Result]"
        Write-Log -Text 'Sucess'
        }
    catch
        {
        Write-Log -Text 'Error'
        }
    }



##  Looking at error records


$Error[0]

$E = $Error[0]

$E

$E | Format-List

$E | fl *

$E | fl * -force

$E.Exception

$E.Exception | fl * -force

$E.Exception.GetType().FullName

$E.Exception.InnerException | fl * -force

$E.Exception.InnerException.GetType().FullName



Invoke-RestMethod -Uri 'http://localhost/DoesNotExist'

$E2 = $Error[0]

$E2 | fl * -force

$E2.TargetObject

$E2.Exception | fl * -force

$E2.Exception.GetType().FullName

$E2.Exception.Response
$E2.Exception.Response.StatusCode
[int]$E2.Exception.Response.StatusCode

$E2.Exception.Response.Headers
$E2.Exception.Response.Headers['Server']



##  Referencing the error in a catch block

try
    {
    1/0
    }
catch
    {
    Write-Log -Text $_.Exception.Message
    }



##  Logging error details

try
    {
    1/0
    }
catch
    {
    Write-Log -Text 'Error trying to do math.'
    Write-Log -Text "Exception.Message [$($_.Exception.Message)]"
    Write-Log -Text "Exception.GetType() [$($_.Exception.GetType())]"
    Write-Log -Text "Exception.InnerException.Message [$($_.Exception.InnerException.Message)]"
    }


##  Full Write-Log function

function Write-Log
    {
    [cmdletbinding()]
    Param (
        [string]$Text,
        $ErrorRecord )

    ##  Assumes $LogFile defined in higher scope
    
    #  Prepend date/time
    $Entry = (Get-Date).ToString( 'M/d/yyyy HH:mm:ss - ' ) + $Text

    #  Write entry to log file
    $Entry | Out-File -FilePath $LogFile -Encoding UTF8 -Append

    #  Write entry to screen
    Write-Verbose -Message $Entry -Verbose

    #  If error record included
    #    Recurse to capture exception details
    If ( $ErrorRecord -is [System.Management.Automation.ErrorRecord] )
        {
        Write-Log -Text "Exception.Message [$($ErrorRecord.Exception.Message)]"
        Write-Log -Text "Exception.GetType() [$($ErrorRecord.Exception.GetType())]"
        Write-Log -Text "Exception.InnerException.Message [$($ErrorRecord.Exception.InnerException.Message)]"
        }
    }



try
    {
    1/0
    }
catch
    {
    Write-Log -Text 'Error trying to do math.' -ErrorRecord $_
    }



##  Full Write-Log function for csv log

function Write-Log
    {
    [cmdletbinding()]
    Param (
        [string]$Text,
        $ErrorRecord )

    ##  Assumes $LogFile defined in higher scope
    
    #  Build log entry
    $Entry = [pscustomobject]@{
        Date   = (Get-Date).ToString( 'M/d/yyyy HH:mm:ss' )
        Server = $Env:ComputerName
        Text   = $Text
        Error  = ''
        ErrorType  = ''
        InnerError = '' }

    #  If error record supplied
    #    Add error details to log entry
    If ( $ErrorRecord -is [System.Management.Automation.ErrorRecord] )
        {
        $Entry.Error      = $ErrorRecord.Exception.Message
        $Entry.ErrorType  = $ErrorRecord.Exception.GetType()
        $Entry.InnerError = $ErrorRecord.Exception.InnerException.Message
        }

    #  Export entry to log file
    $Entry | Export-CSV -Path $LogFile -Encoding UTF8 -Append -NoTypeInformation

    #  Write entry to screen
    Write-Verbose -Message ( $Entry.PSObject.Properties.Value -join ' - ' ) -Verbose
    }



##  Catch filter by exception type

$E.Exception.InnerException.Gettype().FullName

function InverseOf ( $N )
    {
    try
        {
        1/$N
        }
    catch [System.DivideByZeroException]
        {
        'Infinity'
        }
    }

InverseOf 2
InverseOf 0
InverseOf potato



function InverseOf ( $N )
    {
    try
        {
        1/$N
        }
    catch [System.DivideByZeroException]
        {
        'Infinity'
        }
    catch
        {
        "You're kidding, right?"
        }
    }

InverseOf 2
InverseOf 0
InverseOf potato



$E3 = $Error[1]

$E3.Exception.GetType().FullName
$E3.Exception.GetType().BaseType.FullName
$E3.Exception.GetType().BaseType.BaseType.FullName
$E3.Exception.GetType().BaseType.BaseType.BaseType.FullName
$E3.Exception.GetType().BaseType.BaseType.BaseType.BaseType.FullName

$E3.Exception.InnerException.GetType().FullName
$E3.Exception.InnerException.GetType().BaseType.FullName
$E3.Exception.InnerException.GetType().BaseType.BaseType.FullName

$E3.Exception.GetType().FullName
$E3.Exception.GetType().BaseType.FullName
$E3.Exception.InnerException.GetType().FullName
$E3.Exception.InnerException.GetType().BaseType.FullName


function BigInverseOf ( $N )
    {
    try
        {
        1/$N
        $N * 10
        }
    catch [System.DivideByZeroException]
        {
        'Infinity'
        }
    catch [System.ArithmeticException]
        {
        'Also Infinity'
        }
    catch
        {
        "You're kidding, right?"
        }
    }

BigInverseOf 2
BigInverseOf 0
BigInverseOf ([decimal]::MaxValue)
BigInverseOf potato



##  Nested try/catch example

try
    {
    Do-Thing1

    try
        {
        Do-Thing2A
        Write-Log -Text 'Success'
        }
    catch
        {
        try
            {
            Do-Thing2B
            Write-Log -Text 'Success with thing 2B'
            }
        catch
            {
            Write-Log -Text 'Neither thing 2A nor 2B worked'
            }
        }
    }
catch
    {
    Write-Log -Text 'Thing 1 failed'
    }



##  Intentionallay throw an error

try
    {
    throw
    }
catch
    {
    Write-Log -Text 'Error' -ErrorRecord $_
    }



##  Throw error with message

try
    {
    throw "Superior is too far to drive."
    }
catch
    {
    Write-Log -Text 'Error' -ErrorRecord $_
    }



##  Throw specific exception type

try
    {
    throw [System.DivideByZeroException]@{}
    }
catch
    {
    Write-Log -Text 'Error' -ErrorRecord $_
    }



##  Throw specific error type with custom message

try
    {
    throw [System.DivideByZeroException]"I can't go there"
    }
catch
    {
    Write-Log -Text 'Error' -ErrorRecord $_
    }



##  More error action examples

#  Error not caught
try
    {
    Get-Item D:\DoesNotExist
    }
catch
    {
    Write-Log -Text 'Error' -ErrorRecord $_
    }



#  Set error action preference 
$ErrorActionPreference = 'Stop'

#  Error caught
try
    {
    Get-Item D:\DoesNotExist
    }
catch
    {
    Write-Log -Text 'Error' -ErrorRecord $_
    }



#  Reset to normal
$ErrorActionPreference = 'Continue'


#  Function does not respect -ErrorAction switch

function Get-HRAPIUser
    {
    Param  ( $EmpID )

    $User = Invoke-RestMethod2 -Uri "$HRapiURL/UserbyID?EmpID=$EmpID"

    If ( -not $User )
        {
        throw [System.Management.Automation.ItemNotFoundException]"EmpID $EmpID not found in HR API."
        }
    Else
        {
        return $User
        }
    }

Get-HRAPIUser -EmpID 123

Get-HRAPIUser -EmpID 123 -ErrorAction SilentlyContinue



#  Function respects -ErrorAction switch via [cmdletbinding()]

function Get-HRAPIUser
    {
    [cmdletbinding()]
    Param  ( $EmpID )

    $User = Invoke-RestMethod2 -Uri "$HRapiURL/UserbyID?EmpID=$EmpID"

    If ( -not $User )
        {
        throw [System.Management.Automation.ItemNotFoundException]"EmpID $EmpID not found in HR API."
        }
    Else
        {
        return $User
        }
    }

Get-HRAPIUser -EmpID 123

Get-HRAPIUser -EmpID 123 -ErrorAction SilentlyContinue



#  ErrorAction acts on internal function code (rather than results)
#  potentially changing the behavior of the function

function Get-HRAPIUser
    {
    [cmdletbinding()]
    Param  ( $EmpID )

    $User = Invoke-RestMethod2 -Uri "$HRapiURL/UserbyID?EmpID=$EmpID"

    If ( -not $User )
        {
        throw [System.Management.Automation.ItemNotFoundException]"EmpID $EmpID not found in HR API."
        }

    return 'Joe Cool'
    }

Get-HRAPIUser -EmpID 123

Get-HRAPIUser -EmpID 123 -ErrorAction SilentlyContinue



##  Rethrow error to parent in nested try/catch 

try
    {
    try
        {
        #  Import module
        Import-Module -Name $Module
        }
    
    #  Error
    #    Log it
    #    Rethrow (skip to end)
    catch
        {
        $ErrorMessage = 'Error importing module'
        Write-Log $ErrorMessage -ErrorRecord $_
        throw $_
        }

    try
        {
        #  Get users
        $Users = Get-ADUser -Filter *
        }
    
    #  Error
    #    Log it
    #    Rethrow (skip to end)
    catch
        {
        $ErrorMessage = 'Error getting users'
        Write-Log $ErrorMessage -ErrorRecord $_
        throw $_
        }
    }

#  Error
#    Email error alert
catch
    {
    #  Email error alert
    Send-MailMessage `
        -To         $AlertList `
        -From       'InfraAutomation@Contoso.com' `
        -Subject    'Error running script' `
        -Body       $ErrorMessage `
        -SMTPServer $SMTPServer
    }



#  Catching unhandled errors

try
    {
    try
        {
        #  Import module
        Import-Module -Name $Module
        }
    
    #  Error
    #    Log it
    #    Rethrow (skip to end)
    catch
        {
        $ErrorMessage = 'Error importing module'
        Write-Log $ErrorMessage -ErrorRecord $_
        throw $_
        }

    try
        {
        #  Get users
        $Users = Get-ADUser -Filter *
        }
    
    #  Error
    #    Log it
    #    Rethrow (skip to end)
    catch
        {
        $ErrorMessage = 'Error getting users'
        Write-Log $ErrorMessage -ErrorRecord $_
        throw $_
        }
    }

#  Error
#    Email error alert
catch
    {
    #  If we didn't get here from a rethrown error
    #    Unhandled error
    If ( -not $_.Exception.WasThrownFromThrowStatement )
        {
        $ErrorMessage = 'Unhandled error'

        Write-Log -Text $ErrorMessage -ErrorRecord $_
        Write-Log -Text $_.ScriptStackTrace
        }

    #  Email error alert
    Send-MailMessage `
        -To         $AlertList `
        -From       'InfraAutomation@Contoso.com' `
        -Subject    'Error running script' `
        -Body       $ErrorMessage `
        -SMTPServer $SMTPServer
    }



##  Simple try/finally example for cleanup

$EAP = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try
    {
    #  All of my code
    }

finally
    {
    #region  Cleanup

    $ErrorActionPreference = $EAP

    #endregion
    }



##  Finally block for cleanup sample

function Get-MailboxCount
    {
    try
        {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
        $Module  = Import-PSSession -Session $Session -DisableNameChecking

        $Mailboxes = Get-Mailbox

        return $Mailboxes.Count
        }
    
    finally
        {
        #region  Cleanup

        $Mailboxes = $Null
        $Module  | Remove-Module
        $Session | Remove-PSSession

        #endregion
        }
    }



##  Ctrl-C demo

try
    {
    Start-Sleep -Seconds 60
    }
finally
    {
    Write-Log 'Finally'
    }



##  Trap statement - "Replaced" by try/catch in PS v2, but sometimes useful

try
    {
    Write-Log -Text 'Start process'
    1/0
    Write-Log -Text 'Still going'
    1/0
    Write-Log -Text 'End process'
    }
catch
    {
    'Infinity'
    }


trap [System.DivideByZeroException]
    {
    'Infinity'
    continue
    }

Write-Log -Text 'Start process'
1/0
Write-Log -Text 'Still going'
1/0
Write-Log -Text 'End process'



##  Big complex example, nested try/catch/finally

$EAP = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try
    {
    try
        {
        #  Import module
        Import-Module -Name $Module
        }
    
    #  Error
    #    Log it
    #    Rethrow (skip to end)
    catch
        {
        $ErrorMessage = 'Error importing module'
        Write-Log $ErrorMessage -ErrorRecord $_
        throw $_
        }

    try
        {
        #  Get users
        $Users = Get-ADUser -Filter *
        }
    
    #  Error
    #    Log it
    #    Rethrow (skip to end)
    catch
        {
        $ErrorMessage = 'Error getting users'
        Write-Log $ErrorMessage -ErrorRecord $_
        throw $_
        }
    
    $UsersDone  = 0
    $UserErrors = 0

    ForEach ( $User in $Users )
        {
        try
            {
            Do-Stuff $User
            $UsersDone++
            }
        catch
            {
            Write-Log -Text "Error processing user [$($User.SamAccountName)]." -ErrorRecord $_
            
            $UserErrors++
            }
        }
    }

catch
    {
    #  Set error exit code
    $ExitCode = 0xBAD

    #  If we didn't get here from a rethrown error
    #    Unhandled error
    If ( -not $_.Exception.WasThrownFromThrowStatement )
        {
        $ErrorMessage = 'Unhandled error'

        Write-Log -Text $ErrorMessage -ErrorRecord $_
        Write-Log -Text $_.ScriptStackTrace
        }
    }

finally
    {
    #region  Send status email

    #  Build email
    If ( $Errormessage )
        {
        $Body = "Error: $ErrorMesage" + [environment]::NewLine
        }
    Else
        {
        $Body = 'Success' + [environment]::NewLine
        }

    $Body += "Users done:  $UsersDone"  + [environment]::NewLine
    $Body += "User errors: $UserErrors" + [environment]::NewLine

    try
        {
        #  Email status
        Send-MailMessage `
            -To         $AlertList `
            -From       'InfraAutomation@Contoso.com' `
            -Subject    'Script complete' `
            -Body       $Body `
            -SMTPServer $SMTPServer
        }

    #  Error
    #    Log it
    catch
        {
        Write-Log -Text 'Error sending status email' -ErrorRecord $_
        }
    
    #endregion


    #region  Clean up

    $ErrorActionPreference = $EAP

    #endregion
    

    #  Return exit code
    Exit $ExitCode
    }
