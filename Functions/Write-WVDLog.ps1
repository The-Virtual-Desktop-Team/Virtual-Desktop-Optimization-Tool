function Write-WVDLog
{
    [cmdletbinding()]
    param (
        $Message,

        [ValidateSet('Info', 'Warning', 'Error', 'Verbose')]
        $Level = 'Info',

        [string[]]
        $Tag,
        
        [Switch]
        $OutputToScreen 
    )
    
    $Title = "[VDI Optimize]"
    Write-Verbose "$Title $Message"
    If ($OutputToScreen)
    {
        switch ($Level)
        {
            'Info' { Write-Host    "$Title $Message" }
            'Warning' { Write-Warning "$Title $Message" }
            'Error' { Write-Host    "$Title - $Message" -ForegroundColor Red }
            #'Verbose' { Write-Verbose "$Title $Message"}
        }
    }

    $callItem = (Get-PSCallstack)[1]
    $data = [PSCustomObject][ordered]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Level     = $Level
        Tag       = $Tag -join ","
        Line      = $callItem.ScriptLineNumber
        File      = $callItem.ScriptName
        Message   = $Message
    }
    Export-Csv -InputObject $data -Path $script:logpath -NoTypeInformation -Append
}

Function Set-WVDLog
{
    [CmdletBinding()]
    Param
    (
        $Path
    )
    $Script:logpath = $Path
}