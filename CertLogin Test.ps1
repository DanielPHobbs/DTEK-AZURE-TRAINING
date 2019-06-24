
function Login-AzurebyCert
{
   Param (
   [String] $CertSubject,
   [String] $ApplicationId,
   [String] $TenantId
   )
   
   $Thumbprint = Get-ChildItem -Path cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $MyCertSubject} |Select-Object -ExpandProperty Thumbprint

   #Thumbprint.GetType()
   Login-AZAccount -ServicePrincipal -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -TenantId $TenantId | Out-Null
}


$MyCertSubject="Test-sub-CertLogin-SPN1"

Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID '2c7088a0-ce06-4058-ac46-5d9111bbea41' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'

Get-AzResourceGroup

#$MyCertSubject="Test-sub-CertLogin-SPN1"
#$Thumbprint = Get-ChildItem -Path cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $MyCertSubject} |Select-Object -ExpandProperty Thumbprint
#Write-Host -Object "My thumbprint is: $Thumbprint";