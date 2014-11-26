# This script using some cmdlets from the DISM PowerShell module.
# The DISM PowerShell module is included in Windows 8.1 and Windows Server 2012 R2 and does not need to be imported.
# On other supported operating systems, you can use the DISM PowerShell module included in the Windows ADK.
# Read more: http://technet.microsoft.com/en-us/library/hh825010.aspx

Param(
  [switch]$BuildPXE = $False,
  [switch]$CreatePeISO = $False
)

$WinpeRoot				= "H:\adk\winpe_build"
$PxeRoot				= "H:\adk\winpe_pxe"
 
# ADK installation path. ADK 8.1 can be found here: https://www.microsoft.com/en-US/download/details.aspx?id=39982
$ADK_Path				= "${Env:ProgramFiles(x86)}\Windows Kits\8.1\Assessment and Deployment Kit"

$WinPE_PackagesRoot		= "${ADK_Path}\Windows Preinstallation Environment\amd64\WinPE_OCs"
$WinPE_Packages			= "WinPE-HTA.cab", "WinPE-Scripting.cab", "WinPE-WMI.cab", "WinPE-NetFx.cab", "WinPE-PowerShell.cab", "WinPE-DismCmdlets.cab", "WinPE-StorageWMI.cab"
$DriversPath			= "H:\adk\drivers\win2012r2"
$BCD_Path				= "${ADK_Path}\Deployment Tools\amd64\BCDBoot"
$OScdimg_Path			= "${ADK_Path}\Deployment Tools\amd64\Oscdimg"
$Dism_Path				= "${ADK_Path}\Deployment Tools\amd64\DISM"
$PE_Media_Path			= "${ADK_Path}\Windows Preinstallation Environment"
$PE_Source_Path			= "${ADK_Path}\Windows Preinstallation Environment\amd64"
$PE_Wim					= "${ADK_Path}\Windows Preinstallation Environment\amd64\en-us\winpe.wim"

$Env:Path += $BCD_Path;$OScdimg_Path;$Dism_Path;$::path
 
# Calling a script which sets some useful variables 
& "${ADK_Path}\Deployment Tools\DandISetEnv.bat"

# Cleanup
Remove-Item -Recurse -Force $WinpeRoot
if (!(Test-Path -path $WinpeRoot))
{
	New-Item $WinpeRoot -Type Directory > $null
}

# Copying WinPE files (same way as copype.cmd does)
New-Item $WinpeRoot\media -Type Directory > $null
New-Item $WinpeRoot\mount -Type Directory > $null
New-Item $WinpeRoot\fwfiles -Type Directory > $null
Copy-Item $PE_Source_Path\Media\ -Destination $WinpeRoot\media -Recurse
New-Item $WinpeRoot\media\sources -Type Directory > $null
Copy-Item $PE_Wim -Destination $WinpeRoot\media\sources\boot.wim
Copy-Item $OScdimg_Path\efisys.bin -Destination $WinpeRoot\fwfiles
Copy-Item $OScdimg_Path\etfsboot.com -Destination $WinpeRoot\fwfiles

# Mounting WinPE wim-image
#Mount-WindowsImage -ImagePath "$WinpeRoot\media\sources\boot.wim" -Index 1 -Path "$WinpeRoot\mount"
&Dism.exe /Mount-Wim "/WimFile:$WinpeRoot\media\sources\boot.wim" /index:1 "/MountDir:$WinpeRoot\mount"

# Adding some useful packages. Packages description and dependencies for WinPE 8.1 can be found here: http://technet.microsoft.com/en-us/library/hh824926.aspx
ForEach ($WinPE_Package in $WinPE_Packages)
{
	Write-Host "Adding package $WinPE_Package"
	Add-WindowsPackage -PackagePath "$WinPE_PackagesRoot\$WinPE_Package" -Path "$WinpeRoot\mount"
	#&Dism.exe "/image:$WinpeRoot\mount" /Add-Package "/PackagePath:$WinPE_PackagesRoot\$WinPE_Package" | Out-Null
}

# Adding drivers
#Add-WindowsDriver -Path "$WinpeRoot\mount" -Driver $DriversPath -Recurse
Write-Host "Adding drivers"
&Dism.exe "/image:$WinpeRoot\mount" /Add-Driver "/driver:$DriversPath" /recurse

# Setting the timezone. List of available timezones can be found here: http://technet.microsoft.com/en-US/library/cc749073(v=ws.10).aspx
Write-Host "Setting the timezone"
&Dism.exe "/image:$WinpeRoot\mount" "/Set-TimeZone:Russian Standard Time"

# Unmounting and updating the image
#Dismount-WindowsImage -Path "$WinpeRoot\mount" -Save
&Dism.exe /Unmount-Wim "/MountDir:$WinpeRoot\mount" /Commit

# Creationg ISO image from WinPE tree
if ($CreatePeISO)
{
	& "$PE_Media_Path\MakeWinPEMedia.cmd" "/iso" "/f" $WinpeRoot "$WinpeRoot\winpe_amd64.iso"
}

# PXE part. Not finished yet
if ($BuildPXE)
{
	Remove-Item -Recurse -Force $PxeRoot
	if (!(Test-Path -path $PxeRoot))
	{
		New-Item $PxeRoot -Type Directory > $null
	}
	New-Item "$PxeRoot\Boot" -Type Directory > $null
}
