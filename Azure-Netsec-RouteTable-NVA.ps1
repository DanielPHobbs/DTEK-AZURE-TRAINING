

<#
	.SYNOPSIS
   AZFirewall demo1.ps1
   https://docs.microsoft.com/en-us/azure/virtual-network/scripts/virtual-network-powershell-sample-route-traffic-through-nva
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
 $rgName='DTEKTEST-WE-NETSEC-NVA-WORKSHOP'
 $location='westeurope'
 
 
 New-AzResourceGroup -Name $rgName -Location $location

#User credentials for Server VMs
$securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("NETSECvmADMIN", $securePassword)


# Create a virtual network, a front-end subnet, a back-end subnet, and a DMZ subnet.
$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix 10.0.1.0/24
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix 10.0.2.0/24
$dmzsubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-Dmz' -AddressPrefix 10.0.0.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix 10.0.0.0/16 `
  -Location $location -Subnet $fesubnet, $besubnet, $dmzsubnet



# Create NSG rules to allow HTTP & HTTPS traffic inbound.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-ALL' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTPS-All' -Description 'Allow HTTPS' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 443

# Create a network security group (NSG) for the front-end subnet.
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
-Name 'MyNsg-FrontEnd' -SecurityRules $rule1,$rule2

# Associate the front-end NSG to the front-end subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsg

# Create a public IP address for the firewall VM.
$publicip = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIP-Firewall' `
  -location $location -AllocationMethod Dynamic

# Create a NIC for the firewall VM and enable IP forwarding.
$nicVMFW = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'MyNic-Firewall' `
  -PublicIpAddress $publicip -Subnet $vnet.Subnets[2] -EnableIPForwarding

#Create a firewall VM to accept all traffic between the front and back-end subnets.
$vmConfig = New-AzVMConfig -VMName 'MyVm-Firewall' -VMSize Standard_DS2 | `
    Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm-Firewall' -Credential $cred | `
    Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nicVMFW.Id
    
$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Create a route for traffic from the front-end to the back-end subnet through the firewall VM.
$route = New-AzRouteConfig -Name 'RouteToBackEnd' -AddressPrefix 10.0.2.0/24 `
  -NextHopType VirtualAppliance -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIpAddress

# Create a route for traffic from the front-end subnet to the Internet through the firewall VM.
$route2 = New-AzRouteConfig -Name 'RouteToInternet' -AddressPrefix 0.0.0.0/0 `
  -NextHopType VirtualAppliance -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIpAddress

# Create route table for the FrontEnd subnet.
$routeTableFEtoBE = New-AzRouteTable -Name 'MyRouteTable-FrontEnd' -ResourceGroupName $rgName `
  -location $location -Route $route, $route2

# Associate the route table to the FrontEnd subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' -AddressPrefix 10.0.1.0/24 `
  -NetworkSecurityGroup $nsg -RouteTable $routeTableFEtoBE
  
# Create a route for traffic from the back-end subnet to the front-end subnet through the firewall VM.
$route = New-AzRouteConfig -Name 'RouteToFrontEnd' -AddressPrefix '10.0.1.0/24' -NextHopType VirtualAppliance `
  -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIPAddress

# Create a route for traffic from the back-end subnet to the Internet through the firewall VM.
$route2 = New-AzRouteConfig -Name 'RouteToInternet' -AddressPrefix '0.0.0.0/0' -NextHopType VirtualAppliance `
  -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIPAddress

# Create route table for the BackEnd subnet.
$routeTableBE = New-AzRouteTable -Name 'MyRouteTable-BackEnd' -ResourceGroupName $rgName `
  -location $location -Route $route, $route2

# Associate the route table to the BackEnd subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix '10.0.2.0/24' -RouteTable $routeTableBE