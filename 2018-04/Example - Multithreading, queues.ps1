<#
    Example code
    v2 - Multithreading for queue-based tasks

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

#  Cross-thread objects
$VMNameQueue  = [System.Collections.Concurrent.BlockingCollection[String]]@{}
$VMQueue      = [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]@{}
$ResultQueue  = [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]@{}

#  Define thread parameters
$VMGeneratorParameters = @{
    ResourceGroup = $ResourceGroup
    VMNameQueue   = $VMNameQueue }

$VMProcessorParameters = @{
    VMNameQueue = $VMNameQueue
    VMQueue     = $VMQueue }

$VMStatusProcessorParameters = @{
    VMQueue      = $VMQueue
    ResultQueue  = $ResultQueue }

#  Define thread scripts
$VMGeneratorScript =
    {
    Param (
        [string]$ResourceGroup,
        [System.Collections.Concurrent.BlockingCollection[String]]$VMNameQueue )

    ##  Get all VMs
    Get-AzureRmVM2 -ResourceGroupName $ResourceGroup |
        ForEach-Object {
            $VMNameQueue.Add( $_.Name ) }

    $VMNameQueue.CompleteAdding()
    }

$VMProcessorScript =
    {
    Param (
        [System.Collections.Concurrent.BlockingCollection[String]]$VMNameQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$VMQueue )

    ForEach ( $VMName in $VMNameQueue.GetConsumingEnumerable() )
        {
        ##  Get VM
        $VM = Get-AzureRmVM2 -Name $VMName
        
        $VMQueue.Add( $VM )
        }

    $VMQueue.CompleteAdding()
    }

$VMStatusProcessorScript =
    {
    Param (
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$VMQueue,
        [System.Collections.Concurrent.BlockingCollection[PSCustomObject]]$ResultQueue )

    ForEach ( $VM in $VMQueue.GetConsumingEnumerable() )
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

    $ResultQueue.CompleteAdding()
    }

#  Create runspace pool
$RunspacePool = [runspacefactory]::CreateRunspacePool( 1, 3 )
$RunspacePool.Open()

#  Launch threads
$RunningThreads = @()
$RunningThreads += New-Thread -ScriptBlock $VMGeneratorScript       -Parameters $VMGeneratorParameters       -RunspacePool $RunspacePool
$RunningThreads += New-Thread -ScriptBlock $VMProcessorScript       -Parameters $VMProcessorParameters       -RunspacePool $RunspacePool
$RunningThreads += New-Thread -ScriptBlock $VMStatusProcessorScript -Parameters $VMStatusProcessorParameters -RunspacePool $RunspacePool

#  Process results
ForEach ( $Result in $ResultQueue.GetConsumingEnumerable() )
    {
    $Result
    }

#  Clean up
$RunningThreads | ForEach-Object { $_.PowerShell.Dispose() }
$RunspacePool.Dispose()

$Timer.Elapsed.TotalSeconds
