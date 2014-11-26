@echo off
 
REM Where to put PXE-ready WinPE tree
Set pxe_root=G:\opk\pxe
 
REM Location of WinPE tree prepared by winpe_build.cmd
Set winpe_root=G:\opk\winpe_build
 
REM ADK installation path
Set adk_path=%programfiles(x86)%\Windows Kits\8.1\Assessment and Deployment Kit
 
REM User scripts location to include in new WinPE image. Scripts tree should include the modified startnet.cmd in which you can add your stuff
Set scripts_path=G:\opk\winpe\scripts
 
REM Calling a script which sets some useful variables
call "%adk_path%\Deployment Tools\DandISetEnv.bat"
 
REM Cleaning WinPE-PXE tree
if exist %pxe_root% rd /q /s %pxe_root%
 
REM Creating new WinPE-PXE tree
mkdir %pxe_root%
mkdir %pxe_root%\Boot
 
REM Copying WinPE wim images file, mountiong it and getting some files needed for PXE boot
copy %winpe_root%\media\sources\boot.wim %pxe_root%\Boot\winpe.wim
Dism /Mount-Wim /WimFile:%pxe_root%\Boot\winpe.wim /index:1 /MountDir:%winpe_root%\mount
copy %winpe_root%\mount\Windows\Boot\PXE\*.* %pxe_root%\Boot\
copy %winpe_root%\media\boot\boot.sdi %pxe_root%\Boot\boot.sdi
copy %winpe_root%\mount\Windows\System32\bcdedit.exe %pxe_root%\Boot\bcdedit.exe
 
REM Putting user scripts inside
copy /Y %scripts_path%\*.* %winpe_root%\mount\Windows\System32\
 
REM Unmounting the image
Dism /Unmount-Wim /MountDir:%winpe_root%\mount\ /Commit
 
REM Creating bootloader configuration
%pxe_root%\Boot\bcdedit.exe -createstore %pxe_root%\Boot\BCD
set BCDEDIT=%pxe_root%\Boot\bcdedit.exe -store %pxe_root%\Boot\BCD
%BCDEDIT% -create {ramdiskoptions} /d "Ramdisk options"
%BCDEDIT% -set {ramdiskoptions} ramdisksdidevice boot
%BCDEDIT% -set {ramdiskoptions} ramdisksdipath \Boot\boot.sdi
%BCDEDIT% -set {ramdiskoptions} ramdisktftpblocksize 8192
 
REM Adding new booloader entry and getting its GUID
for /f "tokens=3 delims={} " %%a in ('%BCDEDIT% -create -d "Windows PE" -application osloader') do set guid=%%a
 
REM Setting some options for the boot entry
%BCDEDIT% -set {%guid%} systemroot \Windows
%BCDEDIT% -set {%guid%} detecthal Yes
%BCDEDIT% -set {%guid%} winpe Yes
%BCDEDIT% -set {%guid%} osdevice ramdisk=[boot]\Boot\winpe.wim,{ramdiskoptions}
%BCDEDIT% -set {%guid%} device ramdisk=[boot]\Boot\winpe.wim,{ramdiskoptions}
%BCDEDIT% -create {bootmgr} /d "Windows BootManager"
%BCDEDIT% -set {bootmgr} timeout 30 
%BCDEDIT% -displayorder {%guid%}
 
REM Deleting now unneeded bcdedit
del /Q %pxe_root%\Boot\bcdedit.exe
