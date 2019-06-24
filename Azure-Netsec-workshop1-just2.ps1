<#
	.SYNOPSIS
	Azure-Netsec-Workshop-just2.ps1
	
	.DESCRIPTION
	Creates a virtual network with 3 subnets
  Creates NSG's and rules 
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
$cred = New-Object System.Management.Automation.PSCredential ("NETSECvmADMIN", $securePassword)

#-------ENVIROMENT ------
Set-StrictMode -Version 3
# Variables for common values
$rgName='DTEKTEST-WE-NETSEC-NG-Workshop'
$location='westeurope'

clear-host

#-------MAIN ------
# Create a resource group.
New-AzResourceGroup -Name $rgName -Location $location

write-host "Creating Networking "
# Create a virtual network with a front-end subnet and back-end subnet.
$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'DTEKTEST-FRONTEND-SN2' -AddressPrefix '10.1.1.0/24'
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'DTEKTEST-BACKEND-SN2' -AddressPrefix '10.1.2.0/24'
$ag1Subnet = New-AzVirtualNetworkSubnetConfig -Name 'AG1Subnet' -AddressPrefix '10.1.3.0/28'


# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$nsgRuleFTP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Outbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 20-21 -Access deny


$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'DTEKTEST-VNet2' -AddressPrefix '10.1.0.0/16' -Location $location -Subnet $besubnet,$fesubnet,$ag1Subnet

write-host "Creating NSG's "
# Create a network security group for the front-end subnet.
$nsgfe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location -Name 'DTEKTEST-Nsg-FrontEnd' -SecurityRules $nsgRuleRDP
start-sleep 30
# Associate the front-end NSG to the front-end subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'DTEKTEST-FRONTEND-SN2' -AddressPrefix '10.1.1.0/24' -NetworkSecurityGroup $nsgfe | Set-AzureRmVirtualNetwork

# Create a network security group for the Back-end subnet.
$nsgBe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location -Name 'DTEKTEST-Nsg-BackEnd' -SecurityRules $nsgRuleRDP,$nsgRuleFTP
start-sleep 30
# Associate the Back-end NSG to the Back-end subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'DTEKTEST-BACKEND-SN2' -AddressPrefix '10.1.2.0/24' -NetworkSecurityGroup $nsgBe | Set-AzureRmVirtualNetwork


write-host "Completed Creating NSG's "

# Create Variables for 5 VM's

  $servNameMaster="NETSEC-M1-SRV"
  $servName1="NETSEC-WS-SRV1"
  $servName2="NETSEC-WS-SRV2"
  
  $PipNameMaster =  "PublicIP-" + $servNameMaster
  $PipName1 =  "PublicIP-" + $servName1
  $PipName2 =  "PublicIP-" + $servName2
  
  $PiPMaster = New-AzPublicIpAddress -Name $PipNamemaster  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP1 = New-AzPublicIpAddress -Name $PipName1  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP2 = New-AzPublicIpAddress -Name $PipName2  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  
 

  # Create a network security group

$NsgName1 = "NSG-" + $servName1
$NsgName2 = "NSG-" + $servName2

$nsg1 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName1 -SecurityRules $nsgRuleRDP
$nsg2 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName2 -SecurityRules $nsgRuleRDP


$NicMaster = "NIC-" + $servNameMaster
$Nic1 = "NIC-" + $servName1
$Nic2 = "NIC-" + $servName2

$nicMaster = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $NicMaster -PublicIpAddress $PiPMaster -Subnet $vnet.Subnets[1]
$nic1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic1 -PublicIpAddress $pip1 -NetworkSecurityGroup $nsg1 -Subnet $vnet.Subnets[0]
$nic2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic2 -PublicIpAddress $pip2 -NetworkSecurityGroup $nsg2 -Subnet $vnet.Subnets[0]


  
 # Create 3 Servers config files
write-host "Creating 3 VM's for Workhop 1"
$vmConfigMaster = New-AzVMConfig -VMName $servNameMaster -VMSize 'Standard_B1ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servNameMaster -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicMaster.Id
$vmConfig1 = New-AzVMConfig -VMName $servName1 -VMSize 'Standard_B1ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName1 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic1.Id
$vmConfig2 = New-AzVMConfig -VMName $servName2 -VMSize 'Standard_B1ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName2 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic2.Id


write-host "Creating------ $servNameMaster "
$vmMaster = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfigMaster
write-host "Creating------ $servName1 "
$vm1 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig1
#write-host "Creating------ $servName2 "
#$vm2 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig2


#-------------- POST VM Configuration Install FTP ------
write-host "Configuring FTP for------ $servNameMaster "
$CustomScriptExtensionProperties1 = @{
  VMName = $servNameMaster
  Name = "InstallFTP"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/Install-Ftp.ps1"
  Run = "Install-FTP.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties1


write-host "Configuring OS for------ $servName1 "
$CustomScriptExtensionProperties3 = @{
  VMName = $servName1
  Name = "ConfigureOS"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureOS.ps1"
  Run = "ConfigureOS.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties3

write-host "Completed Workshop 1 Lab enviroment "





