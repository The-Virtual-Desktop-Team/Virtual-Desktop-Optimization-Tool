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
            Write-Host "[VDI Optimize] Configure LanManWorkstation Settings" -ForegroundColor Cyan
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
                                    Write-Verbose "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
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
        Write-Host "[VDI Optimize] Configuring Network Adapter Buffer Size" -ForegroundColor Cyan
        Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB
    }

    End
    {

    }
}