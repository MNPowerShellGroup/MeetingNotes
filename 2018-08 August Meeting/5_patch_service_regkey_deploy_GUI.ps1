
Add-Type -AssemblyName PresentationFramework

$error.Clear()

#function to pop message box if missing parameters
function missing_parameters() {
    [System.Windows.MessageBox]::Show("Missing parameters!
Make sure to make a selection for each item in this step.", 'Error!', 'OK', 'Error')
}
#function to review provided information
function dialog_box() {
    param($function)
    $result = [System.Windows.MessageBox]::Show($global:message, 'Please review the parameters', 'YesNo', 'Information')
    if ($result -eq 'Yes') {&$function}
}
#function to display errors
function error_box() {
    [System.Windows.MessageBox]::Show($global:message, 'Error!', 'OK', 'Error')
}

$error.Clear()
$global:myerror = "0"

#Function to set the local registry
function set_local_registry () {
    #Set on local computer

    # Setup default patching attributes
    # do not change these
    $default_management = "yes"
    $week = "Not Applicable"
    $reoccurrence = "weekly"
    $active_management = "yes"
    $duration_in_hours = "3"

    #set registrty path
    $reg_path = "HKLM:\SOFTWARE\TargetCorp\Patch"

    #remove previous values, if any
    If (Test-Path -Path "HKLM:\SOFTWARE\TargetCorp\Patch" ) {

        try {
            
            Remove-Item "HKLM:\SOFTWARE\TargetCorp\Patch" -Recurse -ErrorAction Stop
        }
        catch {

            $global:myerror = "1"
            $global:message = "Could not delete the patch registry key, ensure you're running as an administrator.  Error:  $_.Exception.Message"
            error_box

        }
    }
   
    #Check if TargetCorp keys exist, if not create
    If (!(test-path "HKLM:\SOFTWARE\TargetCorp" ) -and !($error)) {

        try {
            New-Item -Path "HKLM:\SOFTWARE\TargetCorp" -ErrorAction Stop
        }
        catch {

            $global:myerror = "1"
            $global:message = "Could not create the TargetCorp registry key, ensure you're running as an administrator. Error:  $_.Exception.Message"
            error_box
        }
        

    }

    #Check if patch key exists, if note create
    If (!(test-path "HKLM:\SOFTWARE\TargetCorp\Patch") -and !($error)) {

        try {
            New-Item -Path "HKLM:\SOFTWARE\TargetCorp\Patch" -ErrorAction Stop
        }
        catch {

            $global:myerror = "1"
            $global:message = "Could not create the patch registry key, ensure you're running as an administrator. Error:  $_.Exception.Message"
            error_box
        }
        

    }

    #set the registry keys
    try {
        New-ItemProperty -Path $reg_path -Name "default_management" -PropertyType String -Value $default_management -Force -ErrorAction Stop
        New-ItemProperty -Path $reg_path -Name "day" -PropertyType String -Value $global:maintenance_day -Force -ErrorAction Stop
        New-ItemProperty -Path $reg_path -Name "start_time" -PropertyType String -Value $global:maintenance_time -Force -ErrorAction Stop
        New-ItemProperty -Path $reg_path -Name "week_of_month" -PropertyType String -Value $week -Force -ErrorAction Stop
        New-ItemProperty -Path $reg_path -Name "reoccurrence" -PropertyType String -Value $reoccurrence -Force -ErrorAction Stop
        New-ItemProperty -Path $reg_path -Name "active_management" -PropertyType String -Value $active_management -Force -ErrorAction Stop
        New-ItemProperty -Path $reg_path -Name "duration_in_hours" -PropertyType String -Value $duration_in_hours -Force -ErrorAction Stop
    }
    catch {

        $global:myerror = "1"
        $global:message = "Could not create the patch registry settings, ensure you're running as an administrator. Error:  $_.Exception.Message"
        error_box

    }

}


################################
# Create Forms and buttons     #
################################
Add-Type -AssemblyName System.Windows.Forms

#Main Form
$Form = New-Object Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(600, 920)
$Form.MaximizeBox = "false"
$Form.MinimumSize = "600,360"
$Form.MaximumSize = "600,360"
$Form.StartPosition = "CenterScreen"
$Form.Text = "Patching Service set day and start time for weekly maintenance window"
$Form.AutoSize = $True
#$Icon = New-Object system.drawing.icon (".\pirate.ico")
#$Form.Icon = $Icon

#Form top label
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "This GUI will help you set your day and start time for Windows patching.
This tool must be run as an Administrator."
$Label1.AutoSize = $True
$Label1.Location = new-object system.drawing.size(5, 1)
$Form.Controls.Add($Label1)

#Label "Working..."
$LabelWorking = New-Object System.Windows.Forms.Label
$LabelWorking.Text = "Working..."
$LabelWorking.AutoSize = $true
$LabelWorking.Location = new-object system.drawing.size(15, 120)
$FontBold = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold) 
$LabelWorking.Font = $FontBold


#Label "Complete"
$LabelComplete = New-Object System.Windows.Forms.Label
$LabelComplete.Text = "Congratulations! Your maintenance window 
settings have been applied"
$LabelComplete.AutoSize = $true
$LabelComplete.Location = new-object system.drawing.size(45, 150)
$FontBold = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold) 
$LabelComplete.Font = $FontBold

#Label "select day label"
$LabelStep1 = New-Object System.Windows.Forms.Label
$LabelStep1.Text = "Select maintenance window day: "
$LabelStep1.AutoSize = $True
$FontBold = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold) 
$LabelStep1.Font = $FontBold
$LabelStep1.Location = new-object system.drawing.size(10, 45)
$Form.Controls.Add($LabelStep1)

#combobox "select day combobox"
$DropDownDay = new-object System.Windows.Forms.ComboBox
$DropDownDay.Location = new-object System.Drawing.Size(450, 45)
$DropDownDay.Size = new-object System.Drawing.Size(120, 90)
$form.controls.Add($DropDownDay)
$DropDownArrayTime2 = @("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
ForEach ($Item in $DropDownArrayTime2) {
    $DropDownDay.Items.Add($Item)
}


#Label "select start time label"
$LabelItem1_1 = New-Object System.Windows.Forms.Label
$LabelItem1_1.Text = "Select the maintenance window start time:"
$LabelItem1_1.AutoSize = $True
$FontBold = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold) 
$LabelItem1_1.Font = $FontBold
$LabelItem1_1.Location = new-object system.drawing.size(10, 80)
$Form.Controls.Add($LabelItem1_1)

#combobox "select start time combobox"
$DropDownStartTime = new-object System.Windows.Forms.ComboBox
$DropDownStartTime.Location = new-object System.Drawing.Size(450, 80)
$DropDownStartTime.Size = new-object System.Drawing.Size(120, 90)
$form.controls.Add($DropDownStartTime)
$DropDownArrayTime2 = @("0000", "0300", "0600", "0900", "1200", "1500", "1800", "2100")
ForEach ($Item in $DropDownArrayTime2) {
    $DropDownStartTime.Items.Add($Item)
}

#Main Exit Button
$ButtonExit = New-Object System.Windows.Forms.Button
$ButtonExit.BackColor = "Yellow"
$ButtonExit.add_click( {$Form.Close()})
$ButtonExit.Text = "Exit"
$ButtonExit.Location = New-Object System.Drawing.Size(420, 280)
$ButtonExit.Size = New-Object System.Drawing.Size(100, 23)
$Form.Controls.Add($ButtonExit)

#Button Add Maintenance Window
$ButtonAddMaintenanceWindow = New-Object System.Windows.Forms.Button
$ButtonAddMaintenanceWindow.Text = "Set maintenance window"
$ButtonAddMaintenanceWindow.Location = New-Object System.Drawing.Size(250, 280)
$ButtonAddMaintenanceWindow.Size = New-Object System.Drawing.Size(140, 23)
$ButtonAddMaintenanceWindow.ForeColor = "White"
$ButtonAddMaintenanceWindow.BackColor = "Green"
$Form.Controls.Add($ButtonAddMaintenanceWindow)

$ButtonAddMaintenanceWindow.add_click( {
        $LabelWorking.Location = new-object system.drawing.size(80, 200)
        $Form.Controls.Remove($ButtonAddMaintenanceWindow)
        $Form.Controls.Add($LabelWorking)

        $global:maintenance_day = $DropdownDay.SelectedItem
        $global:maintenance_time = $DropDownStartTime.SelectedItem
        if ($DropDownDay.SelectedItem -and $DropdownStartTime.SelectedItem) {
            $global:message = "
  
                Maintenance window will be added:
                $($global:maintenance_day)  $($global:maintenance_time)
  
                Proceed?"
            dialog_box ("set_local_registry")
        }
        else { missing_parameters }
  
        $Form.Controls.Remove($LabelWorking)
        $Form.Controls.Add($LabelComplete)
        $Form.Controls.Add($ButtonAddMaintenanceWindow)
    })


#show the dialog
$form.ShowDialog()