# This script is set for doing a remote execute to start bootstrap.
# it is separate, so that we can control the commands being passed to the bootstrap script
# and allow us to execute one line of code.

# compatibility:
# PowerShell v2 and newer. (winSrv 2008r2)

write-host " Creating directories ..." -foregroundcolor green
# Creating directory for the temporary files used during bootstrapping
If((Test-Path "c:\temp") -eq $False){New-Item -Path "c:\temp" -ItemType directory}

# Creating directory for chef files. Normally created during boostrap but our
# unattended bootstrap requires the directory earlier than it would be available.
If((Test-Path "c:\chef") -eq $False){New-Item -Path "c:\chef" -ItemType directory}

Set-Location c:\chef

(New-Object System.Net.WebClient).DownloadFile("https://artifcatoryServerpath/bootstrap_sccm_infra_org.ps1","c:\chef\bootstrap.ps1")

c:\chef\bootstrap.ps1 `
  -chef_org sccm `
  -chef_url https://<ChefServer> -chef_env _default `
  -node_name $env:COMPUTERNAME `
  -artifactory_loc https://<artifactoryLocation> `
  -chef_client https://<artifactoryLocation/chef-client-x64.msi `
  -chef_role distribution_point
