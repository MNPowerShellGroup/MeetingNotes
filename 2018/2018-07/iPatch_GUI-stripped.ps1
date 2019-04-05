############################
# iPatch API GUI           #
# 5/10/2018                #
# Vadim Teosyan            #
############################

Add-Type -AssemblyName PresentationFramework

[string]$existingProtocols = [System.Net.ServicePointManager]::SecurityProtocol
if(!$existingProtocols.Contains("Tls12")){
[string]$appendProtocols = $existingProtocols + ", Tls12"
$UpdateProtocols = [System.Net.SecurityProtocolType]$appendProtocols
[System.Net.ServicePointManager]::SecurityProtocol = $UpdateProtocols
}

#To Supress all on-screen errors uncomment the line below
#$ErrorActionPreference = 'silentlycontinue'

#Define Global Variables
$global:Authorization = $null
$global:TextboxToken = $null
$global:TextboxKey = $null
$global:servers_collection_id = "<collectionID>"
$global:collection_id = $null
$global:folder_id = "<folderID>"
$global:file = $null
$global:collections = $null
$global:collection_name = $null
$global:maintenance_day = $null
$global:maintenance_time = $null
$global:message = $null
$global:reboot_flag = $true
$global:SUG = $null
$global:SUGName = $null
$global:file = $null

$global:deployment_expiration = $null
$global:deployment_day = $null
$global:deployment_time = $null

$global:DropDownCollections= $null
$global:DropDownCollections2 = $null
$error.clear()

###############################################
#Token and Keys definition + Headers function #
###############################################
$global:Authorization = "Bearer " + $global:TextboxToken.Text
function headers()
{
 $global:Authorization = "Bearer "+"$($global:TextboxToken.Text)";
 $global:headers = @{
 "Authorization" = $global:Authorization
 "x-api-key" = $($global:TextboxKey.Text)
  }
}


function check_keys()
{
  $global:myerror = $null
 if (!$global:TextboxKey.Text -or !$global:TextboxToken.Text) {
   $global:myerror = "1"
  $global:message ="API Key and/or Token missing!
Please provide them in the top fields."
  [System.Windows.MessageBox]::Show($global:message,'Please review the parameters','OK','Error')
 }
}

function verify_keys()
{ 
  $global:myerror = $null
 $error.clear()
 $exec = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1 -Headers $Global:headers
 if ($error -match "Unauthorized") {
    $global:myerror = "1"
  $global:message ="Invalid API Key/Token!
Make sure you are using valid/latest ones."
 [System.Windows.MessageBox]::Show($global:message,'Please review the parameters','OK','Error')
 write-host "READY`n" -ForegroundColor Green
 }
}

function dialog_box()
{
 param($function)
 $result = [System.Windows.MessageBox]::Show($global:message,'Please review the parameters','YesNo','Information')
 if ($result -eq 'Yes') {&$function}
}

function missing_parameters()
{
  [System.Windows.MessageBox]::Show("Missing parameters!
Make sure to make a selection for each item in this step.",'Error!','OK','Error')
}

function error_box()
{
[System.Windows.MessageBox]::Show($global:message,'Error!','OK','Error')
}

function message_box()
{
[System.Windows.MessageBox]::Show($global:message,'Action Completed!','OK','Information')
}

###########################
# Maintenance Window POST #
###########################
function post_maintenance_window ()
{
 write-host "Executing Maintenance Window POST, Please Wait..."
 write-host "`nAdding a new maintenance window to : " -NoNewline
 write-host $global:collection_name -ForegroundColor Green
 $error.clear()
 $global:myerror = "0"

 $date = get-date -format "yyyy-MM-dd"
 $pos = $global:maintenance_time.IndexOf("-")
 $hour = $global:maintenance_time.Substring(0,$pos)
 $start_time = $date+"T"+$hour

 $body = @{
  name = "Maintenance Window"
  collection_id = $global:collection_id
  recurrence_type = "3"
  start_time = $start_time
  day = $global:maintenance_day.ToLower()
  hour_duration = "3"
  week = "1"
 }

 $json = $body | ConvertTo-Json
 write-host $json | Out-String

 $deploy = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/maintenance_windows -Method Post -Body $json -ContentType 'application/json' -Headers $global:headers
 write-host $deploy | Out-String
 
  if ($error) {
  $global:myerror = "1"
  $global:message ="API call timeout/error! `nQuery the Device Collection to check if the Maintenance window was added successfully."
  error_box
  }
   else {
    $global:message = $null;
    $global:message ="Maintenance window was added successfully:`n"
     foreach ($item in $deploy) {$global:message+= $item.description}
    message_box
   }

 write-host
 Write-Host " Device Collections POST executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

####################################
# Function Device Collections POST #
####################################
function post_device_collections ()
{
 write-host "Executing Device Collections POST, Please Wait..."
 write-host "`nCreating a new device collection: " -NoNewline
 write-host $global:collection_name -ForegroundColor Green
 
 $error.Clear()
 $global:myerror = "0"

 $device_list = @()
 foreach ($server in Get-Content $global:file){
  write-host $server;
  write-host
  $device_list += [string]$server
  }

 $body = @{
  collection_name = $global:collection_name
  limit_to_collection_id = $global:servers_collection_id
  device_list = $device_list
  folder_id = $global:folder_id
  rule_name = $global:collection_name
  comment = ""
 }

 $json = $body | ConvertTo-Json
 write-host $json | Out-String

 $deploy = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/device_collections -Method Post -Body $json -ContentType 'application/json' -Headers $global:headers
 write-host $deploy | Out-String

 #$global:message = $deploy | out-string

  if ($error) {
  $global:myerror = "1"
  $global:message ="API call timeout/error! `nQuery the Device Collection to check if it was created successfully."
  error_box
  }
   else {
    $global:message ="Device Collection $global:collection_name was created successfully!"
    message_box
   }

 write-host
 Write-Host "Device Collections POST executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

####################################
# Function Device Collections PUT  #
####################################
function put_device_collections ()
{
 write-host "Executing Device Collections PUT, Please Wait..."
 
 $device_list = @()
 foreach ($server in Get-Content $global:file){
  write-host $server;
  write-host
  $device_list += [string]$server
  }

 $body = @{
 action = "add"
  device_list = $device_list
  rule_name = ""
 }

 $json = $body | ConvertTo-Json

 write-host $json | Out-String

 #$deploy = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/device_collections/$global:collection_id -Method Put -Body $json -ContentType 'application/json' -Headers $global:headers
 write-host $deploy | Out-String

 write-host
 Write-Host "Device Collections PUT executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

######################################
# Function Device Collections DELETE #
######################################
function delete_device_collections ()
{
$error.Clear()
$global:myerror = "0"
 write-host "Executing Device Collections DELETE on collection: $global:collection_id, Please Wait..."
 $deploy = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/device_collections/$global:collection_id -Method Delete -ContentType 'application/json' -Headers $global:headers
 
  if ($error) {
  $global:myerror = "1"
  $global:message ="API call timeout/error! `nQuery the Device Collection to check if it was deleted successfully."
  error_box
  }
   else {
    $global:message ="Device Collection $global:collection_id was deleted successfully!"
    message_box
   }
 
 write-host
 Write-Host "Device Collections DELETE executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

#######################################
# Function Device Collections Details #
#######################################
function details_device_collections ()
{
 write-host "Executing GET Device Collections Details on collection: $global:collection_id, Please Wait..."
  
 $details = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/device_collections/$global:collection_id -Method Get -ContentType 'application/json' -Headers $global:headers
 $maint = $null
 foreach ($item in $details.maintenance_windows) {$maint+= $item.description+"`n"}
 if (!$maint) {$maint = "None defined"}
 
 $message = "Collection ID: "+$details.collection_id+" `nCollection Name: "+$details.collection_name+" `nDevices: "+$details.device_list+" `nMaintenance Windows:`n"+$maint
 
 [System.Windows.MessageBox]::Show($message,'Collection Details','OK','Information')

 Write-Host "GET Device Collections Details executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

####################################
# Function Deployments POST        #
####################################
function post_deployments ()
{
 write-host "Executing Deployments POST, Please Wait..."
 $error.Clear()
 $global:myerror = "0"

 if ($global:reboot_flag -eq $true){$reboot = "0"} else {$reboot = "2"}

  $start_time= $global:deployment_day+"T"+$global:deployment_time
  $date = Get-Date
  $description = "Deployment created on: $date"
  
 $body = @{
  collection_id = $global:collection_id
  update_group_id = [string]$global:SUG
  suppress_reboot = $reboot
  start_time = $start_time
  enforcement_deadline = $start_time
  use_gmt_times = "false"
  install_outside_of_maintenance_windows = "false"
  reboot_outside_of_maintenance_windows = "false"
  deployment_description = $description
  notify_user = "true"
 }

 $json = $body | ConvertTo-Json
 write-host $json | Out-String

 $deploy = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/deployments -Method Post -Body $json -ContentType 'application/json' -Headers $global:headers
 write-host $deploy | Out-String

 if ($error) {
 $global:myerror = "1"
 $global:message ="API call timeout/error! `nQuery your deployment to check if it was scheduled successfully."
 error_box
 }
  else {
   #get-deployments()
   $global:message ="Deployment was scheduled successfully!"
   message_box
   }

 write-host
 Write-Host "Deployments POST executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

############################
# Function Deployments GET #
############################
function get-deployments ($Param3)
{
 $deployments = @()
 write-host "Executing Deployments GET, Please Wait..."
   
 $deployments= Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/deployments -Method Get -ContentType 'application/json' -Headers $global:headers

 $global:deployments = $deployments -match $Param3
 
 if ($Param3) {
  write-host "Deployments GET executed with a search keyword: " -NoNewline
  write-host $Param3 -foregroundColor Green
 }
  else {
   Write-Host "Deployments GET executed"
  }
 write-host "`nREADY`n" -ForegroundColor Green
}

###############################
# Function Deployments DELETE #
###############################
function delete-deployments ()
{
 write-host "Executing Deployments DELETE on deployment:$global:deployment, Please Wait..."
 $error.clear()
 $global:myerror = "0"

 $deployments= Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/deployments/$global:deployment -Method Delete -ContentType 'application/json' -Headers $global:headers
 
 if ($error) {
 $global:myerror = "1"
 $global:message ="API call timeout/error! `nQuery your deployment to check if it was deleted successfully."
 error_box
 }
  else {
   $global:message ="Deployment $global:deployment was deleted successfully!"
   message_box
   }

 Write-Host "Deployments DELETE executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

################################
# Function Deployments Details #
################################
function details-deployments ()
{
 write-host "Executing Deployments Details on deployment: $global:deployment, Please Wait..."
 $error.clear()
 $global:myerror = "0"
 $message = $null

 $deployments= Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/deployments/$global:deployment -Method Get -ContentType 'application/json' -Headers $global:headers

 $message = $deployments | out-string
 [System.Windows.MessageBox]::Show($message,'Deployment Details','OK','Information')

 Write-Host "Deployments Details executed"
 write-host "`nREADY`n" -ForegroundColor Green
}

###################################
# Function Device Collections GET #
###################################
function get-device_collections ($Param2)
{
 $dev_collections = @()
 write-host "Executing Device Collections GET, Please Wait..."

 $dev_collections = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/device_collections -Method Get -ContentType 'application/json' -Headers $global:headers

 $temp = $dev_collections -match $Param2
 $global:collections = $temp -match "APD"

 if ($Param2) {
  write-host "Device Collections GET executed with a search keyword: " -NoNewline
  write-host $Param2 -foregroundColor Green
 }
  else {
   Write-Host "Device Collections GET executed"
  }
 write-host "`nREADY`n" -ForegroundColor Green
}


#############################################################
# Function to retrieve the latest Windows Server SUG number #
#############################################################
function get-sug()
{
write-host "Retrieving the latest Windows Server SUG, Please Wait..."

$SUGs = Invoke-RestMethod -Uri https://API-URL/sccm_patch_deployments/v1/software_update_groups -Method Get -ContentType 'application/json' -Headers $global:headers
$array = @()
foreach ($SUG in $SUGs)
 { 
  if ($SUG.update_group_name -match "Server")
   { $array+= $SUG}  
 }

 #$global:SUG = ($array | measure-object -Property update_group_id -maximum).maximum
 $global:SUG = ($array | sort-object -Property update_group_id -Descending)[0].update_group_id
 $global:SUGName = ($array | sort-object -Property update_group_id -Descending)[0].update_group_name
 write-host "Latest Available Windows Server SUG is: $global:SUG"
 write-host "`nREADY`n" -ForegroundColor Green
 }

################################
# Create Forms and buttons     #
################################
Add-Type -AssemblyName System.Windows.Forms

#Main Form
$Form = New-Object Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(600,920)
$Form.MaximizeBox= "false"
$Form.MinimumSize = "600,920"
$Form.MaximumSize = "600,920"
$Form.StartPosition = "CenterScreen"
$Form.Text = "iPatch GUI"
$Form.AutoSize = $True
#$Icon = New-Object system.drawing.icon (".\pirate.ico")
#$Form.Icon = $Icon

#Form top label
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "This GUI will make iPatch API queries, help you create device collections, schedule deployments, etc."
$Label1.AutoSize = $True
$Label1.Location = new-object system.drawing.size(5,1)
$Form.Controls.Add($Label1)

#Advanced Form
$FormAdvanced = New-Object Windows.Forms.Form
$FormAdvanced.Size = New-Object Drawing.Size @(600,400)
$FormAdvanced.MaximizeBox= "false"
$FormAdvanced.MinimumSize = "600,400"
$FormAdvanced.MaximumSize = "600,400"
$FormAdvanced.StartPosition = "CenterScreen"
$FormAdvanced.Text = "iPatch Advanced Options"
$FormAdvanced.AutoSize = $True

#Advanced Form top label
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "iPatch Advanced Options"
$Label2.AutoSize = $True
$Label2.Location = new-object system.drawing.size(5,1)
$FormAdvanced.Controls.Add($Label2)

#Form API Token
$LabelToken = New-Object System.Windows.Forms.Label
$LabelToken.Text = "API Token:"
$LabelToken.AutoSize = $True
$LabelToken.Location = new-object system.drawing.size(5,20)
$Form.Controls.Add($LabelToken)

#Textbox API Token
$global:TextboxToken = New-Object System.Windows.Forms.TextBox
$global:TextboxToken.Location = New-Object System.Drawing.Size(65,20)
$global:TextboxToken.Size = New-Object System.Drawing.Size(200,20)
$Form.Controls.Add($global:TextboxToken)

#Form API Key
$LabelKey = New-Object System.Windows.Forms.Label
$LabelKey.Text = "API Key:"
$LabelKey.AutoSize = $True
$LabelKey.Location = new-object system.drawing.size(270,20)
$Form.Controls.Add($LabelKey)

#Textbox API Key
$global:TextboxKey = New-Object System.Windows.Forms.TextBox
$global:TextboxKey.Location = New-Object System.Drawing.Size(320,20)
$global:TextboxKey.Size = New-Object System.Drawing.Size(200,20)
$Form.Controls.Add($global:TextboxKey)

#___________________________________________________________________________________________
#Advanced Settings
#Deployments Find/Delete Section
$LabelDeployments = New-Object System.Windows.Forms.Label
$LabelDeployments.Text = "Find and Delete your Deployments:"
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelDeployments.Font = $FontBold
$LabelDeployments.AutoSize = $True
$LabelDeployments.Location = new-object system.drawing.size(5,20)
$FormAdvanced.Controls.Add($LabelDeployments)

#Button "Deployments Delete"
$ButtonDeploymentsDELETE = New-Object System.Windows.Forms.Button
$ButtonDeploymentsDELETE.Text = "Delete Selected Deployment"
$ButtonDeploymentsDELETE.ForeColor = "Red"
$ButtonDeploymentsDELETE.Location = new-object System.Drawing.Size(15,95);
$ButtonDeploymentsDELETE.Size = new-object System.Drawing.Size(160,20);
$ButtonDeploymentsDELETE.add_click({
headers;
verify_keys;
$LabelWorking.Location = new-object system.drawing.size(15,70)
$FormAdvanced.Controls.Add($LabelWorking)
$global:message = "Selected Deployment:`n$($global:DropDownDeployments.selectedItem)`nwill be deleted!`n`nProceed?"
$FormAdvanced.controls.Remove($global:DropDownDeployments);$FormAdvanced.controls.remove($ButtonDeploymentsDELETE)

dialog_box("delete-deployments")
$FormAdvanced.Controls.Remove($LabelWorking)
})

#Button "Deployments GET"
$ButtonDeploymentsGET = New-Object System.Windows.Forms.Button
$ButtonDeploymentsGET.add_click({
$FormAdvanced.controls.Remove($global:DropDownDeployments);$FormAdvanced.controls.remove($ButtonDeploymentsDELETE)
$FormAdvanced.Controls.Remove($LabelNotFound)
headers; 
verify_keys;
$FormAdvanced.Controls.Remove($ButtonGetDeploymentsDetails)
$LabelSearching.Location = new-object system.drawing.size(15,70)
$FormAdvanced.Controls.Add($LabelSearching)
$Param3 = $TextBoxDeploymentsGET.Text ; 

if (!$TextBoxDeploymentsGET.Text) { $global:message = "Search keyword is mandatory!"; error_box ; $FormAdvanced.Controls.Remove($LabelSearching)}
else {
get-deployments $Param3 ; 
$FormAdvanced.Controls.Remove($LabelSearching)

 if ($global:deployments.count -eq "0") {
 $LabelNotFound.Location = new-object system.drawing.size(15,70)
 $FormAdvanced.Controls.Add($LabelNotFound)}
 else {
 $global:DropDownDeployments = new-object System.Windows.Forms.ComboBox;
 $global:DropDownDeployments.Location = new-object System.Drawing.Size(15,70);
 $global:DropDownDeployments.Size = new-object System.Drawing.Size(410,30);
 $DropDownArrayDeployments = $global:Deployments
 ForEach ($Item in $global:deployments) {
	$global:DropDownDeployments.Items.Add("$($Item.deployment_id) - $($Item.deployment_name)")
 }

 $DropDownDeployments_SelectedIndexChanged=
 {
   If ($global:DropDownDeployments.text) {
    $deployment = $global:DropdownDeployments.SelectedItem
    $pos = $deployment.IndexOf(" - ")
    $global:deployment = $deployment.Substring(0,$pos)
    $FormAdvanced.Controls.Add($ButtonGetDeploymentsDetails)
    $FormAdvanced.Controls.Add($ButtonDeploymentsDELETE)
    #$LabelSelectedDeployment.Text = $global:Deployments
    #$FormAdvanced.Controls.Add($LabelSelectedDeployment)
    }
 }

 $global:DropDownDeployments.add_SelectedIndexChanged($DropDownDeployments_SelectedIndexChanged)
 
 $FormAdvanced.controls.Add($global:DropDownDeployments)
 }
 }
 })

$ButtonDeploymentsGET.Text = "Deployments GET"
$ButtonDeploymentsGET.Location = New-Object System.Drawing.Size(15,40)
$ButtonDeploymentsGET.Size = New-Object System.Drawing.Size(200,23)
$FormAdvanced.Controls.Add($ButtonDeploymentsGET)

#Textbox for Deployments GET
$TextboxDeploymentsGET = New-Object System.Windows.Forms.TextBox
$TextboxDeploymentsGET.Location = New-Object System.Drawing.Size(250,40)
$TextboxDeploymentsGET.Size = New-Object System.Drawing.Size(150,150)
$FormAdvanced.Controls.Add($TextboxDeploymentsGET)

#Button "Clear" for "Deployments GET" text box
$ButtonDeploymentsGETClear = New-Object System.Windows.Forms.Button
$ButtonDeploymentsGETClear.add_click({$TextboxDeploymentsGET.Clear(); $global:DropDownDeployments.Items.Clear();$FormAdvanced.controls.Remove($global:DropDownDeployments);$FormAdvanced.controls.remove($ButtonDeploymentsDELETE)
$FormAdvanced.Controls.Remove($ButtonGetDeploymentsDetails)
$FormAdvanced.Controls.Remove($LabelNotFound)})
$ButtonDeploymentsGETClear.Text = "Clear"
$ButtonDeploymentsGETClear.Location = New-Object System.Drawing.Size(400,40)
$ButtonDeploymentsGETClear.Size = New-Object System.Drawing.Size(50,21)
$ButtonDeploymentsGETClear.BackColor = "White"
$FormAdvanced.Controls.Add($ButtonDeploymentsGETClear)

#Collections Find/Modify
$LabelCollections = New-Object System.Windows.Forms.Label
$LabelCollections.Text = "Find and Delete your Device Collections:"
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelCollections.Font = $FontBold
$LabelCollections.AutoSize = $True
$LabelCollections.Location = new-object system.drawing.size(5,120)
$FormAdvanced.Controls.Add($LabelCollections)

#Label Modify
#$LabelModifyCollection = New-Object System.Windows.Forms.Label
#$LabelModifyCollection.Text = "To modify your selected Device collection, select a file with server names to add to it"
#$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
#$LabelModifyCollection.Font = $FontBold
#$LabelModifyCollection.AutoSize = $True
#$LabelModifyCollection.Location = new-object system.drawing.size(5,260)

$ButtonCollectionsDELETE = New-Object System.Windows.Forms.Button
$ButtonCollectionsDELETE.Text = "Delete Selected Collection"
$ButtonCollectionsDELETE.Location = new-object System.Drawing.Size(15,200);
$ButtonCollectionsDELETE.Size = new-object System.Drawing.Size(160,20);
$ButtonCollectionsDELETE.BackColor = "Red"


$ButtonCollectionsDELETE.add_click({
if ($global:DropDownCollections.selecteditem)
{
 $pos = $global:DropDownCollections.selecteditem.IndexOf(" - ")
 $global:collection_id = $global:DropDownCollections.selecteditem.Substring(0,$pos)
 $global:message = "Selected Collection:`n$($global:DropDownCollections.selecteditem)`nwill be deleted!`n`nProceed?"
 
 $LabelWorking.Location = new-object system.drawing.size(15,200)
 $FormAdvanced.Controls.Remove($ButtonCollectionsDELETE)
 $FormAdvanced.Controls.Add($LabelWorking)
 
 dialog_box("delete_device_collections")

 $FormAdvanced.Controls.Remove($LabelWorking)
 $TextboxCollectionsGET.Clear();$global:DropDownCollections.items.Clear();
 $FormAdvanced.Controls.Remove($global:DropDownCollections)
 }
 else {missing_parameters} }
 )

#Button "Device Collections GET"
$ButtonCollectionsGET = New-Object System.Windows.Forms.Button
$ButtonCollectionsGET.add_click({
headers;
verify_keys;
 $FormAdvanced.Controls.Remove($LabelNotFound)
 $FormAdvanced.Controls.Remove($global:DropDownCollections);$FormAdvanced.Controls.Remove($ButtonCollectionsDELETE)
 $FormAdvanced.Controls.Remove($ButtonCollectionsDELETE)
 $FormAdvanced.Controls.Remove($global:DropDownCollections)
 #$FormAdvanced.Controls.Remove($LabelModifyCollection)
 #$FormAdvanced.Controls.Remove($LabelItemAdvanced)
 #$FormAdvanced.Controls.Remove($TextBoxAdvanced)
 #$FormAdvanced.Controls.Remove($ButtonBrowseAdvanced)
 #$FormAdvanced.Controls.Remove($ButtonCollectionsModify)
$LabelSearching.Location = new-object system.drawing.size(15,175)
$FormAdvanced.Controls.Add($LabelSearching)
$Param2 = $TextboxCollectionsGET.Text;
get-device_collections $Param2 ; 
$FormAdvanced.Controls.Remove($LabelSearching)
 if ($global:collections.count -eq "0") {
 $LabelNotFound.Location = new-object system.drawing.size(15,175)
 $FormAdvanced.Controls.Add($LabelNotFound)}
 else {
 $global:DropDownCollections = new-object System.Windows.Forms.ComboBox;
 $global:DropDownCollections.Location = new-object System.Drawing.Size(15,175);
 $global:DropDownCollections.Size = new-object System.Drawing.Size(430,30);
 $DropDownArrayCollections = $global:collections
 ForEach ($Item in $global:collections) {
	$global:DropDownCollections.Items.Add("$($Item.collection_id) - $($Item.collection_name)")
 }
 $FormAdvanced.Controls.Add($ButtonCollectionsDELETE)
 $FormAdvanced.Controls.Add($global:DropDownCollections)
 #$FormAdvanced.Controls.Add($LabelModifyCollection)
 #$FormAdvanced.Controls.Add($LabelItemAdvanced)
 #$FormAdvanced.Controls.Add($TextBoxAdvanced)
 #$FormAdvanced.Controls.Add($ButtonBrowseAdvanced)
 #$FormAdvanced.Controls.Add($ButtonCollectionsModify)
  }
 })

$ButtonCollectionsGET.Text = "Device Collections GET"
$ButtonCollectionsGET.Location = New-Object System.Drawing.Size(15,140)
$ButtonCollectionsGET.Size = New-Object System.Drawing.Size(200,23)
$FormAdvanced.Controls.Add($ButtonCollectionsGET)

#Textbox for the "Device Collections Get" button
$TextboxCollectionsGET = New-Object System.Windows.Forms.TextBox
$TextboxCollectionsGET.Location = New-Object System.Drawing.Size(250,140)
$TextboxCollectionsGET.Size = New-Object System.Drawing.Size(150,150)
$FormAdvanced.Controls.Add($TextboxCollectionsGET)

#Button "Clear" for "Device Collections GET" text box
$ButtonCollectionsGETClear = New-Object System.Windows.Forms.Button
$ButtonCollectionsGETClear.add_click({
 $TextboxCollectionsGET.Clear()
 $global:DropDownCollections.items.Clear()
 $FormAdvanced.Controls.Remove($global:DropDownCollections)
 $FormAdvanced.Controls.Remove($ButtonCollectionsDELETE)
 $FormAdvanced.Controls.Remove($LabelNotFound)
 $FormAdvanced.Controls.Remove($global:DropDownCollections)
 $FormAdvanced.Controls.Remove($ButtonGetDeploymentsDetails)
 #$FormAdvanced.Controls.Remove($LabelModifyCollection)
 #$FormAdvanced.Controls.Remove($LabelItemAdvanced)
 #$FormAdvanced.Controls.Remove($TextBoxAdvanced)
 #$FormAdvanced.Controls.Remove($ButtonBrowseAdvanced)
  #$FormAdvanced.Controls.Remove($ButtonCollectionsModify)
 })
$ButtonCollectionsGETClear.Text = "Clear"
$ButtonCollectionsGETClear.Location = New-Object System.Drawing.Size(400,140)
$ButtonCollectionsGETClear.Size = New-Object System.Drawing.Size(50,21)
$ButtonCollectionsGETClear.BackColor = "White"
$FormAdvanced.Controls.Add($ButtonCollectionsGETClear)

#Button Collection Modify
#$ButtonCollectionsModify = New-Object System.Windows.Forms.Button
#$ButtonCollectionsModify.Text = "Modify Selected Collection"
#$ButtonCollectionsModify.Location = new-object System.Drawing.Size(15,350);
#$ButtonCollectionsModify.Size = new-object System.Drawing.Size(160,20);
#$ButtonCollectionsModify.BackColor = "Red"
<#
$ButtonCollectionsModify.add_click({
if ($global:DropDownCollections.selecteditem)
{
 $servers = get-content $global:file
 $pos = $global:DropDownCollections.selecteditem.IndexOf(" - ")
 $global:collection_id = $global:DropDownCollections.selecteditem.Substring(0,$pos)
 $global:message = "Selected Collection:
$($global:DropDownCollections.selecteditem)
will be modified!
The following devices will be added:
$servers



Proceed?"
 dialog_box("put_device_collections")}
 else {missing_parameters} }
 )
 #>

#Button Get Deployments Details
$ButtonGetDeploymentsDetails = New-Object System.Windows.Forms.Button
$ButtonGetDeploymentsDetails.Text = "Get Deployment Details"
$ButtonGetDeploymentsDetails.Location = New-Object System.Drawing.Size(430,70)
$ButtonGetDeploymentsDetails.Size = New-Object System.Drawing.Size(150,23)

$ButtonGetDeploymentsDetails.add_click({
 $LabelWorking.Location = new-object system.drawing.size(15,200)
 $FormAdvanced.Controls.Remove($ButtonGetDeploymentsDetails)
 $FormAdvanced.Controls.Add($LabelWorking)

 headers;
 verify_keys;
 details-deployments

 $FormAdvanced.Controls.Remove($LabelWorking)
 $FormAdvanced.Controls.Add($ButtonGetDeploymentsDetails)
})

 #Advanced form Exit Button
$ButtonAdvancedExit = New-Object System.Windows.Forms.Button
$ButtonAdvancedExit.BackColor = "Yellow"
$ButtonAdvancedExit.add_click({
$TextboxCollectionsGET.Clear();
$FormAdvanced.Controls.Remove($global:DropDownCollections);$FormAdvanced.Controls.Remove($ButtonCollectionsDELETE);
#$FormAdvanced.Controls.Remove($LabelModifyCollection);
$TextboxDeploymentsGET.Clear();$FormAdvanced.controls.Remove($global:DropDownDeployments);$FormAdvanced.controls.remove($ButtonDeploymentsDELETE)
 $FormAdvanced.Controls.Remove($ButtonCollectionsDELETE)
 $FormAdvanced.Controls.Remove($global:DropDownCollections)
 $FormAdvanced.Controls.Remove($ButtonGetDeploymentsDetails)
 #$FormAdvanced.Controls.Remove($LabelModifyCollection)
 #$FormAdvanced.Controls.Remove($LabelItemAdvanced)
 #$FormAdvanced.Controls.Remove($TextBoxAdvanced)
 #$FormAdvanced.Controls.Remove($ButtonBrowseAdvanced)
  #$FormAdvanced.Controls.Remove($ButtonCollectionsModify)
  $FormAdvanced.Controls.Remove($LabelNotFound)
$FormAdvanced.Close()
$Form.Refresh()
})
$ButtonAdvancedExit.Text = "Close"
$ButtonAdvancedExit.Location = New-Object System.Drawing.Size(15,330)
$ButtonAdvancedExit.Size = New-Object System.Drawing.Size(100,23)
$FormAdvanced.Controls.Add($ButtonAdvancedExit)

#-----------------------------------------------------------------------------------------
#Label "Step 1"
$LabelStep1 = New-Object System.Windows.Forms.Label
$LabelStep1.Text = "Step 1: Create an SCCM collection with device list (servers)
    Device Collection POST by device list."
$LabelStep1.AutoSize = $True
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelStep1.Font = $FontBold
$LabelStep1.Location = new-object system.drawing.size(10,45)
$Form.Controls.Add($LabelStep1)

#Label "Item 1"
$LabelItem1_1 = New-Object System.Windows.Forms.Label
$LabelItem1_1.Text = "1. Enter New Device Collection Name. 
    Only Letters, Numbers, Spaces, Dashes and Underscores are allowed (Ex: SAP Data Services - Prod):"
$LabelItem1_1.AutoSize = $True
$LabelItem1_1.Location = new-object system.drawing.size(10,80)
$Form.Controls.Add($LabelItem1_1)

#Texbox for "Item 1"
$TextBoxItem1 = New-Object System.Windows.Forms.TextBox
$TextBoxItem1.Location = New-Object System.Drawing.Size(15,110)
$TextBoxItem1.Size = New-Object System.Drawing.Size(400,15)
$Form.Controls.Add($TextBoxItem1)

#Label Item 2"
$LabelItem2 = New-Object System.Windows.Forms.Label
$LabelItem2.Text = "2. Provide a file location containing a server list to be added to this collection:
    File must be in a plain text with each server name in its own line (Ex: C:\temp\servers.txt)"
$LabelItem2.AutoSize = $True
$LabelItem2.Location = new-object system.drawing.size(10,140)
$Form.Controls.Add($LabelItem2)

#Textbox for "Item 2"
$TextBoxItem2 = New-Object System.Windows.Forms.TextBox
$TextBoxItem2.Location = New-Object System.Drawing.Size(15,170)
$TextBoxItem2.Size = New-Object System.Drawing.Size(200,15)
$Form.Controls.Add($TextBoxItem2)

#File Browser Function
function browse()
{
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = "C:\temp"
 $OpenFileDialog.filter = "TXT Files (*.txt)| *.txt"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

#Button "Browse"
$ButtonBrowse = New-Object System.Windows.Forms.Button
$ButtonBrowse.add_click({$global:file = browse ; $TextBoxItem2.Clear(); $TextBoxItem2.SelectedText = $global:file
})
$ButtonBrowse.Text = "Browse..."
$ButtonBrowse.Location = New-Object System.Drawing.Size(220,170)
$ButtonBrowse.Size = New-Object System.Drawing.Size(80,23)
$Form.Controls.Add($ButtonBrowse)

#Button "Create New Collection!"
$ButtonCreateNewCollection = New-Object System.Windows.Forms.Button
$ButtonCreateNewCollection.add_click({
headers;
check_keys;
verify_keys;
$LabelWorking.Location = new-object system.drawing.size(65,202)
$Form.Controls.Remove($ButtonCreateNewCollection)
$Form.Controls.Add($LabelWorking)
if ($global:myerror -eq $null) {
if ($TextBoxItem1.Text -and $global:file)
 {
 if ($TextBoxItem1.Text -match '[^a-zA-Z0-9_\-\ ]') {$global:message = "Invalid Characters in Collection Name!`n Allowed Characters are a-z, A-Z, 0-9, -, _, Space."; error_box}
else
{
 $global:collection_name = $TextBoxItem1.Text;
  $servers = get-content $global:file
  $global:message = "New Device collection will be created as follows:
Collection Name: $($TextBoxItem1.Text)

Server list from $($global:file):
$servers


Proceed?"
  dialog_box("post_device_collections")
 }
 }
  else {missing_parameters}
  }
  $Form.Controls.Remove($LabelWorking)
  $Form.Controls.Add($ButtonCreateNewCollection)
})

$ButtonCreateNewCollection.Text = "Create New Collection!"
$ButtonCreateNewCollection.Location = New-Object System.Drawing.Size(15,200)
$ButtonCreateNewCollection.Size = New-Object System.Drawing.Size(200,23)
$ButtonCreateNewCollection.ForeColor = "White"
$ButtonCreateNewCollection.BackColor = "Green"
$Form.Controls.Add($ButtonCreateNewCollection)
###############################################################################

#Label "Caution"
$LabelCaution = New-Object System.Windows.Forms.Label
$LabelCaution.Text = "CAUTION: You must allow about 15 minutes for the collection to be created in SCCM`n and before proceeding to the next step!"
$LabelCaution.AutoSize = $True
$LabelCaution.Location = new-object system.drawing.size(10,240)
$Form.Controls.Add($LabelCaution)

#-----------------------------------------------------------------------------------------
#Step 2
#Query SCCM with a device collection keyword to find a new collection number
$LabelStep2 = New-Object System.Windows.Forms.Label
$LabelStep2.Text = "Step 2. Find your new device collection and assign a maintenance window to it."
$LabelStep2.AutoSize = $True
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelStep2.Font = $FontBold
$LabelStep2.Location = new-object system.drawing.size(10,280)
$Form.Controls.Add($LabelStep2)

#Label "Item 2_1"
$LabelItem2_1 = New-Object System.Windows.Forms.Label
$LabelItem2_1.Text = "1. Find your new device collection, Enter a search keyword, or leave blank to retrieve all:"
$LabelItem2_1.AutoSize = $True
$LabelItem2_1.Location = new-object system.drawing.size(10,305)
$Form.Controls.Add($LabelItem2_1)

#Label "Not FOUND"
$LabelNotFound = New-Object System.Windows.Forms.Label
$LabelNotFound.Text = "Not Found! Modify your search criteria."
$LabelNotFound.AutoSize = $true
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$LabelNotFound.ForeColor = "red"
$LabelNotFound.Font = $FontBold

#Label "Searching..."
$LabelSearching = New-Object System.Windows.Forms.Label
$LabelSearching.Text = "Searching..."
$LabelSearching.AutoSize = $true
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelSearching.Font = $FontBold

#Label "Working..."
$LabelWorking = New-Object System.Windows.Forms.Label
$LabelWorking.Text = "Working..."
$LabelWorking.AutoSize = $true
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelWorking.Font = $FontBold

#Button "Device Collections GET"
$LabelSelectedCollectionID = New-Object System.Windows.Forms.Label
$LabelSelectedCollectionID.Text = ""
$LabelSelectedCollectionID.AutoSize = $True
$LabelSelectedCollectionID.Location = new-object system.drawing.size(480,355)
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelSelectedCollectionID.Font = $FontBold

$ButtonDeviceCollectionsQuery = New-Object System.Windows.Forms.Button
$ButtonDeviceCollectionsQuery.add_click({
headers;
check_keys;
verify_keys;
if ($global:myerror -eq $null) {
$LabelSearching.Location = new-object system.drawing.size(15,355)
$Form.Controls.Add($LabelSearching)
$form.controls.Remove($global:DropDownCollections);$form.controls.remove($LabelSelectedCollectionID);$Form.Controls.Remove($ButtonGetCollectionDetails1); $form.Controls.Remove($LabelNotFound);
$Param2 = $TextBoxDeviceCollectionsQuery.Text ; get-device_collections $Param2 ; 
 $global:DropDownCollections = new-object System.Windows.Forms.ComboBox;
 $global:DropDownCollections.Location = new-object System.Drawing.Size(15,355);
 $global:DropDownCollections.Size = new-object System.Drawing.Size(430,30);
 $Form.Controls.Remove($LabelSearching)
 if ($global:collections.count -eq "0") {
 $LabelNotFound.Location = new-object system.drawing.size(15,355)
 $form.Controls.Add($LabelNotFound)}
 else {
 $DropDownArrayCollections = $global:collections
 ForEach ($Item in $global:collections) {
	$global:DropDownCollections.Items.Add("$($Item.collection_id) - $($Item.collection_name)")
 }
 $form.controls.Add($global:DropDownCollections)

 $DropDownCollections_SelectedIndexChanged=
{
   If ($global:DropDownCollections.text) {
   $collection = $global:Dropdowncollections.SelectedItem

$pos = $collection.IndexOf(" - ")
$global:collection_id = $collection.Substring(0,$pos)

$LabelSelectedCollectionID.Text = $global:collection_id
$Form.Controls.Add($LabelSelectedCollectionID)
$Form.Controls.Add($ButtonGetCollectionDetails1) 
   }
}
$global:DropDownCollections.add_SelectedIndexChanged($DropDownCollections_SelectedIndexChanged)
 #$form.controls.Add($global:DropDownCollections)
}
 }
 })

$ButtonDeviceCollectionsQuery.Text = "Device Collections GET"
$ButtonDeviceCollectionsQuery.Location = New-Object System.Drawing.Size(15,325)
$ButtonDeviceCollectionsQuery.Size = New-Object System.Drawing.Size(200,23)
$Form.Controls.Add($ButtonDeviceCollectionsQuery)

#Textbox for the "Device Collections Get" button
$TextBoxDeviceCollectionsQuery = New-Object System.Windows.Forms.TextBox
$TextBoxDeviceCollectionsQuery.Location = New-Object System.Drawing.Size(250,325)
$TextBoxDeviceCollectionsQuery.Size = New-Object System.Drawing.Size(150,150)
$Form.Controls.Add($TextBoxDeviceCollectionsQuery)

#Button "Clear" for "Device Collections GET" text box
$ButtonDeviceCollectionsQueryClear= New-Object System.Windows.Forms.Button
$ButtonDeviceCollectionsQueryClear.add_click({$TextBoxDeviceCollectionsQuery.Clear()
$global:DropDownCollections.Items.Clear()
$Form.controls.Remove($global:DropDownCollections)
$Form.controls.remove($LabelSelectedCollectionID)
$Form.Controls.Remove($ButtonGetCollectionDetails1)
$Form.Controls.Remove($LabelNotFound)
$Form.Refresh()
})
$ButtonDeviceCollectionsQueryClear.Text = "Clear"
$ButtonDeviceCollectionsQueryClear.Location = New-Object System.Drawing.Size(400,325)
$ButtonDeviceCollectionsQueryClear.Size = New-Object System.Drawing.Size(50,21)
$ButtonDeviceCollectionsQueryClear.BackColor = "White"
$Form.Controls.Add($ButtonDeviceCollectionsQueryClear)

#Label "Selected Collection ID"
$LabelCollectionID = New-Object System.Windows.Forms.Label
$LabelCollectionID.Text = "Selected Collection ID:"
$LabelCollectionID.AutoSize = $True
$LabelCollectionID.Location = new-object system.drawing.size(460,330)
$Form.Controls.Add($LabelCollectionID)

#Maintenance Window
$LabelStep11 = New-Object System.Windows.Forms.Label
$LabelStep11.Text = "2. Define a Maintenance window for your new device collection:"
$LabelStep11.AutoSize = $True
$LabelStep11.Location = new-object system.drawing.size(10,380)
$Form.Controls.Add($LabelStep11)

$DropDownDay = new-object System.Windows.Forms.ComboBox
$DropDownDay.Location = new-object System.Drawing.Size(15,400)
$DropDownDay.Size = new-object System.Drawing.Size(130,30)
$form.controls.Add($DropDownDay)
$DropDownArrayDay = @("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")
ForEach ($Item in $DropDownArrayDay) {
	$DropDownDay.Items.Add($Item)
}

$DropDownTime = new-object System.Windows.Forms.ComboBox
$DropDownTime.Location = new-object System.Drawing.Size(180,400)
$DropDownTime.Size = new-object System.Drawing.Size(130,30)
$form.controls.Add($DropDownTime)
$DropDownArrayTime = @("00:00-03:00","03:00-06:00","06:00-09:00","09:00-12:00","12:00-15:00","15:00-18:00","18:00-21:00","21:00-24:00")
ForEach ($Item in $DropDownArrayTime) {
	$DropDownTime.Items.Add($Item)
}

#Button Get Collection Details 1
$ButtonGetCollectionDetails1 = New-Object System.Windows.Forms.Button
$ButtonGetCollectionDetails1.Text = "Get Collection Details"
$ButtonGetCollectionDetails1.Location = New-Object System.Drawing.Size(450,380)
$ButtonGetCollectionDetails1.Size = New-Object System.Drawing.Size(130,23)
$ButtonGetCollectionDetails1.add_click({
$LabelWorking.Location = new-object system.drawing.size(475,380)
$Form.Controls.Remove($ButtonGetCollectionDetails1)
$Form.Controls.Add($LabelWorking)

if ($global:collection_id) {
headers;
details_device_collections;
} 
else {$global:message = "Please select a collection from the drop-down list"; error_box}
$Form.Controls.Remove($LabelWorking)
$Form.Controls.Add($ButtonGetCollectionDetails1)
})

#Button Add Maintenance Window
$ButtonAddMaintenanceWindow = New-Object System.Windows.Forms.Button
$ButtonAddMaintenanceWindow.Text = "Add Maintenance Window to the device collection!"
$ButtonAddMaintenanceWindow.Location = New-Object System.Drawing.Size(15,440)
$ButtonAddMaintenanceWindow.Size = New-Object System.Drawing.Size(350,23)
$ButtonAddMaintenanceWindow.ForeColor = "White"
$ButtonAddMaintenanceWindow.BackColor = "Green"
$Form.Controls.Add($ButtonAddMaintenanceWindow)

$ButtonAddMaintenanceWindow.add_click({
headers;
check_keys;
verify_keys;
$LabelWorking.Location = new-object system.drawing.size(80,445)
$Form.Controls.Remove($ButtonAddMaintenanceWindow)
$Form.Controls.Add($LabelWorking)

if ($global:myerror -eq $null) {
$global:maintenance_day = $DropdownDay.SelectedItem
$global:maintenance_time = $DropDownTime.SelectedItem
$global:collection_name = $global:DropDownCollections.selectedItem
if ($DropDownCollections.selectedItem -and $DropDownDay.SelectedItem -and $DropdownTime.SelectedItem)
 {
  $global:message = "Selected Collection:
$($global:collection_name)

Maintenance window will be added:
$($global:maintenance_day)  $($global:maintenance_time)

Proceed?"
dialog_box ("post_maintenance_window")
}  else { missing_parameters }

}
$Form.Controls.Remove($LabelWorking)
$Form.Controls.Add($ButtonAddMaintenanceWindow)
 })


#---------------------------------------------------
#Step 3 - Schedule a deployment
$LabelStep3 = New-Object System.Windows.Forms.Label
$LabelStep3.Text = "Step 3. Schedule a deployment for your collection"
$LabelStep3.AutoSize = $True
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelStep3.Font = $FontBold
$LabelStep3.Location = new-object system.drawing.size(10,485)
$Form.Controls.Add($LabelStep3)

$LabelItem3_1 = New-Object System.Windows.Forms.Label
$LabelItem3_1.Text = "1. Find the latest SUG for Windows Servers:"
$LabelItem3_1.AutoSize = $True
$LabelItem3_1.Location = new-object system.drawing.size(10,510)
$Form.Controls.Add($LabelItem3_1)

$LabelSUG = New-Object System.Windows.Forms.Label
$LabelSUG.AutoSize = $True

#Button "Query for the latest Windows Server SUG"
$ButtonSUGQuery = New-Object System.Windows.Forms.Button
$ButtonSUGQuery.add_click({
headers;
check_keys;
verify_keys;
if ($global:myerror -eq $null) {
$LabelSearching.Location = new-object system.drawing.size(15,560)
$Form.Controls.Remove($LabelSUG)
$Form.Controls.Add($LabelSearching)
get-sug ; 
$LabelSUG.ForeColor = "Green"
$LabelSUG.Text = "Found SUG: $global:SUG - $global:SUGName"
$LabelSUG.Location = new-object system.drawing.size(15,560)
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelSUG.Font = $FontBold
$Form.Controls.Remove($LabelSearching)
$Form.Controls.Add($LabelSUG)
}
})

$ButtonSUGQuery.Text = "Query for the latest Windows Server SUG"
$ButtonSUGQuery.Location = New-Object System.Drawing.Size(15,530)
$ButtonSUGQuery.Size = New-Object System.Drawing.Size(250,23)
$Form.Controls.Add($ButtonSUGQuery)

###########################

#Label "Item 3_2"
$LabelItem3_2 = New-Object System.Windows.Forms.Label
$LabelItem3_2.Text = "2. Find your new device collection, Enter a search keyword, or leave blank to retrieve all:"
$LabelItem3_2.AutoSize = $True
$LabelItem3_2.Location = new-object system.drawing.size(10,585)
$Form.Controls.Add($LabelItem3_2)

#Button "Device Collections GET"
$LabelSelectedCollectionID2= New-Object System.Windows.Forms.Label
$LabelSelectedCollectionID2.Text = ""
$LabelSelectedCollectionID2.AutoSize = $True
$LabelSelectedCollectionID2.Location = new-object system.drawing.size(480,635)
$FontBold = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
$LabelSelectedCollectionID2.Font = $FontBold

#Button Get Collection Details 2
$ButtonGetCollectionDetails2 = New-Object System.Windows.Forms.Button
$ButtonGetCollectionDetails2.Text = "Get Collection Details"
$ButtonGetCollectionDetails2.Location = New-Object System.Drawing.Size(450,660)
$ButtonGetCollectionDetails2.Size = New-Object System.Drawing.Size(130,23)
$ButtonGetCollectionDetails2.add_click({
$LabelWorking.Location = new-object system.drawing.size(475,660)
$Form.Controls.Remove($ButtonGetCollectionDetails2)
$Form.Controls.Add($LabelWorking)
headers;
details_device_collections;
$Form.Controls.Remove($LabelWorking)
$Form.Controls.Add($ButtonGetCollectionDetails2)
})


$ButtonDeviceCollectionsQuery2 = New-Object System.Windows.Forms.Button
$ButtonDeviceCollectionsQuery2.add_click({
headers;
check_keys;
verify_keys;
if ($global:myerror -eq $null) {
$LabelSearching.Location = new-object system.drawing.size(15,635)
$Form.Controls.Add($LabelSearching)
$form.controls.Remove($global:DropDownCollections2);$form.controls.remove($LabelSelectedCollectionID2);$Form.Controls.Remove($ButtonGetCOllectionDetails2);
 $form.Controls.Remove($LabelNotFound)
$Param2 = $TextBoxDeviceCollectionsQuery2.Text ; get-device_collections $Param2 ; 
 $global:DropDownCollections2 = new-object System.Windows.Forms.ComboBox;
 $global:DropDownCollections2.Location = new-object System.Drawing.Size(15,635);
 $global:DropDownCollections2.Size = new-object System.Drawing.Size(430,30);
 $DropDownArrayCollections2 = $global:collections
 $Form.Controls.Remove($LabelSearching)
 if ($global:collections.count -eq "0") {
 $LabelNotFound.Location = new-object system.drawing.size(15,635)
 $form.Controls.Add($LabelNotFound)}
 else {
 ForEach ($Item in $global:collections) {
  $global:DropDownCollections2.Items.Add("$($Item.collection_id) - $($Item.collection_name)")
 }
 $form.controls.Add($global:DropDownCollections2)
 
 # $global:DropDownCollections2.add_TextChanged($DropDownCollections_SelectedIndexChanged)
  $DropDownCollections_SelectedIndexChanged=
{
   If ($global:DropDownCollections2.text) {
   $collection = $global:DropDownCollections2.SelectedItem

$pos = $collection.IndexOf(" - ")
$global:collection_id = $collection.Substring(0,$pos)

$LabelSelectedCollectionID2.Text = $global:collection_id
$Form.Controls.Add($LabelSelectedCollectionID2)
$Form.Controls.Add($ButtonGetCOllectionDetails2)
   }
}
$global:DropDownCollections2.add_SelectedIndexChanged($DropDownCollections_SelectedIndexChanged) }
}
})

$ButtonDeviceCollectionsQuery2.Text = "Device Collections GET"
$ButtonDeviceCollectionsQuery2.Location = New-Object System.Drawing.Size(15,605)
$ButtonDeviceCollectionsQuery2.Size = New-Object System.Drawing.Size(200,23)
$Form.Controls.Add($ButtonDeviceCollectionsQuery2)

#Textbox for the "Device Collections Get" button
$TextBoxDeviceCollectionsQuery2 = New-Object System.Windows.Forms.TextBox
$TextBoxDeviceCollectionsQuery2.Location = New-Object System.Drawing.Size(250,605)
$TextBoxDeviceCollectionsQuery2.Size = New-Object System.Drawing.Size(150,150)
$Form.Controls.Add($TextBoxDeviceCollectionsQuery2)

#Button "Clear" for "Device Collections GET" text box
$ButtonDeviceCollectionsQuery2Clear= New-Object System.Windows.Forms.Button
$ButtonDeviceCollectionsQuery2Clear.add_click({$TextBoxDeviceCollectionsQuery2.Clear(); $global:DropDownCollections2.Items.Clear();$form.controls.Remove($global:DropDownCollections2);$form.controls.remove($LabelSelectedCollectionID2);$Form.Controls.Remove($ButtonGetCOllectionDetails2);
 $form.Controls.Remove($LabelNotFound)})

$ButtonDeviceCollectionsQuery2Clear.Text = "Clear"
$ButtonDeviceCollectionsQuery2Clear.Location = New-Object System.Drawing.Size(400,605)
$ButtonDeviceCollectionsQuery2Clear.Size = New-Object System.Drawing.Size(50,21)
$ButtonDeviceCollectionsQuery2Clear.BackColor = "White"
$Form.Controls.Add($ButtonDeviceCollectionsQuery2Clear)

#Label "Selected Collection ID"
$LabelCollectionID2 = New-Object System.Windows.Forms.Label
$LabelCollectionID2.Text = "Selected Collection ID:"
$LabelCollectionID2.AutoSize = $True
$LabelCollectionID2.Location = new-object system.drawing.size(460,610)
$Form.Controls.Add($LabelCollectionID2)

#Item 3_3 - Reboot flag
$Item3_3 = New-Object System.Windows.Forms.Label
$Item3_3.Text = "3. Specify a reboot flag:"
$Item3_3.AutoSize = $True
$Form.Controls.Add($Item3_3)
$Item3_3.Location = new-object system.drawing.size(10,670)

#Checkbox "Reboot flag"
$CheckboxRebootFlag = New-Object System.Windows.Forms.Checkbox 
$CheckboxRebootFlag.Location = New-Object System.Drawing.Size(15,687) 
$CheckboxRebootFlag.Size = New-Object System.Drawing.Size(400,40)
$CheckboxRebootFlag.Checked = $true;
$CheckboxRebootFlag.Text = "Reboot servers automatically after patching (recommended).`nNOTE: The installation of patches and a reboot will be performed within`nthe collection's defined maintenance window"
$Form.Controls.Add($CheckboxRebootFlag)

#Item 3_4 - Maintenance start time
$Item3_4 = New-Object System.Windows.Forms.Label
$Item3_4.Text = "4. Specify deployment start date and time:"
$Item3_4.AutoSize = $True
$Item3_4.Location = new-object system.drawing.size(10,730)
$Form.Controls.Add($Item3_4)

$calendar = New-Object System.Windows.Forms.DateTimePicker
$calendar.MinDate = get-date
$calendar.Location = New-Object System.Drawing.Size(15,750)
$Form.Controls.Add($calendar)

$LabelTime = New-Object System.Windows.Forms.Label
$LabelTime.Text = "Time:"
$LabelTime.AutoSize = $True
$LabelTime.Location = new-object system.drawing.size(280,748)
$Form.Controls.Add($LabelTime)

$DropDownTime2 = new-object System.Windows.Forms.ComboBox
$DropDownTime2.Location = new-object System.Drawing.Size(320,745)
$DropDownTime2.Size = new-object System.Drawing.Size(50,30)
$form.controls.Add($DropDownTime2)
$DropDownArrayTime2 = @("00:00","01:00","02:00","03:00","04:00","05:00","06:00","07:00","08:00","09:00","10:00","11:00","12:00",
                        "13:00","14:00","15:00","16:00","17:00","18:00","19:00","20:00","21:00","22:00","23:00")
ForEach ($Item in $DropDownArrayTime2) {
	$DropDownTime2.Items.Add($Item)
}

#Button Schedule this Deployment
$ButtonScheduleThisDeployment = New-Object System.Windows.Forms.Button
$ButtonScheduleThisDeployment.Text = "Schedule this Deployment!"
$ButtonScheduleThisDeployment.Location = New-Object System.Drawing.Size(15,780)
$ButtonScheduleThisDeployment.Size = New-Object System.Drawing.Size(360,23)
$ButtonScheduleThisDeployment.ForeColor = "White"
$ButtonScheduleThisDeployment.BackColor = "Green"
$Form.Controls.Add($ButtonScheduleThisDeployment)
$LabelWorking.Location = new-object system.drawing.size(260,780)
$Form.Controls.Add($LabelWorking)

$ButtonScheduleThisDeployment.add_click({
headers;
check_keys;
verify_keys;
$LabelWorking.Location = new-object system.drawing.size(260,780)
$Form.Controls.Remove($ButtonScheduleThisDeployment)
$Form.Controls.Add($LabelWorking)
if ($global:myerror -eq $null) {
if ($global:SUG -and $global:collection_id -and $calendar.Value -and $DropdownTime2.SelectedItem)
 {
 If ($CheckboxRebootFlag.Checked -eq "True")
  {
    $global:reboot_flag = $true
  }else {
  $global:reboot_flag = $false }

  $date = $calendar.Value
  $global:deployment_day = $date.toString("yyyy-MM-dd")
  $global:deployment_time = $DropdownTime2.SelectedItem
  $global:deployment_expiration = $date.AddDays(90)

$global:message = "Selected Collection:
$($global:DropDownCollections2.selectedItem)
is scheduled with the SUG: $($global:SUG) 
to be deployed on: $($global:deployment_day) at: $($global:deployment_time)
Reboot flag is set to: $global:reboot_flag

This deployment will expire on $($global:deployment_expiration)


Proceed?"
dialog_box("post_deployments")}
else {missing_parameters}
$Form.Controls.Add($ButtonScheduleThisDeployment)
$Form.Controls.Remove($LabelWorking)
}
})


#GUI Clear ALL Button
$ButtonClearAll = New-Object System.Windows.Forms.Button
$ButtonClearAll.add_click({$form.controls.Remove($global:DropDownCollections2);
$TextBoxItem1.Clear();
$TextBoxItem2.Clear();
$TextBoxDeviceCollectionsQuery.Clear();
#$global:DropDownCollections.Items.Clear();
$form.Controls.Remove($global:DropDownCollections);
$form.Controls.Remove($LabelSelectedCollectionID);
$TextBoxDeviceCollectionsQuery2.Clear();
#$global:DropDownCollections2.Items.Clear();
$form.Controls.Remove($global:DropDownCollections2);
$form.Controls.Remove($LabelSelectedCollectionID2);
$Form.Controls.Remove($ButtonGetCollectionDetails1);
$Form.Controls.Remove($ButtonGetCollectionDetails2);
$form.Controls.Remove($LabelNotFound)
$LabelSUG.Text="";
$Form.Controls.Remove($LabelSUG)
$CheckboxRebootFlag.Checked = $true;
$DropDownDay.SelectedIndex="-1";
$DropdownTime.SelectedIndex="-1";
$DropDownTime2.SelectedIndex = "-1";
$calendar.value = get-date;
write-host "All Clear`n"
write-host "READY`n" -ForegroundColor Green
})
$ButtonClearAll.Text = "Clear All Fields"
$ButtonClearAll.Location = New-Object System.Drawing.Size(15,820)
$ButtonClearAll.Size = New-Object System.Drawing.Size(200,23)
$ButtonClearAll.BackColor = "White"
$Form.Controls.Add($ButtonClearAll)

#GUI Advanced Button
$ButtonAdvanced = New-Object System.Windows.Forms.Button
$ButtonAdvanced.ForeColor = "White"
$ButtonAdvanced.BackColor = "Blue"
$ButtonAdvanced.add_click({
check_keys;
if ($global:myerror -eq $null) {
$FormAdvanced.ShowDialog()}
}
)
$ButtonAdvanced.Text = "Advanced Options --->"
$ButtonAdvanced.Location = New-Object System.Drawing.Size(375,810)
$ButtonAdvanced.Size = New-Object System.Drawing.Size(200,23)
$Form.Controls.Add($ButtonAdvanced)

#Help Link
$LinkHelp = new-object System.Windows.Forms.LinkLabel
$LinkHelp.Location = New-Object System.Drawing.Size(490,843)
$LinkHelp.Size = New-Object System.Drawing.Size(150,14)
$LinkHelp.LinkColor = "BLUE"
$LinkHelp.ActiveLinkColor = "RED"
$LinkHelp.Text = "iPatch API Help"
$LinkHelp.add_Click({[system.Diagnostics.Process]::start("https://git_pages_url")})
$Form.Controls.Add($LinkHelp)

#Label Author
$LabelAuthor= new-object System.Windows.Forms.Label
$LabelAuthor.Location = New-Object System.Drawing.Size(395,860)
$LabelAuthor.Size = New-Object System.Drawing.Size(190,24)
$LabelAuthor.Text = "2018 Vadim Teosyan"
$Form.Controls.Add($LabelAuthor)

#Main Exit Button
$ButtonExit = New-Object System.Windows.Forms.Button
$ButtonExit.BackColor = "Yellow"
$ButtonExit.add_click({$Form.Close()})
$ButtonExit.Text = "Exit"
$ButtonExit.Location = New-Object System.Drawing.Size(15,850)
$ButtonExit.Size = New-Object System.Drawing.Size(100,23)
$Form.Controls.Add($ButtonExit)

#cls
write-host "READY`n" -ForegroundColor Green
$Form.ShowDialog()