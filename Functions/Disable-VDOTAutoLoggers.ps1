function Disable-VDOTAutoLoggers
{
    [CmdletBinding()]

    Param
    (

    )

    Begin
    {
        Write-Verbose "Entering Function '$($MyInvocation.MyCommand.Name)'"
    }
    Process
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
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
