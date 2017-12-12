# Help yourself with comment based help

## Sources

- <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1&viewFallbackFrom=powershell-Microsoft.PowerShell.Core>

- <http://mikefrobbins.com/2016/12/07/locations-for-comment-based-help-in-powershell-functions>

- <http://www.sapien.com/blog/2015/02/18/troubleshooting-comment-based-help>

- Good information from June Blender for a deep dive into PowerShell Help

- <https://github.com/juneb/PowerShellHelpDeepDive>


## What is comment based help

- Comment based help is help for your script or function written into the script or function itself via a series of comments. It can be used to describe what the script or function does, list what parameters it accepts, show examples of utilization, and more. See source link above.

- Comment based help can be access using the get-help cmdlet

- Note that accessing a functions comment based help in a script you must dot source your script then run the get-help cmdlet against the function name
    
    - Example for script

        ```powershell
        C:\githubprojects\MeetingNotes\December Meeting [master ≡]> Get-Help .\adr_wrapper.ps1
        ```

    - Example for function within script. Note if the script has mandatory parameters you must pass the parameters

        ```powershell
        C:\githubprojects\MeetingNotes\December Meeting [master ≡]> . .\adr_wrapper.ps1 -SiteCode nul -ADRName null ; get-help removeupdate
        ```
## Comment based help structure

- Comment based help is written within a comment block

    ```powershell
     <# 
    Enclose your comment based help in a comment block like this.
    It works well for multipled lines of comments which are used in writting comment based help
    #>
    ```
- Keywords in the help are preceded by a . and generally are written all capital letters and followed by and description that is indented on the next line.

    - You can use one to all of the keywords for comment based help.
    - There are many keywords, here's a short list of main keywords. See the Microsoft doc linked above for a more exhaustive list
    
        - SYNOPSIS

            -Brief explanation of what script or function does

        - DESCRIPTION

            -A detailed explanaion of what script or function does

        - PARAMETER <name>

            -Explanation of the parameter. Write one for each parameter.

        - EXAMPLE

            -Example of utilization. Can have mulitple .EXAMPLE sections for multiple examples.

## Auto generated help

- Get-Help cmdlet auto generates the following list content that will display along with the hel your right

    - Name
    
    - Syntax

    - Parameter List

    - Common Parameters

    - Parameter Attribute Table

    - Remarks


## Where to use comment based help in script

- Begining of script file

    - This is the preferred location.

- End of the script file

    - Not preferred, but can be used. Comment-based help is meant to be leveraged outside of the script, so location isn't of paramount importance.

## Where to use comment based help in function

- Beginning of function body

    - This is the preferred location. This helps keep the comment-based help as part of the funtion.

- End of function body

    - Much like the script help this is not preferred, but can be used. Comment-based help is meant to be leveraged outside of the function, so location isn't of paramount importance.

- Before function keyword

    - Not preferred, this historically is where I'd describe the function. But I see the benefits of the help within the funtion to keep it self contained.

## When to use comment based help

 - Comment based help acts as good documention of the intention an utilzation of the script or function. Having good comment based help enables someone to understand the script without having to open the script in an editor. 

 - Comment based help also works well for those troubleshooting the script as it offers information about the intent and can speak to the work the script is doing and why. This offers some advantages over inline comments as it's stored in one place and trouble spots can be called out
 
 - As a contract with the user of the script. Describe what the script or function will do and inform the user of what to expect and for what to watch.

 - As Help Driven Development. Using the help as that contract helps drive what code gets written to meet the comittment create in the help and helps keep us directed to keep scope creep down.
