<#
.SYNOPSIS
    A simple implentation of FizzBuzz
.DESCRIPTION
    Counts through numbers, from 1 to the maxCount value.  If the number is divisible by 3, it outputs "fizz"
    If it is divisible by 5, it outputs "Buzz", if it is divisible by both, it outputs "FizzBuzz" 
.EXAMPLE
    PS C:\> fizzbuzz.ps1
    Plays fizzbuzz up to 10
    1
    2
    Fizz
    4
    Buzz
    Fizz
    7
    8
    9
    Buzz
.EXAMPLE
    PS C:\> fizzbuzz.ps1 -MaxCount 100
    Plays fizzbuzz up to 100
.INPUTS
    [Integer]
.NOTES
    Inspired by Tom Scott's IT Interview question youtube video
#>
function Start-FizzBuzz
{
    param(
        [parameter(Mandatory = $false)]
        [int]
        $MaxCount = 10
    )

    foreach ($i in (1..$MaxCount))
    {
        switch ($i)
        {
            {$i % 3 -eq 0} { $out += 'Fizz' }
            {$i % 5 -eq 0} { $out += 'Buzz' }

            default {$out = $i}
        }
        Write-Output $out
        $out = ''
    }
}