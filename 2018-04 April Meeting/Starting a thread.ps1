<#
    Example code for

    Starting a thread

    Tim Curwick
    Created for MN PowerShell Automation Group
    4/10/2018
#>


#  Cross-thread objects
$UserQueue   = [System.Collections.Concurrent.BlockingCollection[String]]@{}
$OutputQueue = [System.Collections.Concurrent.BlockingCollection[PSObject]]@{}

#  Thread parameters
$ThreadParameters = @{
    UserQueue = $UserQueue
    OutputQueue = $OutputQueue
    SomeOtherVariable = $SomeOtherVariable }

#  Thread script
$ThreadScript = {
    Param (
        [System.Collections.Concurrent.BlockingCollection[String]]$UserQueue,
        [System.Collections.Concurrent.BlockingCollection[PSObject]]$OutputQueue,
        [String]$SomeOtherVariable )

    <#  Thread code here #>

    }

#  Create runspace pool
#  with minimum and maximum number of threads to run
$RunspacePool = [runspacefactory]::CreateRunspacePool( 1, 7 )
$RunspacePool.Open()

#  Create thread
$PowerShell = [PowerShell]::Create()
$PowerShell.RunspacePool = $RunspacePool
 
#  Add script
[void]$PowerShell.AddScript( $ThreadScript )
    
#  Add parameters
[void]$PowerShell.AddParameters( $ThreadParameters )
 
#  Start thread
$Handler = $PowerShell.BeginInvoke()
 
#  Save thread objects
$RunningThread = [PSCustomObject]@{
    PowerShell = $PowerShell
    Handler    = $Handler } 
