<# 

File Name      : expand_msu_files.ps1
Created        : 2018-02-12
Writen by      : David Medeiros
Prerequisite   : PowerShell V2 over Vista and upper.
Part of		   : Blite 1.0
Source URL     : 

#>

cls
# Get all params
param (
	[Parameter(Mandatory=$true)][string]$updatesdir,
	[Parameter(Mandatory=$true)][string]$arch
)

# Define updates directory
$msufolder = "$updatesdir\$arch"

# Expand all updates inside updates directory
$getitem = (Get-Item -Path $msufolder -Verbose).FullName
 Foreach($item in (ls $msufolder *.msu -Name))
 {
    echo "======== Extracting MSU files ========"
    $item = $msufolder + "\" + $item
    expand -F:* $item $msufolder
 }

# Clean the mess
remove-item $msufolder\*.txt -Confirm:$false -Force
remove-item $msufolder\*.exe -Confirm:$false -Force
remove-item $msufolder\*.xml -Confirm:$false -Force
remove-item $msufolder\WSUSSCAN.cab -Confirm:$false -Force
remove-item $msufolder\*.msu -Confirm:$false -Force
