
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
$rgName='DTEKTRAINING-RG1'
$location='westeurope'


New-AzResourceGroup -Name $rgName -Location $location


#-------MAIN ------

$webappname1="DTEKTRAINING-WebApp1"

$webappPlan1="DTEKTEST-WE-NETSEC-WebApp-Plan1"

$location="West Europe"


start-sleep 30
write-host "Creating Web App Plan" 

# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappPlan1 -Location $location -ResourceGroupName $rgName -Tier Free

# Create a web app.
Write-host "Creating Web App $webappname1"

$WebApp1=New-AzWebApp -Name $webappname1 -Location $location -AppServicePlan $webappPlan1 -ResourceGroupName $rgName



$gittoken="<replace-with-a-GitHub-access-token>"
$gitrepo="https://github.com/DanielPHobbs/DTEK-AZURE-TRAINING/tree/master/app-service-web-dotnet-get-started-master"

Write-host "Dropping content on Web App $webappname1"

#https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line
#https://docs.microsoft.com/en-us/azure/app-service/scripts/powershell-continuous-deployment-github

# SET GitHub
$PropertiesObject = @{
    token = $gittoken;
}
Set-AzResource -PropertyObject $PropertiesObject `
-ResourceId /providers/Microsoft.Web/sourcecontrols/GitHub -ApiVersion 2015-08-01 -Force

# Configure GitHub deployment from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgName `
-ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname1/web `
-ApiVersion 2015-08-01 -Force