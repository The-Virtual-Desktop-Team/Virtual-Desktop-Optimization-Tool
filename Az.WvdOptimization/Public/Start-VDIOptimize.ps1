<#
- TITLE:          Microsoft Windows 10 Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith, Tim Muessig, Jason Parker
- AUTHORED DATE:  4/17/2021
- CONTRIBUTORS:   
- LAST UPDATED:   
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

<#
All VDOT main function Event ID's           [1-9]   - Normal Operations (Informational, Warning)
All WindowsMediaPlayer function Event ID's  [10-19] - Normal Operations (Informational, Warning)
All AppxPackages function Event ID's        [20-29] - Normal Operations (Informational, Warning)
All ScheduledTasks function Event ID's      [30-39] - Normal Operations (Informational, Warning)
All DefaultUserSettings function Event ID's [40-49] - Normal Operations (Informational, Warning)
All AutoLoggers function Event ID's         [50-59] - Normal Operations (Informational, Warning)
All Services function Event ID's            [60-69] - Normal Operations (Informational, Warning)
All Network function Event ID's             [70-79] - Normal Operations (Informational, Warning)
All LocalPolicy function Event ID's         [80-89] - Normal Operations (Informational, Warning)
All DiskCleanup function Event ID's         [90-99] - Normal Operations (Informational, Warning)


All VDOT main function Event ID's           [100-109] - Errors Only
All WindowsMediaPlayer function Event ID's  [110-119] - Errors Only
All AppxPackages function Event ID's        [120-129] - Errors Only
All ScheduledTasks function Event ID's      [130-139] - Errors Only
All DefaultUserSettings function Event ID's [140-149] - Errors Only
All AutoLoggers function Event ID's         [150-159] - Errors Only
All Services function Event ID's            [160-169] - Errors Only
All Network function Event ID's             [170-179] - Errors Only
All LocalPolicy function Event ID's         [180-189] - Errors Only
All DiskCleanup function Event ID's         [190-199] - Errors Only

#>

<# Categories of cleanup items:
This script is dependent on three elements:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

The UWP app input file contains the list of almost all the UWP application packages that can be removed with PowerShell interactively.  
The Store and a few others, such as Wallet, were left off intentionally.  Though it is possible to remove the Store app, 
it is nearly impossible to get it back.  Please review the lists below and comment out or remove references to packages that you do not want to remove.
#>
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
