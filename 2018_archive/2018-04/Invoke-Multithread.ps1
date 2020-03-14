function Invoke-Multithread
    {
    <#
    .SYNOPSIS
        Run input against function in multiple threads

    .PARAMETER  Function
        String - Name of the defined function to run

    .PARAMETER  Parameters
        Hashtable - Parameters (other than pipeline input) for Function

    .PARAMETER  Threads
        Int - Number of parallel threads to use
        Defaults to 2

    .PARAMETER  NoSort
        Switch - If present, results are returned in the order they complete processing.
                 If not present, results are return in the same order as their
                 respective inputs.

    .PARAMETER  InputObject
        Object[] - Array of objects or pipeline input to be processed by Scriptblock


    .EXAMPLE
    #  Single thread
    $Groups | Get-ADGroupMember
    #  Default 2 threads
    $Groups | Invoke-Multithread Get-ADGroupMember

    .EXAMPLE
    #  Single thread
    $Groups | Get-ADGroupMember -Server DC01
    #  4 threads
    $Groups | Invoke-Multithread Get-ADGroupMember -Parameters @{ Server = 'DC01' } -Threads 4

    .EXAMPLE
    #  Single thread
    $Groups | Get-ADGroupMember -Server DC01 -Recursive
    #  8 threads
    $Groups | Invoke-Multithread Get-ADGroupMember -Parameters @{ Server = 'DC01'; Recursive = $True } -Threads 8

    .EXAMPLE
    function YourFunction {
        Param ( [parameter( ValueFromPipeline = $True )]$InputParam, $Thing1, $Thing2 )
        Process
            {
            # Your pipeline code
            }
        }
    #  Single thread
    $InputObjects | YourFunction -Thing1 'Alpha' -Thing2 27
    #  Default 2 threads
    $InputObjects | Invoke-Multithread YourFunction -Parameters @{ Thing1 = 'Alpha'; Thing2 = 27 }

    .EXAMPLE
    function Start-RandomSleep {
        Param ( [parameter( ValueFromPipeline = $True )]$Thing1 )
        Process
            {
            Start-Sleep -Seconds ( Get-Random 5 )
            $Thing1
            }
        }
    #  Default sorting - Output is in same order as input
    1..10 | Invoke-Multithread Start-RandomSleep -Threads 10

    #  returns 1, 2, 3, 4, 5, 6, 7, 8, 9, 10


    #  NoSort option - Results returned when ready
    1..10 | Invoke-Multithread Start-RandomSleep -Threads 10 -NoSort

    #  returns 7, 4, 5, 1, 6, 8, 10, 2, 3, 9


    .NOTES
        v1.0  3/16/18  Tim Curwick  Created
    #>
    [cmdletbinding()]
    Param (
        [string]   $Function,
        [hashtable]$Parameters,
        [int]      $Threads = 2,
        [switch]   $NoSort,

        [parameter( ValueFromPipeline = $True )]
        [array]    $InputObject )

    Begin
        {
        #region  Initialize Variables

            #  Collection for thread references        
            $RunningThreads = @()

            #  Index of next input object
            $Index = 0

            #  Index of next sorted result
            $ResultIndex = 0

            #  Result object (needs to exist before using as a [ref] variable)
            $Result = [pscustomobject]@{}

            #  Collection for results
            $Results = @{}

            #  Number of threads must be greater than 0
            $Threads = [math]::Max( $Threads, 1 )

            #  Cross-thread objects
            $InputQueue   = [System.Collections.Concurrent.BlockingCollection[PSObject]]@{}
            $ResultQueue  = [System.Collections.Concurrent.BlockingCollection[PSObject]]@{}
            $ThreadStatus = [System.Collections.Concurrent.ConcurrentDictionary[Int,String]]@{}

        #endregion


        #region  Define wrapped function
        
            #  Get the specified Function
            $Command = Get-Command $Function -ErrorAction SilentlyContinue

            #  If Function is defined in a module
            #    Set the wrapped function as an alias for the Function
            If ( $Command.ModuleName )
                {
                $FunctionDefinition = 'Set-Alias -Name Invoke-WrappedFunction -value ' + $Command.Name
                }

            #  If Function is a script-defined function
            #    Use the definition of Function to define the wrapped function
            ElseIf ( $Command.CommandType -eq 'Function' )
                {
                $FunctionDefinition = 'function Invoke-WrappedFunction { ' + $Command.Definition + ' }'
                }
            
            #  Else (Function is not defined in a module and is not a script-defined function)
            #    Throw error
            Else
                {
                Write-Error -Message "Unable to parse function [$Function]."
                }

            #  Convert wrapped function to scriptblock
            $FunctionDefinition = [scriptblock]::Create( $FunctionDefinition )

        #endregion

        #  Define thread parameters
        $ThreadParameters = @{
            InputQueue         = $InputQueue    
            ResultQueue        = $ResultQueue   
            ThreadStatus       = $ThreadStatus
            FunctionDefinition = $FunctionDefinition
            FunctionParam      = $Parameters }

        #  Define script to run in each thread
        $ThreadScript =
            {
            Param(
                [System.Collections.Concurrent.BlockingCollection[PSObject]]
                $InputQueue,

                [System.Collections.Concurrent.BlockingCollection[PSObject]]
                $ResultQueue,
        
                [System.Collections.Concurrent.ConcurrentDictionary[Int,String]]
                $ThreadStatus,

                [Scriptblock]
                $FunctionDefinition,

                [Hashtable]
                $FunctionParam )

            #  Define Invoke-WrappedFunction
            . $FunctionDefinition

            #  Add self to list of running threads
            $ThreadID = [appdomain]::GetCurrentThreadId()
            $ThreadStatus[$ThreadID] = 'Waiting'

            #  For each Item in queue...
            #  (If queue is empty, will wait for item. If queue is closed, loop ends.)
            ForEach ( $Item in $InputQueue.GetConsumingEnumerable() )
                {
                #  Set status to busy
                $ThreadStatus[$ThreadID] = 'Processing'

                #  Define result hashtable
                $Result = @{ Index = $Item.Index; Value = $Null; Error = $Null }

                #  Call wrapped function, with or without additional parameters
                try
                    {
                    If ( $FunctionParam.Keys )
                        {
                        $Result.Value = $Item.Value | Invoke-WrappedFunction @FunctionParam
                        }
                    Else
                        {
                        $Result.Value = $Item.Value | Invoke-WrappedFunction
                        }
                    }
                
                #  Error
                #    Add to result
                catch
                    {
                    $Result.Error = $_
                    }
    
                #  Return result
                $ResultQueue.Add( $Result )

                #  Set status to ready for work
                $ThreadStatus[$ThreadID] = 'Waiting'
                }

            #  If this is the last running thread
            #    Close the new result queue
            [void]$ThreadStatus.TryRemove( $ThreadId, [ref]$Null )
            If ( $ThreadStatus.Count -eq 0 )
                {
                $ResultQueue.CompleteAdding()
                }
            }
            
        #  Create runspace pool
        $RunspacePool = [runspacefactory]::CreateRunspacePool( 1, $Threads )
        $RunspacePool.Open()
        }

    Process
        {
        try
            {
            #  For each input object (looping to handle non-pipeline array input)
            ForEach ( $InputElement in $InputObject )
                {

                #  If we are not yet at max thread count and
                #  there are no threads waiting for work
                #    Start another thread
                If ( $RunningThreads.Count -lt $Threads -and
                        $ThreadStatus.Values -notcontains 'Waiting' )
                    {
                    #  Create thread
                    $PowerShell = [PowerShell]::Create()
                    $PowerShell.RunspacePool = $RunspacePool
    
                    #  Add script
                    [void]$PowerShell.AddScript( $ThreadScript )
    
                    #  Add parameters
                    [void]$PowerShell.AddParameters( $ThreadParameters )
    
                    #  Start thread
                    $Handler = $PowerShell.BeginInvoke()
        
                    #  Add thread hooks to collection
                    $RunningThreads += [PSCustomObject]@{
                        PowerShell = $PowerShell
                        Handler    = $Handler }
                    }

                #  Add input object to input queue
                #  (Adding an index so results can be returned in the correct order)
                $InputQueue.Add( @{ Index = $Index++; Value = $InputElement } )

                #  Check result queue
                #    Put any results in the results collection
                #    Repeat until empty
                While ( $ResultQueue.TryTake( [ref]$Result ) )
                    {
                    #  If NoSort specified
                    #    Return result immediately
                    If ( $NoSort )
                        {
                        #  Return result value to output stream
                        $Result.Value

                        #  If an error was returned
                        #    Write error to error stream
                        If ( $Result.Error )
                            {
                            Write-Error -ErrorRecord $Result.Error
                            }
                        }

                    #  Else (NoSort not specified)
                    #    Save result to collection
                    Else
                        {
                        $Results[$Result.Index] = $Result
                        }
                    }

                #  If NoSort not specified
                #    Process result collection
                If ( -not $NoSort )
                    {

                    #  Check results collection
                    #    If the result for the next result index is found
                    #      Process it
                    #    Repeat as needed
                    While ( $Results[$ResultIndex] )
                        {
                        #  Return result value to output stream
                        $Results[$ResultIndex].Value

                        #  If an error was returned
                        #    Write error to error stream
                        If ( $Results[$ResultIndex].Error )
                            {
                            Write-Error -ErrorRecord $Results[$ResultIndex].Error
                            }

                        #  Remove processed result from results collection
                        $Results.Remove( $ResultIndex )

                        #  Increment next result index to process
                        $ResultIndex++
                        }
                    }
                }
            }
        finally
            {
            #  Catch Ctrl-C
            If ( -not $? )
                {
                #  Clean up
                $InputQueue.CompleteAdding()
                $RunningThreads | ForEach-Object { $_.PowerShell.Stop(); $_.PowerShell.Dispose() }
                $RunspacePool.Dispose()
                }
            }
        }

    End
        {
        try
            {
            #  Close input queue
            $InputQueue.CompleteAdding()

            #  For each result in result queue
            #  (Will wait for additional results until queue is closed)
            ForEach ( $Result in $ResultQueue.GetConsumingEnumerable() )
                {
                If ( $NoSort )
                    {
                    #  Return result value to output stream
                    $Result.Value

                    #  If an error was returned
                    #    Write error to error stream
                    If ( $Result.Error )
                        {
                        Write-Error -ErrorRecord $Result.Error
                        }
                    }
                Else
                    {
                    #  Put result in results collection
                    $Results[$Result.Index] = $Result

                    #  Check results collection
                    #    If the result for the next result index is found
                    #      Process it
                    #    Repeat as needed
                    While ( $Results[$ResultIndex] )
                        {
                        #  Return result value to output stream
                        $Results[$ResultIndex].Value

                        #  If an error was returned
                        #    Write error to error stream
                        If ( $Results[$ResultIndex].Error )
                            {
                            Write-Error -ErrorRecord $Results[$ResultIndex].Error
                            }

                        #  Remove processed result from results collection
                        $Results.Remove( $ResultIndex )

                        #  Increment next result index to process
                        $ResultIndex++
                        }
                    }
                }
            }
        finally
            {
            #  Clean up
            $RunningThreads | ForEach-Object { $_.PowerShell.Stop(); $_.PowerShell.Dispose() }
            $RunspacePool.Dispose()
            }
        }
    }