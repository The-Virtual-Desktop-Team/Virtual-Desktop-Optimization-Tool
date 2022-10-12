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

[Cmdletbinding(DefaultParameterSetName = "Default")]
Param (
    # Parameter help description
    [ArgumentCompleter( { Get-ChildItem $(Join-Path $PSScriptRoot Configurations) -Directory | Select-Object -ExpandProperty Name } )]
    [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

    [ValidateSet('All', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO', 'DiskCleanup')] 
    [String[]]
    $Optimizations,

    [Parameter()]
    [ValidateSet('All', 'Edge', 'RemoveLegacyIE', 'RemoveOneDrive')]
    [String[]]
    $AdvancedOptimizations,

    [Switch]$Restart,
    [Switch]$AcceptEULA
)

#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

<#
- TITLE:          Microsoft Windows Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
- AUTHORED DATE:  11/19/2019
- CONTRIBUTORS:   Travis Roberts (2020), Jason Parker (2020)
- LAST UPDATED:   10/11/2022
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
    # Load all function files for later use
    $VDOTFunctions = Get-ChildItem $PSScriptRoot\Functions\*-VDOT*.ps1 | Select-Object -ExpandProperty FullName
    $VDOTFunctions | ForEach-Object {
        Write-Verbose "Loading Function $_"
        . $_
    }
    
    [Version]$VDOTVersion = "3.0.2009.1" 
    # Create Key
    $KeyPath = 'HKLM:\SOFTWARE\VDOT'
    If (-Not(Test-Path $KeyPath))
    {
        New-Item -Path $KeyPath | Out-Null
    }

    # Add VDOT Version Key
    $Version = "Version"
    $VersionValue = $VDOTVersion
    If (Get-ItemProperty $KeyPath -Name Version -ErrorAction SilentlyContinue)
    {
        Set-ItemProperty -Path $KeyPath -Name $Version -Value $VersionValue
    }
    Else
    {
        New-ItemProperty -Path $KeyPath -Name $Version -Value $VersionValue | Out-Null
    }

    # Add VDOT Last Run
    $LastRun = "LastRunTime"
    $LastRunValue = Get-Date
    If (Get-ItemProperty $KeyPath -Name LastRunTime -ErrorAction SilentlyContinue)
    {
        Set-ItemProperty -Path $KeyPath -Name $LastRun -Value $LastRunValue
    }
    Else
    {
        New-ItemProperty -Path $KeyPath -Name $LastRun -Value $LastRunValue | Out-Null
    }

    If (-not([System.Diagnostics.EventLog]::SourceExists("Virtual Desktop Optimization")))
    {
        # All VDOT main function Event ID's [1-9]
        $EventSources = @('VDOT', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO', 'AdvancedOptimizations', 'DiskCleanup')
        New-EventLog -Source $EventSources -LogName 'Virtual Desktop Optimization'
        Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName 'Virtual Desktop Optimization'
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Log Created"
    }
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Starting VDOT by user '$env:USERNAME', for VDOT build '$WindowsVersion', with the following options:`n$($PSBoundParameters | Out-String)" 

    $StartTime = Get-Date
    $CurrentLocation = Get-Location
    $WorkingLocation = (Join-Path $PSScriptRoot Configurations\$WindowsVersion)

    try
    {
        Push-Location $WorkingLocation -ErrorAction Stop
    }
    catch
    {
        $Message = "Invalid Path $WorkingLocation - Exiting Script!"
        Write-EventLog -Message $Message -Source 'VDOT' -EventID 100 -EntryType Error -LogName 'Virtual Desktop Optimization'
        Write-Warning $Message
        Return
    }
}
PROCESS
{
    if (-not ($PSBoundParameters.Keys -match 'Optimizations') )
    {
        Write-EventLog -Message "No Optimizations (Optimizations or AdvancedOptimizations) passed, exiting script!" -Source 'VDOT' -EventID 100 -EntryType Error -LogName 'Virtual Desktop Optimization'
        $Message = "`nThe Optimizations parameter no longer defaults to 'All', you must explicitly pass in this parameter.`nThis is to allow for running 'AdvancedOptimizations' separately " 
        Write-Host " * " -ForegroundColor black -BackgroundColor yellow -NoNewline
        Write-Host " Important " -ForegroundColor Yellow -BackgroundColor Red -NoNewline
        Write-Host " * " -ForegroundColor black -BackgroundColor yellow -NoNewline
        Write-Host $Message -ForegroundColor yellow -BackgroundColor black
        Set-Location $CurrentLocation
        Return
    }
    $EULA = Get-Content $PSScriptRoot\EULA.txt
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
    $OSVersion = Get-VDOTOperatingSystemInfo
    New-VDOTCommentBox "$($OSVersion.Caption)`nVersion: $($OSVersion.DisplayVersion) - Release ID: $($OSVersion.ReleaseID)"

    #region Disable, then remove, Windows Media Player including payload
    If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All") 
    {
        Remove-VDOTWindowsMediaPlayer    
    }
    #endregion

    #region Begin Clean APPX Packages
    If ($Optimizations -contains "AppxPackages" -or $Optimizations -contains "All")
    {
        Remove-VDOTAppxPackages
    }
    #endregion

    #region Disable Scheduled Tasks

    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($Optimizations -contains 'ScheduledTasks' -or $Optimizations -contains "All") 
    {
        Disable-VDOTScheduledTasks
    }
    #endregion

    #region Customize Default User Profile

    # Apply appearance customizations to default user registry hive, then close hive file
    If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All")
    {
        Optimize-VDOTDefaultUserSettings
    }
    #endregion

    #region Disable Windows Traces
    If ($Optimizations -contains "AutoLoggers" -or $Optimizations -contains "All")
    {
        Disable-VDOTAutoLoggers
    }
    #endregion

    #region Disable Services
    If ($Optimizations -contains "Services" -or $Optimizations -contains "All")
    {
        Disable-VDOTServices
    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All")
    {
        Optimize-VDOTNetworkOptimizations
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
        Optimize-VDOTLocalPolicySettings
    }
    #endregion
    
    #region Edge Settings
    If ($AdvancedOptimizations -contains "Edge" -or $AdvancedOptimizations -contains "All")
    {
        Optimize-VDOTEdgeSettings
    }
    #endregion

    #region Remove Legacy Internet Explorer
    If ($AdvancedOptimizations -contains "RemoveLegacyIE" -or $AdvancedOptimizations -contains "All")
    {
        Remove-VDOTRemoveLegacyIE
    }
    #endregion

    #region Remove OneDrive Commercial
    If ($AdvancedOptimizations -contains "RemoveOneDrive" -or $AdvancedOptimizations -contains "All")
    {
        Remove-VDOTRemoveOneDrive
    }

    #endregion

    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
    If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
    {
        Optimize-VDOTDiskCleanup
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
        Write-Warning "A reboot is required for all changes to take effect"
    }
    ########################  END OF SCRIPT  ########################
}
