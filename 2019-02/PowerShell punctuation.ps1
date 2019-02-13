#  PowerShell Punctuation
#  Demo code

#  Tim Curwick

#  MN PowerShell Automation Group
#  2/12/2019


##  Question mark

#  Alias for Where-Object
gci | ? Length -gt 10MB

#  Best practice - do not use aliases


##  Exclamation point

#  Alternative to -not
If(!$True){$X=$False}

#  Best practice - do not use "aliases" - spell out -not
If ( -not $True ) { $X = $False }


##  Percent sign

#  Alias for ForEach-Object
gci|%{$T=0}{$T+=$_.Length}{$T}

#  Best practice - do no use aliases
Get-ChildItem | ForEach-Object { $Total = 0 } { $Total += $_.Length } { $Total }


#  Remainder operator
#  (Not a modulus operator. Sort of)
If ( ($Loop++) % 100 -eq 0 ) { "$Loop loops done so far..." }


#  PowerShell parser has two modes Command mode and Expression mode
#  Punctuation (and other things) may be interpreted differently in each mode

#  Command mode
gci | % { $_ }

#  Expression mode
27 % 4


#  Command mode
Get-Item -Path C:\Temp

#  Expression mode
$Path = "C:\Temp"


##  Asterisk

#  Multiply
#  Not just for numbers

#  Concatenate repeated string
$Width = 22
'-' * 22


#  Create large arrays with a non-default value
@( 100 ) * 10

@( 'Red', 'Yellow', 'Blue' ) * 4


##  Plus, plus equals

#  Add, add assign
#  Not just for numbers

#  Concatenate strings
'This' + 'That'

$Body = ''
If ( $ErrorMessage ) { $Body += 'Oops. $Errormessage' + [environment]::NewLine }


#  Add elements to an array
$Array  = @()
$Array += 'red'
$Array += 'yellow'
$Array += 'blue'


#  Combine hashtables
$CopyParam = @{ Tile = 'TileA' }
If ( $TargetWorkspace ) { $CopyParam += @{ TargetWorkspace = $TargetWorkspace } }
If ( $TargetDashboard ) { $CopyParam += @{ TargetDashboard = $TargetDashboard } }
If ( $TargetReport    ) { $CopyParam += @{ TargetReport    = $TargetReport    } }
If ( $TargetDataset   ) { $CopyParam += @{ TargetDataset   = $TargetDataset   } }
Copy-SpbiTile @CopyParam


#  Dynamic type conversion
#  Usually converts right hand value to match left hand value

22 + "44"

"44" + 22


#  Usually, not always

"44" / 22

"44" / "22"


##  Period - Member operator

#  Multiple steps
$Path = '\\Server1\ShareA\Dept\Folder1\Folder2\Doc.txt'
$NewPath = $Path.Substring( 0, $Path.LastIndexOf( "\" ) + 1 )
$NewPath = $NewPath.Replace( "\$OldServer\", "\$NewServer\" )
$NewPath = $NewPath.Replace( "\$OldShare\", "\$NewShare\" )
$NewPath = $NewPath.Replace( "\$OldDept\", "\$NewBL\$NewDivision\$NewDept\" )
$NewPathLength = $NewPath.Length

#  Chaining methods and properties
$NewPathLength = $Path.Substring( 0, $Path.LastIndexOf( '\' ) + 1 ).Replace( '\Server1\', '\Server2\' ).Replace( '\ShareA\', '\ShareB\' ).Replace( '\Folder2\', '\' ).Length

#  Chaining with white space
$NewPath = $Path.
    Substring( 0, $Path.LastIndexOf( '\' ) + 1 ).
    Replace( '\Server1\', '\Server2\' ).
    Replace( '\ShareA\', '\ShareB\' ).
    Replace( '\Folder2\', '\' )


#  Compact, hard to read
$NewCompany = $OldCompany.Replace( 'Contoso', 'Microsoft' )
$NewID = $OldID.Replace( 'Contoso', 'Microsoft' )
$NewLogo = $OldLogo.Replace( 'Contoso', 'Microsoft' )

#  Readable with white space
$NewCompany = $OldCompany.Replace( 'Contoso', 'Microsoft' )
$NewID      = $OldID.     Replace( 'Contoso', 'Microsoft' )
$NewLogo    = $OldLogo.   Replace( 'Contoso', 'Microsoft' )


## Semicolon

#  Static member operator

#  White space works with static properties and methods
[datetime]:: Now
[math]::     Pow( 22, 4 )


##  Binary operators vs unary operators

#  Binary operators have two parameters, a left hand value and a right hand value
$This -and $That


#  Unary operators have a single parameters, a right hand value
-not $This


#  Note that some unary operators can be used on the right side of the "right" hand value
++$Counter
$Counter++


#  Some operators are multipurposed and are defined as both binary and unary operators

#  Binary minus
#  Subtraction
$Total - $Used

#  Unary minus
#  Negative
-$Days


##  Comma

#  Binary comma is the array operator ( not @() )
1, 2
$Object1, $Object2


#  Unary comma is used to define an array with a single element
,1
,$Object1


#  This DOES NOT create an array within an array
#  It just ensures that the array is an array
@( @( 1 ) )

#  This does create an array within an array
,@( 1 )


#  This creates an array with three elements,
#  the first of which is an array with one element
, 1, 2, 3


#  Adding a dummy array around an array that you don't want PowerShell to unwrap

 @( 1, 2, 3 ) | Measure-Object                        #  Yields a count of 3
 @( 1, 2, 3 ) | ForEach-Object { $_.GetType().Name }  #  Yields Int32, Int32, Int32


,@( 1, 2, 3 ) | Measure-Object                        #  Yields a count of 1
,@( 1, 2, 3 ) | ForEach-Object { $_.GetType().Name }  #  Yields object[]


#  return array as single object
return ,$Results


##  Parenthesis

#  Order of operation

2 *  3 + 4  * 5  #  Yields 26
2 * (3 + 4) * 5  #  Yields 70


#  Reverse the direction of order of operation

#  Casting is applied right to left
$File = Get-Item -Path C:\Temp\abc.ps1

 [string]$File. Length  #  Yields length of the file
([string]$File).Length  #  Yields length of the file full name


#  Great for avoiding errors when calling a string method on an potentially Null value

#  Instead of 
If ( $Response )
    {
    $UserMessage = $Response.Replace( '<br>', [environment]::NewLine )
    }
Else
    {
    $UserMessage = ''
    }

#  We can
$UserMessage = ([string]$Response).Replace( '<br>', [environment]::NewLine )


#  Use for changing parser mode
$Path = 'C:\Temp'

#  Fails because after a command, PowerShell uses command mode.
#  In command mode, PowerShell assumes "[string]" is a literal part of a string
Get-Item -Path  [string]$Path

#  Works becaue inside the parentheses, PowerShell switches back to expression mode
Get-Item -Path ([string]$Path)


#  Use to output the result of an assignment expression
  $X = 2
( $X = 2 )


#  Use to output and use the result of an assignment expression
If ( (++$Loops) % 100 -eq 0 ) { "$Loops loops complete..." }


#  Use to assign a value in part of an expression to a variable for reuse later in the expression
$Start = ( $Date = Get-Date -S 0 -M 0 ).AddMinutes( 15 - $Date.Minute % 15 )


#  Like in math, parentheses mean do whatever is in here first, and use the result
#  This can include simple commands
$Path = 'C:\Temp'
( Get-ChildItem -Path $Path ).Count


#  This does not work for more complex commands
#  This fails
( If ( $Path.Length -gt 2 ) { Get-ChildItem -Path $Path } ).Count


#  For more complex commands, use $()

$( If ( $Path.Length -gt 2 ) { Get-ChildItem -Path $Path } ).Count


#  $() has no restrictions on what works inside it

If ( $( try { Test-Path -Path $Path } catch {} ) )
    {
    #  Do stuff
    }

$(
        Import-Module ActiveDirectory
        $Users = Get-ADUser * -Properties MemberOf
        $Groups = $Users.MemberOf | Sort-Object -Unique
        ForEach ( $Group in $Groups )
            {
            Get-ADGroupMember -Identity $Groups
            }
    ).Count


#  $() is recognized inside expandable strings
$UserError = "Error trying to that. $($_.Exception.Message)"


#  @() is exactly the same as $(), except output is always an array.

$( )       #  Null output
$( 1 )     #  Integer output
$( 1, 2 )  #  Array of integers output


@( )       #  Empty array output
@( 1 )     #  Array with one integer output
@( 1, 2 )  #  Array of integers output


#  Use @() for more readable code

#  Instead of
$Colors = 'Red', 'Yellow', 'Blue', 'Orange', 'Green', 'Purple'

#  or
$Colors =
    'Red',
    'Yellow',
    'Blue',
    'Orange',
    'Green',
    'Purple'

#  We can use
$Colors = @(
    'Red'
    'Yellow'
    'Blue'
    'Orange'
    'Green'
    'Purple' )


##  A semicolon terminates a pipeline (which is almost every line in PowerShell)

#  Semicolon and a line terminator can be used almost interchangeably.

#  Use a semicolon to make code more readable
[grid]::SetRow( $labelVnet         , 0 ); [grid]::SetColumn( $labelVnet         , 0 )
[grid]::SetRow( $comboVNetName     , 0 ); [grid]::SetColumn( $comboVNetName     , 1 )
[grid]::SetRow( $labelVnetRange    , 1 ); [grid]::SetColumn( $labelVnetRange    , 0 )
[grid]::SetRow( $textVNetRange     , 1 ); [grid]::SetColumn( $textVNetRange     , 1 )
[grid]::SetRow( $labelDNSServers   , 2 ); [grid]::SetColumn( $labelDNSServers   , 0 )
[grid]::SetRow( $textVNetDNSServers, 2 ); [grid]::SetColumn( $textVNetDNSServers, 1 )
[grid]::SetRow( $labelSubnets      , 3 ); [grid]::SetColumnSpan( $labelSubnets      , 2 )
[grid]::SetRow( $dgvSubnets        , 4 ); [grid]::SetColumnSpan( $dgvSubnets        , 2 )
[grid]::SetRow( $NetworkButtonPanel, 5 ); [grid]::SetColumnSpan( $NetworkButtonPanel, 2 )


#  Use a line break to make code more readable

#  Instead of 
$Hashtable = @{ Alpha = 24; Bravo = 33; Charlie = Get-ChildItem $Path }

#  Use
$Hashtable = @{
    Alpha   = 24
    Bravo   = 33
    Charlie = Get-ChildItem $Path }


#  Every semicolon can be replace by a line break
#  Line breaks that come at the "end" of a line can be replaced by semicolon
#  Line breaks that were put in the "middle" of a line cannot

#  Works
$ValueX = 2
$ValueY = 3

#  Works
$ValueX = 2; $ValueY = 3


#  Works
$ValueX =
    2

#  Doesn't work
$ValueX = ; 2


#  Works
$ValueX = 2  # First value
$ValueY = 3  # Second value

#  Doesn't work
$ValueX = 2  # First value; $ValueY = 3  # Second value
