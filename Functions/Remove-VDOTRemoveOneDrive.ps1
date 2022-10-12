function Remove-VDOTRemoveOneDrive
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
        Write-EventLog -EventId 80 -Message "Remove OneDrive Commercial" -LogName 'Virtual Desktop Optimization' -Source 'AdvancedOptimizations' -EntryType Information
        Write-Host "[VDI Advanced Optimize] Removing OneDrive Commercial" -ForegroundColor Cyan
        $OneDrivePath = @('C:\Windows\System32\OneDriveSetup.exe', 'C:\Windows\SysWOW64\OneDriveSetup.exe')   
        $OneDrivePath | foreach {
            If (Test-Path $_)
            {
                Write-Host "`tAttempting to uninstall $_"
                Write-EventLog -EventId 80 -Message "Commercial $_" -LogName 'Virtual Desktop Optimization' -Source 'AdvancedOptimizations' -EntryType Information
                Start-Process $_ -ArgumentList "/uninstall" -Wait
            }
        }
        Write-EventLog -EventId 80 -Message "Removing shortcut links for OneDrive" -LogName 'Virtual Desktop Optimization' -Source 'AdvancedOptimizations' -EntryType Information
        Remove-Item -Path 'C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'C:\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'  -Force -ErrorAction SilentlyContinue
    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
