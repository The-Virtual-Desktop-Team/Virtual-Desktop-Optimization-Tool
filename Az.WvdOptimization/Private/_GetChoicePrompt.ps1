Function _GetChoicePrompt {
    <#
        .SYNOPSIS
            Creates a customizable user prompt at the console.
        .DESCRIPTION
            This function will create a custom prompt with custom selections for the operator to make specific decisions or choices
    #>
    [CmdletBinding()]
    Param (
        # Array of strings for the options to be presented ("Yes","No" -or- "&Yes",&No"), use the '&' symbol as the designated letter for selection
        [Parameter(Mandatory = $true)]
        [String[]]$OptionList,

        # Title of the choice prompt
        [Parameter(Mandatory = $false)]
        [String]$Title,

        # Message to convey to the user / operator
        [Parameter(Mandatory = $False)]
        [String]$Message = $null,

        # Select the default choice (index based on the number of options)
        [int]$Default = 0 
    )
    $Options = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
    $OptionList | ForEach-Object { $Options.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_)) } 
    $Host.ui.PromptForChoice($Title, $Message, $Options, $Default) 
}