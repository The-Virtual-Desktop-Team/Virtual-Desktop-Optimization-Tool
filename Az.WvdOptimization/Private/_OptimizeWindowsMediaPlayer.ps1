Function _OptimizeWindowsMediaPlayer
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
            Write-EventLog -EventId 10 -Message "[VDI Optimize] Disable / Remove Windows Media Player" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Host "[VDI Optimize] Disable / Remove Windows Media Player"
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-EventLog -EventId 10 -Message "Removing $($_.PackageName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            Write-EventLog -EventId 110 -Message "Disabling / Removing Windows Media Player - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
        }

    }

    End
    {

    }
}