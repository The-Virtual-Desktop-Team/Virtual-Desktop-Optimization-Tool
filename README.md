> **Please be sure to participate in our NEW survey!**
>
> [VDI Optimization User Experience Survey](https://forms.office.com/r/gN02UxDQmf)

# Introduction

The Virtual Desktop Optimization Tool was created to automatically apply setting referenced in white paper:
"Optimizing Windows 10, version 2004 for a Virtual Desktop Infrastructure (VDI) role"  

URL: <https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds-vdi-recommendations-2004>  

There is not, as of October 14, 2021, an updated version of this whitepaper. *Most optimizations are applicable in current builds*, as they were in the 2004 paper.  We are working to transition to documentation in this repository in the near future.

The optimization settings in this tool are the *potential* settings that reduce compute activity, and thus increase user density per host.  It is important to test the optimization settings in each respective environment, and adjust settings as needed.  As of configuration "2009", the entire set of files that contain the settings are .JSON files.  The parameter that this tool uses to determine whether or not to apply a setting is 'VDIState'.  If 'VDIState' is set to "Enabled", the setting will be applied.  If 'VDIState' is set to anything else, the setting will not be applied.

This version of the VDOT tool now supports Windows 11. There is a new configuration folder called '21H2' that is used if run on Windows 11.  There are very few changes from previous builds.  As always, please open a new issue if a problem is encountered running this tool.

## References

 <https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx>  
 <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6>  
 <https://blogs.technet.microsoft.com/secguide/2016/01/21/lgpo-exe-local-group-policy-object-utility-v1-0/>  
 <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6>  
 <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6>  
 <https://msdn.microsoft.com/en-us/library/cc422938.aspx>
 [Windows 10 Release Information](https://docs.microsoft.com/en-us/windows/release-health/release-information)
 [Windows 11 Release Information](https://docs.microsoft.com/en-us/windows/release-health/windows11-release-information)


**NOTE:** This script now takes just a few minutes to complete on the reference (gold) device. The total runtime will be presented at the end, in the status output messages.  
A prompt to reboot will appear when the script has completely finished running. Wait for this prompt to confirm the script has successfully completed.  
Also, the "-verbose" parameter in PowerShell directs the script to provide descriptive output as the script is running.

## Dependencies


 1. LGPO.EXE (available at <https://www.microsoft.com/en-us/download/details.aspx?id=55319>) stored in the 'LGPO' folder.
 **[NOTE]** We may move away from the using LGPO.exe to apply policy settings at some point.  The preferred methods to apply policy settings are:

    1. Use a domain-based Group Policy Object (GPO)

 1. Previously saved local group policy settings, available on the GitHub site where this script is located
 1. The PowerShell script file 'Win10_VirtualDesktop_Optimize.ps1'
 1. All VDOT files and folders.

**NOTE:** This script should take just a few minutes to complete. The total runtime will be presented at the end, in the status output messages.  
A prompt to reboot will appear when the script has completely finished running. Wait for this prompt to confirm the script has successfully completed.  
Also, the "-verbose" parameter in PowerShell directs the script to provide descriptive output as the script is running.

## Full Instructions (for all current Windows versions)

On the device that will be receiving the optimizations:

1. Create a folder (ex. "C:\Optimize")
1. Download or copy the entire VDOT set of files and folders
1. Unblock the downloaded .zip file, either manually using File -> Properties, or using PowerShell:
[Unblock-File](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-5.1)
1. Extract the VDOT download to the folder previously created (ex. "C:\Optimize)
1. Start PowerShell elevated
1. In PowerShell, change directory to the scripts folder (ex. C:\Optimize)
1. Run the following PowerShell commands:  

**"Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process"**  
**".\Win10_VirtualDesktop_Optimize.ps1 -Verbose**  

**[NOTE]** The VDOT tool determines OS version at run-time.  You can specify a different set of configuration files by using the "-WindowsVersion" parameter.  

When complete, you should see a prompt to restart.  You do not have to restart right away.

## Known Issues

> ### Windows cannot check certificate information (01/17/2020)
>
> **IMPORTANT:** Windows cannot check certificate information (CRL) with the following setting disabled
>
> **Local Computer Policy \ Computer Configuration \ Administrative Templates \ System \ Internet Communication Management \ Internet Communication settings**
>  
>
> The following setting has been removed from VDOT:
>
> **Turn off Automatic Root Certificates Update**

> ### Disabling 'CDPSvc' can cause SystemSettings.exe to crash (01/27/2020)
>
> A new issue was discovered recently regarding the 'CDPSvc'. If that service is disabled, and a new user logs on to the computer then opens 'System Settings' to view display settings, 'SystemSettings.exe' will crash and log an error to the event log with code "fatal app exit".  
>
>The setting for the 'CDPSvc' is now unchanged in 'Win10_1909_ServicesDisable.txt'.

> ### O365 cannot contact licensing server (04/20/2020)
>
> Previously the VDOT script had a local policy setting at this location set to disabled:
>
> **Local Computer Policy \ Computer Configuration \ Administrative Templates \ System \ Internet Communication Management \ Internet Communication settings**
>
> **Turn off Windows Network Connectivity Status Indicator active tests**
>
>With the active tests disabled, Office 365 is not able to contact it's licensing service, and therefore would not run any of the Office apps.  This setting has been changed back to **"Not configured"** in the included LGPO configuration.

> ### Some apps have no visible border in cloud environments (04/22/2020)
>
> In some virtual environments, such as Azure Windows Virtual Desktop, some of the application windows will have no border.  An example is Windows File Explorer.  You can replicate this by opening Wordpad and File Explorer, then move then around and note that you may not see a border where one app starts and the other ends.  
>
> One of the optimizations recently added changes the Visual Effects settings (found in System Properties) to reduce animations and effects, while still maintaining a good user experience.  
>
> * **"smoothing screen fonts"**  
> * **"show shadows under mouse pointer"**
> * **"Show shadows under windows"**  
>
> These user settings will enable a shadow effect around the windows like File Explorer, so that the border of the app is now visible.  
>
> These settings are written to the default user profile registry hive, so would apply only to users whose profile is created after these optimizations run, and on this device.

> ### Apps run, even though the app has not been run (04/29/2020)
>
> Several of the built-in UWP apps, such as Skype, Phone, and Photos, will start processes and run in the background, even though the user has not started the app(s).  On a single machine  this is near-zero impact, but on multi-session Windows, it can be a slightly larger impact issue.  There is a setting in the 'Settings' app, under 'Background apps' that allows you to control this behavior on a per-user basis.  However, there is currently no way to change this behavior as a global setting, other than to completely uninstall the app.
>
> If you would like to keep one or more of these apps in your image, and still control the background behavior, you can edit the default user registry hive and set the following settings:
>
>        "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.Photos_8wekyb3d8bbwe /v Disabled /t REG_DWORD /d 1 /f
>        "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.Photos_8wekyb3d8bbwe /v DisabledByUser /t REG_DWORD /d 1 /f
>        "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.SkypeApp_kzf8qxf38zg5c /v Disabled /t REG_DWORD /d 1 /f
>        "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.SkypeApp_kzf8qxf38zg5c /v DisabledByUser /t REG_DWORD /d 1 /f
>        "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe /v Disabled /t REG_DWORD /d 1 /f
>        "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe /v DisabledByUser /t REG_DWORD /d 1 /f
>
> You could also set these settings with Group Policy Preferences, and should take effect after a log off and log back on, or a Gpupdate refresh.

> ### Windows Update not working (05/11/2020)
>
> With the settings included in the local policy configuration, which is restored to the target during the processing of these scripts, if you attempt to run Windows Update manually, Windows may report an error.
>
> The reason these settings are in place in these scripts, is in case you deploy these to a target that is Internet connected, Windows Update may try to install updates while session hosts are actively being utilized. Virtual Desktop environments often control Windows Update to only be allowed during maintenance windows, or not run at all, but instead deploy new hosts.  
>
> The most recent resolution for this issue is to set the **'UsoSvc'** back to the default start value of **"manual"**.
> Alternatively, edit **'Services.json'** and change the **'VDIState'** of **'UsoSvc'** to **"unchanged"**.
> Also, local policy settings have been updated to leave Windows Update settings unchanged from default settings.

### Note on disk cleanup (06/11/2020)

>Starting with the 2004 version of these scripts, use of the Disk Cleanup Wizard (Cleanmgr.exe) has been deprecated.  DCW is near end-of-life, but also sometimes "hangs" during running of the scripts.  Instead some basic disk cleanup has been incorporated into the 'Win10_VirtualDesktop_Optimize.ps1' script.  There are logs, traces, and event log files deleted.  If you wish to maintain log files, you can edit the .PS1 script and remove those entries.

### Start Menu "broken links" (10/13/2020)

>There have been several reports of problems with the Start Menu after applying the optimization settings, and possibly other actions.  Recently we were able to reproduce a problem with the Start Menu by performing a Feature Update from 1909 to 2004, where the 1909 session host had the optimization settings in place.  The problem could arise as the result of having "optimized" user profiles, either locally or in a profile solution such as FSLogix.  Then the Feature Update process does some work with Appx packages during that process, leading to orphaned items in the user's Start Menu.
>
>1. Create a script to repair the Start Menu, by copying the following to a text file, saving that as a .CMD or .BAT file, then providing that to the affected user either interactively or a logon script (normally does not require elevation).
>
>`start /wait taskkill /IM StartMenuExperienceHost.exe /F`  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\AC"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\AppData"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalCache"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\RoamingState"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\Settings"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\SystemAppData"  
>        rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\TempState"  
>        Start C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe
>
>1. Re-run VDOT with the appropriate '-WindowsVersion' parameter (e.g. 2004).  
>
>**[NOTE]** Not only will this repair the Start Menu in some cases, there are a few settings that are specific to the specific build that may not have been previously applied.

>### OneDrive local policy setting prevents automatic OneDrive sign-in (01/27/2021)
>
>There is a default setting for OneDrive set in this tool, with these details:  
>
>`Computer Configuration\Administrative Templates\Windows Components\OneDrive`  
>`"Prevent OneDrive from generating network traffic until the user signs in to OneDrive"`  
>
> Default state: Not Configured  
> Optimization tool state: Enabled  
>
>There was another issue related to this setting also reported recently.  Some of the Office apps would "hang" for several or more seconds, until OneDrive sync was complete.  This could be related to this setting.  Therefore, revert this setting to the default state of `"not configured"`.
>
>This particular policy setting is actually a preference.  You can confirm this by noting the "down arrow" overlay on the setting icon.  A good way to revert the setting would be to change the setting back to default with group policy.  If you had to do this for each user, the process could be more involved.

>### Hang at logoff from "Task Window" (April 16, 2021)
>
>We have had reports of a task window hanging at logoff, when the host is configured with multiple languages. Initial testing has shown that this is likely the result of one or more user-mode services being disabled by the script.  The services in question are:
>
>-CDPSvc  
>-CDPUserSvc
>
>The 'VDIState' setting of these two "per-user" services has been changed from 'Disabled' to 'Unchanged'.

>### Snip & Sketch not working after optimizations (May 25, 2021)
>
> After running the VDOT optimizations, the 'Snip & Sketch' UWP app can be started, but clicking to perform a new capture does not work (nothing happens).  Also, clicking Snip & Sketch, an error is recorded in the Application event log, similar to the following:  
>
> `Faulting application name: ScreenClippingHost.exe, version: 2001.22012.0.2020, time stamp: 0x5ff501a5`  
> `Faulting module name: ScreenClipping.dll, version: 2001.22012.0.2020, time stamp: 0x5ff4fde8`  
> `Exception code: 0x80000003`  
> `Fault offset: 0x000000000001b92d`  
This has been resolved in recent builds.
## Other Notes

> ### Note on reinstalling Appx Packages
>
>If you find that you have removed a UWP package and now need it back, the easiest way is to either open up the Microsoft Store app and search for the application, or click or copy and paste to a web browser, the URL for that app included in the 'AppxPackages.json' configuration file.
>
>To prevent a particular UWP app from being removed in the first place, edit the 'AppxPackages.json' configuration file, search for the application, and change the 'VDIState' of that application entry from 'Disabled' to anything else, such as 'Unchanged'.
>

## Disclaimer

This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant 
You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form 
of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in 
which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code 
is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.

Microsoft provides programming examples for illustration only, without warranty either expressed or
implied, including, but not limited to, the implied warranties of merchantability and/or fitness 
for a particular purpose.  

This sample assumes that you are familiar with the programming language being demonstrated and the 
tools used to create and debug procedures. Microsoft support professionals can help explain the 
functionality of a particular procedure, but they will not modify these examples to provide added 
functionality or construct procedures to meet your specific needs. if you have limited programming 
experience, you may want to contact a Microsoft Certified Partner or the Microsoft fee-based consulting 
line at (800) 936-5200. 
