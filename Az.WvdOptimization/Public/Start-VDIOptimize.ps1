Function Start-VDIOptimize
{
    [Cmdletbinding(DefaultParameterSetName = "Default")]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String]$Path,    

        [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

        [ValidateSet('All', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO', 'DiskCleanup')] 
        [String[]]$Optimizations = "All",

        [Switch]$Restart,

        [Switch]
        $AcceptEULA
    )
    BEGIN
    {
        #Requires -RunAsAdministrator
        #Requires -PSEdition Desktop

        $StartTime = Get-Date
        If (-not([System.Diagnostics.EventLog]::SourceExists("Virtual Desktop Optimization")))
        {
            New-EventLog -
            New-EventLog -Source 'VDOT' -LogName 'Virtual Desktop Optimization'
            Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Log Created"
        }
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Starting VDOT with the following options:`n$($PSBoundParameters | Out-String)"
        $WorkingLocation = Join-Path -Path $Path -ChildPath $WindowsVersion
    }
    PROCESS
    {
        If (Test-Path -Path $WorkingLocation)
        {
            $StartingLocation = Get-Location
            Push-Location $WorkingLocation
            Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message ("[VDI Optimize] Found and loaded working location:`n`r{0}" -f $WorkingLocation)
        }
        Else
        {
            $Message = ("[VDI Optimize] Unable to validate working location:`n`r{0}" -f $WorkingLocation)
            Write-EventLog -EventId 100 -Message $Message -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
            $Exception = [Exception]::new($Message)
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "WorkingLocationNotFound",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $WorkingLocation
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord) 
        }

        _ShowMenu -Title "Virtual Desktop Optimization Tool v2021.05.xx" -Style Full -Color Cyan -ClearScreen -DisplayOnly
        
        $EULA = Get-Content -Path ("{0}\EULA.txt" -f $Path)
        
        If (-NOT $AcceptEULA)
        {
            $EULA | Out-Host
            Switch (_GetChoicePrompt -OptionList "&Yes", "&No" -Title "End User License Agreement" -Message "Do you accept the EULA?" -Default 0)
            {
                0
                {
                    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "EULA Accepted"
                }
                1
                {
                    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning -EventId 5 -Message "EULA Declined, exiting!"
                    Set-Location $StartingLocation
                    $EndTime = Get-Date
                    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
                    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "VDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds"
                    Return
                }
                Default
                {
                    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "EULA Accepted"
                }
            }
        }
        Else 
        {
            Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "EULA Accepted by Parameter" 
        }

        If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All")
        {
            # All WindowsMediaPlayer function Event ID's [10-19]
            _OptimizeWindowsMediaPlayer
        }
        If ($Optimizations -contains "AppxPackages" -or $Optimizations -contains "All")
        {
            # All AppxPackages function Event ID's [20-29]
            _OptimizeAppxPackages -AppxConfigFilePath ".\ConfigurationFiles\AppxPackages.json"
        }
    
        # All ScheduledTasks function Event ID's [30-39]
        If ($Optimizations -contains "ScheduledTasks" -or $Optimizations -contains "All")
        {
            _OptimizeScheduledTasks -ScheduledTasksFilePath ".\ConfigurationFiles\ScheduledTasks.json"
        }

        # All DefaultUserSettings function Event ID's [40-49]
        If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All")
        {
            _OptimizeDefaultUserSettings -DefaultUserSettingsFilePath ".\ConfigurationFiles\DefaultUserSettings.json"
        }
    
        # All AutoLoggers function Event ID's [50-59]
        If ($Optimizations -contains "Autologgers" -or $Optimizations -contains "All")
        {
            _OptimizeAutoLoggers -AutoLoggersFilePath ".\ConfigurationFiles\Autologgers.json"
        }

        # All Services function Event ID's [60-69]
        If ($Optimizations -contains "Services" -or $Optimizations -contains "All")
        {
            _OptimizeServices -ServicesFilePath ".\ConfigurationFiles\Services.json"
        }

        # All Network function Event ID's [70-79]
        If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All")
        {
            _OptimizeNetwork -NetworkOptimizationsFilePath ".\ConfigurationFiles\LanManWorkstation.json"
        }

        # All LocalPolicy function Event ID's [80-89]
        If ($Optimizations -contains "LGPO" -or $Optimizations -contains "All")
        {
            _OptimizeLocalPolicy -LocalPolicyFilePath ""
        }

        # All DiskCleanup function Event ID's [90-99]
        If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
        {
            _OptimizeDiskCleanup
        }
    }
    
    END
    {
        $Message = ("[VDI Optimize] Total Run Time: {0}:{1}:{2}.{3}" -f $ScriptRunTime.Hours, $ScriptRunTime.Minutes, $ScriptRunTime.Seconds, $ScriptRunTime.Milliseconds)
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message $Message
        Set-Location $StartingLocation
        _ShowMenu -Title ("Thank you from the Virtual Desktop Optimization Team`n {0}" -f $Message) -Style Mini -DisplayOnly -Color Cyan
    }
}
