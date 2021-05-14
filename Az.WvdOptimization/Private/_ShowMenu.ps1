Function _ShowMenu {
    <#
        .SYNOPSIS
            Shows a console based menu and title or just a console title banner in a variety of colors and stles.
        .DESCRIPTION
            Create a console based menu and use this function to display it with a descriptive title bar. This function is primarily used to display the title bar in a variety of colors and sytles. It is useful when used to convey important information to the console operator.
    #>
    Param (
        # Single line title or banner used as a desciption or message to the console operator
        [Parameter(Position=0,Mandatory=$true)]
        [System.String]$Title,

        # Console based menu with multiple selection options
        [Parameter(Position=1,Mandatory=$false)]
        [System.String]$Menu,

        # Allows for a variety of style selections and sizes, default style (full)
        [Parameter(Position=2,Mandatory=$false)]
        [ValidateSet("Full","Mini","Info")]
        [System.String]$Style = "Full",

        # Foreground text colors
        [Parameter(Position=3,Mandatory=$false)]
        [ValidateSet("White","Cyan","DarkCyan","Magenta","Yellow","DarkYellow","Green","DarkGreen","Red","DarkRed","Gray","DarkGray","Blue","DarkBlue")]
        [System.String]$Color = "Gray",

        # Clears the console screen before displaying the menu / title
        [Parameter(Position=4,Mandatory=$false)]
        [Switch]$ClearScreen,

        # Does not prompt for menu selection, shows the menu display only.
        [Parameter(Position=5,Mandatory=$false)]
        [Switch]$DisplayOnly
    )

    [System.Text.StringBuilder]$menuPrompt = "`n"
    Switch($Style) {
        "Full" {
            [Void]$menuPrompt.AppendLine("/" * (95))
            [Void]$menuPrompt.AppendLine("////`n`r//// $Title`n`r////")
            [Void]$menuPrompt.AppendLine("/" * (95))
        }
        "Mini" {
            [Void]$menuPrompt.AppendLine("\" * (80))
            [Void]$menuPrompt.AppendLine(" $Title")
            [Void]$menuPrompt.AppendLine("\" * (80))
        }
        "Info" {
            [Void]$menuPrompt.AppendLine("-" * (80))
            [Void]$menuPrompt.AppendLine("-- $Title")
            [Void]$menuPrompt.AppendLine("-" * (80))
        }
    }

    #add the menu
    If (-NOT [System.String]::IsNullOrEmpty($Menu)) { [Void]$menuPrompt.Append($Menu) }
    If ($ClearScreen) { [System.Console]::Clear() }
    If ($DisplayOnly) {Write-Host $menuPrompt.ToString() -ForegroundColor $Color}
    Else {
        [System.Console]::ForegroundColor = $Color
        Read-Host -Prompt $menuPrompt.ToString()
        [System.Console]::ResetColor()
    }    
}