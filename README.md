# Windows Virtual Desktop Optimization Tool (VDOT)

![Contributors](https://img.shields.io/github/contributors/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool)
![Forks](https://img.shields.io/github/forks/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool)
![Stars](https://img.shields.io/github/stars/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool)
![Commits](https://img.shields.io/github/last-commit/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool)
![Issues](https://img.shields.io/github/issues/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool)
![Languages](https://img.shields.io/github/languages/top/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool)

## Introduction

The Virtual Desktop Optimization Tool (VDOT) is a set of mostly text-based tools that apply settings to a Windows operating system, intended to improve performance.  The performance gains are in overall startup time, first logon time, subsequent logon time, and usability during a user-session.  

The VDOT tool came about from years of performance tuning of on-premises Virtual Desktop Infrastructure (VDI).  Some of those VDI implementations were not Internet-connected, or limited Internet-connected, rendering some features and/or functionality of Windows non-functional.  Instead of having non-functional components running, those items that could be disabled or removed in a supported manner, were done so.  The result was faster startup, login, and smoother user throughout user sessions.  

Later when Azure Virtual Desktop (AVD) came about, the VDOT tool was meticulously gone over, and made to support AVD, in a manner that would not degrade the user interface, reduce functionality, or in any way impair the AVD session hosts.  Input was received and implemented from the Microsoft Windows and Azure Virtual Desktop product groups.

As the VDOT tool exists now, it is compatible with a wide-range of systems.  It works on VDI, AVD, stand-alone Windows, Windows Server (with some caveats), and some optimizations are even applied to the Windows 365 offering.  

The optimization settings in this tool are the ***potential*** settings that reduce compute activity, and thus increase user density per host.  It is important to test the optimization settings in each respective environment, and adjust settings as needed. 

The files that determine what to disable, remove, or set as policy, are in text-based .JSON files, in the respective OS version folder (ex. '2009').  *The JSON parameter that this tool uses to determine whether or not to apply a setting is **'VDIState'***.  If the 'VDIState' parameter in the respective .JSON file is set to **Disabled**, the optimization setting will be applied.  If 'VDIState' is set to anything else, the setting will not be applied.  

 > [!NOTE]
 > This script takes a few minutes to complete. The total runtime will be presented at the end, in the status output messages.  A prompt to reboot will appear when the script has completely finished running. Wait for this prompt to confirm the script has successfully completed.  A reboot is necessary because several items cannot be stopped in the current session.

The "-verbose" parameter in PowerShell directs the script to provide descriptive output as the script is running.

## Major Features and Functionality

### Support for Windows 11

Windows 11 in some respects, reports the same as Windows 10, to various configuration management tools.  Currently (as of 7/29/22) has 'ReleaseID' value of '2009'.  Until the 'ReleaseID' number changes, all new optimizations are going to be included in the 'Configuration Files' folder underneath the '2009' folder.  Therefore, the 2009 folder configuration files apply to Windows 10, as well as Windows 11.

### Microsoft Edge (Chromium) optimizations

The current version of Edge in Windows 10, as of 07/29/2022, is Microsoft Edge (Chromium based).  There are a set of policy template files specific to the new Edge.  The VDOT tool now has the following optimization options for Microsoft Edge:  

* Set Edge as the default app for common Internet file types (using 'DefaultAssociations.xml' file and policy)
* Allow Edge to start processes at sign-in, whether or not the Edge app itself is started
* Disable "OOBE", or out-of-box experience. Though much improved, still heavy for virtual desktop environments
* Disable one-time redirection dialog and banner
* Show product assistance and recommendation notifications
* Allows Microsoft Edge processes to start at OS sign-in and restart in background after the last browser window is closed.
* Allows Microsoft Edge processes to start at OS sign-in and keep running after the last browser window is closed.

### AppxPackages

The AppxPackages.json manifest, regardless of version of Windows, now has the "VDIState" set to "Unchanged". The reason is that there is not a "recommended" list of apps to remove for all environments. In each case, if you want to remove a Universal Windows Platform (UWP) application, change the "VDIState" value from **Unchanged** to **"Disabled"**.

### "-Optimizations" parameter and new "-AdvancedOptimizations" parameters

The VDOT tool has several parameters passed to the main PowerShell file **"Windows_VDOT.ps1"** that provides installation granularity.  The two parameters used to control exactly what optimizations are applied are:

* `-Optimizations`
  * All
  * AppxPackages
  * Autologgers
  * DefaultUserSettings
  * DiskCleanup
  * LGPO (Local Group Policy Objects)
  * NetworkOptimizations
  * ScheduledTasks
  * Services
  * WindowsMediaPlayer
* `-AdvancedOptimizations`
  * All
  * Edge
  * RemoveLegacyIE (remove IE11 payload)
  * RemoveOneDrive

The result is that you could run as many, as few, or even one sub-parameter contained from the list above.  Here are two examples of running the VDOT tool for specific optimization categories.

```powershell
Windows_VDOT.ps1 -Optimizations AppxPackages -AcceptEula -Verbose
```

  

>
>PS C:\VDOT\Windows_VDOT.ps1 -AdvancedOptimizations Edge, AppxPackages -AcceptEula -Verbose
>

## References

 [PowerShell: Running Executables](https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx)  
 [Remove-Item](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6)  
 [LGPO](https://techcommunity.microsoft.com/t5/microsoft-security-baselines/lgpo-exe-local-group-policy-object-utility-v1-0/ba-p/701045)  
 [Set-Service](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-7.2)  
 [Remove-Item](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-7.2&viewFallbackFrom=powershell-6)  
 [2.2.1.7.2 GlobalFolderOptionsVista element](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gppref/a6ca3a17-1971-4b22-bf3b-e1a5d5c50fca)  
 [Windows 10 Release Information](https://docs.microsoft.com/en-us/windows/release-health/release-information)  
 [Windows 11 Release Information](https://docs.microsoft.com/en-us/windows/release-health/windows11-release-information)

## Dependencies

 1. LGPO.EXE stored in the 'LGPO' folder.  

 > [!NOTE]
 > We may move away from the using LGPO.exe to apply policy settings at some point.  The preferred method to apply policy settings are to use a domain-based Group Policy Object (GPO).

 1. Previously saved local group policy settings, available on the GitHub site where this script is located.
 1. The PowerShell script file 'Windows_VDOT.ps1'.
 1. All VDOT files and folders.

**NOTE:** This script should take just a few minutes to complete. The total runtime will be presented at the end, in the status output messages.  
A prompt to reboot will appear when the script has completely finished running. Wait for this prompt to confirm the script has successfully completed.  
Also, the "-verbose" parameter in PowerShell directs the script to provide descriptive output as the script is running.

## Full Instructions (for all current Windows versions)

On the device that will be receiving the optimizations:

1. Create a folder (ex. "C:\Optimize").
1. Download or copy the entire VDOT set of files and folders.
1. Unblock the downloaded .zip file, either manually using File -> Properties, or using PowerShell:
[Unblock-File](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-5.1)
1. Extract the VDOT download to the folder previously created (ex. "C:\Optimize).
1. Start PowerShell elevated.
1. In PowerShell, change directory to the scripts folder (ex. C:\Optimize).
1. Run the following PowerShell commands:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

.\Windows_VDOT.ps1 -Verbose 
#This will run all optimizations, except Edge

.\Windows_VDOT.ps1 -Optimizations All 
#This is the same as the command above and will run all optimizations, except Edge

.\Windows_VDOT.ps1 -Optimizations Edge, All  
#This will run all optimizations including Edge

.\Windows_VDOT.ps1 -Optimizations AppxPackages -AcceptEULA
#This will run AppxPackages only and auto accept the EULA
```

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

>Starting with the 2004 version of these scripts, use of the Disk Cleanup Wizard (Cleanmgr.exe) has been deprecated.  DCW is near end-of-life, but also sometimes "hangs" during running of the scripts.  Instead some basic disk cleanup has been incorporated into the 'Windows_VDOT.ps1' script.  There are logs, traces, and event log files deleted.  If you wish to maintain log files, you can edit the .PS1 script and remove those entries.

### Start Menu "broken links" (10/13/2020)

>There have been several reports of problems with the Start Menu after applying the optimization settings, and possibly other actions.  Recently we were able to reproduce a problem with the Start Menu by performing a Feature Update from 1909 to 2004, where the 1909 session host had the optimization settings in place.  The problem could arise as the result of having "optimized" user profiles, either locally or in a profile solution such as FSLogix.  Then the Feature Update process does some work with Appx packages during that process, leading to orphaned items in the user's Start Menu.
>
>1. Create a script to repair the Start Menu, by copying the following to a text file, saving that as a .CMD or .BAT file, then providing that to the affected user either interactively or a logon script (normally does not require elevation).
>
>```bat
>   start /wait taskkill /IM StartMenuExperienceHost.exe /F  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\AC"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\AppData"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalCache"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\RoamingState"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\Settings"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\SystemAppData"  
>   rd /S /Q "%UserProfile%\Appdata\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\TempState"  
>   Start C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe
>
>```
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
