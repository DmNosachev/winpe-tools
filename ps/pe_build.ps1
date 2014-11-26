# This script using some cmdlets from the DISM PowerShell module.
# The DISM PowerShell module is included in Windows 8.1 and Windows Server 2012 R2 and does not need to be imported.
# On other supported operating systems, you can use the DISM PowerShell module included in the Windows ADK.
# Read more: http://technet.microsoft.com/en-us/library/hh825010.aspx

Param(
  [switch]$BuildPXE = false,
  [switch]$CreatePeISO = false
)

$WinpeRoot				= 'H:\adk\winpe_build'
$PxeRoot				= 'H:\adk\winpe_pxe'
 
# ADK installation path. ADK 8.1 can be found here: https://www.microsoft.com/en-US/download/details.aspx?id=39982
$ADK_Path				= "$($Env:ProgramFiles(x86))\Windows Kits\8.1\Assessment and Deployment Kit"

$WinPE_PackagesRoot	= "$ADK_Path\Windows Preinstallation Environment\amd64\WinPE_OCs"
$WinPE_Packages		= "$WinPE_PackagesRoot\WinPE-HTA.cab", "$WinPE_PackagesRoot\WinPE-Scripting.cab", "$WinPE_PackagesRoot\WinPE-WMI.cab", "$WinPE_PackagesRoot\WinPE-NetFx.cab", "$WinPE_PackagesRoot\WinPE-PowerShell.cab", "$WinPE_PackagesRoot\WinPE-DismCmdlets.cab", "$WinPE_PackagesRoot\WinPE-StorageWMI.cab"
$DriversPath		= 'H:\adk\drivers\win2012r2'
$BCD_Path			= "$ADK_Path\Deployment Tools\amd64\BCDBoot"
 
# Calling a script which sets some useful variables 
cmd.exe /c "$ADK_Path\Deployment Tools\DandISetEnv.bat"

# Cleanup
Remove-Item -Recurse -Force $WinpeRoot
if (!(Test-Path -path $WinpeRoot)) {New-Item $WinpeRoot -Type Directory}

if ($BuildPXE)
{
	Remove-Item -Recurse -Force $PxeRoot
	if (!(Test-Path -path $PxeRoot)) {New-Item $PxeRoot -Type Directory}
	New-Item "$PxeRoot\Boot" -Type Directory
}

# Calling standart script that copies WinPE tree
& copype.cmd amd64 $WinpeRoot | Out-Host

# Mounting WinPE wim-image
Mount-WindowsImage -ImagePath "$WinpeRoot\media\sources\boot.wim" -Index 1 -Path "$WinpeRoot\mount"

# Adding some useful packages. Packages description and dependencies for WinPE 8.1 can be found here: http://technet.microsoft.com/en-us/library/hh824926.aspx
ForEach ($WinPE_Package in $WinPE_Packages)
{
	Add-WindowsPackage -PackagePath $WinPE_Package -Path "$WinpeRoot\mount"
}

# Adding drivers
Add-WindowsDriver -Path "$WinpeRoot\mount" -Driver $DriversPath -Recurse

# Unmounting and updating the image
Dismount-WindowsImage –Path "$WinpeRoot\mount" -Save

# Creationg ISO image from WinPE tree
if ($CreatePeISO)
{
	& Makewinpemedia /iso /f $WinpeRoot "$(WinpeRoot)\winpe_amd64.iso"
}
