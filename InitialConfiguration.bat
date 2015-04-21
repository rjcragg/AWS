::This file does the initial configuration of the AWS instance.
::This should be filled with things that you only want to do once, like name the computer.
::OnstartConfiguration is a copy of this, but with most commands DISABLED
::Download and run this from the (elevated?) command line by using the following command:

::bitsadmin.exe /transfer "Start" https://raw.githubusercontent.com/rjcragg/AWS/master/InitialConfiguration.bat InitialConfiguration.bat & InitialConfiguration.bat

::Last Edited By: Ryan Cragg 2015-03-31

::::GENERAL SETTINGS FOR LATER IN BATCH FILE::::

set OnstartConfigurationURL=https://raw.githubusercontent.com/rjcragg/AWS/master/OnstartConfiguration.bat
set SAFE_LICENSE_FILE=@107.20.199.168
set EC2PASSWORD=FME2015learnings
set PORTFORWARDING=81;82;443;8080;8081
::set FMEDESKTOPURL=https://s3.amazonaws.com/downloads.safe.com/fme/2015/fme_eval.msi
set FMEDESKTOPURL=https://s3.amazonaws.com/FME-Installers/fme-desktop-b15475-win-x86.msi
set FMEDESKTOP64URL=https://s3.amazonaws.com/downloads.safe.com/fme/2015/win64/fme_eval.msi
set FMESERVERURL=https://s3.amazonaws.com/downloads.safe.com/fme/2015/win64/fme_eval.msi
set FMEDATAURL=https://s3.amazonaws.com/FMEData/FME-Sample-Dataset-Full.zip

set DISABLED=::
set LOG=c:\temp\Configure.log
set TEMP=c:\temp

echo "Starting Downloading, Installing, and Configuring" > %LOG%

::::CONFIGURE WINDOWS SETTINGS::::

::Set some SYSTEM environment variables
setx /m SAFE_LICENSE_FILE %SAFE_LICENSE_FILE% >> %LOG%
setx /m FME_USE_LM_ENVIRONMENT YES >> %LOG%
setx /m FME_TEMP D:\TEMP >> %LOG%

:: Log that variables are set correctly
echo "Variables are set to:" >> %LOG%
set >> %LOG%

::Make the D:\temp used by FME_TEMP
md %FME_TEMP% >> %LOG%

:: The purpose of this section is to configure proxy ports for Remote Desktop
:: It must be run with elevated permissions (right-click and run as administrator)
:: The batch file assumes the computer name will not change.
:: Be sure to also open the listed ports in the EC2 security group
:: The ports to be set are in PORTFORWARDING:
:: First, we reset the existing proxy ports.
netsh interface portproxy reset

:: Now we set the proxy ports and add them to the firewall
for %%f IN (%PORTFORWARDING%) DO (
	netsh interface portproxy add v4tov4 listenport=%%f connectport=3389 connectaddress=%COMPUTERNAME%
	netsh firewall add portopening TCP %%f "Remote Desktop Port Proxy"
	)
::We should make sure port 80 is open too, for FME Server. This might be unnecessary
netsh firewall add portopening TCP 80 "FME Server"

::Set Computer Name. This will require a reboot. Reboot is at the end of this batch file.
wmic computersystem where name="%COMPUTERNAME%" call rename name="FMETraining"  >> %LOG%
::Set Password for Administrator. I hate password complexity requiremens, but they can't be changed from the command line.
net user Administrator %EC2PASSWORD%
::Make sure password does not expire.
WMIC USERACCOUNT WHERE "Name='administrator'" SET PasswordExpires=FALSE  >> %LOG%

::::SCHEDULED TASKS::::

:: It's a very good idea to limit how long an instance will run for. Leaving them for weeks at a time is bad
::Create the Scheduled tasks. Shut down machine if not logged onto within 24 (cancelled on logon by another task) or 56 hours.
::Remember to FORCE schedule task creation--otherwise you'll be prompted. 
::Create the Shutdowns
schtasks /Create /F /RU SYSTEM /TN FirstAutoShutdown /SC ONSTART /DELAY 1440:00 /TR "C:\Windows\System32\shutdown.exe /s" >> %LOG%
schtasks /Create /F /RU SYSTEM /TN SecondAutoShutdown /SC ONSTART /DELAY 3360:00 /TR "C:\Windows\System32\shutdown.exe /s" >> %LOG%
::On Logon, Disable the FirstAutoShutdown
schtasks /Create /F /RU SYSTEM /TN DisableAutoShutdown /SC ONLOGON /TR "schtasks /Change /Disable /TN "FirstAutoShutdown"" >> %LOG%
::Then, re-enable FirstAutoShutdown
schtasks /Create /F /RU SYSTEM /TN EnableAutoShutdown /SC ONLOGON /TR "schtasks /Change /Enable /TN "FirstAutoShutdown"" >> %LOG%

::Create scheduled task that downloads and runs the other batch file. User aria2--bitsadmin doesn't play well with scheduled tasks
::Get the other batch file and run it.
schtasks /Create /F /RU SYSTEM /TN OnstartConfiguration /SC ONSTART /TR "pushd %TEMP% && aria2c %OnstartConfigurationURL% --allow-overwrite=true && OnstartConfiguration.bat" >> %LOG%

::The VNC Scheduled Task is created when installing VNC, in the INSTALL SOFTWARE section

::::INSTALL SOFTWARE::::

::Install Chocolatey
::https://chocolatey.org/
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) >$null 2>&1" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

::Bitsadmin does not work in a scheduled task. Install aria2. It is amazingly fast.
choco install aria2 -y >> %LOG%

::I'm sure GIT will be useful at some point
choco install git -y >> %LOG%

::WinDirStat is useful for finding what is taking up drive space.
choco install windirstat -y >> %LOG%

::UltraVNC is useful when helping students troubleshoot. Why 2 passwords? The first is for full control; the second is for view-only.
::Create a scheduled task to start VNCServer. If it is a service, you have to log in, and that kicks out the student
choco install ultravnc -y >> %LOG%
"C:\Program Files\uvnc bvba\UltraVNC\setpasswd.exe" safevnc safevnc2 >> %LOG%
schtasks /Create /F /TN UltraVNCServer /SC ONLOGON /TR "C:\Program Files\uvnc bvba\UltraVNC\winvnc.exe" >> %LOG%

::Google Chrome and Firefox are useful web browsers
choco install google-chrome-x64 -y  >> %LOG%
choco install firefox -y  >> %LOG%

::The following should be used in the onsite script:
::Adobe Reader is used to read manuals
choco install adobereader -y  >> %LOG%

::Notepad++ is great for text editing
choco install notepadplusplus -y  >> %LOG%

::Google Earth is useful
choco install googleearth -y  >> %LOG%

::Install Python and Eclipse
choco install python -y  >> %LOG%
choco install python2 -y  >> %LOG%
choco install eclipse -y  >> %LOG%

::Download the latest FMEData. This is done so that Ryan doesn't have to create a new AMI whenever there is just a small change in FMEData
::FMEData should be kept as https://s3.amazonaws.com/FMEData/FME-Sample-Dataset-Full.zip
::Get the basic FMEData and unzip any updates into c:\
pushd d:\ && aria2c %FMEDATAURL% --allow-overwrite=true >> %LOG%
pushd d:\ && unzip -u FME-Sample-Dataset-Full.zip -d c:\ >> %LOG%

::The lastest FME Desktop Installers are available from http://www.safe.com/fme/fme-desktop/trial-download/download.php
pushd d:\ && aria2c %FMEDESKTOPURL% --allow-overwrite=true >> %LOG%
pushd d:\ && aria2c %FMEDESKTOP64URL% --allow-overwrite=true >> %LOG%

::The lastest FME Server Installers are available from http://www.safe.com/fme/fme-server/trial-download/download.php
pushd d:\ && aria2c %FMESERVERURL%  --allow-overwrite=true >> %LOG%

::Might be nice to have the lastest ArcGIS installer downloaded and ready to go.
:: Silent Install?

::Silent Install of PostGreSQL/PostGIS?
::Silent Install of Oracle?

::Copy FMEDATA onto the SSD drive for better performance, or backup.
robocopy c:\fmedata d:\fmedata /E >> c:\temp\FMEServerRestart.log
robocopy c:\fmedata2014 d:\fmedata2014 /E >> c:\temp\FMEServerRestart.log
robocopy c:\fmedata2015 d:\fmedata2015 /E >> c:\temp\FMEServerRestart.log
echo "This is a temporary drive. It is deleted upon shutdown. Use with caution" > "d:\This is a temporary drive.txt"

echo "Finished the Restart Process" >> c:\temp\FMEServerRestart.log

::::INITIAL CONFIGURATION ONLY::::
::Restart the computer

