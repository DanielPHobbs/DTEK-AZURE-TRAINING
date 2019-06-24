
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
$rgName='DTEKTEST-WE-NETSEC-AG-WORKSHOP'
$rgName1='DTEKTEST-WE-NETSEC-Workshop'
$location='westeurope'
$AGname="DTEK-NETSEC-AG1"
$VNET="dtektest-vnet2"
$AG1PIPName="DTEK-NETSEC-AG1-PIP"

New-AzResourceGroup -Name $rgName -Location $location


#-------MAIN ------
# Replace the following URL with a public GitHub repo URL
$gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"
$webappname1="DTEKTEST-WE-NETSEC-WebApp1"
$webappname2="DTEKTEST-WE-NETSEC-WebApp2"
$webappPlan1="DTEKTEST-WE-NETSEC-WebApp-Plan1"

$location="West Europe"


start-sleep 30
write-host "Creating Web App Plan" 

# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappPlan1 -Location $location -ResourceGroupName $rgName -Tier Free

# Create a web app.
Write-host "Creating Web App $webappname1"

$WebApp1=New-AzWebApp -Name $webappname1 -Location $location -AppServicePlan $webappPlan1 -ResourceGroupName $rgName

Write-host "Creating Web App $webappname2"
$WebApp2=New-AzWebApp -Name $webappname2 -Location $location -AppServicePlan $webappPlan1 -ResourceGroupName $rgName

# Configure GitHub deployment from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
    isManualIntegration = "true";
}
Write-host "Dropping content on Web App $webappname1"

Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgName -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname1/web -ApiVersion 2015-08-01 -Force

Write-host "Dropping content on Web App $webappname2"

Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgName -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname2/web -ApiVersion 2015-08-01 -Force


start-sleep 60

Write-host "Creating Application Gateway $AGname"



$AG1pip = New-AzPublicIpAddress -ResourceGroupName $rgName -Location westeurope -Name $AG1PIPName -AllocationMethod Dynamic

# Create IP configurations and frontend port
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName1 -Name $VNET
$subnet=$vnet.Subnets[2]


$gipconfig = New-AzApplicationGatewayIPConfiguration -Name AG1-IPConfig -Subnet $subnet
$fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name AG1-FrontendIPConfig -PublicIPAddress $AG1pip
$frontendport = New-AzApplicationGatewayFrontendPort -Name AG1-FrontendPort -Port 80


#https://4sysops.com/archives/creating-and-configuring-web-apps-behind-an-azure-application-gateway-using-powershell/
# Create the backend pool and settings
[string]$webApp1HN=$WebApp1.HostNames
[string]$webApp2HN=$WebApp2.HostNames

$defaultPool = New-AzApplicationGatewayBackendAddressPool -Name 'AG1GatewayBackendPool' -BackendFqdns $webApp1HN,$webApp2HN
$poolSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name AG1PoolSettings `
  -Port 80 `
  -Protocol Http `
  -CookieBasedAffinity Enabled `
  -RequestTimeout 120 `
  

# Create the default listener and rule
$defaultlistener = New-AzApplicationGatewayHttpListener `
  -Name AG1defaultListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendport
$frontendRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name rule1 `
  -RuleType Basic `
  -HttpListener $defaultlistener `
  -BackendAddressPool $defaultPool `
  -BackendHttpSettings $poolSettings

# Create the application gateway
$sku = New-AzApplicationGatewaySku `
  -Name WAF_Medium `
  -Tier WAF `
  -Capacity 2
$wafConfig = New-AzApplicationGatewayWebApplicationFirewallConfiguration `
  -Enabled $true `
  -FirewallMode "Detection"
$appgw = New-AzApplicationGateway `
  -Name $AGname `
  -ResourceGroupName $rgName `
  -Location $location `
  -BackendAddressPools $defaultPool `
  -BackendHttpSettingsCollection $poolSettings `
  -FrontendIpConfigurations $fipconfig `
  -GatewayIpConfigurations $gipconfig `
  -FrontendPorts $frontendport `
  -HttpListeners $defaultlistener `
  -RequestRoutingRules $frontendRule `
  -Sku $sku `
  -WebApplicationFirewallConfig $wafConfig


  Write-host "Enabling Application Gateway $AGname diagnostics"

  # Create a storage account
$storageAccount = New-AzStorageAccount `
  -ResourceGroupName $rgName  `
  -Name 'dtekworkshopagdiags1' `
  -Location $location `
  -SkuName "Standard_LRS"

# Configure diagnostics
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $rgName `
  -Name $AGname
$store = Get-AzStorageAccount `
  -ResourceGroupName $rgName `
  -Name 'dtekworkshopagdiags1'
Set-AzDiagnosticSetting `
  -ResourceId $appgw.Id `
  -StorageAccountId $store.Id `
  -Category ApplicationGatewayAccessLog, ApplicationGatewayPerformanceLog, ApplicationGatewayFirewallLog `
  -Enabled $true `
  -RetentionEnabled $true `
  -RetentionInDays 30




  <# Not Tested 
#for testing
$rgName='DTEKTEST-WE-NETSEC-AG-WORKSHOP'
$location='westeurope'
$AGname="DTEK-NETSEC-AG1"


$getgw =  Get-AzApplicationGateway -Name $AGname -ResourceGroupName $rgName

# Create the Health probe object 
$match=New-AzApplicationGatewayProbeHealthResponseMatch -StatusCode 200-401
$probe = Add-AzApplicationGatewayProbeConfig -ApplicationGateway $getgw -Name probe01 -Protocol Http -PickHostNameFromBackendHttpSettings -Match $match -Path '/' -Interval 30 -Timeout 120 -UnhealthyThreshold 8

# Set the backend HTTP settings to use the new probe
$getgw = Set-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $getgw -Name $getgw.BackendHttpSettingsCollection.name -Port 80 -Protocol Http -CookieBasedAffinity Disabled -Probe $probe -RequestTimeout 120

# Save the application gateway with the configuration changes
Set-AzApplicationGateway -ApplicationGateway $getgw
#>



# Get the IP address
Get-AzPublicIPAddress -ResourceGroupName $rgName -Name $AG1PIPName

