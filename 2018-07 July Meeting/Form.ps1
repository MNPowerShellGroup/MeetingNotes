#Main Form
$Form = New-Object Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(600,900)
$Form.MaximizeBox= "false"
$Form.MinimumSize = "600,900"
$Form.MaximumSize = "600,900"
$Form.StartPosition = "CenterScreen"
$Form.Text = "iPatch GUI"
$Form.AutoSize = $True

$Form.ShowDialog()