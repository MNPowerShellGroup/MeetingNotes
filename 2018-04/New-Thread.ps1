function New-Thread
    {
    <#
        .SYNOPSIS
            Start given PowerShell script in a new thread

        .PARAMETER  ScriptBlockUnique
            ScriptBlock to run in the new thread
            Required

        .PARAMETER  RunspacePoolUnique
            RunspacePool to use for the new thread
            Required

        .PARAMETER  ParametersUnique
            Hashtable - Parameters for the new thread

        .PARAMETER  UseEmbeddedParameters
            Switch
            If present, parameter names are derived from ScriptBlockUnique
            and parameter values are set to matching variable values.

            Matching variables must exist with correct values.

            Thread parameter names cannot be 'ScriptBlockUnique',
            'RunspacePoolUnique', 'ParametersUnique', or 'UseEmbeddedParameters'.

        .NOTES
            v 1.0  3/23/18  Tim Curwick  Created
    #>

    [cmdletbinding()]
    Param (
        [ScriptBlock]
        $ScriptBlockUnique,

        [System.Management.Automation.Runspaces.RunspacePool]
        $RunspacePoolUnique,
        
        [Hashtable]
        $ParametersUnique,
        
        [Switch]
        $UseEmbeddedParameters )

    If ( $UseEmbeddedParameters )
        {
        #  Build parameter hashtable
        $ScriptBlockUnique.Ast.ParamBlock.Parameters |
            ForEach-Object { $_.Name.ToString().Trim( '$' ) } |
            ForEach-Object `
                -Begin   { $ParametersUnique  = @{} } `
                -Process { $ParametersUnique += @{ $_ = Get-Variable -Name $_ -ValueOnly } }
        }

    #  Create thread
    $PowerShell = [PowerShell]::Create()
    $PowerShell.RunspacePool = $RunspacePoolUnique
    
    #  Add script
    [void]$PowerShell.AddScript( $ScriptBlockUnique )
    
    #  Add parameters
    If ( $ParametersUnique.Count )
        {
        [void]$PowerShell.AddParameters( $ParametersUnique )
        }
    
    #  Start thread
    $Handler = $PowerShell.BeginInvoke()
        
    #  Return thread hooks
    [PSCustomObject]@{
        PowerShell = $PowerShell
        Handler    = $Handler }
    }
