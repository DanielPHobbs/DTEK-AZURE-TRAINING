function Login-AzurebyCert
{
   Param (
   [String] $CertSubject,
   [String] $ApplicationId,
   [String] $TenantId
   )
   
   $Thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $CertSubject }).Thumbprint
   Login-AZAccount -ServicePrincipal -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -TenantId $TenantId | Out-Null
}


$MyCertSubject='Test-sub-CertLogin-SPN1'
Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID '907ab3d0-8f67-4f7d-b986-d37185433b33' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'

$locations = Get-AzLocation | Where-Object {$_.location -in "westeurope"}

foreach ($l in $locations)
    {
        $vmSizes += Get-AzVmSize -Location $l.Location | Select-Object @{Name="LocationDisplayName"; Expression = {$l.DisplayName}},@{Name="Location"; Expression = {$l.Location}},Name,NumberOfCores,MemoryInMB,MaxDataDiskCount,OSDiskSizeInMB,ResourceDiskSizeInMB
    }
 
#$vmSizes | Export-Csv -Path "AzureVmSizes.csv" -NoTypeInformation
$vmSizes | ft