Function Remove-VDOTAppxPackages
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
        $AppxConfigFilePath = ".\ConfigurationFiles\AppxPackages.json"
        If (Test-Path $AppxConfigFilePath)
        {
            Write-EventLog -EventId 20 -Message "[VDI Optimize] Removing Appx Packages" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
            Write-Host "[VDI Optimize] Removing Appx Packages" -ForegroundColor Cyan
            $AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {                
                        Write-EventLog -EventId 20 -Message "Removing Provisioned Package $($Item.AppxPackage)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Removing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
                    }
                    catch 
                    {
                        Write-EventLog -EventId 120 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Error 
                        Write-Warning "Failed to remove Appx Package $($Item.AppxPackage) - $($_.Exception.Message)"
                    }
                }
            }
            Else 
            {
                Write-EventLog -EventId 20 -Message "No AppxPackages found to disable" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Warning 
                Write-Warning "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else 
        {

            Write-EventLog -EventId 20 -Message "Configuration file not found - $AppxConfigFilePath" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Warning 
            Write-Warning "Configuration file not found -  $AppxConfigFilePath"
        }
    }

    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}