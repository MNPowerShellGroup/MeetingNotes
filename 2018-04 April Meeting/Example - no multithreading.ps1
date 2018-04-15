<#
    Example code
    v1 - Single threaded

    Querying Azure for all properties of all VMs in resource group

    Requires module MultithreadingTest to mock Azure commands.
    (If modified for acutal Azure commands, assumes Azure connection has
     already been established.)

    Tim Curwick
    Created for MN PowerShell Automation Group
    4/10/2018
#>

$Timer = [System.Diagnostics.Stopwatch]::StartNew()

$ResourceGroup = 'TestRG'

##  Get all VMs
$EmptyVMs = Get-AzureRmVM2 -ResourceGroupName $ResourceGroup

ForEach( $EmptyVM in $EmptyVMs )
    {
    ##  Get VM
    $VM       = Get-AzureRmVM2 -Name $EmptyVM.Name

    ##  Get VM status
    $VMStatus = Get-AzureRmVM2 -Name $EmptyVM.Name -Status

    ##  Build results
    $Status = [string]$VMStatus.Statuses.
        Where{ $_.Code }.
        Where{ $_.Code.StartsWith( 'PowerState/' ) }.
        ForEach{ $_.Code.Split( '/' )[1] }

    [pscustomobject]@{
        Name   = $VM.Name
        Size   = $VM.HardwareProfile.VmSize
        Status = $Status }
    }

$Timer.Elapsed.TotalSeconds
