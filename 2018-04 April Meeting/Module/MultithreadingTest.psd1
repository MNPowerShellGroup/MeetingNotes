function Get-AzureRmVM2
    {
    Param ( [string]$Name, [switch]$Status )

    Start-Sleep -Milliseconds 1000

    If ( $Status )
        {
        return @{ Statuses = @( @{ Code = 'PowerState/' + ( 'Stopped', 'Running' )[(Get-Random 2)] } ) }
        }
    If ( $Name )
        {
        return @{ Name = $Name; HardwareProfile = @{ VmSize = ( 'S1', 'S2', 'S4' )[(Get-Random 3)] } }
        }
    return ( 10..19 ).ForEach{ @{ Name = "VM$_" } }
    }
