Function _OptimizeScheduledTasks
{
    [CmdletBinding()]
    Param
    (
        $ScheduledTasksFilePath
    )

    Begin
    {

    }

    Process
    {
        If (Test-Path $ScheduledTasksFilePath)
        {
            Write-EventLog -EventId 30 -Message "[VDI Optimize] Disable Scheduled Tasks" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
            Write-Host "[VDI Optimize] Disable Scheduled Tasks" -ForegroundColor Cyan
            $SchTasksList = (Get-Content $ScheduledTasksFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($SchTasksList.count -gt 0)
            {
                Foreach ($Item in $SchTasksList)
                {
                    $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled')
                    {
                        Write-EventLog -EventId 30 -Message "Attempting to disable Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        Write-Verbose "Attempting to disable Scheduled Task: $($TaskObject.TaskName)"
                        try
                        {
                            Disable-ScheduledTask -InputObject $TaskObject | Out-Null
                            Write-EventLog -EventId 30 -Message "Disabled Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information 
                        }
                        catch
                        {
                            Write-EventLog -EventId 130 -Message "Failed to disabled Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error 
                        }
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') 
                    {
                        Write-EventLog -EventId 30 -Message "$($TaskObject.TaskName) Scheduled Task is already disabled - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
                    }
                    Else
                    {
                        Write-EventLog -EventId 130 -Message "Unable to find Scheduled Task: $($TaskObject.TaskName) - $($_.Exception.Message)" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Error
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 30 -Message "No Scheduled Tasks found to disable" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
            }
        }
        Else 
        {
            Write-EventLog -EventId 30 -Message "File not found! -  $ScheduledTasksFilePath" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Warning
        }
    }
    
    End
    {

    }
}