function New-VDOTCommentBox ()
{
    param([string]$titleText)
    $lines = $titleText.Split("`n")
    $output = "$("#"*70)`n"
    $output += "#$(" "*68)#`n"

    foreach ($line in $lines)
    {
        if ($line.Length -gt 65)
        {
            $line = $line.Substring(0, 66)
        }
        $line = $line.Trim()
        $lspaces = ([math]::Floor((68 - $line.trim().Length) / 2))      
        $rspaces = (68 - $lspaces - $line.Length)
        $output += "#$(" "*$lspaces)$($line.trim())$(" "*$rspaces)#`n"

    }
    $output += "#$(" "*68)#`n"
    $output += "$("#"*70)`n"
    return $output
}
