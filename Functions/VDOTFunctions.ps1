#'WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup'
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
            Write-EventLog -EventId 1 -Message "[VDI Optimize] Disable / Remove Windows Media Player" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Verbose "[VDI Optimize] Disable / Remove Windows Media Player"
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-EventLog -EventId 1 -Message "Removing $($_.PackageName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            Write-EventLog -EventId 100 -Message "Disabling / Removing Windows Media Player - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
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
            Write-EventLog -EventId 1 -Message "[VDI Optimize] Removing Appx Packages" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Host "[VDI Optimize] Removing Appx Packages"
            $AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {                
                        Write-EventLog -EventId 1 -Message "Removing Provisioned Package $($Item.AppxPackage)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Removeing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                        
                        Write-EventLog -EventId 1 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-EventLog -EventId 1 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
                    }
                    catch 
                    {
                        Write-EventLog -EventId 100 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
                        Write-Warning "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)"
                    }
                }
            }
            Else 
            {
                Write-EventLog -EventId 100 -Message "No AppxPackages found to disable" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning 
                Write-Warning "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else 
        {

            Write-EventLog -EventId 100 -Message "Configuration file not found - $AppxConfigFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning 
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

    )

    Begin
    {

    }

    Process
    {
        Write-host "Optimize-ScheduledTasks"
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

    )

    Begin
    {

    }

    Process
    {
        Write-Host "Optimize-DefaultUserSettings"
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

    )

    Begin
    {

    }

    Process
    {
        Write-Host "Optimize-AutoLoggers"
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

    )

    Begin
    {

    }

    Process
    {

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

    )

    Begin
    {

    }

    Process
    {

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

    )

    Begin
    {

    }

    Process
    {

    }

    End
    {

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

    }

    End
    {

    }
}
