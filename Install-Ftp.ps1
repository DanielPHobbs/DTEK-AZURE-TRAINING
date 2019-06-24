# Install the Windows feature for FTP
Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
Install-WindowsFeature Web-Server -IncludeAllSubFeature  IncludeManagementTools
Import-Module WebAdministration
# Create the FTP site
$FTPSiteName = 'Default FTP Site'
$FTPRootDir = 'C:\FTPRoot'
$FTPPort = 21
New-WebFtpSite -Name $FTPSiteName -Port $FTPPort -PhysicalPath $FTPRootDir