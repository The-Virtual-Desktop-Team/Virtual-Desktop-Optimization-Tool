[Cmdletbinding()]
Param
(
    [Parameter()]
    [ValidateSet('2004')]
    $WindowsVersion = 2004

)

#Requires -RunAsAdministrator
<#
- TITLE:          Microsoft Windows 10 VDI/WVD Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
- AUTHORED DATE:  11/19/2019
- LAST UPDATED:   5/8/2020
- PURPOSE:        To automatically apply setting referenced in white paper:
                  "Optimizing Windows 10, for Virtual Desktop Infrastructure (VDI) and Windows Virtual Desktop (WVD)" 
                  URL: TBD

- Important:      Every setting in this script and input files are possible recommendations only,
                  and NOT requirements in any way. Please evaluate every setting for applicability
                  to your specific environment. These scripts have been tested on plain Hyper-V
                  VMs. Please test thoroughly in your environment before implementation

- DEPENDENCIES    1. LGPO.EXE (available at https://www.microsoft.com/en-us/download/details.aspx?id=55319)
                  2. LGPO database files available on the GitHub site where this script is located
                  3. This PowerShell script
                  4. The text input files containing all the apps, services, traces, etc. that you...
                     may be interested in disabling. Please review these input files to customize...
                     to your environment/requirements

- REFERENCES:
https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://blogs.technet.microsoft.com/secguide/2016/01/21/lgpo-exe-local-group-policy-object-utility-v1-0/
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://msdn.microsoft.com/en-us/library/cc422938.aspx

<# Categories of cleanup items:
- Appx package cleanup                 - Complete
- Scheduled tasks                      - Complete
- Automatic Windows traces             - Complete
- Local group policy                   - Complete
- System services                      - Complete
- Disk cleanup                         - Complete
- Default User Profile Customization   - Complete

This script is dependent on three elements:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

The UWP app input file contains the list of almost all the UWP application packages that can be removed with PowerShell interactively.  
The Store and a few others, such as Wallet, were left off intentionally.  Though it is possible to remove the Store app, 
it is nearly impossible to get it back.  Please review the lists below and comment out or remove references to packages that you do not want to remove.
#>

$StartTime = Get-Date
$CurrentLocation = Get-Location

Try 
{
    Set-Location (Join-Path $PSScriptRoot $WindowsVersion)-ErrorAction Stop
}
Catch
{
    Write-Warning "Invalid Path $(Join-Path $PSScriptRoot $WindowsVersion) - Exiting script!"
    Break
}

#region Disable, then remove, Windows Media Player including payload
    
Try
{
    Write-Verbose "Disabling Windows Media Player Feature"
    Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
    Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
        Write-Verbose "Removeing $($_.PackageName)"
        Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue  -NoRestart | Out-Null
    }
}
Catch { }

#endregion

#region Begin Clean APPX Packages


If (Test-Path .\ConfigurationFiles\AppxPackages.json)
{
    $AppxPackage = Get-Content .\ConfigurationFiles\AppxPackages.json | ConvertFrom-Json 
    $AppxPackage = $AppxPackage | Where-Object { $_.VDIState -eq 'Disabled' }
}

If ($AppxPackage.Count -gt 0)
{
    Foreach ($Item in $AppxPackage)
    {
        $Package = "*$($Item.AppxPackage)*"
        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
        Get-AppxPackage -Name $Package | Remove-AppxPackage -ErrorAction SilentlyContinue  | Out-Null
        
        #Write-Verbose "`t`tAttempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
        #Get-AppxPackage -AllUsers -Name $Package | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
        
        Write-Verbose "`t`tRemoving Provisioned Package $($item.AppxPackage)"
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $Package } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    }
}
#endregion

#region Disable Scheduled Tasks

# This section is for disabling scheduled tasks.  If you find a task that should not be disabled
# change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
If (Test-Path .\ConfigurationFiles\ScheduledTasks.json)
{
    $SchTasksList = Get-Content .\ConfigurationFiles\ScheduledTasks.json | ConvertFrom-Json
    $SchTasksList = $SchTasksList | Where-Object { $_.VDIState -eq 'Disabled' }
}
If ($SchTasksList.count -gt 0)
{
    #$EnabledScheduledTasks = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" }
    Foreach ($Item in $SchTasksList)
    {
        #$Task = (($Item -split ":")[0]).Trim()
        Write-Verbose "Disabling Scheduled Task $($Item.ScheduledTask)"
        Disable-ScheduledTask -TaskName $Item.ScheduledTask -ErrorAction SilentlyContinue
        #$EnabledScheduledTasks | Where-Object { $_.TaskName -like "*$Task*" } #| Disable-ScheduledTask
    }
}
#endregion

#region Customize Default User Profile
# Apply appearance customizations to default user registry hive, then close hive file

If (Test-Path .\ConfigurationFiles\DefaultUserSettings.txt)
{
    $DefaultUserSettings = Get-Content .\ConfigurationFiles\DefaultUserSettings.txt
}
If ($DefaultUserSettings.count -gt 0)
{
    Write-Verbose "Processing Default User Settings registry keys"
    Foreach ($Item in $DefaultUserSettings)
    {
        Start-Process C:\Windows\System32\Reg.exe -ArgumentList "$Item" -Wait 
    }
}
#endregion

#region Disable Windows Traces
If (Test-Path .\ConfigurationFiles\Autologgers.Json)
{
    $DisableAutologgers = Get-Content .\ConfigurationFiles\Autologgers.Json | ConvertFrom-Json
}

If ($DisableAutologgers.count -gt 0)
{
    $DisableAutologgers = $DisableAutologgers | Where-Object { $_.Disabled -eq 'True' }
    Foreach ($Item in $DisableAutologgers)
    {
        Write-Verbose "Adding $($Item.KeyName)"
        New-ItemProperty -Path "$($Item.KeyName)" -Name "Start" -PropertyType "DWORD" -Value "0" -Force | Out-Null
    }
}
#endregion

#region Local Group Policy Settings
# - This code does not:
#   * set a lock screen image.
#   * change the "Root Certificates Update" policy.
#   * change the "Enable Windows NTP Client" setting.
#   * set the "Select when Quality Updates are received" policy

if (Test-Path (Join-Path $PSScriptRoot "LGPO\LGPO.exe")) 
{
    Write-Verbose "Importing Local Group Policy Items"
    Start-Process (Join-Path $PSScriptRoot "LGPO\LGPO.exe") -ArgumentList "/g .\LGPO" -Wait
}
#endregion

#region Disable Services
If (Test-Path .\ConfigurationFiles\Services.json)
 
{
    $ServicesToDisable = Get-Content .\ConfigurationFiles\Services.json | ConvertFrom-Json
}

If ($ServicesToDisable.count -gt 0)
{
    $ServicesToDisable = $ServicesToDisable | Where-Object { $_.VDIState -eq 'Disabled' }
    Foreach ($Item in $ServicesToDisable)
    {
        Write-Verbose "Stopping $($Item.Name) - $($Item.Description)"
        Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue
        Write-Verbose "`t`tDisabling $($Item.Name)"
        Set-Service $Item.Name -StartupType Disabled 
    }
}
#endregion

#region Network Optimization
# LanManWorkstation optimizations
Write-Verbose "Configuring LanManWorlstation Optimizations"
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "DisableBandwidthThrottling" -PropertyType "DWORD" -Value "1" -Force | Out-Null
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "FileInfoCacheEntriesMax" -PropertyType "DWORD" -Value "1024" -Force | Out-Null
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "DirectoryCacheEntriesMax" -PropertyType "DWORD" -Value "1024" -Force | Out-Null
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "FileNotFoundCacheEntriesMax" -PropertyType "DWORD" -Value "1024" -Force | Out-Null
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "DormantFileLimit" -PropertyType "DWORD" -Value "256" -Force | Out-Null

# NIC Advanced Properties performance settings for network biased environments
Write-Verbose "Configuring Network Adapter Buffer Size"
Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB

<# Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
Set-NetAdapterAdvancedProperty command.
#>
#endregion

#region
# ADDITIONAL DISK CLEANUP
# Delete not in-use files in locations C:\Windows\Temp and %temp%
# Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
# 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup

Write-Verbose "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use"
Get-ChildItem -Path c:\ -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

# Delete "RetailDemo" content (if it exits)
Write-Verbose "Removing Retail Demo content (if it exists)"
Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

# Delete not in-use anything in the C:\Windows\Temp folder
Write-Verbose "Removing all files not in use in $env:windir\TEMP"
Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

# Clear out Windows Error Reporting (WER) report archive folders
Write-Verbose "Cleaning up WER report archive"
Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force -ErrorAction SilentlyContinue

# Delete not in-use anything in your %temp% folder
Write-Verbose "Removing files not in use in $env:TEMP directory"
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

# Clear out ALL visible Recycle Bins
Write-Verbose "Clearing out ALL Recycle Bins"
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# Clear out BranchCache cache
Write-Verbose "Clearing BranchCache cache"
Clear-BCCache -Force -ErrorAction SilentlyContinue

#endregion

Set-Location $CurrentLocation
$EndTime = Get-Date
$ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
Write-Host "Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds" -ForegroundColor Cyan

Add-Type -AssemblyName PresentationFramework
$Answer = [System.Windows.MessageBox]::Show("Reboot to make changes effective?", "Restart Computer", "YesNo", "Question")
Switch ($Answer)
{
    "Yes" { Write-Warning "Restarting Computer in 15 Seconds"; Start-sleep -seconds 15; Restart-Computer -Force }
    "No" { Write-Warning "A reboot is required for all changed to take effect" }
    Default { Write-Warning "A reboot is required for all changed to take effect" }
}

########################  END OF SCRIPT  ########################
