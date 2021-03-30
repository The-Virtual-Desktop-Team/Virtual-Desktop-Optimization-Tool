
#Script to setup golden image with Azure Image Builder

#Create temp folder
New-Item -Path 'C:\temp' -ItemType Directory -Force | Out-Null


#Start sleep

Start-Sleep -Seconds 10

#InstallNotepadplusplus

Invoke-WebRequest -Uri 'https://notepad-plus-plus.org/repository/7.x/7.7.1/npp.7.7.1.Installer.x64.exe' -OutFile 'c:\temp\notepadplusplus.exe'
Invoke-Expression -Command 'c:\temp\notepadplusplus.exe /S'
#Start sleep
Start-Sleep -Seconds 10

#InstallFSLogix

Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile 'c:\temp\fslogix.zip'
Start-Sleep -Seconds 10
Expand-Archive -Path 'C:\temp\fslogix.zip' -DestinationPath 'C:\temp\fslogix\'  -Force
Invoke-Expression -Command 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe /install /quiet /norestart'

#Start sleep
Start-Sleep -Seconds 10

#InstallTeamsMachinemode
New-Item -Path 'HKLM:\SOFTWARE\Citrix\PortICA' -Force | Out-Null
Invoke-WebRequest -Uri 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&download=true&managedInstaller=true&arch=x64' -OutFile 'c:\temp\Teams.msi'
Invoke-Expression -Command 'msiexec /i C:\temp\Teams.msi /quiet /l*v C:\temp\teamsinstall.log ALLUSER=1'
Start-Sleep -Seconds 30
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32 -Name Teams -PropertyType Binary -Value ([byte[]](0x01,0x00,0x00,0x00,0x1a,0x19,0xc3,0xb9,0x62,0x69,0xd5,0x01)) -Force

#Settingup Registry for fslogix


New-Item –Path "HKLM:\SOFTWARE\FSLogix" –Name "Profiles" -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\Profiles" -PropertyType Dword -Name ENABLED -value 1 -Force


#Set-up profile share location 

$LOC=" \\WVDSERVERNAME\WVDPROFILESHARE"
New-ItemProperty "HKLM:\SOFTWARE\FSLogix\Profiles" -Type MultiString  -PSProperty "VHDLocations" -Value $Loc

#Setup Office Containers 

#Creating Hive

New-Item –Path "HKLM:\SOFTWARE\FSLogix" –Name "ODFC" -Force

New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name DeleteLocalProfileWhenVHDShouldApply -value 1 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name FlipFlopProfileDirectoryName -value 1 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name OutlookCachedMode -value 0 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name RemoveOrphanedOSTFilesOnLogoff -value 0 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name IncludeOfficeFileCache -value 1 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name IncludeOneDrive -value 0 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name IncludeOutlook -value 0 -Force
New-ItemProperty –Path "HKLM:\SOFTWARE\FSLogix\ODFC" -PropertyType Dword -Name IncludeTeams -value 0 -Force






