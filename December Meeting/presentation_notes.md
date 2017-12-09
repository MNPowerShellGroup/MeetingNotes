# Help yourself with comment based help

## Sources

source:  <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1&viewFallbackFrom=powershell-Microsoft.PowerShell.Core>


## What is comment based help

-Comment based help is help for your script or function written into the script or function itself via a series of comments. It can be used to describe what the script or function does, list what parameters it accepts, show examples of utilization, and more. See source link above.

-Comment based help can be access using the get-help cmdlet
    
    -show example from adr_wrapper.ps1
## Comment based help structure

-Comment based help is written within a comment block

    -<# and# >, signifiy the beginning and end of a script block

-Keywords in the help are preceded by a . and generally are written all capital letters and followed by and description that is indented on the next line.

    -You can use one to all of the keywords for comment based help.
    -There are many keywords, here's a short list of main keywords. See the source above for a more exhaustive list
    
        -SYNOPSIS

            -Brief explanation of what script or function does

        -DESCRIPTION

            -A detailed explanaion of what script or function does

        -PARAMETER <name>

            -Explanation of the parameter. Write one for each parameter.

        -EXAMPLE

            -Example of utilization. Can have mulitple .EXAMPLE sections for multiple examples.

## Auto generated help



## Where to use comment based help in script

-Begining of script file

    -This is the preferred location.

-End of the script file

    -Not preferred, but can be used. Comment-based help is meant to be leveraged outside of the script, so location isn't of paramount importance.

## Where to use comment based help in function

-Beginning of function body

    -This is the preferred location. This helps keep the comment-based help as part of the funtion.

-End of function body

    -Much like the script help this is not preferred, but can be used. Comment-based help is meant to be leveraged outside of the function, so location isn't of paramount importance.

-Before function keyword

    -Not preferred, this historically is where I'd describe the function. But I see the benefits of the help within the funtion to keep it self contained.



