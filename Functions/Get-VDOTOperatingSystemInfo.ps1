Function Get-VDOTOperatingSystemInfo
{
    [CmdletBinding()]
    param ()

    Begin 
    {
         Write-Verbose "Entering Function '$($MyInvocation.MyCommand.Name)'"
    }
        
    Process 
    {
        $CIMOSInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version
        $RegOSInfo = Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object CurrentVersion, CurrentBuildNumber, DisplayVersion, ReleaseID
        $OSInfo = [PSCustomObject]@{
            Caption = $CIMOSInfo.Caption
            Version = $CIMOSInfo.Version
            CurrentVersion = $RegOSInfo.CurrentVersion
            CurrentBuildNumber = $RegOSInfo.CurrentBuildNumber
            DisplayVersion = $RegOSInfo.DisplayVersion
            ReleaseID = $RegOSInfo.ReleaseID
        }
    }

    End 
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
        Return $OSInfo
    }
}