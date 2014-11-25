@echo off
 
REM Where to put Windows PE tree and ISO
Set winpe_root=H:\adk\winpe_build
 
REM ADK installation path. ADK 8.1 can be found here: https://www.microsoft.com/en-US/download/details.aspx?id=39982
Set adk_path=%programfiles(x86)%\Windows Kits\8.1\Assessment and Deployment Kit
 
REM Drivers tree path
Set drivers_path=H:\adk\drivers\win2012r2
 
REM Calling a script which sets some useful variables 
call "%adk_path%\Deployment Tools\DandISetEnv.bat"
 
REM Cleaning WinPE tree
if exist %winpe_root% rd /q /s %winpe_root%
 
REM Calling standart script that copies WinPE tree
call copype.cmd amd64 %winpe_root%
 
REM Mounting WinPE wim-image
Dism /Mount-Wim /WimFile:%winpe_root%\media\sources\boot.wim /index:1 /MountDir:%winpe_root%\mount
 
REM Adding some useful packages. Packages description and dependencies for WinPE 8.1 can be found here: http://technet.microsoft.com/en-us/library/hh824926.aspx
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-HTA.cab"
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFx.cab"
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell.cab"
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"
Dism /image:%winpe_root%\mount /Add-Package /PackagePath:"%adk_path%\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
 
REM Adding drivers
Dism /image:%winpe_root%\mount /Add-Driver /driver:%drivers_path% /recurse
 
REM Setting the timezone. List of available timezones can be found here: http://technet.microsoft.com/en-US/library/cc749073(v=ws.10).aspx
Dism /image:%winpe_root%\mount /Set-TimeZone:"Russian Standard Time"
 
REM Unmounting and updating the image
Dism /Unmount-Wim /MountDir:%winpe_root%\mount\ /Commit
 
REM Creationg ISO image from WinPE tree
Makewinpemedia /iso /f %winpe_root% %winpe_root%\winpe_amd64.iso
