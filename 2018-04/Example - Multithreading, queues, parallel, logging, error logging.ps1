<#
    Example code
    v3 - Multithreading for queue-based tasks and parallel performance
         with additional queues and threads for logging and eror handling

    Querying Azure for all properties of all VMs in resource group

    Requires module MultithreadingTest to mock Azure commands.
    (If modified for acutal Azure commands, assumes Azure connection has
     already been established.)

    Uses function New-Thread (in separate file)

    Tim Curwick
    Created for MN PowerShell Automation Group
    4/10/2018
#>

$Timer = [System.Diagnostics.Stopwatch]::StartNew()

$ResourceGroup = 'TestRG'
$LogName       = 'D:\PowerShell\Multithreading\Log.txt'
$ErrorLogName  = 'D:\PowerShell\Multithreading\ErrorLog.txt'

#  Cross-thread objects
$VMNameQueue  = [System.Collections.Concurrent.BlockingCollection[String]]@{}
$VMQueue      = [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]@{}
$ResultQueue  = [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]@{}
$LogQueue     = [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]@{}
$ErrorQueue   = [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]@{}
$VMThreadStatus       = [System.Collections.Concurrent.ConcurrentDictionary[Int,String]]@{}
$VMStatusThreadStatus = [System.Collections.Concurrent.ConcurrentDictionary[Int,String]]@{}

#  Define thread parameters
$VMGeneratorParameters = @{
    ResourceGroup = $ResourceGroup
    VMNameQueue   = $VMNameQueue
    LogQueue      = $LogQueue
    ErrorQueue    = $ErrorQueue }

$VMProcessorParameters = @{
    VMNameQueue    = $VMNameQueue
    VMQueue        = $VMQueue
    VMThreadStatus = $VMThreadStatus
    LogQueue       = $LogQueue
    ErrorQueue     = $ErrorQueue }

$VMStatusProcessorParameters = @{
    VMQueue     = $VMQueue
    ResultQueue = $ResultQueue
    VMStatusThreadStatus = $VMStatusThreadStatus
    LogQueue    = $LogQueue
    ErrorQueue  = $ErrorQueue }

$LogProcessorParameters = @{
    LogName  = $LogName
    LogQueue = $LogQueue }

$ErrorProcessorParameters = @{
    ErrorLogName = $ErrorLogName
    ErrorQueue   = $ErrorQueue }

#  Define thread scripts
$VMGeneratorScript =
    {
    Param (
        [string]$ResourceGroup,
        [System.Collections.Concurrent.BlockingCollection[String]]$VMNameQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$LogQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$ErrorQueue )

    $ThreadType = 'VMGenerator'
    $ThreadId   = [appdomain]::GetCurrentThreadId()
    
    function Write-Log ( $Text )
        {
        $LogQueue.Add( [pscustomobject]@{
            Date       = Get-Date
            ThreadType = $ThreadType
            ThreadId   = $ThreadId
            Message    = $Text } )
        }

    function Write-ErrorLog ( $Text, $ErrorRecord )
        {
        $ErrorQueue.Add( [pscustomobject]@{
            Date       = Get-Date
            ThreadType = $ThreadType
            ThreadId   = $ThreadId
            Message    = $Text
            Error      = $ErrorRecord } )
        }

    Write-Log -Text "Thread start."

    try
        {
        Write-Log -Text 'Getting all VMs for resource group [$ResourceGroup].'

        ##  Get all VMs
        Get-AzureRmVM2 -ResourceGroupName $ResourceGroup |
            ForEach-Object {
                $VMNameQueue.Add( $_.Name ) }

        $VMNameQueue.CompleteAdding()
        }
    catch
        {
        $ErrorMessage = 'Global error.'
        Write-ErrorLog -Text $ErrorMessage -ErrorRecord $_
        Write-Log      -Text $ErrorMessage
        }
    Write-Log -Text "Thread complete."
    }

$VMProcessorScript =
    {
    Param (
        [System.Collections.Concurrent.BlockingCollection[String]]$VMNameQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$VMQueue,
        [System.Collections.Concurrent.ConcurrentDictionary[Int,String]]$VMThreadStatus,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$LogQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$ErrorQueue )

    $ThreadType = 'VMProcessor'
    $ThreadId   = [appdomain]::GetCurrentThreadId()
    
    function Write-Log ( $Text )
        {
        $LogQueue.Add( [pscustomobject]@{
            Date       = Get-Date
            ThreadType = $ThreadType
            ThreadId   = $ThreadId
            Message    = $Text } )
        }

    function Write-ErrorLog ( $Text, $ErrorRecord )
        {
        $ErrorQueue.Add( [pscustomobject]@{
            Date       = Get-Date
            ThreadType = $ThreadType
            ThreadId   = $ThreadId
            Message    = $Text
            Error      = $ErrorRecord } )
        }

    Write-Log -Text "Thread start."

    try
        {
        #  Add self to list of running threads
        $ThreadID = [appdomain]::GetCurrentThreadId()
        $VMThreadStatus[$ThreadID] = 'Running'

        ForEach ( $VMName in $VMNameQueue.GetConsumingEnumerable() )
            {
            Write-Log -Text "Processing VM [$VMName]"

            try
                {
                ##  Get VM
                $VM = Get-AzureRmVM2 -Name $VMName
        
                $VMQueue.Add( $VM )
                }
            catch
                {
                $ErrorMessage = "Error processing VM [$VMName]."
                Write-ErrorLog -Text $ErrorMessage -ErrorRecord $_
                Write-Log      -Text $ErrorMessage
                }
            }

        #  If this is the last running thread
        #    Close the new result queue
        [void]$VMThreadStatus.TryRemove( $ThreadId, [ref]$Null )
        If ( $VMThreadStatus.Count -eq 0 )
            {
            $VMQueue.CompleteAdding()
            }
        }
    catch
        {
        $ErrorMessage = 'Global error.'
        Write-ErrorLog -Text $ErrorMessage -ErrorRecord $_
        Write-Log      -Text $ErrorMessage
        }
    Write-Log -Text "Thread complete."
    }

$VMStatusProcessorScript =
    {
    Param (
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$VMQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$ResultQueue,
        [System.Collections.Concurrent.ConcurrentDictionary[Int,String]]$VMStatusThreadStatus,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$LogQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$ErrorQueue )

    $ThreadType = 'VMStatusProcessor'
    $ThreadId   = [appdomain]::GetCurrentThreadId()
    
    function Write-Log ( $Text )
        {
        $LogQueue.Add( [pscustomobject]@{
            Date       = Get-Date
            ThreadType = $ThreadType
            ThreadId   = $ThreadId
            Message    = $Text } )
        }

    function Write-ErrorLog ( $Text, $ErrorRecord )
        {
        $ErrorQueue.Add( [pscustomobject]@{
            Date       = Get-Date
            ThreadType = $ThreadType
            ThreadId   = $ThreadId
            Message    = $Text
            Error      = $ErrorRecord } )
        }

    Write-Log -Text "Thread start."

    try
        {
        #  Add self to list of running threads
        $ThreadID = [appdomain]::GetCurrentThreadId()
        $VMStatusThreadStatus[$ThreadID] = 'Running'

        ForEach ( $VM in $VMQueue.GetConsumingEnumerable() )
            {
            Write-Log -Text "Processing VM [$($VM.Name)]"

            try
                {
                ##  Get VM status
                $VMStatus = Get-AzureRmVM2 -Name $VM.Name -Status

                ##  Build results
                $Status = [string]$VMStatus.Statuses.
                    Where{ $_.Code }.
                    Where{ $_.Code.StartsWIth( 'PowerState/' ) }.
                    ForEach{ $_.Code.Split( '/' )[1] }

                $Result = [pscustomobject]@{
                    Name   = $VM.Name
                    Size   = $VM.HardwareProfile.VmSize
                    Status = $Status }

                $ResultQueue.Add( $Result )
                }
            catch
                {
                $ErrorMessage = "Error processing VM [$($VM.Name)]."
                Write-ErrorLog -Text $ErrorMessage -ErrorRecord $_
                Write-Log      -Text $ErrorMessage
                }
            }

        #  If this is the last running thread
        #    Close the new result queue
        [void]$VMStatusThreadStatus.TryRemove( $ThreadId, [ref]$Null )
        If ( $VMStatusThreadStatus.Count -eq 0 )
            {
            $ResultQueue.CompleteAdding()
            }
        }
    catch
        {
        $ErrorMessage = 'Global error.'
        Write-ErrorLog -Text $ErrorMessage -ErrorRecord $_
        Write-Log      -Text $ErrorMessage
        }
    Write-Log -Text "Thread complete."
    }

$LogProcessorScript =
    {
    Param (
        [String]$LogName,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$LogQueue )

    ForEach ( $Entry in $LogQueue.GetConsumingEnumerable() )
        {
        $Entry.Date, $Entry.ThreadType, $Entry.ThreadId, $Entry.Message -join ' - ' |
            Out-File -FilePath $LogName -Append
        }
    }

$ErrorProcessorScript =
    {
    Param (
        [String]$ErrorLogName,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$ErrorQueue )

    ForEach ( $ErrorItem in $ErrorQueue.GetConsumingEnumerable() )
        {
        $ErrorItem.Date, $ErrorItem.ThreadType, $ErrorItem.ThreadId, $ErrorItem.Message -join ' - ' |
            Out-File -FilePath $ErrorLogName -Append

        $ErrorItem.Date, $ErrorItem.ThreadType, $ErrorItem.ThreadId, 'Exception Message', $ErrorItem.Error.Exception.Message -join ' - ' |
            Out-File -FilePath $ErrorLogName -Append

        $ErrorItem.Date, $ErrorItem.ThreadType, $ErrorItem.ThreadId, 'Exception Type', $ErrorItem.Error.Exception.GetType() -join ' - ' |
            Out-File -FilePath $ErrorLogName -Append

        $ErrorItem.Date, $ErrorItem.ThreadType, $ErrorItem.ThreadId, 'Inner Exception Message', $ErrorItem.Error.Exception.InnerException.Message -join ' - ' |
            Out-File -FilePath $ErrorLogName -Append
        }
    }

#  Create runspace pool
$RunspacePool = [runspacefactory]::CreateRunspacePool( 1, 24 )
$RunspacePool.Open()

#  Launch threads
$RunningThreads = @()

$RunningThreads += New-Thread -ScriptBlock $VMGeneratorScript    -Parameters $VMGeneratorParameters    -RunspacePool $RunspacePool

ForEach ( $i in 1..4 )
    {
    $RunningThreads += New-Thread -ScriptBlock $VMProcessorScript -Parameters $VMProcessorParameters -RunspacePool $RunspacePool
    }
ForEach ( $i in 1..4 )
    {
    $RunningThreads += New-Thread -ScriptBlock $VMStatusProcessorScript -Parameters $VMStatusProcessorParameters -RunspacePool $RunspacePool
    }

$RunningThreads += New-Thread -ScriptBlock $LogProcessorScript   -Parameters $LogProcessorParameters   -RunspacePool $RunspacePool
$RunningThreads += New-Thread -ScriptBlock $ErrorProcessorScript -Parameters $ErrorProcessorParameters -RunspacePool $RunspacePool

#  Process results
ForEach ( $Result in $ResultQueue.GetConsumingEnumerable() )
    {
    $Result
    }

$ErrorQueue.CompleteAdding()
$LogQueue.CompleteAdding()

While ( $ErrorQueue.Count -or $LogQueue.Count ) { Start-Sleep -Milliseconds 100 }

#  Clean up
$RunningThreads | ForEach-Object { $_.PowerShell.Dispose() }
$RunspacePool.Dispose()

$Timer.Elapsed.TotalSeconds
