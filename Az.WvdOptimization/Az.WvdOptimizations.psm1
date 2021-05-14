# Get Public and Private functions
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach ($Function in @($Public + $Private))
{
    Try
    {
        . $Function.FullName
    }
    Catch
    {
        Write-Error -Message ("Failed to import function ({0}): {1}" -f $Function.FullName, $_)
    }
}

# Export only the public functions
Export-ModuleMember -Function $Public.Basename