#  Single thread
$Groups | Get-ADGroupMember

#  Default 2 threads
$Groups | Invoke-Multithread Get-ADGroupMember


#  Single thread
$Groups | Get-ADGroupMember -Server DC01

#  4 threads
$Groups | Invoke-Multithread Get-ADGroupMember -Parameters @{ Server = 'DC01' } -Threads 4


#  Single thread
$Groups | Get-ADGroupMember -Server DC01 -Recursive

#  8 threads
$Groups | Invoke-Multithread Get-ADGroupMember -Parameters @{ Server = 'DC01'; Recursive = $True } -Threads 8


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