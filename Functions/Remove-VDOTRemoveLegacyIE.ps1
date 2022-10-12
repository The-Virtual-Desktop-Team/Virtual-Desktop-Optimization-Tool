function Remove-VDOTRemoveLegacyIE
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
        Write-EventLog -EventId 80 -Message "Remove Legacy Internet Explorer" -LogName 'Virtual Desktop Optimization' -Source 'AdvancedOptimizations' -EntryType Information
        Write-Host "[VDI Advanced Optimize] Remove Legacy Internet Explorer" -ForegroundColor Cyan
        Get-WindowsCapability -Online | Where-Object Name -Like "*Browser.Internet*" | Remove-WindowsCapability -Online 
    }
    End
    {
        Write-Verbose "Exiting Function '$($MyInvocation.MyCommand.Name)'"
    }
}
