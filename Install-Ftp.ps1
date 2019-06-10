# Install the Windows feature for FTP

Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature

Install-WindowsFeature Web-Server -IncludeAllSubFeature  -IncludeManagementTools

Import-Module WebAdministration

# Create the FTP site

New-Item -Path "D:\" -Name "FTProot" -ItemType "directory"

$FTPSiteName = 'Dtek-Training-FTP-Site'

$FTPRootDir = 'D:\FTPRoot'

$FTPPort = 21

New-WebFtpSite -Name $FTPSiteName -Port $FTPPort -PhysicalPath $FTPRootDir

& netsh advfirewall set allprofiles state off

Restart-Service -Name mpssvc 
