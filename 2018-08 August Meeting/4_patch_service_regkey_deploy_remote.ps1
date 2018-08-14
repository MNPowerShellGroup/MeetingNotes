###########################################################################################
# iPatch_regkey_deploy script                                                             #
# This script will deploy registry keys to setup the given servers for automated patching #
# NOTE: Must be ran with a COID account that has administrator permissions to servers     #
# If registry keys/values already exist on the remote server, they will be modified       #
#  with newly provided settings.                                                          #
# The script currently provides no error checking, so please type your values carefully!  #
# 4/24/2018 Vadim Teosyan                                                                 #
# 5/23/2018 Joe Artz                                                                      #
#       -removed prompts and added parameter set                                          #
#       -updated to run locally or remotely if computer list is supplied                  #
#       -added try...catch to provide feedback to user                                    #
###########################################################################################

[CmdletBinding()]
param(
        [Parameter(Mandatory=$False)]
            [string[]]$server_list,
        [Parameter(Mandatory=$True,
        HelpMessage="Please select one of the following days of the week:  sunday, monday, tuesday, wednesday, thursday, friday")]
        [ValidateSet("sunday","monday","tuesday","wednesday","thursday","friday","saturday")]
            [string]$day,
        [Parameter(Mandatory=$True,
        HelpMessage="Please select a start time using military time from the following list: 0000,0300,0600,0900,1200,1500,1800,2100")]
        [ValidateSet("0000","0300","0600","0900","1200","1500","1800","2100")]
            [string]$start_time
)

#Set the day to lower case
$day = $day.ToLower()

# Setup default patching attributes
# do not change these
$default_management = "yes"
$week = ""
$reoccurrence = "weekly"
$active_management = "yes"
$duration_in_hours = "3"

#set registrty path
$reg_path = "HKLM:\SOFTWARE\TargetCorp\Patch"


# Apply patching registry key attributes to the list of specified servers
If ($server_list -eq $null ) {
    #Set on local computer

    #remove previous values, if any
    If (Test-Path -Path "HKLM:\SOFTWARE\TargetCorp\Patch" ) {

        try {
            
            Remove-Item "HKLM:\SOFTWARE\TargetCorp\Patch" -Recurse -ErrorAction Stop
        }
        catch {

            Write-Host -ForegroundColor Yellow "Could not delete the patch registry key, ensure you're running as an administrator"
            throw 

        }
 
        
    }
   
    #Check if TargetCorp keys exist, if not create
    If (!(test-path "HKLM:\SOFTWARE\TargetCorp" )){

        try {
            New-Item -Path "HKLM:\SOFTWARE\TargetCorp"
        }
        catch {
            Write-Host -ForegroundColor Yellow  "Could not create the TargetCorp registry key, ensure you're running as an administrator"

            throw
        }
        

    }

    #Check if patch key exists, if note create
    If (!(test-path "HKLM:\SOFTWARE\TargetCorp\Patch")){

        try {
            New-Item -Path "HKLM:\SOFTWARE\TargetCorp\Patch"
        }
        catch {
            Write-Host -ForegroundColor Yellow "Could not create the patch registry key, ensure you're running as an administrator"

            throw
        }
        

    }

    #set the registry keys
    try {
        New-ItemProperty -Path $reg_path -Name "default_management" -PropertyType String -Value $default_management -Force
        New-ItemProperty -Path $reg_path -Name "day" -PropertyType String -Value $day -Force
        New-ItemProperty -Path $reg_path -Name "start_time" -PropertyType String -Value $start_time -Force
        New-ItemProperty -Path $reg_path -Name "week_of_month" -PropertyType String -Value $week -Force
        New-ItemProperty -Path $reg_path -Name "reoccurrence" -PropertyType String -Value $reoccurrence -Force
        New-ItemProperty -Path $reg_path -Name "active_management" -PropertyType String -Value $active_management -Force
        New-ItemProperty -Path $reg_path -Name "duration_in_hours" -PropertyType String -Value $duration_in_hours -Force
    }
    catch {
        Write-Host -ForegroundColor Yellow "Could not create the patch registry settings, ensure you're running as an administrator"

        throw
    }


} Else {

    foreach ($server in $server_list){

    #invoke command to check for regkey and remove if exists, as we're overwriyting it
    Invoke-Command -ComputerName $server -ScriptBlock {
        
        If (Test-Path -Path "HKLM:\SOFTWARE\TargetCorp\Patch" ) {

            try {
                Remove-Item "HKLM:\SOFTWARE\TargetCorp\Patch" -Recurse
            }
            catch {
                Write-Host -ForegroundColor Yellow "Could not delete the patch registry key, ensure you're running as an administrator"

                throw
            }
        
        
        }
    }

    Invoke-Command -ComputerName $server -ScriptBlock {
        If (!(test-path "HKLM:\SOFTWARE\TargetCorp" )){

            try {
                New-Item -Path "HKLM:\SOFTWARE\TargetCorp"
            }
            catch {
                Write-Host -ForegroundColor Yellow "Could not create the TargetCorp registry key, ensure you're running as an administrator"

                throw
            }
            
    
        }
    }
    Invoke-Command -ComputerName $server -ScriptBlock {
        If (!(test-path "HKLM:\SOFTWARE\TargetCorp\Patch")){

            try {
                New-Item -Path "HKLM:\SOFTWARE\TargetCorp\Patch"
            }
            catch {
                Write-Host -ForegroundColor Yellow "Could not create the patch registry key, ensure you're running as an administrator"

                throw
            }
            
    
        }
    }

    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "default_management" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$default_management
    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "day" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$day
    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "start_time" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$start_time
    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "week_of_month" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$week
    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "reoccurrence" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$reoccurrence
    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "active_management" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$active_management
    Invoke-Command -ComputerName $server -ScriptBlock {param($P,$D) New-ItemProperty -Path $P -Name "duration_in_hours" -PropertyType String -Value $D -Force} -ArgumentList $reg_path,$duration_in_hours
    }
}