<#
https://4sysops.com/archives/creating-and-configuring-web-apps-behind-an-azure-application-gateway-using-powershell/
https://docs.microsoft.com/en-us/azure/application-gateway/scripts/create-vmss-waf-powershell
	.SYNOPSIS
	Azure-Netsec-Workshop4-2webapp-1ag.ps1
	
	.DESCRIPTION
	Create 2 Web Apps 
    Creates an Application gateway
    
    
	.INPUTS
    None
    
    .OUTPUTS 
    None
	
	.NOTES
	Version: 1.0
	Author: Daniel Hobbs
	Creation Date: 06062019
	Purpose/Change: Initial script development
	
	.EXAMPLE
	
    #>

#-------FUNCTIONS ------  
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


$MyCertSubject="Test-sub-CertLogin-SPN1"
Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID '2c7088a0-ce06-4058-ac46-5d9111bbea41' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'

#-------ENVIROMENT ------
clear-host
Set-StrictMode -Version 3

$rgName1='DTEKTEST-WE-NETSEC-NG-Workshop'
$rgName2='DTEKTEST-WE-NETSEC-IIS-WORKSHOP'
$rgName3='DTEKTEST-WE-NETSEC-AG-WORKSHOP'
$rgName4='DTEKTEST-WE-NETSEC-FW-WORKSHOP'

$location='westeurope'

#does rg name exist 

Get-AzureRmResourceGroup -Name $rgName4 -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    Write-Host "Resource group $rgName4 does not exist"
}
else
{
Write-Host "Deleting Resource group $rgName4"
 $IsDelete = Remove-AzResourceGroup -Name $rgName4 -Force
 if($IsDelete -eq 'True')
 {Write-Host "Resource group $rgName4 deleted successfully"}
}

Get-AzureRmResourceGroup -Name $rgName3 -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    Write-Host "Resource group $rgName3 does not exist"
}
else
{
Write-Host "Deleting Resource group $rgName3"
 $IsDelete = Remove-AzResourceGroup -Name $rgName3 -Force
 if($IsDelete -eq 'True')
 {Write-Host "Resource group $rgName3 deleted successfully"}
}

Get-AzureRmResourceGroup -Name $rgName2 -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    Write-Host "Resource group $rgName2 does not exist"
}
else
{
Write-Host "Deleting Resource group $rgName2"
 $IsDelete = Remove-AzResourceGroup -Name $rgName2 -Force
 if($IsDelete -eq 'True')
 {Write-Host "Resource group $rgName2 deleted successfully"}
}
 
Get-AzureRmResourceGroup -Name $rgName1 -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    Write-Host "Resource group $rgName1 does not exist"
}
else
{
Write-Host "Deleting Resource group $rgName1"
 $IsDelete = Remove-AzResourceGroup -Name $rgName1 -Force
 if($IsDelete -eq 'True')
 {Write-Host "Resource group $rgName1 deleted successfully"}
}
 