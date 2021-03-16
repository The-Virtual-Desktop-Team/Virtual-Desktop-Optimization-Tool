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
    [Parameter(ParameterSetName="Default",Position=0,Mandatory=$false)]
    [Parameter(ParameterSetName="Tasks",Position=0,Mandatory=$false)]
    [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

    [Parameter(ParameterSetName="Tasks",Position=1,Mandatory=$false)]
    [Switch]$WindowsMediaPlayer,

    [Parameter(ParameterSetName="Tasks",Position=2,Mandatory=$false)]
    [Switch]$AppxPackages,

    [Parameter(ParameterSetName="Tasks",Position=3,Mandatory=$false)]
    [Switch]$ScheduledTasks,

    [Parameter(ParameterSetName="Tasks",Position=4,Mandatory=$false)]
    [Switch]$DefaultUserSettings,

    [Parameter(ParameterSetName="Tasks",Position=5,Mandatory=$false)]
    [Switch]$Autologgers,

    [Parameter(ParameterSetName="Tasks",Position=6,Mandatory=$false)]
    [Switch]$Services,

    [Parameter(ParameterSetName="Tasks",Position=7,Mandatory=$false)]
    [Switch]$NetworkOptimizations,

    [Parameter(ParameterSetName="Tasks",Position=8,Mandatory=$false)]
    [Switch]$LGPO,

    [Parameter(ParameterSetName="Tasks",Position=9,Mandatory=$false)]
    [Switch]$DiskCleanup,

    [Parameter(ParameterSetName="Default",Position=2,Mandatory=$false)]
    [Parameter(ParameterSetName="Tasks",Position=10,Mandatory=$false)]
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
    $StartTime = Get-Date
    $CurrentLocation = Get-Location
    $WorkingLocation = (Join-Path $PSScriptRoot $WindowsVersion)

    # Evaluate PSBoundParameters and if no valid parameters are passed, enable all tasks
    $validTaskParameters = 0
    Foreach ($Key in $PSCmdlet.MyInvocation.BoundParameters.Keys) {
        Switch ($Key) {
            "WindowsMediaPlayer" { $validTaskParameters++ }
            "AppxPackages" { $validTaskParameters++ }
            "DefaultUserSettings" { $validTaskParameters++ }
            "Autologgers" { $validTaskParameters++ }
            "ScheduledTasks" { $validTaskParameters++ }
            "Services" { $validTaskParameters++ }
            "DiskCleanup" { $validTaskParameters++ }
            "NetworkOptimizations" { $validTaskParameters++ }
            "LGPO" { $validTaskParameters++ }
            Default { $null }
        }
    }

    If ($validTaskParameters -eq 0) {
        $WindowsMediaPlayer = $true
        $AppxPackages = $true
        $ScheduledTasks = $true
        $DefaultUserSettings = $true
        $Autologgers = $true
        $Services = $true
        $DiskCleanup = $true
        $NetworkOptimizations = $true
        $LGPO = $true
    }

    try { Push-Location (Join-Path $PSScriptRoot $WindowsVersion)-ErrorAction Stop }
    catch {
        Write-Warning ("Invalid Path {0} - Exiting script!" -f $WorkingLocation)
        Break
    }
}
PROCESS {

    #region Disable, then remove, Windows Media Player including payload
    If ($WindowsMediaPlayer) {
        try {
            Write-Output ("[VDI Optimize] Disable / Remove Windows Media Player")
            Write-Verbose "Disabling Windows Media Player Feature"
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-Verbose "Removing $($_.PackageName)"
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch { Write-Output ("[ERROR] Disabling / Removing Windows Media Player - {0}" -f $_.Exception.Message)}
    }
    #endregion

    #region Begin Clean APPX Packages
    If ($AppxPackages) {
        If (Test-Path .\ConfigurationFiles\AppxPackages.json) {
            Write-Output ("[VDI Optimize] Removing Appx Packages")
            $AppxPackage = (Get-Content .\ConfigurationFiles\AppxPackages.json | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0) {
                Foreach ($Item in $AppxPackage) {
                    try {                
                        Write-Verbose ("Removing Provisioned Package {0}" -f $Item.AppxPackage)
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                                    
                        Write-Verbose ("Attempting to remove [All Users] {0} - {1}" -f $Item.AppxPackage,$Item.Description)
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-Verbose ("Attempting to remove {0} - {1}" -f $Item.AppxPackage,$Item.Description)
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue  | Out-Null
                    }
                    catch { Write-Output ("[ERROR] Failed to remove Appx Package ({0}) - {1}" -f $Item.AppxPackage,$_.Exception.Message) }
                }
            }
            Else { Write-Warning ("No AppxPackages found to disable") }
        }
        Else { Write-Warning ("File not found: {0}\ConfigurationFiles\AppxPackages.json" -f $WorkingLocation) }
    }
    #endregion

    #region Disable Scheduled Tasks

    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($ScheduledTasks) {
        If (Test-Path .\ConfigurationFiles\ScheduledTasks.json) {
            Write-Output ("[VDI Optimize] Disable Scheduled Tasks")
            $SchTasksList = (Get-Content .\ConfigurationFiles\ScheduledTasks.json | ConvertFrom-Json).Where({$_.VDIState -eq 'Disabled'})
            If ($SchTasksList.count -gt 0) {
                Foreach ($Item in $SchTasksList) {
                    $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled') {
                        Write-Verbose ("Attempting to disable Scheduled Task: {0}" -f $TaskObject.TaskName)
                        try { Disable-ScheduledTask -InputObject $TaskObject | Out-Null }
                        catch { Write-Output ("[ERROR] Failed to disabled Scheduled Task: {0} - {1}" -f $TaskObject.TaskName,$_.Exception.Message) }
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') { Write-Verbose ("{0} Scheduled Task already disbled" -f $TaskObject.TaskName) }
                    Else { Write-Output ("[ERROR] Unable to find Scheduled Task: {0}" -f $Item.ScheduledTask) }
                }
            }
            Else { Write-Warning ("No Scheduled Tasks found to disable") }
        }
        Else { Write-Warning ("File not found: {0}\ConfigurationFiles\ScheduledTasks.json" -f $WorkingLocation) }
    }
    #endregion

    #region Customize Default User Profile

    # Apply appearance customizations to default user registry hive, then close hive file
    If ($DefaultUserSettings) {
        If (Test-Path .\ConfigurationFiles\DefaultUserSettings.json) {
            Write-Output ("[VDI Optimize] Set Default User Settings")
            $UserSettings = (Get-Content .\ConfigurationFiles\DefaultUserSettings.json | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
            If ($UserSettings.Count -gt 0) {
                Write-Verbose "Processing Default User Settings (Registry Keys)"

                & REG LOAD HKLM\VDOT_TEMP C:\Users\Default\NTUSER.DAT | Out-Null

                Foreach ($Item in $UserSettings) {
                    If ($Item.PropertyType -eq "BINARY") { $Value = [byte[]]($Item.PropertyValue.Split(",")) }
                    Else { $Value = $Item.PropertyValue }

                    If (Test-Path -Path ("{0}" -f $Item.HivePath)) {
                        Write-Verbose ("Found {0}\{1}" -f $Item.HivePath,$Item.KeyName)
                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue) { Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Force }
                        Else { New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null }
                    }
                    Else {
                        Write-Warning ("Registry Path not found: {0}" -f $Item.HivePath)
                        Write-Verbose ("Creating new Registry Key")
                        $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                        If (Test-Path -Path $newKey.PSPath) { New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null}
                        Else { Write-Output ("[ERROR] Failed to create new Registry key") }
                    }
                }

                & REG UNLOAD HKLM\DEFAULT | Out-Null
            }
            Else { Write-Warning ("No Default User Settings to set") }
        }
        Else { Write-Warning ("File not found: {0}\ConfigurationFiles\DefaultUserSettings.json" -f $WorkingLocation) }
    }
    #endregion

    #region Disable Windows Traces
    If ($Autologgers) {
        If (Test-Path .\ConfigurationFiles\Autologgers.Json) {
            Write-Output ("[VDI Optimize] Disable Autologgers")
            $DisableAutologgers = (Get-Content .\ConfigurationFiles\Autologgers.Json | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
            If ($DisableAutologgers.count -gt 0) {
                Write-Verbose ("Processing Autologger Configuration File")
                Foreach ($Item in $DisableAutologgers) {
                    Write-Verbose ("Updating Registry Key for: {0}" -f $Item.KeyName)
                    New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name "Start" -PropertyType "DWORD" -Value 0 -Force | Out-Null
                }
            }
            Else { Write-Warning ("No Autologgers found to disable") }
        }
        Else { Write-Warning ("File not found: {0}\ConfigurationFiles\Autologgers.json" -f $WorkingLocation) }
    }
    #endregion

    #region Disable Services
    If ($Services) {
        If (Test-Path .\ConfigurationFiles\Services.json) {
            Write-Output ("[VDI Optimize] Disable Services")
            $ServicesToDisable = (Get-Content .\ConfigurationFiles\Services.json | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })

            If ($ServicesToDisable.count -gt 0) {
                Write-Verbose ("Processing Services Configuration File")
                Foreach ($Item in $ServicesToDisable) {
                    Write-Verbose ("Attempting to Stop Service {0} - {1}" -f $Item.Name,$Item.Description)
                    try { Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue }
                    catch { Write-Output ("[ERROR] Failed to disabled Service: {0} - {1}" -f $Item.Name,$_.Exception.Message) }
                    Write-Verbose ("Attempting to Disable Service {0} - {1}" -f $Item.Name,$Item.Description)
                    Set-Service $Item.Name -StartupType Disabled 
                }
            }  
            Else { Write-Warning ("No Services found to disable") }
        }
        Else { Write-Warning ("File not found: {0}\ConfigurationFiles\Services.json" -f $WorkingLocation) }
    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($NetworkOptimizations) {
        If (Test-Path .\ConfigurationFiles\LanManWorkstation.json) {
            Write-Output ("[VDI Optimize] Configure LanManWorkstation Settings")
            $LanManSettings = Get-Content .\ConfigurationFiles\LanManWorkstation.json | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0) {
                Write-Verbose ("Processing LanManWorkstation Settings ({0} Hives)" -f $LanManSettings.Count)
                Foreach ($Hive in $LanManSettings) {
                    If (Test-Path -Path $Hive.HivePath) {
                        Write-Verbose ("Found {0}" -f $Hive.HivePath)
                        $Keys = $Hive.Keys.Where{$_.SetProperty -eq $true}
                        If ($Keys.Count -gt 0) {
                            Write-Verbose ("Create / Update LanManWorkstation Keys")
                            Foreach ($Key in $Keys) {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue) { Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force }
                                Else { New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null }
                            }
                        }
                        Else { Write-Warning ("No LanManWorkstation Keys to create / update") }
                    }
                    Else { Write-Warning ("Registry Path not found: {0}" -f $Hive.HivePath) }
                }
            }
            Else { Write-Warning ("No LanManWorkstation Settings found") }
        }
        Else { Write-Warning ("File not found: {0}\ConfigurationFiles\LanManWorkstation.json" -f $WorkingLocation) }

        # NIC Advanced Properties performance settings for network biased environments
        Write-Verbose "Configuring Network Adapter Buffer Size"
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
    If ($LGPO) {
        If (Test-Path (Join-Path $PSScriptRoot "LGPO\LGPO.exe")) {
            Write-Output ("[VDI Optimize] Import Local Group Policy Items")
            Write-Verbose "Importing Local Group Policy Items"
            Start-Process (Join-Path $PSScriptRoot "LGPO\LGPO.exe") -ArgumentList "/g .\LGPO" -Wait
        }
        Else { Write-Warning ("File not found: {0}\LGPO\LGPO.exe" -f $PSScriptRoot) }
    }
    #endregion

    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
    If ($DiskCleanup) {
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
    }
    #endregion

    Set-Location $CurrentLocation
    $EndTime = Get-Date
    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
    Write-Host "Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds" -ForegroundColor Cyan

    If ($Restart) { Restart-Computer -Force }
    Else { Write-Warning "A reboot is required for all changed to take effect" }


    ########################  END OF SCRIPT  ########################
}
