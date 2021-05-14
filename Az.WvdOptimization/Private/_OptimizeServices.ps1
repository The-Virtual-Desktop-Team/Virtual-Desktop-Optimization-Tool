Function _OptimizeServices
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