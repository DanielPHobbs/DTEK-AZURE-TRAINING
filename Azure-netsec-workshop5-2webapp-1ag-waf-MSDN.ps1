
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


$MyCertSubject="MSDN-sub-CertLogin-SPN"
Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID 'fb7090c0-5b01-4e9e-96c7-29adf989d56f' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'
Get-AzContext

#-------ENVIROMENT ------
clear-host
Set-StrictMode -Version 3
$rgName='MSDN-PAAS-WEB-APPS-RG1'
$rgName1='DTEKSVRAccessRG1'
$VNET="DTEK-PRODUCTION-Vnet2"
$location='northeurope'
$AGname="DTEK-MSDN-AG1"

$AG1PIPName="DTEK-MSDN-AG1-PIP"

#-------MAIN ------


$webappname1="DTEK-MSDN-WebApp1"
$webappname2="DTEK-MSDN-WebApp2"
$webappPlan1="DTEK-MSDN-WebApp-Plan1"




start-sleep 30
write-host "Creating Web App Plan" 

# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappPlan1 -Location $location -ResourceGroupName $rgName -Tier Free

# Create a web app.
Write-host "Creating Web App $webappname1"

$WebApp1=New-AzWebApp -Name $webappname1 -Location $location -AppServicePlan $webappPlan1 -ResourceGroupName $rgName

Write-host "Creating Web App $webappname2"
$WebApp2=New-AzWebApp -Name $webappname2 -Location $location -AppServicePlan $webappPlan1 -ResourceGroupName $rgName


start-sleep 60

Write-host "Creating Application Gateway $AGname"

$AG1pip = New-AzPublicIpAddress -ResourceGroupName $rgName -Location $location -Name $AG1PIPName -AllocationMethod Dynamic

# Create IP configurations and frontend port


$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName1 -Name $VNET
$subnet=$vnet.Subnets[1]
$SubnetName=$subnet.Name
Write-host "AG1 subnet is $SubnetName"

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
  -Name 'dtekmsdnag1diags' `
  -Location $location `
  -SkuName "Standard_LRS"

# Configure diagnostics
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $rgName `
  -Name $AGname
$store = Get-AzStorageAccount `
  -ResourceGroupName $rgName `
  -Name 'dtekmsdnag1diags'
Set-AzDiagnosticSetting `
  -ResourceId $appgw.Id `
  -StorageAccountId $store.Id `
  -Category ApplicationGatewayAccessLog, ApplicationGatewayPerformanceLog, ApplicationGatewayFirewallLog `
  -Enabled $true `
  -RetentionEnabled $true `
  -RetentionInDays 30

<# Not Tested 
# Load the application gateway resource into a PowerShell variable by using Get-AzApplicationGateway.
$getgw =  Get-AzApplicationGateway -Name $AGname -ResourceGroupName $rgName
# Create the probe object that will check health at http://contoso.com/path/path.htm
$probe = Add-AzApplicationGatewayProbeConfig -ApplicationGateway $getgw -Name probe01 -Protocol Http -HostName 'contoso.com' -Path '/path/custompath.htm' -Interval 30 -Timeout 120 -UnhealthyThreshold 8
# Set the backend HTTP settings to use the new probe
$getgw = Set-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $getgw -Name $getgw.BackendHttpSettingsCollection.name -Port 80 -Protocol Http -CookieBasedAffinity Disabled -Probe $probe -RequestTimeout 120
# Save the application gateway with the configuration changes
Set-AzApplicationGateway -ApplicationGateway $getgw
#>



# Get the IP address
Get-AzPublicIPAddress -ResourceGroupName $rgName -Name $AG1PIPName

