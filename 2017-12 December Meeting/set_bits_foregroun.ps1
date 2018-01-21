<#
.SYNOPSIS
    Sets BITS download jobs to foreground for the number of max threads specified.
.DESCRIPTION
    This script sets the first 8 BITS download jobs to foreground to speed up content distribution. 8 threads was the 
    chosen number as BITS seemed to go a little sideways when running more than 8 parallel downloads on Server 2012. We
    can set the BITS jobs to foreground as we've QOS on the WAN to ensure we don't utilize excessive amounts of WAN link.
    This setting will loop for ~24 hours to ensure that 8 BITS jobs are downloading in foregroud all the time. The script is deployed as
    an SCCM baseline that runs once a day.
#>
function runme {
$MaxThreads = 8
$ShouldRun = $true

While ($ShouldRun -eq $true) {
    if ((Get-BitsTransfer -AllUsers).count -eq 0) {     
       #"no jobs"
       $ShouldRun = $false
       break 
       }
    if  ((Get-BitsTransfer -AllUsers | ? {$_.jobstate -eq "transferring"}).count -eq -0){
        #"no jobs transferring"
        break 
    }
    if ((Get-BitsTransfer -AllUsers | ? {<# $_.jobstate -eq "transferring"  -and #> $_.priority -eq "foreground"}).count -lt $MaxThreads -and $ShouldRun -eq $true ) {         
            # "set job"
            Get-BitsTransfer -AllUsers | ? {<# $_.jobstate -eq "transferring"  -and #> $_.priority -ne "foreground"} | select -First 1 | Set-BitsTransfer -Priority Foreground | Out-Null
            # "sleep"
            start-sleep 1
            if ((Get-BitsTransfer -AllUsers | ? {<# $_.jobstate -eq "transferring"  -and #> $_.priority -eq "foreground"}).count -ge $MaxThreads) { 
                #"too many jobs, break"
                $ShouldRun = $false
                break
                }
            }
    else {$ShouldRun = $false}
    }

#write-host "compliant"
}

0..1500 | % { 
#"running"
# write-host "count $_ of 1500"
runme
start-sleep 60
}

