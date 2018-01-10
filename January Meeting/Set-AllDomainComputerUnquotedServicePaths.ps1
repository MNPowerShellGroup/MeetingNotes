### Audit Workstations For Unquoted Service Paths ###


#Goal: Use existing functions to streamline on demand/scheduled audits for unquoted service paths

#region Functions

Function Get-ServicePath
{
    [CmdletBinding(SupportsShouldProcess)]
 Param
 (
    [Parameter( 
        Mandatory,
        ValueFromPipeline,
        ValueFromPipelinebyPropertyName,
        Position = 0)]
    [ValidateNotNullorEmpty()]
    [Alias('Computer', 'ComputerName', 'Server', '_ServerName')]
    [string[]]$Name = $env:Computername
 )

 Process
 {  
    $ErrorActionPreference = 'Stop'
    # Process each item in Pipeline
    ForEach ( $Computer in $Name )
    { 
    # use try catch blocks for offline computers
        try
        {
            $result = REG QUERY "\\$Computer\HKLM\SYSTEM\CurrentControlSet\Services" /v ImagePath /s 2>&1

                #Error output from this command doesn't catch, so we need to test for it...
                if ($result[0] -like '*ERROR*' -or $result[0] -like '*Denied*')
                {
                    # Only evals true when return from reg is exception
                    #create custom object with info for machine that returns errors
                    [pscustomobject][ordered]@{
                    'ComputerName' = $Computer
                    'Status'        = 'REG Failed'
                    'Key'           = 'Unavailable'
                    'Image Path'    = 'Unavailable'
                    }# End custom object properites

                }# End if

                else
                {
                    # Clean up the format of the results array
                    $result = $result[0..($result.length -2) ] # Remove last (blank line and REG Summary)
                    $result = $result | Where-Object { $_ -ne ""} # Removes blank lines
                    
                    # create loop to create objects for objects found and add object to collection array object
                    $count = 0
                    While ($count -lt $result.length)
                    {
                        $PathValue = $($result[$count+1]).Split("", 11) # split Image Path return
                        $PathValue = $PathValue[10].Trim(' ') # Trim out white space, left with just value data

                        $KeyValue  = $result[$count].Replace('HKEY_LOCAL_MACHINE','HKLM:')

                        $obj = [pscustomobject][ordered]@{
                            'ComputerName' = $Computer
                            'Status'        = 'Retrieved'
                            'Key'           = $KeyValue
                            'ImagePath'     = $PathValue
                        } # End [pscustomobject]

                        # add object to array
                        [array]$Collection += $obj

                        # increase counter for next loop 
                        $count = $count + 2

                        #reset $obj to null
                        $obj = $null

                    } # End While loop

                } # End else

            Write-Output $Collection

            $collection = $null # Reset $collection for next loop
        } # End try
        catch
        {
            #Write-Warning $_.Exception.Message 
        }# End catch

    } # End ForEach

 } # End Process

}


Function Get-UnquotedServicePath
{
    [cmdletbinding(SupportsShouldProcess)]
    	Param ( #Define a Mandatory input
    	[Parameter(
    	 ValueFromPipeline,
    	 ValueFromPipelinebyPropertyName,
    	 Position = 0)]
         $obj
    	) #End Param
    Begin
    {
        Try
        {
            if($obj -eq $null)
            {
                Write-Verbose "$obj is null"
            }
        }

        Catch
        {

        }
    } 
    Process
    { #Process Each object on Pipeline
    	if ($obj.key -eq "Unavailable")
    	{ #The keys were unavailable, I just append object and continue
    	#$obj | Add-Member -MemberType NoteProperty -Name BadKey -Value "Unknown"
    	#$obj | Add-Member -MemberType NoteProperty -Name FixedPath -Value "Can't Fix"
    	#Write-Output $obj
    	$obj = $nul #clear $obj
        
        #break

    	} #end if

    	else
    	{
    	#If we get here, I have a key to examine and fix
    	#We're looking for keys with spaces in the path and unquoted
    	#the Path is always the first thing on the line, even with embedded arguments
    	$examine = $obj.ImagePath
    	if (!($examine.StartsWith('"'))) { #Doesn't start with a quote
    		if (!($examine.StartsWith("\??"))) { #Some MS Services start with this but don't appear vulnerable
    			if ($examine.contains(" ")) { #If contains space
    				#when I get here, I can either have a good path with arguments, or a bad path
    				if ($examine.contains("-") -or $examine.contains("/")) { #found arguments, might still be bad
    					#split out arguments
    					$split = $examine -split " -", 0, "simplematch"
    					$split = $split[0] -split " /", 0, "simplematch"
    					$newpath = $split[0].Trim(" ") #Path minus flagged args
    					if ($newpath.contains(" ")){
    						#check for unflagged argument
    						$eval = $newpath -Replace '".*"', '' #drop all quoted arguments
    						$detunflagged = $eval -split "\", 0, "simplematch" #split on foler delim
    							if ($detunflagged[-1].contains(" ")){ #last elem is executable and any unquoted args
    								$fixarg = $detunflagged[-1] -split " ", 0, "simplematch" #split out args
    								$quoteexe = $fixarg[0] + '"' #quote that EXE and insert it back
    								$examine = $examine.Replace($fixarg[0], $quoteexe)
    								$examine = $examine.Replace($examine, '"' + $examine)
    								$badpath = $true
    							} #end detect unflagged
    						$examine = $examine.Replace($newpath, '"' + $newpath + '"')
    						$badpath = $true
    					} #end if newpath
    					else { #if newpath doesn't have spaces, it was just the argument tripping the check
    						$badpath = $false
    					} #end else
    				} #end if parameter
    				else
    					{#check for unflagged argument
    					$eval = $examine -Replace '".*"', '' #drop all quoted arguments
    					$detunflagged = $eval -split "\", 0, "simplematch"
    					if ($detunflagged[-1].contains(" ")){
    						$fixarg = $detunflagged[-1] -split " ", 0, "simplematch"
    						$quoteexe = $fixarg[0] + '"'
    						$examine = $examine.Replace($fixarg[0], $quoteexe)
    						$examine = $examine.Replace($examine, '"' + $examine)
    						$badpath = $true
    					} #end detect unflagged
    					else
    					{#just a bad path
    						#surround path in quotes
    						$examine = $examine.replace($examine, '"' + $examine + '"')
    						$badpath = $true
    					}#end else
    				}#end else
    			}#end if contains space
    			else { $badpath = $false }
    		} #end if starts with \??
    		else { $badpath = $false }
    	} #end if startswith quote
    	else { $badpath = $false }
    	#Update Objects
    	if ($badpath -eq $false){
    		$obj | Add-Member -MemberType NoteProperty -Name BadKey -Value "No"
    		$obj | Add-Member -MemberType NoteProperty -Name FixedPath -Value "N/A"
    		Write-Verbose $obj
    		$obj = $nul #clear $obj
    		}
    	if ($badpath -eq $true){
    		$obj | Add-Member -MemberType NoteProperty -Name BadKey -Value "Yes"
    		#sometimes we catch doublequotes
    		if ($examine.endswith('""')){ $examine = $examine.replace('""','"') }
    		$obj | Add-Member -MemberType NoteProperty -Name FixedPath -Value $examine
    		Write-Output $obj

    		$obj = $nul #clear $obj
    		}	
    	} #end top else
    } #End Process

    End
    {
    <#  Testing
        
        $Count     = 0
        $Frequency = 500
        $Length    = 100

        While ($Count -lt 25)
        {
            [console]::Beep($Frequency,$Length)
            $Frequency = (Get-Random -Minimum 200 -Maximum 1000)
            $Length = (Get-Random -Minimum 50 -Maximum 200)
            #$Frequency = $Frequency + 5
            $Count++
        }

        # Create SAPI.SPVoice object to "announce" (literally) completion of the Get-UnquotedServicePath function
        $announce      = New-Object -ComObject SAPI.SPVoice
        # set rate a little faster than default
        $announce.rate = 2
        # get array of available voices
        $announceList = $announce.GetVoices()
        # set voice to "Hazel" (british woman voice) ####NOTE: after upgrading to Windows 10 I no longer have Hazel... only David and Zira :(
        $announce.Voice = $announceList.Item(1)
        #  Now have "Hazel" announce the finish ## Win 10 Update - voice is now Zira
        [void] $announce.Speak("I found the unquoted service paths! Ready to take action sir!")
        #>
    }
}


Function Set-QuotedServicePath
{
    [CmdletBinding()]
        Param
        (
            [Parameter(
                ValueFromPipeline,
                ValueFromPipelinebyPropertyName,
                Position = 0 )]
            [ValidateNotNullorEmpty()]
            $UnquotedServiceArray
        )


    Process
    {
        
        $ErrorActionPreference = 'Stop'
        try
        {
            foreach ( $Service in $UnquotedServiceArray)
            {
                # set correct image path for service
                Set-RemoteRegistryKeyProperty -ComputerName $Service.ComputerName -Path $Service.Key -PropertyName ImagePath -PropertyValue $Service.FixedPath

                # add corrected path to array of fixed paths
                #[array]$FixedPathArray += $Service.Key

            }
        }
        catch
        {
            "Unable to set new value for $Service, check to ensure session is running in admin context- note to self....add check to future version"
        }
        finally
        {
            # force correct setting for imagepath
            foreach ( $Service in $UnquotedServiceArray)
            {
                # set correct image path for service
                Set-RemoteRegistryKeyProperty -ComputerName $Service.ComputerName -Path $Service.Key -PropertyName ImagePath -PropertyValue $Service.FixedPath

                # add corrected path to array of fixed paths
                [array]$FixedPathArray += $Service.Key

            }
        }
    }

    End
    {
        "Fixed ImagePath values for: `n"
        foreach($Path in $FixedPathArray)
        {
            "$Path `n"
        }
    }
}


#endregion


#region Variables

$AllComputerList = Get-ADComputer -Filter * -SearchBase 'OU=workstations,DC=PoSh,DC=net'

$ComputerList = Get-Content W:\NinitePro\NiniteWorkstations.txt

$Date = Get-Date -f {yyyy.MM.dd}

$OfflineLogPath = 'W:\WindowsPowerShell\Reports\UnquotedServicePaths\OfflineComputerLog\'

$LogPath = 'W:\WindowsPowerShell\Reports\UnquotedServicePaths\'

#endregion

#region Audit Computers For Unquoted Service Paths and fix any it finds

## Step 1: set up sessions for all online computers in $ComputerList array
foreach ($Computer in $AllComputerList)
{
    If(Test-Connection $Computer.Name -Count 1 -Quiet)
    {
        [array]$OnlineComputerList += $Computer.Name
    }
    Else
    {
        # if computers are offline log time and names for reference
        "$(Get-Date) $($Computer.name) offline" | Out-File $OfflineLogPath\$($Date)_OfflineLog.txt -Append 
    }
}


## Step 2: query all online computers  and check for unquoted service paths. If any are found fix them and output result to log file.
ForEach ($Computer in $OnlineComputerList) 
{ 
    Get-ServicePath -Name $Computer | Get-UnquotedServicePath | Set-QuotedServicePath | Out-File $LogPath\$($Date)_Fixed_Unquoted_Service_Paths.txt -Append 
}

#endregion


