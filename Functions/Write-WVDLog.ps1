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
    
    #Write-Verbose "$Title $Message"
    If ($OutputToScreen -or ([System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference))
    {
        switch ($Level)
        {
            'Info' { Write-Host    "$Message" }
            'Warning' { Write-Warning "$Message" }
            'Error' { Write-Host    "$Message" -ForegroundColor Red }
            'Verbose' {Write-Verbose "$Message"}
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