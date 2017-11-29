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

