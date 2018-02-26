<# : Batch portion (batch script is in commentary of powershell v2.0+)

: File Name      : BLite.bat
: Created        : 2018-02-12
: Writen by      : David Medeiros
: Prerequisite   : PowerShell V2 over Vista and upper.

@echo off 
color 1f
set maintitle=BLite 1.0
title %maintitle%
SETLOCAL EnableDelayedExpansion
cls

set "menu[0]=Customizar Imagem .wim x86-x64"
set "menu[1]=Sair"
set "default=0"

powershell -noprofile "iex (gc \"%~f0\" | out-string)"

if !menu[%ERRORLEVEL%]! EQU !menu[1]! goto :eof

:configure
start /wait "!titlegoeshere!" notepad.exe "%CD%\settings.ini"

:getsettings
for /f "delims== tokens=1,2" %%G in ('type settings.ini') do set %%G=%%H

:extractiso
if !extractiso! EQU "yes" (
    mkdir "%CD%\extracted"
    start /wait "Extracting ISO Image" "%CD%\tools\7z.exe" x -o"%CD%\extracted" -y "%CD%\iso\*.iso"
    )

:copywim
start /wait "" "C:\Program Files\TeraCopy\TeraCopy.exe" copy "%CD%\extracted\sources\install.wim" "%CD%\wim" /OverwriteOlder /Close

set "updatesdir=%CD%\updates"
set "wgetdir=%CD%\tools\wget.exe"

:createlistfile
: x86
if !archx86! EQU "yes" (
    set arch="x86"
    set filename=download_x86.txt
    mkdir "!updatesdir!\!arch!"
    break>"!updatesdir!\!arch!\!filename!"
    start /wait "!titlegoeshere!" notepad.exe "!updatesdir!\!arch!\!filename!"
    if exist "!updatesdir!\!arch!\!filename!" (
        set filesize=0
        for /f %%i in ('type !updatesdir!\!arch!\!filename!') do set size=%%~zi
        if !size! GTR 0 (
            set download=1
            ) else (
            set download=0
            )
        )
    if !download EQU 1 !wgetdir! -i !updatesdir!\!arch!\!filename! -P !updatesdir!\!arch!
    )

: x64
if !archx64! EQU "yes" (
    set arch="x64"
    set filename="download_x64.txt"
    mkdir "!updatesdir!\!arch!"
    break>"!updatesdir!\!arch!\!filename!"
    start /wait "!titlegoeshere!" notepad.exe "!updatesdir!\!arch!\!filename!"
    if exist "!updatesdir!\!arch!\!filename!" (
        set filesize=0
        for /f %%i in ('type !updatesdir!\!arch!\!filename!') do set size=%%~zi
        if !size! GTR 0 (
            set download=1
            ) else (
            set download=0
            )
        )
    if !download! EQU 1 !wgetdir! -i !updatesdir!\!arch!\!filename! -P !updatesdir!\!arch!
    powershell.exe "& ""expand_msu_files.ps1"""
    )







#>

# Here starts the PowerShell Code
# For future reference: https://goo.gl/6354Cm https://goo.gl/WkT64r

# Console Settings
[console]::CursorVisible=$false

$menutitle = "=== MENU ==="
$menuprompt = "Use the arrow keys.  Hit ENTER to select."

$maxlen = $menuprompt.length + 6
$menu = gci env: | ?{ $_.Name -match "^menu\[\d+\]$" } | %{
    $_.Value.trim()
    $len = $_.Value.trim().Length + 6
    if ($len -gt $maxlen) { $maxlen = $len }
}
[int]$selection = $env:default
$h = $Host.UI.RawUI.WindowSize.Height
$w = $Host.UI.RawUI.WindowSize.Width
$xpos = [math]::floor(($w - ($maxlen + 5)) / 2)
$ypos = [math]::floor(($h - ($menu.Length + 4)) / 3)

$offY = [console]::WindowTop;
$rect = New-Object Management.Automation.Host.Rectangle `
    0,$offY,($w - 1),($offY+$ypos+$menu.length+4)
$buffer = $Host.UI.RawUI.GetBufferContents($rect)

function destroy {
    $coords = New-Object Management.Automation.Host.Coordinates 0,$offY
    $Host.UI.RawUI.SetBufferContents($coords,$buffer)
}

function getKey {
    while (-not ((37..40 + 13 + 48..(47 + $menu.length)) -contains $x)) {
        $x = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode
    }
    $x
}

# Great reference: http://goo.gl/IAmdR6

function WriteTo-Pos ([string]$str, [int]$x = 0, [int]$y = 0,
    [string]$bgc = [console]::BackgroundColor, [string]$fgc = [Console]::ForegroundColor) {
    if($x -ge 0 -and $y -ge 0 -and $x -le [Console]::WindowWidth -and
        $y -le [Console]::WindowHeight) {
        $saveY = [console]::CursorTop
        $offY = [console]::WindowTop       
        [console]::setcursorposition($x,$offY+$y)
        Write-Host $str -b $bgc -f $fgc -nonewline
        [console]::setcursorposition(0,$saveY)
    }
}

function center([string]$what) {
    $what = "    $what  "
    $lpad = " " * [math]::max([math]::floor(($maxlen - $what.length) / 2), 0)
    $rpad = " " * [math]::max(($maxlen - $what.length - $lpad.length), 0)
    WriteTo-Pos "$lpad   $what   $rpad" $xpos $line darkblue white
}

function menu {
    $line = $ypos
    center $menutitle
    $line++
    center " "
    $line++

    for ($i=0; $item = $menu[$i]; $i++) {
        # write-host $xpad -nonewline
        $rtpad = " " * ($maxlen - $item.length)
        if ($i -eq $selection) {
            WriteTo-Pos "[$i] $item $rtpad" $xpos ($line++) white darkblue
        } else {
            WriteTo-Pos "[$i] $item $rtpad" $xpos ($line++) darkblue white
        }
    }
    center " "
    $line++
    center $menuprompt
    1
}

while (menu) {

    [int]$key = getKey

    switch ($key) {

        37 {}   # left or up
        38 { if ($selection) { $selection-- }; break }

        39 {}   # right or down
        40 { if ($selection -lt ($menu.length - 1)) { $selection++ }; break }

        # number or enter
        default { if ($key -gt 13) {$selection = $key - 48}; destroy; exit($selection) }
    }
}
