#Main Form
$Form = New-Object Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(600,900)
$Form.MaximizeBox= "false"
$Form.MinimumSize = "600,900"
$Form.MaximumSize = "600,900"
$Form.StartPosition = "CenterScreen"
$Form.Text = "iPatch GUI"
$Form.AutoSize = $True

#Button Exit
$ButtonExit = New-Object System.Windows.Forms.Button
$ButtonExit.Text = "Exit"
$ButtonExit.Location = New-Object System.Drawing.Size(5,500)
$ButtonExit.Size = New-Object System.Drawing.Size(100,20)
$ButtonExit.BackColor = "Red"
$Form.Controls.Add($ButtonExit)

#Button Exit Click Action
$ButtonExit.add_click({$form.close()})

$Form.ShowDialog()