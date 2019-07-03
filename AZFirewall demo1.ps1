
<#
	.SYNOPSIS
   AZFirewall demo1.ps1
   https://docs.microsoft.com/en-gb/azure/firewall/tutorial-firewall-deploy-portal
   
	.DESCRIPTION
	 Creates a virtual network with 3 subnets
     
    Creates VM Nics and binds NSG's
    Creates 2 VM's in the Backend Subnet
    
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
 
 #-------Azure Cert Login - must have preperaed a cert earlier ------
 $MyCertSubject="Test-sub-CertLogin-SPN1"
 Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID '2c7088a0-ce06-4058-ac46-5d9111bbea41' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'
 
 
 #User credentials for Server VMs
 $securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
 $cred1 = New-Object System.Management.Automation.PSCredential ("NETSECvmADMIN", $securePassword)
 
 #-------ENVIROMENT ------
 clear-host
 Set-StrictMode -Version 3
 # Variables for common values
 $rgName='DTEKTEST-WE-NETSEC-FW-WORKSHOP'
 $location='westeurope'
 
 
 New-AzResourceGroup -Name $rgName -Location $location

#---------Keyvault Version------

#$AdminUserName = 'DTEKAZADMIN'
#$AdminPassName = 'DTEK-SRV-ADMIN-PASSWORD'
#$AdminUser = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $AdminUserName
#$AdminPass = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $AdminPassName
#$cred2 = New-Object System.Management.Automation.PSCredential ("$($AdminUser.SecretValueText)", $AdminPass.SecretValue)

#Create Vnet
Write-Host " Creating Virtual Networks and subnets"
$VnetName=$rgName +"-VnetFWdemo"
New-AzVirtualNetwork -ResourceGroupName $rgName -Name $VnetName -AddressPrefix 192.168.0.0/16 -Location $Location

#Configure subnets
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $VnetName
Add-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.1.0/24
Add-AzVirtualNetworkSubnetConfig -Name JumpBoxSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24
Add-AzVirtualNetworkSubnetConfig -Name ServersSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.2.0/24
Set-AzVirtualNetwork -VirtualNetwork $vnet

#create Public IP for jumpbox and LB
$LBPipName = $rgName + "-PublicIP"
$LBPip = New-AzPublicIpAddress -Name $LBPipName  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
$JumpBoxpip = New-AzPublicIpAddress -Name "JumpHostPublicIP"  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Basic

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

# Create a network security group
$NsgName = $rgName+"-NSG"
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $Location -Name $NsgName -SecurityRules $nsgRuleRDP

Write-Host " Creating Jumpbox VM"
#Create jumpbox
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $VnetName
$JumpBoxSubnetId = $vnet.Subnets[1].Id
# Create a virtual network card and associate with jumpbox public IP address
$JumpBoxNic = New-AzNetworkInterface -Name JumpBoxNic -ResourceGroupName $rgName -Location $Location -SubnetId $JumpBoxSubnetId -PublicIpAddressId $JumpBoxpip.Id -NetworkSecurityGroupId $nsg.Id
$JumpBoxConfig = New-AzVMConfig -VMName JumpBox -VMSize Standard_B2ms| Set-AzVMOperatingSystem -Windows -ComputerName JumpBox -Credential $cred1 | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Version latest | Add-AzVMNetworkInterface -Id $JumpBoxNic.Id
New-AzVM -ResourceGroupName $rgName -Location $Location -VM $JumpBoxConfig

#Create Server VM
Write-Host " Creating Server VM"
$ServersSubnetId = $vnet.Subnets[2].Id
$ServerVmNic = New-AzNetworkInterface -Name ServerVmNic -ResourceGroupName $rgName -Location $Location -SubnetId $ServersSubnetId
$ServerVmConfig = New-AzVMConfig -VMName ServerVm -VMSize Standard_B1ms | Set-AzVMOperatingSystem -Windows -ComputerName ServerVm -Credential $cred1 | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Version latest | Add-AzVMNetworkInterface -Id $ServerVmNic.Id
New-AzVM -ResourceGroupName $rgName -Location $Location -VM $ServerVmConfig

#Create AZFW
Write-Host " Creating Azure FireWall"
$GatewayName = $rgName + "-Azfw"
$Azfw = New-AzFirewall -Name $GatewayName -ResourceGroupName $rgName -Location $Location -VirtualNetworkName $vnet.Name -PublicIpName $LBPip.Name

#Add a rule to allow *microsoft.com
Write-Host " Adding rules and UDR"
$Azfw = Get-AzFirewall -ResourceGroupName $rgName
$Rule = New-AzFirewallApplicationRule -Name R1 -Protocol "http:80","https:443" -TargetFqdn "*microsoft.com"
$RuleCollection = New-AzFirewallApplicationRuleCollection -Name RC1 -Priority 100 -Rule $Rule -ActionType "Allow"
$Azfw.ApplicationRuleCollections = $RuleCollection
Set-AzFirewall -AzureFirewall $Azfw

#Create UDR rule
$Azfw = Get-AzFirewall -ResourceGroupName $rgName
$AzfwRouteName = $rgName + "-AzfwRoute"
$AzfwRouteTableName = $rgName + "-AzfwRouteTable"
$IlbCA = $Azfw.IpConfigurations[0].PrivateIPAddress
$AzfwRoute = New-AzRouteConfig -Name $AzfwRouteName -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $IlbCA
$AzfwRouteTable = New-AzRouteTable -Name $AzfwRouteTableName -ResourceGroupName $rgName -location $Location -Route $AzfwRoute

#associate to Servers Subnet
$vnet.Subnets[2].RouteTable = $AzfwRouteTable
Set-AzVirtualNetwork -VirtualNetwork $vnet