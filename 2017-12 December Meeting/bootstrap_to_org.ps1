# This script will bootstrap windows 2008 and 2012 servers.



Param(
[parameter(Mandatory=$true)][string]$chef_org,
[parameter(Mandatory=$true)][string]$chef_url,
[parameter(Mandatory=$true)][string]$chef_env,
[parameter(Mandatory=$true)][string]$chef_role,
[parameter(Mandatory=$true)][string]$node_name,
[parameter(Mandatory=$true)][string]$artifactory_loc,
[parameter(Mandatory=$true)][string]$chef_client,
[parameter(Mandatory=$false)][switch]$Force
)

# This function is to provide backwards compatibility to Server 2008r2.
# it would be used instead of the Invoke-WebRequest commandlet

Function get-webcontent()
{
  param(
    [Parameter(Mandatory=$true)][string]$uri,
    [Parameter(Mandatory=$true)][string]$OutFile
  )

  write-host " $uri" -foregroundcolor cyan
  write-host " downloading to" -nonewline
  write-host " $OutFile" -foregroundcolor cyan

  try{
    (New-Object System.Net.WebClient).DownloadFile($uri, $OutFile)
  }
    catch [Net.WebException]{
    Write-Host $_.Exception.ToString().split("`n")[0] -foregroundcolor red
  }

  $test = test-path $OutFile
  return $test
}
#================================#

Function get-ChefOrg($rServer){
   $Path = "\\$rServer\c$\chef\client.rb"

   If(Test-Path $Path.trim() -PathType leaf){

     $line = (select-string $path -pattern "chef_server_url").line
     if($line.contains("`'")){$chefServer = $line.split("`'")[1]} #single quotes
     elseif($line.contains("`"")){$chefServer = $line.split("`"")[1]} #double quotes
     Else{$chefServer = $line.split(" ")[1]} #no quotes
   } else {
     $chefServer = "none"
   }
   return $chefServer
}
#================================#

# Define Log File location
write-host "Setting up logs..."
$ScriptPath = split-path $MyInvocation.InvocationName -Parent  #Path of Script
$ScriptFile = split-path $MyInvocation.InvocationName -Leaf    #FileName of Script
$ScriptName = $ScriptFile.Split(".")[0]
$LogFile = "$ScriptPath\$ScriptName`_log`_$(get-date -f yyyy-MM-dd-hh-mm-ss).csv"

$LogLine = "TIMESTAMP,STATUS"
Out-File -FilePath $LogFile -InputObject $LogLine -encoding ascii

Write-Host "Logging to:  " -nonewline
write-host $LogFile -BackgroundColor yellow -ForegroundColor DarkBlue


$LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Start: $node_name"
Write-Host $LogLine -foregroundColor green
Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

write-host "Checking Windows Versions..."
$os = (Get-WmiObject -class Win32_OperatingSystem).Caption
$LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Server OS: $os"
Write-Host $LogLine -foregroundColor green
Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

write-host "Validating working directories ..."
# Creating directory for the temporary files used during bootstrapping
If((Test-Path "c:\temp") -eq $False){
  New-Item -Path "c:\temp" -ItemType directory
  $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Creating: c:\temp"
  Write-Host $LogLine -foregroundColor green
  Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
}

# Creating directory for chef files. Normally created during boostrap but our
# unattended bootstrap requires the directory earlier than it would be available.
If((Test-Path "c:\chef") -eq $False){
  New-Item -Path "c:\chef" -ItemType directory
  $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Creating: c:\chef"
  Write-Host $LogLine -foregroundColor green
  Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
}else{
  # ok, if c:\chef already exists, then a bootstrap has probably already been done.
  # should probably check which org this server is part of. If not the one we are
  # trying to add, then we should clear out the old stuff and redo it. If it is
  # already in the org we want, then maybe we stop?

  #check if currently part of chef org. log it.
  write-host "c:\chef " -nonewline -foregroundcolor cyan
  write-host "already exists on " -nonewline
  write-host $node_name -foregroundcolor cyan -nonewline
  write-host " checking if it is already part of a chef org..."
  $HasChef = get-ChefOrg($node_name)

  If($Force){
  $LogLine = "$node_name, force parameter included, forcing re-bootstrap,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
   Write-Host $LogLine -foregroundColor green
   Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
   $HasChef = "FORCING" # this will cause the next evauation to be true
   }

  If($HasChef -ne "none" -AND $HasChef -notmatch $chef_org){
    # there is a chef_org, but it is not what we are looking for.
    # Hijacking commences.
    $LogLine = "$node_name,Current chef location: $HasChef,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    $LogLine = "$node_name,Moving to chef location: $Chef_url/organizations/$chef_org,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    #Stop the service.
    Stop-Service "chef-client" -Force
    $LogLine = "$node_name,Stopped Chef-Client Service,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    #before we delete, lets grab the log file contents
    $temp = Get-Content $LogFile

    #Delete C:\chef\*
    Remove-Item "C:\chef\*" -Force -Recurse

    #write the log file back before going on.
    Out-File -FilePath $LogFile -Append -Force -InputObject $temp -encoding ascii

    $LogLine = "$node_name,cleared items from c:\chef\,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    #Delete chef-client
    $return = ([wmi]((Get-WmiObject -Class Win32_Product | Where-Object -FilterScript {$_.Name -like "*chef*"}).__PATH)).uninstall()

    If ($return.ReturnValue -eq 0){
      $LogLine = "$node_name,Uninstalled current chef-client,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
      Write-Host $LogLine -foregroundColor green
      Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
    }else{
      $LogLine = "$node_name,Unable to uninstalled current chef-client,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
      Write-Host $LogLine -foregroundColor red
      Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
    }


  }elseif($HasChef -match $chef_org){
    # this server is already in the chef_org we want.
    $LogLine = "$node_name,Already in chef location: $Chef_url/organizations/$chef_org - exiting,$(get-date -f yyyy-MM-dd-hh-mm-ss)"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
    exit

  } # if it gets here, "none" is presumed for existing chef_org, we can move ahead.

}


# Creating the root certificate file, downloading the contents, and adding it to
# the correct certificate store. This is required so the server can be trusted on
# the network. Additionally, the current root certificate does not install in the
# correct store by default, so we had to define it.
write-host "Installing  root certificate ..."
$urifile = "http://RootCertificateLocation/Root.crt"
$LocalFile = "C:\temp\Root.crt"
$result = get-webcontent -uri $urifile -OutFile $LocalFile
If($result -eq $false){
  $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Unable to download: $uriFile - exiting script."
  Write-Host $LogLine -foregroundColor red
  Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

  exit
} else {
  # cert downloaded, so add it.
  Write-host "======START CERTUTIL OUTPUT ======" -foregroundcolor yellow
  Certutil -addstore "Root" $LocalFile
  Write-host "======END CERTUTIL OUTPUT ======" -foregroundcolor yellow
  $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Installed Root certificate $localFile"
  Write-Host $LogLine -foregroundColor green
  Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

  # Downloading the chef organization validator pem file. This allows the node to
  # be able to connect and talk to the chef org.
  write-host "Downloading validator pem..."
 $urifile = "$artifactory_loc/bootstrap_windows/$chef_org-validator.pem"
  $localFile = "C:\chef\$chef_org-validator.pem"

  $result = get-webcontent -uri $urifile -OutFile $localFile
  If($result -eq $false){

    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Unable to download $uriFile - exiting script."
    Write-Host $LogLine -foregroundColor red
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    exit
  } else {
    # pem file downloaded so, get next file.
    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Downloaded: $localFile"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    write-host "Downloading launch.bat..."
    # Hardcoding for now :( since this only exists in one orag at the moment
    # $urifile = "$artifactory_loc/launch.bat"
    $urifile = "https://ArtifactoryLocation/launch.bat"
    $localFile = "C:\chef\launch.bat"

    $result = get-webcontent -uri $urifile -OutFile $localFile
    If($result -eq $false){

    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Unable to download: $uriFile - exiting script."
    Write-Host $LogLine -foregroundColor red
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    exit
  } else {
    #Lanch.bat downloaded, so get next file.
    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Downloaded: $localFile"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    write-host "Downloading chef client msi..."
    $urifile = $chef_client
    $localFile = "c:\temp\chef-client.msi"

    $result = get-webcontent -uri $urifile -OutFile $localFile
    If($result -eq $false){

    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Unable to download: $uriFile - exiting script."
    Write-Host $LogLine -foregroundColor red
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    exit
  } else {
    # All the files downloaded successfully, so Install things now.
    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),downloaded $uriFile to $localFile"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    write-host "Installing chef client ..."
    Start-Process msiexec -NoNewWindow -Wait -RedirectStandardOutput msilog.txt -RedirectStandardError msiError.txt -ArgumentList "/q /i ""C:\temp\chef-client.msi"" ADDLOCAL=""ChefClientFeature,ChefServiceFeature"""
    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Installed: $localFile"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    write-host "Executing launch.bat to create client.rb and node.json ..."
    c:\chef\launch.bat $chef_org $chef_url $chef_env $chef_role $node_name
    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Executed: c:\chef\launch.bat $chef_org $chef_url $chef_env $chef_role $node_name"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

    write-host "Executing first chef run ..."
    Write-host "======START CHEF-CLIENT OUTPUT ======" -foregroundcolor yellow
    c:\opscode\chef\bin\chef-client.bat -j c:\chef\node.json -E $chef_env -i 0 --once
    Write-host "======END CHEF-CLIENT OUTPUT ======" -foregroundcolor yellow
    $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),Executed first chef run"
    Write-Host $LogLine -foregroundColor green
    Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii

  }
  }
  }
  $LogLine = "$(get-date -f yyyy-MM-dd-hh-mm-ss),End $node_name"
  Write-Host $LogLine -foregroundColor green
  Out-File -FilePath $LogFile -Append -Force -InputObject $LogLine -encoding ascii
}
