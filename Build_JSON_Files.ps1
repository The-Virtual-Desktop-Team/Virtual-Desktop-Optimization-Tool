#Build JSON Configuration Files

$WinVersion = '2004'

if (-not(Test-Path .\$WinVersion))
{
    New-Item .\$WinVersion -ItemType Directory | Out-Null
    New-Item .\$WinVersion\ConfigurationFiles -ItemType Directory | Out-Null
}

#region AppxPackages Json
$AppxPackages = @"
Microsoft.BingWeather,"https://www.microsoft.com/en-us/p/msn-weather/9wzdncrfj3q2"
Microsoft.GetHelp,"https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/customize-get-help-app"
Microsoft.Getstarted,"https://www.microsoft.com/en-us/p/microsoft-tips/9wzdncrdtbjj"
Microsoft.Messaging,"https://www.microsoft.com/en-us/p/microsoft-messaging/9wzdncrfjbq6"
Microsoft.MicrosoftOfficeHub,"https://www.microsoft.com/en-us/p/office/9wzdncrd29v9"
Microsoft.MicrosoftSolitaireCollection,"https://www.microsoft.com/en-us/p/microsoft-solitaire-collection/9wzdncrfhwd2"
Microsoft.MicrosoftStickyNotes,"https://www.microsoft.com/en-us/p/microsoft-sticky-notes/9nblggh4qghw"
Microsoft.MixedReality.Portal,"https://www.microsoft.com/en-us/p/mixed-reality-portal/9ng1h8b3zc7m"
Microsoft.Office.OneNote,"https://www.microsoft.com/en-us/p/onenote/9wzdncrfhvjl"
Microsoft.People,"https://www.microsoft.com/en-us/p/microsoft-people/9nblggh10pg8"
Microsoft.Print3D,"https://www.microsoft.com/en-us/p/print-3d/9pbpch085s3s"
Microsoft.SkypeApp,"https://www.microsoft.com/en-us/p/skype/9wzdncrfj364"
Microsoft.Wallet,"https://www.microsoft.com/en-us/payments"
Microsoft.Windows.Photos,"https://www.microsoft.com/en-us/p/microsoft-photos/9wzdncrfjbh4"
Microsoft.Microsoft3DViewer,"https://www.microsoft.com/en-us/p/3d-viewer/9nblggh42ths"
Microsoft.WindowsAlarms,"https://www.microsoft.com/en-us/p/windows-alarms-clock/9wzdncrfj3pr"
Microsoft.WindowsCalculator,"https://www.microsoft.com/en-us/p/windows-calculator/9wzdncrfhvn5"
Microsoft.WindowsCamera,"https://www.microsoft.com/en-us/p/windows-camera/9wzdncrfjbbg"
microsoft.windowscommunicationsapps,"https://www.microsoft.com/en-us/p/mail-and-calendar/9wzdncrfhvqm"
Microsoft.WindowsFeedbackHub,"https://www.microsoft.com/en-us/p/feedback-hub/9nblggh4r32n"
Microsoft.WindowsMaps,"https://www.microsoft.com/en-us/p/windows-maps/9wzdncrdtbvb"
Microsoft.WindowsSoundRecorder,"https://www.microsoft.com/en-us/p/windows-voice-recorder/9wzdncrfhwkn"
Microsoft.Xbox.TCUI,"https://docs.microsoft.com/en-us/gaming/xbox-live/features/general/tcui/live-tcui-overview"
Microsoft.XboxApp,"https://www.microsoft.com/store/apps/9wzdncrfjbd8"
Microsoft.XboxGameOverlay,"https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p"
Microsoft.XboxGamingOverlay,"https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p"
Microsoft.XboxIdentityProvider,"https://www.microsoft.com/en-us/p/xbox-identity-provider/9wzdncrd1hkw"
Microsoft.XboxSpeechToTextOverlay,"https://support.xbox.com/help/account-profile/accessibility/use-game-chat-transcription"
Microsoft.YourPhone,"https://www.microsoft.com/en-us/p/Your-phone/9nmpj99vjbwv"
Microsoft.ZuneMusic, "https://www.microsoft.com/en-us/p/groove-music/9wzdncrfj3pt"
Microsoft.ZuneVideo,"https://www.microsoft.com/en-us/p/movies-tv/9wzdncrfj3p2"
Microsoft.ScreenSketch,"https://www.microsoft.com/en-us/p/snip-sketch/9mz95kl8mr0l"
"@
$AppxPackages = ($AppxPackages -split "`n").trim()
$AppxPackages = $AppxPackages | ConvertFrom-Csv -Delimiter ',' -Header "PackageName", "HelpURL"
$AppxPackagesJson = $AppxPackages | ForEach-Object { [PSCustomObject]@{'AppxPackage' = $_.PackageName; 'VDIState' = 'Disabled'; 'Description' = $_.PackageName; 'URL' = $_.HelpURL } } | ConvertTo-Json
$AppxPackagesJson | Out-File .\$WinVersion\ConfigurationFiles\AppxPackages.json
#endregion AppxPackages Json

#region Autologgers
$AutoLoggers = @"
AppModel
CloudExperienceHostOOBE
DiagLog
ReadyBoot
WDIContextLog
WiFiDriverIHVSession
WiFiSession
WinPhoneCritical
"@
$AutoLoggers = ($AutoLoggers -split "`n").Trim() | ForEach-Object {
    $LogHash = @{ }
    $BaseKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\'
    Switch ($_)
    {
        AppModel
        {
            $Description = "Used by Packaging, deployment, and query of Windows Store apps. Especially on non-persistent VDI, we tightly control what apps are installed and available, and normally don’t let users change the configuration.  Persistent VDI would be a different story.  If you allow reconfiguration of UWP apps, remove this item." 
            $URL = "https://docs.microsoft.com/en-us/windows/win32/api/appmodel/"
            $Disable = $True
        }
        CloudExperienceHostOOBE
        {
            $Description = '“Cloud Experience Host” is an application used while joining the workplace environment or Azure AD for rendering the experience when collecting your company-provided credentials. Once you enroll your device to your workplace environment or Azure AD, your organization will be able to manage your PC and collect information about you (including your location). It might add or remove apps or content, change settings, disable features, prevent you from removing your company account, or reset your PC.”. The OOBE part means “out-of-box experience”.  This trace records events around domain or Azure AD join.  Normally provisioned VDI VMs are already joined, so this logging is unnecessary.' 
            $URL = "https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-how-it-works-technology#cloud-experience-host"
            $Disable = $True
        }
        DiagLog
        {
            $Description = 'A log generated by the Diagnostic Policy Service, which is documented here.  “The Diagnostic Policy Service enables problem detection, troubleshooting and resolution for Windows components. If this service is stopped, diagnostics will no longer function”.  Problem detection in VDI rarely takes place with production machines, but usually happens on machines in a private pool dedicated to troubleshooting.  Windows diagnostics are usually not helpful with VDI.' 
            $URL = "https://docs.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server"
            $Disable = $True
        }
        ReadyBoot
        {
            $Description = '“ReadyBoot is boot acceleration technology that maintains an in-RAM cache used to service disk reads faster than a slower storage medium such as a disk drive”.  VDI does not use “normal” computer disk devices, but usually segments of a shared storage medium.  ReadyBoot and other optimizations designed to assist normal disk devices do not have equivalent effects on shared storage devices.  And further, for non-persistent VDI, 99.999% of computer state is discarded when the user logs off.  This includes any optimizations performed by the OS during runtime.  Therefore, why allow Windows “normal” optimizations when all that computer and I/O work will be discarded at logoff for NP VDI?  For persistent, the choice is yours.  Another consideration is again, pooled VDI.  The users will normally not log into the same VM twice.  Therefore, any RAM caching of predicted I/O will have unknown impact because the underlying disk extent being utilized for that logon session will be different from session to session.' 
            $URL = "https://docs.microsoft.com/en-us/previous-versions/windows/desktop/xperf/readyboot-analysis"
            $Disable = $True
        }
        WDIContextLog
        {
            $Description = 'This is a startup trace that runs all the time, with these loggers: "Microsoft-Windows-Kernel-PnP":0x48000:0x4+"Microsoft-Windows-Kernel-WDI":0x100000000:0xff+"Microsoft-Windows-Wininit":0x20000:0x4+"Microsoft-Windows-Kernel-BootDiagnostics":0xffffffffffffffff:0x4+"Microsoft-Windows-Kernel-Power":0x1:0x4+"Microsoft-Windows-Winlogon":0x20000:0x4+"Microsoft-Windows-Shell-Core":0x6000000:0x4 On my clean state VM, this trace is running and using a very small amount of resources.  Current buffers are 4, buffer size is 16.  Those numbers reflect the amount of physical RAM reserved for this trace.  Because my VM does not use WLAN, AKA “wireless”, this trace is doing nothing for my VM now, and will not as long as I do not use wireless.  Therefore the recommendation to disable this trace and free these resources.' 
            $URL = "https://docs.microsoft.com/en-us/windows-hardware/drivers/network/wifi-universal-driver-model"
            $Disable = $True
        }
        WiFiDriverIHVSession
        {
            $Description = 'This log is a container for “user-initiated feedback” for wireless networking (Wi-Fi).  If the VMs were to emulate wireless networking, you might just leave this one alone.  Also, this trace is enabled by default, but not run until triggered, presumably from a user-initiated feedback for a wireless issue.  The Windows diagnostics would run, gather some information from the current system including an event trace, and then send that information to Microsoft.' 
            $URL = "https://docs.microsoft.com/en-us/windows-hardware/drivers/network/user-initiated-feedback-normal-mode"
            $Disable = $True
        }
        WiFiSession
        {
            $Description = 'Not documented, but not hard to understand.  This is another diagnostic log for the Windows Diagnostics.  If your VMs are not using Wi-Fi, this log is not needed.  You could though leave this alone as it would almost never be started unless a user started a troubleshooter, and troubleshooters are usually disabled in VDI environments.' 
            $URL = "N/A"
            $Disable = $True
        }
        WinPhoneCritical
        {
            $Description = 'Not documented, but not hard to determine its use: diagnostics for phone. If not using or allowing phones to be attached to your VMs, no need to leave a trace enabled that will never be used.  Or just leave this one alone.' 
            $URL = "N/A"
            $Disable = $True
        }
    }
    $LogHash += @{
        KeyName     = "$BaseKey" + "$_" + "\"
        Description = $Description
        URL         = $URL
        Disabled    = $Disable
    }
    [PSCustomObject]$LogHash
} | ConvertTo-Json
$AutoLoggers | Out-File .\$WinVersion\ConfigurationFiles\Autologgers.Json

#endregion Autologgers

#region Scheduled Tasks
$ScheduledTasks = @"
BgTaskRegistrationMaintenanceTask
Consolidator
Diagnostics
FamilySafetyMonitor
FamilySafetyRefreshTask
MapsToastTask
*Compatibility*
Microsoft-Windows-DiskDiagnosticDataCollector
*MNO*
NotificationTask
PerformRemediation
ProactiveScan
ProcessMemoryDiagnosticEvents
Proxy
QueueReporting
RecommendedTroubleshootingScanner
ReconcileLanguageResources
RegIdleBackup
RunFullMemoryDiagnostic
Scheduled
ScheduledDefrag
SilentCleanup
SpeechModelDownloadTask
Sqm-Tasks
SR
StartupAppTask
SyspartRepair
UpdateLibrary
WindowsActionDialog
WinSAT
XblGameSaveTask
"@
$ScheduledTasks = ($ScheduledTasks -split "`n").Trim()
$ScheduledTasksJson = $ScheduledTasks | ForEach-Object { [PSCustomObject] @{'ScheduledTask' = $_; 'VDIState' = 'Disabled'; 'Description' = (Get-ScheduledTask $_ -ErrorAction SilentlyContinue).Description } } | ConvertTo-Json
$ScheduledTasksJson | Out-File .\$WinVersion\ConfigurationFiles\ScheduledTasks.json
#endregion Scheduled Tasks

#region Services
$Services = @"
autotimesvc
BcastDVRUserService
CDPSvc
CDPUserSvc
CscService
defragsvc
DiagSvc
DiagTrack
DPS
DsmSvc
DusmSvc
icssvc
InstallService
lfsvc
MapsBroker
MessagingService
OneSyncSvc
PimIndexMaintenanceSvc
Power
SEMgrSvc
SmsRouter
SysMain
TabletInputService
UsoSvc
VSS
WdiSystemHost
WerSvc
WSearch
XblAuthManager
XblGameSave
XboxGipSvc
XboxNetApiSvc
"@

$Services = ($Services -split "`n").Trim()
$ServicesJson = $Services | Foreach-Object { [PSCustomObject]@{Name = $_; 'VDIState' = 'Disabled' ; 'Description' = (Get-Service $_ -ErrorAction SilentlyContinue).DisplayName } } | ConvertTo-Json
$ServicesJson | Out-File .\$WinVersion\ConfigurationFiles\Services.json
#endregion Services

#region Build Default User Settings
$UserSettingsKeys = @"
Load HKLM\Temp C:\Users\Default\NTUSER.DAT
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShellState /t REG_BINARY /d 240000003C2800000000000000000000 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCompColor /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f
add "HKLM\Temp\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\DWM" /v AlwaysHiberNateThumbnails /t REG_DWORD /d 0 /f
add "HKLM\Temp\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f
add "HKLM\Temp\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f
add "HKLM\Temp\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9032078010000000 /f
add "HKLM\Temp\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
add "HKLM\Temp\Control Panel\International\User Profile" /v HttpAcceptLanguageOptOut /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.Photos_8wekyb3d8bbwe" /v Disabled /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.Windows.Photos_8wekyb3d8bbwe" /v DisabledByUser /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.SkypeApp_kzf8qxf38zg5c" /v Disabled /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.SkypeApp_kzf8qxf38zg5c" /v DisabledByUser /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe" /v Disabled /t REG_DWORD /d 1 /f
add "HKLM\Temp\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe" /v DisabledByUser /t REG_DWORD /d 1 /f
Unload HKLM\Temp
"@
$UserSettingsKeys | Out-File .\$WinVersion\ConfigurationFiles\DefaultUserSettings.txt
#endregion

#region Disk Clean Registry Settings
$DiskCleanKeys = @"
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Diagnostic Data Viewer database files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files\
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files\
"@
$DiskCleanKeys | Out-File .\$WinVersion\ConfigurationFiles\DiskCleanRegSettings.txt
#endregion


