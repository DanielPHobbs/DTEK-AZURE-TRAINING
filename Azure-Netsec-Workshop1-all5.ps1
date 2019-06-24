
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
Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID '907ab3d0-8f67-4f7d-b986-d37185433b33' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'


#User credentials for Server VMs
$securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("NETSECvmADMIN", $securePassword)


# Variables for common values
$rgName='DTEKTEST-WE-NETSEC-Workshop'
$location='westeurope'


# Create a resource group.
New-AzResourceGroup -Name $rgName -Location $location

write-host "Creating NSG's "

# Create a virtual network with a front-end subnet and back-end subnet.
$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'DTEKTEST-FRONTEND-SN2' -AddressPrefix '10.1.1.0/24'
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'DTEKTEST-BACKEND-SN2' -AddressPrefix '10.1.2.0/24'
$ag1Subnet = New-AzVirtualNetworkSubnetConfig -Name 'AG1Subnet' -AddressPrefix '10.1.3.0/28'

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$nsgRuleFTP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Outbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 20-21 -Access deny

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'DTEKTEST-VNet2' -AddressPrefix '10.1.0.0/16' -Location $location -Subnet $besubnet,$fesubnet,$ag1Subnet

# Create a network security group for the front-end subnet and associate.
$nsgfe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location -Name 'DTEKTEST-Nsg-FrontEnd' 
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'DTEKTEST-FRONTEND-SN2' -AddressPrefix '10.1.1.0/24' -NetworkSecurityGroup $nsgfe

# Create a network security group for the Back-end subnet and associate.
$nsgBe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location -Name 'DTEKTEST-Nsg-BackEnd' 
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'DTEKTEST-BACKEND-SN2' -AddressPrefix '10.1.2.0/24' -NetworkSecurityGroup $nsgBe,$nsgRuleFTP

write-host "Completed Creating NSG's "

# Create Variables for 5 VM's
  $servNameMaster="NETSEC-M1-SRV"
  $servName1="NETSEC-WS-SRV1"
  $servName2="NETSEC-WS-SRV2"
  $servName3="NETSEC-WS-SRV3"
  $servName4="NETSEC-WS-SRV4"
  $servName5="NETSEC-WS-SRV5"

  $PipNameMaster =  "PublicIP-" + $servNameMaster
  $PipName1 =  "PublicIP-" + $servName1 
  $PipName2 =  "PublicIP-" + $servName2
  $PipName3 =  "PublicIP-" + $servName3
  $PipName4 =  "PublicIP-" + $servName4
  $PipName5 =  "PublicIP-" + $servName5

  $PiPMaster = New-AzPublicIpAddress -Name $PipNamemaster  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP1 = New-AzPublicIpAddress -Name $PipName1  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP2 = New-AzPublicIpAddress -Name $PipName2  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP3 = New-AzPublicIpAddress -Name $PipName3  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP4 = New-AzPublicIpAddress -Name $PipName4  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  $PiP5 = New-AzPublicIpAddress -Name $PipName5  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard

 # Create an inbound network security group rule for port 3389
 $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

  # Create a network security group

$NsgName1 = "NSG-" + $servName1
$NsgName2 = "NSG-" + $servName2
$NsgName3 = "NSG-" + $servName3
$NsgName4 = "NSG-" + $servName4
$NsgName5 = "NSG-" + $servName5

$nsg1 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName1 -SecurityRules $nsgRuleRDP
$nsg2 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName2 -SecurityRules $nsgRuleRDP
$nsg3 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName3 -SecurityRules $nsgRuleRDP
$nsg4 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName4 -SecurityRules $nsgRuleRDP
$nsg5 = New-AzNetworkSecurityGroup -ResourceGroupName $RGname -Location $Location -Name $NsgName5 -SecurityRules $nsgRuleRDP

$NicMaster = "NIC-" + $servNameMaster
$Nic1 = "NIC-" + $servName1
$Nic2 = "NIC-" + $servName2
$Nic3 = "NIC-" + $servName3
$Nic4 = "NIC-" + $servName4
$Nic5 = "NIC-" + $servName5

$nicMaster = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $NicMaster -PublicIpAddress $PiPMaster -Subnet $vnet.Subnets[1]
$nic1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic1 -PublicIpAddress $pip1 -NetworkSecurityGroup $nsg1 -Subnet $vnet.Subnets[0]
$nic2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic2 -PublicIpAddress $pip2 -NetworkSecurityGroup $nsg2 -Subnet $vnet.Subnets[0]
$nic3 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic3 -PublicIpAddress $pip3 -NetworkSecurityGroup $nsg3 -Subnet $vnet.Subnets[0]
$nic4 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic4 -PublicIpAddress $PiP4 -NetworkSecurityGroup $nsg4 -Subnet $vnet.Subnets[0]
$nic5 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic5 -PublicIpAddress $pip5 -NetworkSecurityGroup $nsg5 -Subnet $vnet.Subnets[0]

 # Create 5 Servers config files

 write-host "Creating 6 VM's for Workhop 1"
$vmConfigMaster = New-AzVMConfig -VMName $servNameMaster -VMSize 'Standard_B1ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servNameMaster -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicMaster.Id
$vmConfig1 = New-AzVMConfig -VMName $servName1 -VMSize 'Standard_B2ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName1 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic1.Id
$vmConfig2 = New-AzVMConfig -VMName $servName2 -VMSize 'Standard_B2ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName2 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic2.Id
$vmConfig3 = New-AzVMConfig -VMName $servName3 -VMSize 'Standard_B2ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName3 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic3.Id
$vmConfig4 = New-AzVMConfig -VMName $servName4 -VMSize 'Standard_B2ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName4 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic4.Id
$vmConfig5 = New-AzVMConfig -VMName $servName5 -VMSize 'Standard_B2ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName5 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic5.Id

write-host "Creating------ $servNameMaster "
$vmMaster = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfigMaster
write-host "Creating------ $servName1 "
$vm1 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig1
write-host "Creating------ $servName2 "
$vm2 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig2
write-host "Creating------ $servName3 "
$vm3 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig3
write-host "Creating------ $servName4 "
$vm4 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig4
write-host "Creating------ $servName5 "
$vm5 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig5

#-------------- POST VM Configuration Install FTP ------
write-host "Configuring FTP for------ $servNameMaster "
$CustomScriptExtensionPropertiesM = @{
  VMName = $servNameMaster
  Name = "InstallFTP"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/Install-Ftp.ps1"
  Run = "Install-FTP.ps1"
}
Set-AzVMCustomScriptExtension @CustomScriptExtensionPropertiesM

write-host "Configuring OS for------ $servName1 "
$CustomScriptExtensionProperties1 = @{
  VMName = $servName1
  Name = "ConfigureOS"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureOS.ps1"
  Run = "ConfigureOS.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties1


write-host "Configuring OS for------ $servName2 "
$CustomScriptExtensionProperties2 = @{
  VMName = $servName2
  Name = "ConfigureOS"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureOS.ps1"
  Run = "ConfigureOS.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties2

write-host "Configuring OS for------ $servName3 "
$CustomScriptExtensionProperties3 = @{
  VMName = $servName3
  Name = "ConfigureOS"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureOS.ps1"
  Run = "ConfigureOS.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties3

write-host "Configuring OS for------ $servName4 "
$CustomScriptExtensionProperties3 = @{
  VMName = $servName4
  Name = "ConfigureOS"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureOS.ps1"
  Run = "ConfigureOS.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties4

write-host "Configuring OS for------ $servName5 "
$CustomScriptExtensionProperties5 = @{
  VMName = $servName5
  Name = "ConfigureOS"
  ResourceGroupName = $RGName
  Location = $Location
  FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureOS.ps1"
  Run = "ConfigureOS.ps1"
}

Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties5

write-host "Completed Workshop 1 Lab enviroment "


