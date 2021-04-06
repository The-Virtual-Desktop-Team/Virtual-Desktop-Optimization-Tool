<#####################################################################################################################################

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

    For more information about Microsoft Certified Partners, please visit the following Microsoft Web site:
    https://partner.microsoft.com/global/30000104 

######################################################################################################################################>

[Cmdletbinding(DefaultParameterSetName="Default")]
Param (
    # Parameter help description
    [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

    [ValidateSet('All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup')] 
    [String[]]
    $Optimizations = "All",


    [Switch]$Restart
)

#Requires -RunAsAdministrator

<#
- TITLE:          Microsoft Windows 10 Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
- AUTHORED DATE:  11/19/2019
- CONTRIBUTORS:   Travis Roberts (2020), Jason Parker (2020)
- LAST UPDATED:   8/14/2020
- PURPOSE:        To automatically apply settings referenced in the following white papers:
                  https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909
                  
- Important:      Every setting in this script and input files are possible recommendations only,
                  and NOT requirements in any way. Please evaluate every setting for applicability
                  to your specific environment. These scripts have been tested on plain Hyper-V
                  VMs. Please test thoroughly in your environment before implementation

- DEPENDENCIES    1. On the target machine, run PowerShell elevated (as administrator)
                  2. Within PowerShell, set exectuion policy to enable the running of scripts.
                     Ex. Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
                  3. LGPO.EXE (available at https://www.microsoft.com/en-us/download/details.aspx?id=55319)
                  4. LGPO database files available in the respective folders (ex. \1909, or \2004)
                  5. This PowerShell script
                  6. The text input files containing all the apps, services, traces, etc. that you...
                     may be interested in disabling. Please review these input files to customize...
                     to your environment/requirements

- REFERENCES:
https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://blogs.technet.microsoft.com/secguide/2016/01/21/lgpo-exe-local-group-policy-object-utility-v1-0/
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://msdn.microsoft.com/en-us/library/cc422938.aspx
#>

<# Categories of cleanup items:
This script is dependent on three elements:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

The UWP app input file contains the list of almost all the UWP application packages that can be removed with PowerShell interactively.  
The Store and a few others, such as Wallet, were left off intentionally.  Though it is possible to remove the Store app, 
it is nearly impossible to get it back.  Please review the lists below and comment out or remove references to packages that you do not want to remove.
#>
BEGIN {
    . ($PSScriptRoot + "\Functions\Write-WVDLog.ps1")
    Set-WVDLog -Path "$PSScriptRoot\WVDLog_$(Get-Date -Format MM-dd-yyyy_HHmmss).csv"
    $StartTime = Get-Date
    $CurrentLocation = Get-Location
    $WorkingLocation = (Join-Path $PSScriptRoot $WindowsVersion)
    Write-WVDLog -Message "Optimization Started at $StartTime from $WorkingLocation" -Level Info -OutputToScreen

    # Evaluate PSBoundParameters and if no valid parameters are passed, enable all tasks
    try { Push-Location (Join-Path $PSScriptRoot $WindowsVersion)-ErrorAction Stop }
    catch {
        Write-WVDLog -Message ("Invalid Path {0} - Exiting script!" -f $WorkingLocation) -Level Error -OutputToScreen
        Break
    }
}
PROCESS {

    #region Disable, then remove, Windows Media Player including payload
    If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All") {
        try {
            Write-WVDLog -Message "[VDI Optimize] Disable / Remove Windows Media Player"  -Level Info    -Tag "MediaPlayer" -OutputToScreen
            Write-WVDLog -Message "[VDI Optimize] Disabling Windows Media Player Feature" -Level Verbose -Tag "MediaPlayer"
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-WVDLog -Message "Removing $($_.PackageName)" -Level Info -Tag "MediaPlayer" #Should be verbose on this line
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch { Write-WVDLog -Message ("Disabling / Removing Windows Media Player - {0}" -f $_.Exception.Message) -Level Error -Tag "MediaPlayer" -OutputToScreen}
    }
    #endregion

    #region Begin Clean APPX Packages
    If ($Optimizations -contains "AppxPackages" -or $Optimizations -contains "All") {
        If (Test-Path .\ConfigurationFiles\AppxPackages.json) {
            Write-WVDLog -Message ("[VDI Optimize] Removing Appx Packages") -Level Info -Tag "AppxPackages" -OutputToScreen
            $AppxPackage = (Get-Content .\ConfigurationFiles\AppxPackages.json | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0) {
                Foreach ($Item in $AppxPackage) {
                    try {                
                        Write-WVDLog -Message ("Removing Provisioned Package {0}" -f $Item.AppxPackage) -Level Verbose -Tag "AppxPackages"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                                    
                        Write-WVDLog -Message ("Attempting to remove [All Users] {0} - {1}" -f $Item.AppxPackage,$Item.Description) -Level Verbose -Tag "AppxPackages"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-WVDLog -Message ("Attempting to remove {0} - {1}" -f $Item.AppxPackage,$Item.Description) -Level Verbose -Tag "AppxPackages"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue  | Out-Null
                    }
                    catch { Write-WVDLog -Message ("[ERROR] Failed to remove Appx Package ({0}) - {1}" -f $Item.AppxPackage,$_.Exception.Message) -Level Error -Tag "AppxPackages" -OutputToScreen }
                }
            }
            Else { Write-WVDLog -Message ("No AppxPackages found to disable") -Level Warning -Tag "AppxPackages" -OutputToScreen}
        }
        Else { Write-WVDLog -Message ("File not found: {0}\ConfigurationFiles\AppxPackages.json" -f $WorkingLocation) -Tag "AppxPackages" -Level Warning  -OutputToScreen }
    }
    #endregion

    #region Disable Scheduled Tasks

    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($Optimizations -contains 'ScheduledTasks' -or $Optimizations -contains 'All') {
        If (Test-Path .\ConfigurationFiles\ScheduledTasks.json) {
            Write-WVDLog -Message ("[VDI Optimize] Disable Scheduled Tasks") -Level Info -Tag "ScheduledTasks" -OutputToScreen
            $SchTasksList = (Get-Content .\ConfigurationFiles\ScheduledTasks.json | ConvertFrom-Json).Where({$_.VDIState -eq 'Disabled'})
            If ($SchTasksList.count -gt 0) {
                Foreach ($Item in $SchTasksList) {
                    $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled') {
                        Write-WVDLog -Message ("Attempting to disable Scheduled Task: {0}" -f $TaskObject.TaskName) -Level Verbose -Tag "ScheduledTasks"
                        try { Disable-ScheduledTask -InputObject $TaskObject | Out-Null }
                        catch { Write-WVDLog -Message ("Failed to disabled Scheduled Task: {0} - {1}" -f $TaskObject.TaskName,$_.Exception.Message) -Level Error -Tag "ScheduledTasks" -OutputToScreen}
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') { Write-WVDLog -Message ("{0} Scheduled Task already disbled" -f $TaskObject.TaskName) -Level Verbose -Tag "ScheduledTasks" }
                    Else { Write-WVDLog -Message ("Unable to find Scheduled Task: {0}" -f $Item.ScheduledTask) -Level Error -Tag "ScheduledTasks" -OutputToScreen }
                }
            }
            Else { Write-WVDLog -Message ("No Scheduled Tasks found to disable") -Level Warning -Tag "ScheduledTasks" -OutputToScreen}
        }
        Else { Write-WVDLog -Message ("File not found: {0}\ConfigurationFiles\ScheduledTasks.json" -f $WorkingLocation) -Level Warning -Tag "ScheduledTasks" -OutputToScreen }
    }
    #endregion

    #region Customize Default User Profile

    # Apply appearance customizations to default user registry hive, then close hive file
    If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All") {
        If (Test-Path .\ConfigurationFiles\DefaultUserSettings.json) {
            Write-WVDLog -Message ("[VDI Optimize] Set Default User Settings") -Tag 'UserSettings' -Level Info -OutputToScreen
            $UserSettings = (Get-Content .\ConfigurationFiles\DefaultUserSettings.json | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
            If ($UserSettings.Count -gt 0) {
                Write-WVDLog -Message "Processing Default User Settings (Registry Keys)" -Level Verbose -Tag "UserSettings"

                & REG LOAD HKLM\VDOT_TEMP C:\Users\Default\NTUSER.DAT | Out-Null

                Foreach ($Item in $UserSettings) {
                    If ($Item.PropertyType -eq "BINARY") { $Value = [byte[]]($Item.PropertyValue.Split(",")) }
                    Else { $Value = $Item.PropertyValue }

                    If (Test-Path -Path ("{0}" -f $Item.HivePath)) {
                        Write-WVDLog -Message ("Found {0}\{1}" -f $Item.HivePath, $Item.KeyName) -Level Verbose -Tag "UserSettings"
                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue) { Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Force }
                        Else { New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null }
                    }
                    Else {
                        Write-WVDLog -Message ("Registry Path not found: {0}" -f $Item.HivePath) -Level Warning -Tag "UserSettings" -OutputToScreen
                        Write-WVDLog -Message ("Creating new Registry Key") -Level Verbose -Tag "UserSettings","NewKey"
                        $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                        If (Test-Path -Path $newKey.PSPath) { New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null}
                        Else { Write-WVDLog -Message ("Failed to create new Registry key") -Level Error -OutputToScreen -Tag "UserSettings"} 
                    }
                }

                & REG UNLOAD HKLM\VDOT_TEMP | Out-Null
            }
            Else { Write-WVDLog -Message ("No Default User Settings to set") -Level Warning -Tag "UserSettings" -OutputToScreen }
        }
        Else { Write-WVDLog -Message ("File not found: {0}\ConfigurationFiles\DefaultUserSettings.json" -f $WorkingLocation) -Level Warning -Tag 'UserSettings' -OutputToScreen }
    }
    #endregion

    #region Disable Windows Traces
    If ($Optimizations -contains "AutoLoggers" -or $Optimizations -contains "All") {
        If (Test-Path .\ConfigurationFiles\Autologgers.Json) {
            Write-WVDLog -Message ("[VDI Optimize] Disable Autologgers") -Level Info -Tag "AutoLoggers" -OutputToScreen
            $DisableAutologgers = (Get-Content .\ConfigurationFiles\Autologgers.Json | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
            If ($DisableAutologgers.count -gt 0) {
                Write-WVDLog -Message ("Processing Autologger Configuration File") -Level Verbose -Tag "AutoLoggers"
                Foreach ($Item in $DisableAutologgers) {
                    Write-WVDLog -Message ("Updating Registry Key for: {0}" -f $Item.KeyName) -Level Verbose -Tag "AutoLoggers"
                    New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name "Start" -PropertyType "DWORD" -Value 0 -Force | Out-Null
                }
            }
            Else { Write-WVDLog -Message ("No Autologgers found to disable") -Level Verbose -Tag "AutoLoggers" -OutputToScreen}
        }
        Else { Write-WVDLog -Message ("File not found: {0}\ConfigurationFiles\Autologgers.json" -f $WorkingLocation) -Level Warning -Tag "AutoLoggers" -OutputToScreen}
    }
    #endregion

    #region Disable Services
    If ($Optimizations -contains "Services" -or $Optimizations -contains "All") {
        If (Test-Path .\ConfigurationFiles\Services.json) {
            Write-WVDLog -Message ("[VDI Optimize] Disable Services") -Level Info -Tag "Services" -OutputToScreen
            $ServicesToDisable = (Get-Content .\ConfigurationFiles\Services.json | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })

            If ($ServicesToDisable.count -gt 0) {
                Write-WVDLog -Message ("Processing Services Configuration File") -Level Verbose -Tag "Services"
                Foreach ($Item in $ServicesToDisable) {
                    Write-WVDLog -Message ("Attempting to Stop Service {0} - {1}" -f $Item.Name, $Item.Description) -Level Verbose -Tag "Services"
                    try { Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue }
                    catch { Write-WVDLog -Message ("Failed to disabled Service: {0} - {1}" -f $Item.Name, $_.Exception.Message)  -Level Error -Tag "Services" }
                    Write-WVDLog -Message ("Attempting to Disable Service {0} - {1}" -f $Item.Name, $Item.Description) -Level Verbose -Tag "Services"
                    Set-Service $Item.Name -StartupType Disabled 
                }
            }  
            Else { Write-WVDLog -Message ("No Services found to disable")  -Level Warning -Tag "Services" -OutputToScreen}
        }
        Else { Write-WVDLog -Message ("File not found: {0}\ConfigurationFiles\Services.json" -f $WorkingLocation)  -Level Warning -Tag "Services" -OutputToScreen }
    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All") {
        If (Test-Path .\ConfigurationFiles\LanManWorkstation.json) {
            Write-WVDLog -Message ("[VDI Optimize] Configure LanManWorkstation Settings") -Level Info -Tag "Network" -OutputToScreen
            $LanManSettings = Get-Content .\ConfigurationFiles\LanManWorkstation.json | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0) {
                Write-WVDLog -Message ("Processing LanManWorkstation Settings ({0} Hives)" -f $LanManSettings.Count) -Level Verbose -Tag "Network"
                Foreach ($Hive in $LanManSettings) {
                    If (Test-Path -Path $Hive.HivePath) {
                        Write-WVDLog -Message ("Found {0}" -f $Hive.HivePath) -Level Verbose -Tag "Network"
                        $Keys = $Hive.Keys.Where{$_.SetProperty -eq $true}
                        If ($Keys.Count -gt 0) {
                            Write-WVDLog -Message ("Create / Update LanManWorkstation Keys") -Level Verbose -Tag "Network"
                            Foreach ($Key in $Keys) {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue) { Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force }
                                Else { New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null }
                            }
                        }
                        Else { Write-WVDLog -Message ("No LanManWorkstation Keys to create / update") -Level Warning -Tag "Network" }  
                    }
                    Else { Write-VDLog -Messageg ("Registry Path not found: {0}" -f $Hive.HivePath)  -Level Warning -Tag "Network" }
                }
            }
            Else { Write-WVDLog -Message ("No LanManWorkstation Settings found")  -Level Warning -Tag "Network" }
        }
        Else { Write-WVDLog -Message ("File not found: {0}\ConfigurationFiles\LanManWorkstation.json" -f $WorkingLocation)  -Level Warning -Tag "Network" }

        # NIC Advanced Properties performance settings for network biased environments
        Write-WVDLog -Message "[VDI Optimize] Configuring Network Adapter Buffer Size" -Level Info -Tag "NIC Properties" -OutputToScreen
        Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB

        <#  NOTE:
            Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
            by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
            Set-NetAdapterAdvancedProperty command.
        #>
    }
    #endregion

    #region Local Group Policy Settings
    # - This code does not:
    #   * set a lock screen image.
    #   * change the "Root Certificates Update" policy.
    #   * change the "Enable Windows NTP Client" setting.
    #   * set the "Select when Quality Updates are received" policy
    If ($Optimizations -contains "LGPO" -or $Optimizations -contains "All") {
        If (Test-Path .\ConfigurationFiles\PolicyRegSettings.json)
        {
            Write-WVDLog -Message ("[VDI Optimize] Local Group Policy Items - JSON") -Level Info -Tag "LGPO" -OutputToScreen         
            Write-WVDLog -Message "Importing Local Group Policy Items using JSON" -Level Verbose -Tag "LGPO"
            ####################################################
            $PolicyRegSettings = Get-Content .\ConfigurationFiles\PolicyRegSettings.json | ConvertFrom-Json
            If ($PolicyRegSettings.Count -gt 0)
            {
                Write-WVDLog -Message ("Processing PolicyRegSettings Settings ({0} Hives)" -f $PolicyRegSettings.Count) -Level Verbose -Tag "LGPO"
                Foreach ($Key in $PolicyRegSettings)
                {
                    If ($Key.VDIState -eq 'Enabled')
                    {
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue) 
                        { 
                            $Write-Host "Found key, would be set to $($Key.RegItemPath) -Name $($Key.RegItemValueName) -Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force 
                        }
                        Else 
                        { 
                            #Write-Host "Create new - $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)"
                            If (Test-path $Key.RegItemPath)
                            {
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
                            Else
                            {
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
            
                        }
                    }
                }
            }
            Else { Write-WVDLog -Message ("No LGPO Settings found")  -Level Warning -Tag "LGPO" }
            ####################################################
        }
        Else 
        {
            If (Test-Path (Join-Path $PSScriptRoot "LGPO\LGPO.exe"))
            {
                Write-WVDLog -Message ("[VDI Optimize] Import Local Group Policy Items") -Level Info -Tag "LGPO" -OutputToScreen
                Write-WVDLog -Message "Importing Local Group Policy Items" -Level Verbose -Tag "LGPO"
                Start-Process (Join-Path $PSScriptRoot "LGPO\LGPO.exe") -ArgumentList "/g .\LGPO" -Wait
            }
            Else { Write-WVDLog -Message ("File not found: {0}\LGPO\LGPO.exe" -f $PSScriptRoot) -Level Warning -Tag "LGPO" -OutputToScreen }
        }
    }
    #endregion

    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
    If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All") {
        Write-WVDLog -Message "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use" -Level Info -Tag "Temp Files" -OutputToScreen
        Get-ChildItem -Path c:\ -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

        # Delete "RetailDemo" content (if it exits)
        Write-WVDLog -Message "Removing Retail Demo content (if it exists)" -Level Info -Tag "Retail Demo" -OutputToScreen
        Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

        # Delete not in-use anything in the C:\Windows\Temp folder
        Write-WVDLog -Message "Removing all files not in use in $env:windir\TEMP" -Level Info -Tag "Windows Temp" -OutputToScreen
        Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

        # Clear out Windows Error Reporting (WER) report archive folders
        Write-WVDLog -Message "Cleaning up WER report archive" -Level Info -Tag "WER Archive" -OutputToScreen
        Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force -ErrorAction SilentlyContinue

        # Delete not in-use anything in your %temp% folder
        Write-WVDLog -Message "Removing files not in use in $env:temp directory" -Level Info -Tag "Temp Dir" -OutputToScreen
        Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

        # Clear out ALL visible Recycle Bins
        Write-WVDLog -Message "Clearing out ALL Recycle Bins" -Level Info -Tag "Recycle Bin" -OutputToScreen
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue

        # Clear out BranchCache cache
        Write-WVDLog -Message "Clearing BranchCache cache" -Level Info -Tag "Branch Cache" -OutputToScreen
        Clear-BCCache -Force -ErrorAction SilentlyContinue
    }
    #endregion

    Set-Location $CurrentLocation
    $EndTime = Get-Date
    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
    Write-WVDLog -Message "`n`nTotal Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds" -Level Info -OutputToScreen
    Write-WVDLog -Message "`n`nThank you from the Virtual Desktop Optimization Team" -Level Info -OutputToScreen

    If ($Restart) { Restart-Computer -Force }
    Else { Write-WVDLog -Message "`nA reboot is required for all changed to take effect" -Level Warning -OutputToScreen }

    ########################  END OF SCRIPT  ########################
}
