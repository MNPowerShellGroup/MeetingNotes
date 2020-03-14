#Main Form
$Form = New-Object Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(600,900)
$Form.MaximizeBox= "false"
$Form.MinimumSize = "600,900"
$Form.MaximumSize = "600,900"
$Form.StartPosition = "CenterScreen"
$Form.Text = "iPatch GUI"
$Form.AutoSize = $True

#Combo Box a.k.a. Dropdown list
$DropDownDay = new-object System.Windows.Forms.ComboBox
$DropDownDay.Location = new-object System.Drawing.Size(15,200)
$DropDownDay.Size = new-object System.Drawing.Size(130,30)
$form.controls.Add($DropDownDay)

#Populate the dropdown list
$DropDownArrayDay = @("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")
ForEach ($Item in $DropDownArrayDay) {
	$DropDownDay.Items.Add($Item)
}

#Selected Dropdown value
$Day = $DropdownDay.SelectedItem


$Form.ShowDialog()