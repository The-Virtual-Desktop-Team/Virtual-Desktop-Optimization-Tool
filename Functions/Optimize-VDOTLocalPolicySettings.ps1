function Optimize-VDOTLocalPolicySettings
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
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
