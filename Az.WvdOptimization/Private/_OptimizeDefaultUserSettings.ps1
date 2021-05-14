Function _OptimizeDefaultUserSettings
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
            Write-Host "[VDI Optimize] Set Default User Settings" -ForegroundColor Cyan
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