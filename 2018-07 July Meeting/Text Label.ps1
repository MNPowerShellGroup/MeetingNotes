#Main Form
$Form = New-Object Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(600,900)
$Form.MaximizeBox= "false"
$Form.MinimumSize = "600,900"
$Form.MaximumSize = "600,900"
$Form.StartPosition = "CenterScreen"
$Form.Text = "iPatch GUI"
$Form.AutoSize = $True

#Text Label
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "This is a sample GUI form."
$Label1.AutoSize = $True
$Label1.Location = new-object system.drawing.size(15,100)
$Form.Controls.Add($Label1)

$Form.ShowDialog()