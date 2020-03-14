##### #  # ##   #  ####   ###
  #   #  # # #  #  #      ##
  #   #  # #  # #  ####   ##
  #   #  # #   ##  #      
###   #### #    #  ####   ##

#region Challenge: Improve on Snake!


#requires -version 2

#
# Powershell Snake Game
# Author : Kurt Jaegers
#

function SetEmptySquare($x, $y)
{
    $matrix[$x, $y] = $emptysquare
    [console]::SetCursorPosition($x + 1, $y + 1)
    Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline " "    
}

function SetBodySquare($x, $y)
{
    $matrix[$x, $y] = $bodysquare
    [console]::SetCursorPosition($x + 1, $y + 1)
    Write-Host -ForegroundColor White -BackgroundColor White -NoNewline " "
}

#
# Draws the snake to the screen, including cleaning up the last segment of the tail
#
function DrawTheSnake($x, $y)
{
    $newPoint = New-Object System.Drawing.Point($x, $y)
    $tail.Enqueue($newPoint)

    SetBodySquare -x $x -y $y

    if ($tail.Count -gt $script:maxTailLength)
    {
        $oldPoint = $tail.Dequeue()
        SetEmptySquare -x $oldPoint.X -y $oldPoint.Y
    }
}


#
# Generate a random location for the apple, making sure it isnt inside the snake
#
function MoveTheApple
{ 
    do 
    {
        $x = get-random -min 2 -max ($width - 2)
        $y = get-random -min 2 -max ($height - 2)
    }
    until ($matrix[$x, $y] -eq $emptysquare )

    $matrix[$x, $y] = $applesquare
    DrawTheApple -x $x -y $y
}

#
# Draw the apple to the screen
#
function DrawTheApple($x, $y)
{
    [console]::SetCursorPosition($x + 1, $y + 1)
    Write-Host -foregroundcolor red -backgroundcolor black "@"
}

#
# Check to see if the snake hits the apple
#
function CheckAppleHit($x, $y)
{
    if ($matrix[$x, $y] -eq $applesquare)
    {
        # relocate the apple
        MoveTheApple
        SetEmptySquare -x $x -y $y
    
        $script:score += 500
    
        # Add to the snake's length
        $script:maxTailLength++
    }
}

#
# Check to see if the snake's head hits the walls of the screen
#
function CheckWallHits($x, $y)
{
    if ($matrix[$x, $y] -eq $wallsquare)
    {
        cls
        write-host -foregroundcolor red "You lost! Score was $script:score"
        exit
    }
}

function SetBorderSquare($x, $y)
{
    [console]::SetCursorPosition($x + 1, $y + 1)
    Write-Host -ForegroundColor Black -BackgroundColor White '#' -NoNewline
    $matrix[$x, $y] = $wallsquare
}

#
# Draw a fence around the edges of the screen
#
function DrawScreenBorders
{    
    for ($x = 0; $x -lt $width; $x++)
    {
        SetBorderSquare -x $x -y 0
        SetBorderSquare -x $x -y ($height - 1)
    }

    for ($y = 0; $y -lt $height; $y++)
    {
        SetBorderSquare -x 0 -y $y
        SetBorderSquare -x ($width - 1) -y $y
    }
}

function CheckSnakeBodyHits($x, $y)
{
    if ($matrix[$x, $y] -eq $bodysquare)
    {
        cls
        write-host -foregroundcolor red "You lost! Score was $script:score"
        exit
    }
}

function DrawScore($score)
{
    $string = "Score: $score"
    $xPos = [int](($script:width - $string.Length) / 2)
    [console]::SetCursorPosition($xPos, 0)

    Write-Host -ForegroundColor Red -BackgroundColor Black $string
}

# ---------------------------------
# ---------------------------------
# Main script block starts here
# ---------------------------------
# ---------------------------------

if ($host.name -ne "ConsoleHost") 
{
    write-host "This script should only be run in a ConsoleHost window (outside of the ISE)"
    exit
    $done=$true
} 

Add-Type -AssemblyName System.Drawing

# Grab UI objects and set some colors
$ui=(get-host).ui
$rui=$ui.rawui
$rui.BackgroundColor="Black"
$rui.ForegroundColor="Red"
cls

# write out lines to make sure the buffer is big enough to cover the screen
for ($i=0; $i -lt $rui.screensize.height; $i++)
{
    write-host "" 
}


$cs = $rui.cursorsize
$rui.cursorsize=0
$script:score = 0

$width = $rui.WindowSize.Width - 2
$height = $rui.WindowSize.Height - 2

$emptysquare = 0
$bodysquare = 1
$applesquare = 2
$wallsquare = 3

$currentX = [int]($width / 2)
$currentY = [int]($height / 2)

$matrix = New-Object 'int[,]' -ArgumentList ($width, $height)

$tail = New-Object System.Collections.Queue
$script:maxTailLength = 5

$done = $false

$before = 0
$after  = 15
$dir = 0

DrawScreenBorders;
DrawTheSnake -x $currentX -y $currentY
MoveTheApple;

while (!$done)
{  
    if ($rui.KeyAvailable)
    {
        $key = $rui.ReadKey()
        if ($key.virtualkeycode -eq -27)
        {
            $done=$true
        }
        if ($key.keydown)
        {
            # Left
            if ($key.virtualkeycode -eq 37)
            {
                $dir=0
            }   
            # Up
            if ($key.virtualkeycode -eq 38)
            {
                $dir=1
            } 
            # Right
            if ($key.virtualkeycode -eq 39)
            {
                $dir=2
            }
            # Down
            if ($key.virtualkeycode -eq 40)
            {
                $dir=3
            }
        }
    }
  
    if ($dir -eq 0)
    { 
        $currentX--;
    }
  
    if ($dir -eq 1)
    {
        $currentY--;
    }
  
    if ($dir -eq 2)
    {
        $currentX++;
    }
  
    if ($dir -eq 3)
    {
        $currentY++;
    }

    CheckWallHits -x $currentX -y $currentY
    CheckSnakeBodyHits -x $currentX -y $currentY
    CheckAppleHit -x $currentX -y $currentY
    DrawTheSnake -x $currentX -y $currentY
    
    $script:score += $script:maxTailLength

    DrawScore -score $script:score

    start-sleep -mil 100
}

$rui.cursorsize=$cs



#endregion


#region Puzzles

# June Blender blog on write verbose

start-process iexplore.exe https://www.sapien.com/blog/2017/02/27/friday-puzzle-solution-why-doesnt-verbose-work/


# June Blender blog on what does Return....return?
Start-Process iexplore.exe https://www.sapien.com/blog/2017/02/18/friday-puzzle-solution-what-does-return-keyword-return/ 


#endregion
