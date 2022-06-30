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
    [ArgumentCompleter( { Get-ChildItem $PSScriptRoot -Directory | Where-Object { $_.Name -ne 'LGPO' } | Select-Object -ExpandProperty Name } )]
    [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

    [ValidateSet('All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','Edge','DiskCleanup')] 
    [String[]]
    $Optimizations = "All",


    [Switch]$Restart,
    [Switch]$AcceptEULA
)

#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

<#
- TITLE:          Microsoft Windows 10 Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
- AUTHORED DATE:  11/19/2019
- CONTRIBUTORS:   Travis Roberts (2020), Jason Parker (2020)
- LAST UPDATED:   5/4/2022
- PURPOSE:        To automatically apply settings referenced in the following white papers:
                  https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909
                  
- Important:      Every setting in this script and input files are possible optimizations only,
                  and NOT recommendations or requirements. Please evaluate every setting for applicability
                  to your specific environment. These scripts have been tested on Hyper-V VMs, as well as Azure VMs...
                  including Windows 11.
                  Please test thoroughly in your environment before implementation

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
This script is dependent on the following:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

The UWP app input file contains the list of almost all the UWP application packages that can be removed with PowerShell interactively.  
The Store and a few others, such as Wallet, were left off intentionally.  Though it is possible to remove the Store app, 
it is nearly impossible to get it back.  Please review the configuration files and change the 'VDIState' to anything but 'disabled' to keep the item.
#>
BEGIN 
{
    

    If (-not([System.Diagnostics.EventLog]::SourceExists("Virtual Desktop Optimization")))
    {
        # All VDOT main function Event ID's [1-9]
        $EventSources = @('VDOT', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO', 'EdgeVDOT', 'DiskCleanup')
        New-EventLog -Source $EventSources -LogName 'Virtual Desktop Optimization'
        Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName 'Virtual Desktop Optimization'
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Log Created"
    }
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Starting VDOT by user '$env:USERNAME', for VDOT build '$WindowsVersion', with the following options:`n$($PSBoundParameters | Out-String)" 

    $StartTime = Get-Date
    $CurrentLocation = Get-Location
    $WorkingLocation = (Join-Path $PSScriptRoot $WindowsVersion)

    try
    {
        Push-Location (Join-Path $PSScriptRoot $WindowsVersion)-ErrorAction Stop
    }
    catch
    {
        $Message = "Invalid Path $WorkingLocation - Exiting Script!"
        Write-EventLog -Message $Message -Source 'VDOT' -EventID 100 -EntryType Error -LogName 'Virtual Desktop Optimization'
        Write-Warning $Message
        Return
    }
}
PROCESS {

    $EULA = Get-Content ..\EULA.txt
    If (-not($AcceptEULA))
    {
        $Title = "Accept EULA"
        $Message = ""
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $EULA
        $Response = $host.UI.PromptForChoice($Title, $Message, $Options, 0)
        If ($Response -eq 0)
        {
            Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "EULA Accepted"
        }
        Else
        {
            Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning -EventId 1 -Message "EULA Declined, exiting!"
            Set-Location $CurrentLocation
            $EndTime = Get-Date
            $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
            Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "VDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds"
            Write-Host "`n`nThank you from the Virtual Desktop Optimization Team" -ForegroundColor Cyan

            continue
        }
    }
    Else 
    {
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "EULA Accepted by Parameter" 
    }

    #region Disable, then remove, Windows Media Player including payload
    If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All") {
        try
        {
            Write-EventLog -EventId 10 -Message "[VDI Optimize] Disable / Remove Windows Media Player" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Information 
            Write-Host "[VDI Optimize] Disable / Remove Windows Media Player" -ForegroundColor Cyan
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-EventLog -EventId 10 -Message "Removing $($_.PackageName)" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Information 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            Write-EventLog -EventId 110 -Message "Disabling / Removing Windows Media Player - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Error 
        }
    }
    #endregion

    #region Begin Clean APPX Packages
    If ($Optimizations -contains "AppxPackages" -or $Optimizations -contains "All")
    {
        $AppxConfigFilePath = ".\ConfigurationFiles\AppxPackages.json"
        If (Test-Path $AppxConfigFilePath)
        {
            Write-EventLog -EventId 20 -Message "[VDI Optimize] Removing Appx Packages" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
            Write-Host "[VDI Optimize] Removing Appx Packages" -ForegroundColor Cyan
            $AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {                
                        Write-EventLog -EventId 20 -Message "Removing Provisioned Package $($Item.AppxPackage)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Removing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
                    }
                    catch 
                    {
                        Write-EventLog -EventId 120 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Error 
                        Write-Warning "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)"
                    }
                }
            }
            Else 
            {
                Write-EventLog -EventId 20 -Message "No AppxPackages found to disable" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Warning 
                Write-Warning "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else 
        {

            Write-EventLog -EventId 20 -Message "Configuration file not found - $AppxConfigFilePath" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Warning 
            Write-Warning "Configuration file not found -  $AppxConfigFilePath"
        }

    }
    #endregion

    #region Disable Scheduled Tasks

    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($Optimizations -contains 'ScheduledTasks' -or $Optimizations -contains "All") {
        $ScheduledTasksFilePath = ".\ConfigurationFiles\ScheduledTasks.json"
        If (Test-Path $ScheduledTasksFilePath)
        {
            Write-EventLog -EventId 30 -Message "[VDI Optimize] Disable Scheduled Tasks" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Information 
            Write-Host "[VDI Optimize] Disable Scheduled Tasks" -ForegroundColor Cyan
            $SchTasksList = (Get-Content $ScheduledTasksFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($SchTasksList.count -gt 0)
            {
                Foreach ($Item in $SchTasksList)
                {
                    $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled')
                    {
                        Write-EventLog -EventId 30 -Message "Attempting to disable Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Information 
                        Write-Verbose "Attempting to disable Scheduled Task: $($TaskObject.TaskName)"
                        try
                        {
                            Disable-ScheduledTask -InputObject $TaskObject | Out-Null
                            Write-EventLog -EventId 30 -Message "Disabled Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Information 
                        }
                        catch
                        {
                            Write-EventLog -EventId 130 -Message "Failed to disabled Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Error 
                        }
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') 
                    {
                        Write-EventLog -EventId 30 -Message "$($TaskObject.TaskName) Scheduled Task is already disabled - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Warning
                    }
                    Else
                    {
                        Write-EventLog -EventId 130 -Message "Unable to find Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Error
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 30 -Message "No Scheduled Tasks found to disable" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Warning
            }
        }
        Else 
        {
            Write-EventLog -EventId 30 -Message "File not found! -  $ScheduledTasksFilePath" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Warning
        }
    }
    #endregion

    #region Customize Default User Profile

    # Apply appearance customizations to default user registry hive, then close hive file
    If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All")
    {
        $DefaultUserSettingsFilePath = ".\ConfigurationFiles\DefaultUserSettings.json"
        If (Test-Path $DefaultUserSettingsFilePath)
        {
            Write-EventLog -EventId 40 -Message "Set Default User Settings" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "[VDI Optimize] Set Default User Settings" -ForegroundColor Cyan
            $UserSettings = (Get-Content $DefaultUserSettingsFilePath | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
            If ($UserSettings.Count -gt 0)
            {
                Write-EventLog -EventId 40 -Message "Processing Default User Settings (Registry Keys)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                Write-Verbose "Processing Default User Settings (Registry Keys)"

                & REG LOAD HKLM\VDOT_TEMP C:\Users\Default\NTUSER.DAT | Out-Null

                Foreach ($Item in $UserSettings)
                {
                    If ($Item.PropertyType -eq "BINARY")
                    {
                        $Value = [byte[]]($Item.PropertyValue.Split(","))
                    }
                    Else
                    {
                        $Value = $Item.PropertyValue
                    }

                    If (Test-Path -Path ("{0}" -f $Item.HivePath))
                    {
                        Write-EventLog -EventId 40 -Message "Found $($Item.HivePath) - $($Item.KeyName)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information        
                        Write-Verbose "Found $($Item.HivePath) - $($Item.KeyName)"
                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue)
                        {
                            Write-EventLog -EventId 40 -Message "Set $($Item.HivePath) - $Value" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                            Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Type $Item.PropertyType -Force 
                        }
                        Else
                        {
                            Write-EventLog -EventId 40 -Message "New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                    }
                    Else
                    {
                        Write-EventLog -EventId 40 -Message "Registry Path not found $($Item.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                        Write-EventLog -EventId 40 -Message "Creating new Registry Key $($Item.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                        $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                        If (Test-Path -Path $newKey.PSPath)
                        {
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                        Else
                        {
                            Write-EventLog -EventId 140 -Message "Failed to create new Registry Key" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Error
                        } 
                    }
                }

                & REG UNLOAD HKLM\VDOT_TEMP | Out-Null
            }
            Else
            {
                Write-EventLog -EventId 40 -Message "No Default User Settings to set" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Warning
            }
        }
        Else
        {
            Write-EventLog -EventId 40 -Message "File not found: $DefaultUserSettingsFilePath" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Warning
        }    }
    #endregion

    #region Disable Windows Traces
    If ($Optimizations -contains "AutoLoggers" -or $Optimizations -contains "All")
    {
        $AutoLoggersFilePath = ".\ConfigurationFiles\Autologgers.Json"
        If (Test-Path $AutoLoggersFilePath)
        {
            Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Information
            Write-Host "[VDI Optimize] Disable Autologgers" -ForegroundColor Cyan
            $DisableAutologgers = (Get-Content $AutoLoggersFilePath | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
            If ($DisableAutologgers.count -gt 0)
            {
                Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Information
                Write-Verbose "Processing Autologger Configuration File"
                Foreach ($Item in $DisableAutologgers)
                {
                    Write-EventLog -EventId 50 -Message "Updating Registry Key for: $($Item.KeyName)" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Information
                    Write-Verbose "Updating Registry Key for: $($Item.KeyName)"
                    Try 
                    {
                        New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name "Start" -PropertyType "DWORD" -Value 0 -Force -ErrorAction Stop | Out-Null
                    }
                    Catch
                    {
                        Write-EventLog -EventId 150 -Message "Failed to add $($Item.KeyName)`n`n $($Error[0].Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Error
                    }
                    
                }
            }
            Else 
            {
                Write-EventLog -EventId 50 -Message "No Autologgers found to disable" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Warning
                Write-Verbose "No Autologgers found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 150 -Message "File not found: $AutoLoggersFilePath" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Error
            Write-Warning "File Not Found: $AutoLoggersFilePath"
        }
    }
    #endregion

    #region Disable Services
    If ($Optimizations -contains "Services" -or $Optimizations -contains "All")
    {
        $ServicesFilePath = ".\ConfigurationFiles\Services.json"
        If (Test-Path $ServicesFilePath)
        {
            Write-EventLog -EventId 60 -Message "Disable Services" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
            Write-Host "[VDI Optimize] Disable Services" -ForegroundColor Cyan
            $ServicesToDisable = (Get-Content $ServicesFilePath | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })

            If ($ServicesToDisable.count -gt 0)
            {
                Write-EventLog -EventId 60 -Message "Processing Services Configuration File" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                Write-Verbose "Processing Services Configuration File"
                Foreach ($Item in $ServicesToDisable)
                {
                    #Write-EventLog -EventId 60 -Message "Attempting to Stop Service $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                    #Write-Verbose "Attempting to Stop Service $($Item.Name) - $($Item.Description)"
                    #try
                    #{
                    #    Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue
                    #}
                    #catch
                    #{
                    #    Write-EventLog -EventId 160 -Message "Failed to disable Service: $($Item.Name) `n $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Error
                    #    Write-Warning "Failed to disable Service: $($Item.Name) `n $($_.Exception.Message)"
                    #}
                    Write-EventLog -EventId 60 -Message "Attempting to disable Service $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                    Write-Verbose "Attempting to disable Service $($Item.Name) - $($Item.Description)"
                    Set-Service $Item.Name -StartupType Disabled 
                }
            }  
            Else
            {
                Write-EventLog -EventId 60 -Message "No Services found to disable" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Warnnig
                Write-Verbose "No Services found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 160 -Message "File not found: $ServicesFilePath" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Error
            Write-Warning "File not found: $ServicesFilePath"
        }    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All")
    {
        $NetworkOptimizationsFilePath = ".\ConfigurationFiles\LanManWorkstation.json"
        If (Test-Path $NetworkOptimizationsFilePath)
        {
            Write-EventLog -EventId 70 -Message "Configure LanManWorkstation Settings" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
            Write-Host "[VDI Optimize] Configure LanManWorkstation Settings" -ForegroundColor Cyan
            $LanManSettings = Get-Content $NetworkOptimizationsFilePath | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0)
            {
                Write-EventLog -EventId 70 -Message "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                Write-Verbose "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)"
                Foreach ($Hive in $LanManSettings)
                {
                    If (Test-Path -Path $Hive.HivePath)
                    {
                        Write-EventLog -EventId 70 -Message "Found $($Hive.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                        Write-Verbose "Found $($Hive.HivePath)"
                        $Keys = $Hive.Keys.Where{ $_.SetProperty -eq $true }
                        If ($Keys.Count -gt 0)
                        {
                            Write-EventLog -EventId 70 -Message "Create / Update LanManWorkstation Keys" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                            Write-Verbose "Create / Update LanManWorkstation Keys"
                            Foreach ($Key in $Keys)
                            {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue)
                                {
                                    Write-EventLog -EventId 70 -Message "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                                    Write-Verbose "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force
                                }
                                Else
                                {
                                    Write-EventLog -EventId 70 -Message "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                                    Write-Host "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null
                                }
                            }
                        }
                        Else
                        {
                            Write-EventLog -EventId 70 -Message "No LanManWorkstation Keys to create / update" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
                            Write-Warning "No LanManWorkstation Keys to create / update"
                        }  
                    }
                    Else
                    {
                        Write-EventLog -EventId 70 -Message "Registry Path not found $($Hive.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
                        Write-Warning "Registry Path not found $($Hive.HivePath)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 70 -Message "No LanManWorkstation Settings foun" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
                Write-Warning "No LanManWorkstation Settings found"
            }
        }
        Else
        {
            Write-EventLog -EventId 70 -Message "File not found - $NetworkOptimizationsFilePath" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
            Write-Warning "File not found - $NetworkOptimizationsFilePath"
        }

        # NIC Advanced Properties performance settings for network biased environments
        Write-EventLog -EventId 70 -Message "Configuring Network Adapter Buffer Size" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
        Write-Host "[VDI Optimize] Configuring Network Adapter Buffer Size" -ForegroundColor Cyan
        Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB -NoRestart
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
    If ($Optimizations -contains "LGPO" -or $Optimizations -contains "All")
    {
        $LocalPolicyFilePath = ".\ConfigurationFiles\PolicyRegSettings.json"
        If (Test-Path $LocalPolicyFilePath)
        {
            Write-EventLog -EventId 80 -Message "Local Group Policy Items" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
            Write-Host "[VDI Optimize] Local Group Policy Items" -ForegroundColor Cyan
            $PolicyRegSettings = Get-Content $LocalPolicyFilePath | ConvertFrom-Json
            If ($PolicyRegSettings.Count -gt 0)
            {
                Write-EventLog -EventId 80 -Message "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                Write-Verbose "Processing PolicyRegSettings Settings ($($PolicyRegSettings.Count) Hives)"
                Foreach ($Key in $PolicyRegSettings)
                {
                    If ($Key.VDIState -eq 'Enabled')
                    {
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue) 
                        { 
                            Write-EventLog -EventId 80 -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                            Write-Verbose "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force 
                        }
                        Else 
                        { 
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-EventLog -EventId 80 -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                                Write-Verbose "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
                            Else
                            {
                                Write-EventLog -EventId 80 -Message "Creating Key and Path" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                                Write-Verbose "Creating Key and Path"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
            
                        }
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 80 -Message "No LGPO Settings Found!" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Warning
                Write-Warning "No LGPO Settings found"
            }
        }
        Else 
        {
            If (Test-Path (Join-Path $PSScriptRoot "LGPO\LGPO.exe"))
            {
                Write-EventLog -EventId 80 -Message "[VDI Optimize] Import Local Group Policy Items" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Information
                Write-Host "[VDI Optimize] Import Local Group Policy Items" -ForegroundColor Cyan
                Write-Verbose "Importing Local Group Policy Items"
                Start-Process (Join-Path $PSScriptRoot "LGPO\LGPO.exe") -ArgumentList "/g .\LGPO" -Wait
            }
            Else
            {
                Write-EventLog -EventId 80 -Message "File not found $PSScriptRoot\LGPO\LGPO.exe" -LogName 'Virtual Desktop Optimization' -Source 'LGPO' -EntryType Warning
                Write-Warning "File not found $PSScriptRoot\LGPO\LGPO.exe"
            }
        }    
    }
    #endregion
    
    #region Edge Settings
    If ($Optimizations -contains "Edge")
    {
        $EdgeFilePath = ".\ConfigurationFiles\EdgeSettings.json"
        If (Test-Path $EdgeFilePath)
        {
            Write-EventLog -EventId 80 -Message "Edge Policy Settings" -LogName 'Virtual Desktop Optimization' -Source 'EdgeVDOT' -EntryType Information
            Write-Host "[VDI Optimize] Edge Policy Settings" -ForegroundColor Cyan
            $EdgeSettings = Get-Content $EdgeFilePath | ConvertFrom-Json
            If ($EdgeSettings.Count -gt 0)
            {
                Write-EventLog -EventId 80 -Message "Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)" -LogName 'Virtual Desktop Optimization' -Source 'EdgeVDOT' -EntryType Information
                Write-Verbose "Processing Edge Policy Settings ($($EdgeSettings.Count) Hives)"
                Foreach ($Key in $EdgeSettings)
                {
                    If ($Key.VDIState -eq 'Enabled')
                    {
                        If ($key.RegItemValueName -eq 'DefaultAssociationsConfiguration')
                        {
                            Copy-Item .\ConfigurationFiles\DefaultAssociationsConfiguration.xml $key.RegItemValue -Force
                        }
                        If (Get-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -ErrorAction SilentlyContinue) 
                        { 
                            Write-EventLog -EventId 80 -Message "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)" -LogName 'Virtual Desktop Optimization' -Source 'EdgeVDOT' -EntryType Information
                            Write-Verbose "Found key, $($Key.RegItemPath) Name $($Key.RegItemValueName) Value $($Key.RegItemValue)"
                            Set-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -Value $Key.RegItemValue -Force 
                        }
                        Else 
                        { 
                            If (Test-path $Key.RegItemPath)
                            {
                                Write-EventLog -EventId 80 -Message "Path found, creating new property -Path $($Key.RegItemPath) -Name $($Key.RegItemValueName) -PropertyType $($Key.RegItemValueType) -Value $($Key.RegItemValue)" -LogName 'Virtual Desktop Optimization' -Source 'EdgeVDOT' -EntryType Information
                                Write-Verbose "Path found, creating new property -Path $($Key.RegItemPath) Name $($Key.RegItemValueName) PropertyType $($Key.RegItemValueType) Value $($Key.RegItemValue)"
                                New-ItemProperty -Path $Key.RegItemPath -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
                            Else
                            {
                                Write-EventLog -EventId 80 -Message "Creating Key and Path" -LogName 'Virtual Desktop Optimization' -Source 'EdgeVDOT' -EntryType Information
                                Write-Verbose "Creating Key and Path"
                                New-Item -Path $Key.RegItemPath -Force | New-ItemProperty -Name $Key.RegItemValueName -PropertyType $Key.RegItemValueType -Value $Key.RegItemValue -Force | Out-Null 
                            }
            
                        }
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 80 -Message "No Edge Policy Settings Found!" -LogName 'Virtual Desktop Optimization' -Source 'EdgeVDOT' -EntryType Warning
                Write-Warning "No Edge Policy Settings found"
            }
        }
        Else 
        {
            Write-Host "Foo, nothing to do here"
        }    
    }

    #endregion
    
    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
        If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
        {
            Write-EventLog -EventId 90 -Message "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use"
            Get-ChildItem -Path c:\ -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

            # Delete "RetailDemo" content (if it exits)
            Write-EventLog -EventId 90 -Message "Removing Retail Demo content (if it exists)" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing Retail Demo content (if it exists)"
            Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

            # Delete not in-use anything in the C:\Windows\Temp folder
            Write-EventLog -EventId 90 -Message "Removing all files not in use in $env:windir\TEMP" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing all files not in use in $env:windir\TEMP"
            Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue -Exclude packer*.ps1

            # Clear out Windows Error Reporting (WER) report archive folders
            Write-EventLog -EventId 90 -Message "Cleaning up WER report archive" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Cleaning up WER report archive"
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force -ErrorAction SilentlyContinue

            # Delete not in-use anything in your %temp% folder
            Write-EventLog -EventId 90 -Message "Removing files not in use in $env:temp directory" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing files not in use in $env:temp directory"
            Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

            # Clear out ALL visible Recycle Bins
            Write-EventLog -EventId 90 -Message "Clearing out ALL Recycle Bins" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Clearing out ALL Recycle Bins"
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue

            # Clear out BranchCache cache
            Write-EventLog -EventId 90 -Message "Clearing BranchCache cache" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Clearing BranchCache cache" 
            Clear-BCCache -Force -ErrorAction SilentlyContinue
        }    #endregion

    Set-Location $CurrentLocation
    $EndTime = Get-Date
    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "VDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds"
    Write-Host "`n`nThank you from the Virtual Desktop Optimization Team" -ForegroundColor Cyan

    If ($Restart) 
    {
        Restart-Computer -Force
    }
    Else
    {
        Write-Warning "A reboot is required for all changed to take effect"
    }
    ########################  END OF SCRIPT  ########################
}
