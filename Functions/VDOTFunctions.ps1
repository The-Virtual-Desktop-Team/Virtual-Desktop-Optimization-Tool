Function Optimize-WindowsMediaPlayer
{
    [CmdletBinding()]
    Param
    (

    )

    Begin
    {

    }

    Process
    {
        try
        {
            Write-EventLog -EventId 10 -Message "[VDI Optimize] Disable / Remove Windows Media Player" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Host "[VDI Optimize] Disable / Remove Windows Media Player"
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-EventLog -EventId 10 -Message "Removing $($_.PackageName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            Write-EventLog -EventId 110 -Message "Disabling / Removing Windows Media Player - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
        }

    }

    End
    {

    }
}

Function Optimize-AppxPackages
{
    [CmdletBinding()]
    Param
    (
        $AppxConfigFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $AppxConfigFilePath)
        {
            Write-EventLog -EventId 20 -Message "[VDI Optimize] Removing Appx Packages" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Host "[VDI Optimize] Removing Appx Packages"
            $AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {                
                        Write-EventLog -EventId 20 -Message "Removing Provisioned Package $($Item.AppxPackage)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Removeing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
                    }
                    catch 
                    {
                        Write-EventLog -EventId 120 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
                        Write-Warning "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)"
                    }
                }
            }
            Else 
            {
                Write-EventLog -EventId 20 -Message "No AppxPackages found to disable" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning 
                Write-Warning "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else 
        {

            Write-EventLog -EventId 20 -Message "Configuration file not found - $AppxConfigFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning 
            Write-Warning "Configuration file not found -  $AppxConfigFilePath"
        }
    }

    End
    {

    }
}

Function Optimize-ScheduledTasks
{
    [CmdletBinding()]
    Param
    (
        $ScheduledTasksFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $ScheduledTasksFilePath)
        {
            Write-EventLog -EventId 30 -Message "[VDI Optimize] Disable Scheduled Tasks" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Host "[VDI Optimize] Disable Scheduled Tasks" -ForegroundColor Cyan
            $SchTasksList = (Get-Content $ScheduledTasksFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($SchTasksList.count -gt 0)
            {
                Foreach ($Item in $SchTasksList)
                {
                    $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled')
                    {
                        Write-EventLog -EventId 30 -Message "Attempting to disable Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Attempting to disable Scheduled Task: $($TaskObject.TaskName)"
                        try
                        {
                            Disable-ScheduledTask -InputObject $TaskObject | Out-Null
                            Write-EventLog -EventId 30 -Message "Disabled Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        }
                        catch
                        {
                            Write-EventLog -EventId 130 -Message "Failed to disabled Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
                        }
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') 
                    {
                        Write-EventLog -EventId 30 -Message "$($TaskObject.TaskName) Scheduled Task is already disabled - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
                    }
                    Else
                    {
                        Write-EventLog -EventId 130 -Message "Unable to find Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 30 -Message "No Scheduled Tasks found to disable" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
            }
        }
        Else 
        {
            Write-EventLog -EventId 30 -Message "File not found! -  $ScheduledTasksFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
        }
    }
    
    End
    {

    }
}

Function Optimize-DefaultUserSettings
{
    [CmdletBinding()]
    Param
    (
        $DefaultUserSettingsFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $DefaultUserSettingsFilePath)
        {
            Write-EventLog -EventId 40 -Message "Set Default User Settings" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "[VDI Optimize] Set Default User Settings"
            $UserSettings = (Get-Content $DefaultUserSettingsFilePath | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
            If ($UserSettings.Count -gt 0)
            {
                Write-EventLog -EventId 40 -Message "Processing Default User Settings (Registry Keys)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
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
                        Write-EventLog -EventId 40 -Message "Found $($Item.HivePath) - $($Item.KeyName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information        
                        Write-Verbose "Found $($Item.HivePath) - $($Item.KeyName)"
                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue)
                        {
                            Write-EventLog -EventId 40 -Message "Set $($Item.HivePath) - $Value" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                            Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Force 
                        }
                        Else
                        {
                            Write-EventLog -EventId 40 -Message "New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                    }
                    Else
                    {
                        Write-EventLog -EventId 40 -Message "Registry Path not found $($Item.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                        Write-EventLog -EventId 40 -Message "Creating new Registry Key $($Item.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                        $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                        If (Test-Path -Path $newKey.PSPath)
                        {
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        }
                        Else
                        {
                            Write-EventLog -EventId 140 -Message "Failed to create new Registry Key" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
                        } 
                    }
                }

                & REG UNLOAD HKLM\VDOT_TEMP | Out-Null
            }
            Else
            {
                Write-EventLog -EventId 40 -Message "No Default User Settings to set" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
            }
        }
        Else
        {
            Write-EventLog -EventId 40 -Message "File not found: $DefaultUserSettingsFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
        }
    }

    End
    {

    }
}

Function Optimize-AutoLoggers
{
    [CmdletBinding()]
    Param
    (
        $AutoLoggersFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $AutoLoggersFilePath)
        {
            Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "[VDI Optimize] Disable Autologgers"
            $DisableAutologgers = (Get-Content $AutoLoggersFilePath | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
            If ($DisableAutologgers.count -gt 0)
            {
                Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                Write-Verbose "Processing Autologger Configuration File"
                Foreach ($Item in $DisableAutologgers)
                {
                    Write-EventLog -EventId 50 -Message "Updating Registry Key for: $($Item.KeyName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                    Write-Verbose "Updating Registry Key for: $($Item.KeyName)"
                    New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name "Start" -PropertyType "DWORD" -Value 0 -Force | Out-Null
                }
            }
            Else 
            {
                Write-EventLog -EventId 50 -Message "No Autologgers found to disable" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
                Write-Verbose "No Autologgers found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 150 -Message "File not found: $AutoLoggersFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
            Write-Warning "File Not Found: $AutoLoggersFilePath"
        }
    }

    End
    {

    }
}

Function Optimize-Services
{
    [CmdletBinding()]
    Param
    (
        $ServicesFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $ServicesFilePath)
        {
            Write-EventLog -EventId 60 -Message "Disable Services" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "[VDI Optimize] Disable Services"
            $ServicesToDisable = (Get-Content $ServicesFilePath | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })

            If ($ServicesToDisable.count -gt 0)
            {
                Write-EventLog -EventId 60 -Message "Processing Services Configuration File" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                Write-Verbose "Processing Services Configuration File"
                Foreach ($Item in $ServicesToDisable)
                {
                    Write-EventLog -EventId 60 -Message "Attempting to Stop Service $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                    Write-Verbose "Attempting to Stop Service $($Item.Name) - $($Item.Description)"
                    try
                    {
                        Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue
                    }
                    catch
                    {
                        Write-EventLog -EventId 160 -Message "Failed to disabled Service: $($Item.Name) `n $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
                        Write-Warning "Failed to disabled Service: $($Item.Name) `n $($_.Exception.Message)"
                    }
                    Write-EventLog -EventId 60 -Message "Attempting to Disable Server $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                    Write-Verbose "Attempting to Disable Server $($Item.Name) - $($Item.Description)"
                    Set-Service $Item.Name -StartupType Disabled 
                }
            }  
            Else
            {
                Write-EventLog -EventId 60 -Message "No Services found to disable" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warnnig
                Write-Verbose "No Services found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 160 -Message "File not found: $ServicesFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
            Write-Warning "File not found: $ServicesFilePath"
        }

    }

    End
    {

    }
}

Function Optimize-Network
{
    [CmdletBinding()]
    Param
    (
        $NetworkOptimizationsFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $NetworkOptimizationsFilePath)
        {
            Write-EventLog -EventId 70 -Message "Configure LanManWorkstation Settings" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "[VDI Optimize] Configure LanManWorkstation Settings"
            $LanManSettings = Get-Content $NetworkOptimizationsFilePath | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0)
            {
                Write-EventLog -EventId 70 -Message "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                Write-Verbose "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)"
                Foreach ($Hive in $LanManSettings)
                {
                    If (Test-Path -Path $Hive.HivePath)
                    {
                        Write-EventLog -EventId 70 -Message "Found $($Hive.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                        Write-Verbose "Found $($Hive.HivePath)"
                        $Keys = $Hive.Keys.Where{ $_.SetProperty -eq $true }
                        If ($Keys.Count -gt 0)
                        {
                            Write-EventLog -EventId 70 -Message "Create / Update LanManWorkstation Keys" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                            Write-Verbose "Create / Update LanManWorkstation Keys"
                            Foreach ($Key in $Keys)
                            {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue)
                                {
                                    Write-EventLog -EventId 70 -Message "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                                    Write-Verbose "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force
                                }
                                Else
                                {
                                    Write-EventLog -EventId 70 -Message "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
                                    Write-Host "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null
                                }
                            }
                        }
                        Else
                        {
                            Write-EventLog -EventId 70 -Message "No LanManWorkstation Keys to create / update" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
                            Write-Warning "No LanManWorkstation Keys to create / update"
                        }  
                    }
                    Else
                    {
                        Write-EventLog -EventId 70 -Message "Registry Path not found $($Hive.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
                        Write-Warning "Registry Path not found $($Hive.HivePath)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 70 -Message "No LanManWorkstation Settings foun" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
                Write-Warning "No LanManWorkstation Settings found"
            }
        }
        Else
        {
            Write-EventLog -EventId 70 -Message "File not found - $NetworkOptimizationsFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
            Write-Warning "File not found - $NetworkOptimizationsFilePath"
        }

        # NIC Advanced Properties performance settings for network biased environments
        Write-EventLog -EventId 70 -Message "Configuring Network Adapter Buffer Size" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
        Write-Host "[VDI Optimize] Configuring Network Adapter Buffer Size"
        Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB
    }

    End
    {

    }
}

Function Optimize-LocalPolicy
{
    [CmdletBinding()]
    Param
    (
        $LocalPolicyFilePath
    )

    Begin
    {

    }

    Process
    {

    }

    End
    {
        #gpupdate /force 
    }
}

Function Optimize-DiskCleanup
{
    [CmdletBinding()]
    Param
    (
        
    )

    Begin
    {

    }

    Process
    {
        If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
        {
            Write-EventLog -EventId 90 -Message "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use"
            Get-ChildItem -Path c:\ -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

            # Delete "RetailDemo" content (if it exits)
            Write-EventLog -EventId 90 -Message "Removing Retail Demo content (if it exists)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Removing Retail Demo content (if it exists)"
            Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

            # Delete not in-use anything in the C:\Windows\Temp folder
            Write-EventLog -EventId 90 -Message "Removing all files not in use in $env:windir\TEMP" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Removing all files not in use in $env:windir\TEMP"
            Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

            # Clear out Windows Error Reporting (WER) report archive folders
            Write-EventLog -EventId 90 -Message "Cleaning up WER report archive" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Cleaning up WER report archive"
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force -ErrorAction SilentlyContinue

            # Delete not in-use anything in your %temp% folder
            Write-EventLog -EventId 90 -Message "Removing files not in use in $env:temp directory" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Removing files not in use in $env:temp directory"
            Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

            # Clear out ALL visible Recycle Bins
            Write-EventLog -EventId 90 -Message "Clearing out ALL Recycle Bins" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Clearing out ALL Recycle Bins"
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue

            # Clear out BranchCache cache
            Write-EventLog -EventId 90 -Message "Clearing BranchCache cache" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "Clearing BranchCache cache"
            Clear-BCCache -Force -ErrorAction SilentlyContinue
        }

    }

    End
    {

    }
}
