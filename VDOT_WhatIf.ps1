#Change directory to the  directory of your configuration files
#Example c:\Virtual-Desktop-Optimization-Tool\2009

$FileName = "VDOT_WhatIf_" + (get-date -format 'MMddyyyy_hhmmss') +".txt"
New-Item $FileName | Out-Null

$AppxConfigFilePath = ".\ConfigurationFiles\AppxPackages.json"
$AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
"Appx Packages" | Out-File $FileName -Append
$AppxPackage | Out-File $FileName -Append

$ScheduledTasksFilePath = ".\ConfigurationFiles\ScheduledTasks.json"
$SchTasksList = (Get-Content $ScheduledTasksFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
"Scheduled Tasks" | Out-File $FileName -Append
$SchTasksList | Out-File $FileName -Append

$DefaultUserSettingsFilePath = ".\ConfigurationFiles\DefaultUserSettings.json"
$UserSettings = (Get-Content $DefaultUserSettingsFilePath | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
"Default User Settings" | Out-File $FileName -Append
$UserSettings | Out-File $FileName -Append

$AutoLoggersFilePath = ".\ConfigurationFiles\Autologgers.Json"
$DisabledAutologgers = (Get-Content $AutoLoggersFilePath | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
"Auto Loggers"  | Out-File $FileName -Append
$DisabledAutologgers | Out-File $FileName -Append

$ServicesFilePath = ".\ConfigurationFiles\Services.json"
$DisabledServices = (Get-Content $ServicesFilePath | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })
"Disabled Services"  | Out-File $FileName -Append
$DisabledServices | Out-File $FileName -Append

$NetworkOptimizationsFilePath = ".\ConfigurationFiles\LanManWorkstation.json"
$LanManSettings = Get-Content $NetworkOptimizationsFilePath | ConvertFrom-Json
"Network Optimizations" | Out-File $FileName -Append
$LanManSettings.HivePath | Out-File $FileName -Append
$LanManSettings.keys | Out-File $FileName -Append

$LocalPolicyFilePath = ".\ConfigurationFiles\PolicyRegSettings.json"
$PolicyRegSettings = (Get-Content $LocalPolicyFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
"Resistry Policy Settings" | Out-File $FileName -Append
$PolicyRegSettings | Out-File $FileName -Append


