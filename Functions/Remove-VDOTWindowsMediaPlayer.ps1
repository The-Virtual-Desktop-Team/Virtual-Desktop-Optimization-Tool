Function Remove-VDOTWindowsMediaPlayer
{
    [CmdletBinding()]
    Param ()

    Begin
    {
         Write-Verbose "Entering Function '$($MyInvocation.MyCommand.Name)'"
    }

    Process
    {
        try
        {
            Write-EventLog -EventId 10 -Message "[VDI Optimize] Disable / Remove Windows Media Player" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Information 
            Write-Host "[VDI Optimize] Disable / Remove Windows Media Player" -ForegroundColor Cyan
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-EventLog -EventId 10 -Message "Removing $($_.PackageName)" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Information 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            Write-EventLog -EventId 110 -Message "Disabling / Removing Windows Media Player - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Error 
        }
    }

    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}