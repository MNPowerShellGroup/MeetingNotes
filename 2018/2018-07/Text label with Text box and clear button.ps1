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
$Label1.Location = new-object system.drawing.size(5,1)
$Form.Controls.Add($Label1)

#Form API Token
$LabelToken = New-Object System.Windows.Forms.Label
$LabelToken.Text = "API Token:"
$LabelToken.AutoSize = $True
$LabelToken.Location = new-object system.drawing.size(5,20)
$Form.Controls.Add($LabelToken)

#Textbox
$global:TextboxToken = New-Object System.Windows.Forms.TextBox
$global:TextboxToken.Location = New-Object System.Drawing.Size(65,20)
$global:TextboxToken.Size = New-Object System.Drawing.Size(200,20)
$Form.Controls.Add($global:TextboxToken)

#Textbox Value
$global:TextboxToken.Text

#Button
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Text = "Clear"
$Button1.Location = New-Object System.Drawing.Size(300,20)
$Button1.Size = New-Object System.Drawing.Size(100,20)
$Form.Controls.Add($Button1)

#Button Click Action
$Button1.add_click({$global:TextboxToken.Clear();message_box})
#$Button1.add_click({$global:TextboxToken.Clear()})

$Form.ShowDialog()