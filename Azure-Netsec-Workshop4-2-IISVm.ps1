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
 Clear-host
 write-host "Authenticating to AZURE "
 $MyCertSubject="Test-sub-CertLogin-SPN1"
 Login-AzurebyCert -Certsubject $MyCertSubject -ApplicationID '2c7088a0-ce06-4058-ac46-5d9111bbea41' -TenantId '92832cfc-349a-4b12-af77-765b6f10b51f'
 
 
 #User credentials for Server VMs
 $securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
 $cred = New-Object System.Management.Automation.PSCredential ("NETSECvmADMIN", $securePassword)
 
 #-------ENVIROMENT ------
 Set-StrictMode -Version 3
# Variables for common values
clear-host
$rgname= 'DTEKTEST-WE-NETSEC-IIS-Workshop'
$rgName1='DTEKTEST-WE-NETSEC-NG-Workshop'
$location='westeurope'

New-AzResourceGroup -Name $rgName -Location $location

$vnet = get-AzVirtualNetwork -ResourceGroupName $rgName1 -Name 'DTEKTEST-VNet2' 
$snet=$vnet.Subnets[2]
$SN=$snet.Name
Write-host "Selected Hosting Subnet Is: $sn"

# Create Variables for 2 VM's
write-host "Creating IPS and NIC's for LAB VM's"

$servName1 ="NETSEC-WEBSRV1"
$servName2 ="NETSEC-WEBSRV2"
  
$PipName1 =  "PIP-" + $servName1 
$PipName2 =  "PIP-" + $servName2
  
$PiP1 = New-AzPublicIpAddress -Name $PipName1  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
$PiP2 = New-AzPublicIpAddress -Name $PipName2  -ResourceGroupName $rgName -Location $Location -AllocationMethod Static -Sku Standard
  
$Nic1 = "NIC-" + $servName1
$Nic2 = "NIC-" + $servName2

$nic1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic1 -PublicIpAddress $pip1  -Subnet $vnet.Subnets[2]
$nic2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name $Nic2 -PublicIpAddress $pip2  -Subnet $vnet.Subnets[2]

$vmConfig3 = New-AzVMConfig -VMName $servName1 -VMSize 'Standard_B1ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName1 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic1.Id
$vmConfig4 = New-AzVMConfig -VMName $servName2 -VMSize 'Standard_B1ms' | Set-AzVMOperatingSystem -Windows -ComputerName $servName2 -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nic2.Id

write-host "Creating------ $servName1 "
$vm1 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig3
write-host "Creating------ $servName2 "
$vm2 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig4



# Install IIS using DSC
$PublicSettings1 = '{"ModulesURL":"https://github.com/Azure/azure-quickstart-templates/raw/master/dsc-extension-iis-server-windows-vm/ContosoWebsite.ps1.zip", "configurationFunction": "ContosoWebsite.ps1\\ContosoWebsite", "Properties": {"MachineName": "NETSEC-WEBSRV1"} }'
$PublicSettings2 = '{"ModulesURL":"https://github.com/Azure/azure-quickstart-templates/raw/master/dsc-extension-iis-server-windows-vm/ContosoWebsite.ps1.zip", "configurationFunction": "ContosoWebsite.ps1\\ContosoWebsite", "Properties": {"MachineName": "NETSEC-WEBSRV2"} }'

write-host "Installing IIS and ASP on ------ $servName1"
Set-AzVMExtension -ExtensionName "DSC" -ResourceGroupName $rgName -VMName $servName1 -Publisher "Microsoft.Powershell" -ExtensionType "DSC" -TypeHandlerVersion 2.19 -SettingString $PublicSettings1 -Location $location

write-host "Installing IIS and ASP on ------ $servName2"
Set-AzVMExtension -ExtensionName "DSC" -ResourceGroupName $rgName -VMName $servName2 -Publisher "Microsoft.Powershell" -ExtensionType "DSC" -TypeHandlerVersion 2.19 -SettingString $PublicSettings2 -Location $location



  write-host "Configuring OS for------ $servName1 "
  $CustomScriptExtensionProperties1 = @{
    VMName = $servName1
    Name = "ConfigureOS"
    ResourceGroupName = $RGName
    Location = $Location
    FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureIIS-webserver.ps1"
    Run = "ConfigureIIS-webserver.ps1"
  }
  
  Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties1

  
  write-host "Configuring OS for------ $servName2 "
  $CustomScriptExtensionProperties2 = @{
    VMName = $servName2
    Name = "ConfigureOS"
    ResourceGroupName = $RGName
    Location = $Location
    FileUri = "https://raw.githubusercontent.com/DanielPHobbs/DTEK-AZURE-TRAINING/master/ConfigureIIS-webserver.ps1"
    Run = "ConfigureIIS-webserver.ps1"
  }
  
  Set-AzVMCustomScriptExtension @CustomScriptExtensionProperties2
  
  
  write-host "Completed Workshop 2 Lab enviroment "



