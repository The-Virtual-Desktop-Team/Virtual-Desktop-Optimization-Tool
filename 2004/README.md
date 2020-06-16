# Introduction 
Automatically apply settings referenced in white paper:

TBD 

These scripts are provided as a means to customize each virtual desktop environment individually, in an easy to use manner.  The text files can be easily edited to prevent removing apps that are desired to be retained.

**NOTE:** As of 4/14/20, these scripts have been tested on **Windows Virtual Desktop (WVD)**.  A number of changes specific to the WVD full desktop experience have been incorporated into the latest version of these scripts.

# Getting Started
 ## DEPENDENCIES
 1. LGPO.EXE (available at https://www.microsoft.com/en-us/download/details.aspx?id=55319) stored in the 'LGPO' folder.
 2. Previously saved local group policy settings, available on the GitHub site where this script is located
 3. The PowerShell script file 'Win10_VirtualDesktop_Optimize.ps1'
 4. The two folders '2004' and 'LGPO'.

NOTE: This script now takes just a few minutes to complete on the reference (gold) device.  The total runtime will be presented at the end, in the status output messages. A prompt to reboot will appear when the script has comoletely finished running. Wait for this prompt to confirm the script has successfully completed.

# Full Instructions
1. Download to the reference device, in a folder (ex. C:\Optimize), the following files:
'Win10_VirtualDesktop_Optimize.ps1'
2. Download to the reference device, in a folder (ex. C:\Optimize), the following folders:
'2004'
'LGPO'
3. Start PowerShell elevated
4. In PowerShell, change directory to the scripts folder (ex. C:\Optimize)
5. Run the following PowerShell commands:
"Set-ExecutionPolicy -ExecutionPolicy RemoteSigned"
".\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose
6. When complete, you should see a prompt to restart.  You do not have to restart right away.

- REFERENCES:
https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://blogs.technet.microsoft.com/secguide/2016/01/21/lgpo-exe-local-group-policy-object-utility-v1-0/
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://msdn.microsoft.com/en-us/library/cc422938.aspx

- Appx package cleanup                 - Complete
- Scheduled tasks                      - Complete
- Automatic Windows traces             - Complete
- OneDrive cleanup                     - Complete
- Local group policy                   - Complete
- System services                      - Complete
- Disk cleanup                         - Complete
- Default User Profile Customization   - Complete

This script is dependant on three elements:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

CHANGE HISTORY (Windows 10, 1909)
- Updated user profile settings to include setting background to blue, so not too much black
- Added a number of optimizations to shell settings for performance
- Updated services input file for service names instead of registry locations
- Disabling services using the Service Control Manager tool 'SC.EXE', not setting registry entries manually
- Changed the method of disabling services, with native PowerShell
- Fixed some small issues with input scripts that caused error messages
- Delete unused .EVTX and .ETL files (very small disk space savings)
- Added a reboot option prompt at the conclusion of the PowerShell script
- Added several LGPO settings to turn off privacy settings on new user logon
- Added settings in default user profile settings to disable suggested content in 'Settings'

# IMPORTANT ISSUE (01/17/2020)
IMPORTANT: There is a setting in the current LGPO files that should not be set by default. As of 1/17/10...
a fix has been checked in to the "Pending" branch.  Once we confirm that resolves the issue we will merge...
into the "Master" branch.  The issue is that Windows will not check certificate information, and thus...
program installations could fail.  The temporary workaround is to open GPEDIT.MSC on the reference image...
The set the policy to "not configured".  Here is the location of the policy setting:

**Local Computer Policy \ Computer Configuration \ Administrative Templates \ System \ Internet Communication Management \ Internet Communication settings**

```
Turn off Automatic Root Certificates Update
```
# IMPORTANT ISSUE (04/14/2020)
IMPORTANT: A local GPO setting previously included, could prevent the activation of Office 365 in Windows Virtual Desktop.
The issue is with Windows Network Connectivity Status Indicator tests.  Disabling these tests also changes the network icon...
on the taskbar from Connected to "status unknown".  This setting was changed back to "not configured as of 4/14/2020.

**Local Computer Policy \ Computer Configuration \ Administrative Templates \ System \ Internet Communication Management \ Internet Communication settings**

```
Turn off Windows Network Connectivity Status Indicator active tests
```
# MINOR ISSUE (04/29/2020)
Background app resource usage issue.  If you choose to keep several of the UWP apps, such as Photos, Skype, and Phone, you may notice that these apps will start up and run in the background, even though a user has not started the app.  This behavior can be controlled through the 'Settings' app, under 'Background apps'.  If you toggle these apps' setting to "off", now the app will not automatically start and run in the background when users logon.  The background resource usage is low, but can add up in multi-session environments.

The issue is that there is not currently a policy that provides a global toggle for these apps.  There are a few ways this can be addressed in the short-term.

1. Set a Group Policy Preference to automatically set the following registry values

`"HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.Photos_8wekyb3d8bbwe" /v Disabled /t REG_DWORD /d 1`
`"HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.Photos_8wekyb3d8bbwe" /v DisabledByUser /t REG_DWORD /d 1`
`"HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.SkypeApp_kzf8qxf38zg5c" /v Disabled /t REG_DWORD /d 1`
`"HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.SkypeApp_kzf8qxf38zg5c" /v DisabledByUser /t REG_DWORD /d 1`
`"HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe" /v Disabled /t REG_DWORD /d 1`
`"HKCU\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe" /v DisabledByUser /t REG_DWORD /d 1`
`"HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" /v Disabled /t REG_DWORD /d 1 /f`
`"HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" /v DisabledByUser /t REG_DWORD /d 1 /f`

Windows Photos appears to be addressed in 2004, as Photos does not start a process and run in the background, even though the app has not been started.  However, MSEdge.exe and SkypeApp.exe start and run automatically, though they have not been started.  The settings above are the equivalent of a user going in to the Settings app, going to the section 'Privacy', and then to the area 'Background apps'.  The setting is "Choose which apps can run in the background'.  To prevent the apps for a user whose profile already exists, move the sliders for Microsoft Edge and Skype to off.  If you log off and back on, SkypeApp.exe won't be running but you may see several processes started for MicrosoftEdge.exe or MicrosoftEdgeCP.exe.  This issue is insignficant on single session Windows, but could be an issue with multi-session Windows.

We set several local group policy settings to direct Edge to not preload tabs and content.  This does not affect Edge in any way, other than to not use resources until a user starts using Edge.

2. Uninstall the apps for "AllUsers", and optionally delete the payload.  The text input file 'AppxPackages.json' uninstalls these apps by default.

3. Edit the default user registry hive, which these scripts do.  The REG.EXE commands have been recently added to the file 'DefaultUserSettings.txt' in this repository.  That way if you want to keep one or all of these apps, and still control the behavior, you can do so with the scripting method.  The registry settings in the default user profile will only apply to any subsequent user profiles on that host/device, and have no effect on existing user profiles.  The registry editing method is currently used because there is no equivalent group policy setting as of 06/11/2020.

Please note that the registry settings listed here are subject to change.

# MINOR ISSUE (06/11/2020)
We had removed the "OneConnect" (Mobile Plans) entry from the input file 'AppxPackages.json', because that UWP app is no longer in Windows 10, starting with 2004.  However, the 2004 scripts are backward compatible with 1909, though have not been tested on any build prior to 1909.  Therefore the 'OneConnect' app entry was added back to the AppxPackages.json file.

# Note on Servicing (06/11/2020)
The 2004 scripts, as currently configured, pause all updates, including Quality Updates.  These settings do not affect Windows Defender, which gets it updates independently. If you want to allow your target machine(s) to contact Windows Update to download and apply updates, you can change the following group policy setting either locally, or in central group policy:

`Computer Configuration\Administrative Templates\Windows Components\Windows Update\Windows Update for Business\`

`Select when Quality Updates are received	Not configured`

You would also want to reset the 'Update Orchestrator' service to it's initial setting of "Automatic (Delayed Start)".

# Note on disk cleanup (06/11/2020)

Starting with the 2004 version of these scripts, we no longer invoke the Disk Cleanup Wizard (Cleanmgr.exe).  DCW is near end-of-life, but also sometimes "hangs" during running of the scripts.  Instead some basic disk cleanup has been incorporated into the 'Win10_VirtualDesktop_Optimize.ps1' script.  There are logs, traces, and event log files deleted.  If you wish to maintain log files, you can edit the .PS1 script and remove those entries.