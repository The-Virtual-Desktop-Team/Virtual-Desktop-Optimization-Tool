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
    [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

    [ValidateSet('All', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO', 'DiskCleanup')] 
    [String[]]
    $Optimizations = "All",


    [Switch]$Restart
)

#Requires -RunAsAdministrator

<#
- TITLE:          Microsoft Windows 10 Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
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
All VDOT main function Event ID's [1-9]
All WindowsMediaPlayer function Event ID's [10-19] - Normal Operations (Informational, Warning)
All AppxPackages function Event ID's [20-29] - Normal Operations (Informational, Warning)
All ScheduledTasks function Event ID's [30-39] - Normal Operations (Informational, Warning)
All DefaultUserSettings function Event ID's [40-49] - Normal Operations (Informational, Warning)
All AutoLoggers function Event ID's [50-59] - Normal Operations (Informational, Warning)
All Services function Event ID's [60-69] - Normal Operations (Informational, Warning)
All Network function Event ID's [70-79] - Normal Operations (Informational, Warning)
All LocalPolicy function Event ID's [80-89] - Normal Operations (Informational, Warning)
All DiskCleanup function Event ID's [90-99] - Normal Operations (Informational, Warning)


All VDOT main function Event ID's [100-109] - Errors Only
All WindowsMediaPlayer function Event ID's [110-119] - Errors Only
All AppxPackages function Event ID's [120-129] - Errors Only
All ScheduledTasks function Event ID's [130-139] - Errors Only
All DefaultUserSettings function Event ID's [140-149] - Errors Only
All AutoLoggers function Event ID's [150-159] - Errors Only
All Services function Event ID's [160-169] - Errors Only
All Network function Event ID's [170-179] - Errors Only
All LocalPolicy function Event ID's [180-189] - Errors Only
All DiskCleanup function Event ID's [190-199] - Errors Only


#>

<# Categories of cleanup items:
This script is dependent on three elements:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

The UWP app input file contains the list of almost all the UWP application packages that can be removed with PowerShell interactively.  
The Store and a few others, such as Wallet, were left off intentionally.  Though it is possible to remove the Store app, 
it is nearly impossible to get it back.  Please review the lists below and comment out or remove references to packages that you do not want to remove.
#>

BEGIN
{
    If (-not([System.Diagnostics.EventLog]::SourceExists("Virtual Desktop Optimization")))
    {
        # All VDOT main function Event ID's [1-9]
        New-EventLog -Source 'VDOT' -LogName 'Virtual Desktop Optimization'
        Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName 'Virtual Desktop Optimization'
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Log Created"
    }
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Starting VDOT with the following options:`n$($PSBoundParameters | Out-String)" 

    . ($PSScriptRoot + "\Functions\VDOTFunctions.ps1")
    $StartTime = Get-Date
    $CurrentLocation = Get-Location
    $WorkingLocation = (Join-Path $PSScriptRoot $WindowsVersion)


}
Process
{
    try 
    { 
        Push-Location  $WorkingLocation -ErrorAction Stop 
    }
    catch
    {
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error -EventId 100 -Message "Invalid path '$WorkingLocation' Exiting Script"
        Write-Warning "Invalid Configuration Location '$WorkingLocation' - Exiting!"
        Return
    }

    If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All")
    {
        # All WindowsMediaPlayer function Event ID's [10-19]
        Optimize-WindowsMediaPlayer
    }
    If ($Optimizations -contains "AppxPackages" -or $Optimizations -contains "All")
    {
        # All AppxPackages function Event ID's [20-29]
        Optimize-AppxPackages -AppxConfigFilePath ".\ConfigurationFiles\AppxPackages.json"
    }
    
    # All ScheduledTasks function Event ID's [30-39]
    If ($Optimizations -contains "ScheduledTasks" -or $Optimizations -contains "All")
    {
        Optimize-ScheduledTasks -ScheduledTasksFilePath ".\ConfigurationFiles\ScheduledTasks.json"
    }

    # All DefaultUserSettings function Event ID's [40-49]
    If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All")
    {
        Optimize-DefaultUserSettings -DefaultUserSettingsFilePath ".\ConfigurationFiles\DefaultUserSettings.json"
    }
    
    # All AutoLoggers function Event ID's [50-59]
    If ($Optimizations -contains "Autologgers" -or $Optimizations -contains "All")
    {
        Optimize-AutoLoggers -AutoLoggersFilePath ".\ConfigurationFiles\Autologgers.json"
    }

    # All Services function Event ID's [60-69]
    If ($Optimizations -contains "Services" -or $Optimizations -contains "All")
    {
        Optimize-Services -ServicesFilePath ".\ConfigurationFiles\Services.json"
    }

    # All Network function Event ID's [70-79]
    If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All")
    {
        Optimize-Network -NetworkOptimizationsFilePath ".\ConfigurationFiles\LanManWorkstation.json"
    }

    # All LocalPolicy function Event ID's [80-89]
    If ($Optimizations -contains "LGPO" -or $Optimizations -contains "All")
    {
        Optimize-LocalPolicy -LocalPolicyFilePath ""
    }

    # All DiskCleanup function Event ID's [90-99]
    If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
    {
        Optimize-DiskCleanup
    }
}

End
{
    Set-Location $CurrentLocation
    $EndTime = Get-Date
    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "VDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds"
    Write-Host "`n`nThank you from the Virtual Desktop Optimization Team" -ForegroundColor Cyan
}
