Login-AzureRmAccount
 
# Select a subscription
$subscriptionId = (Get-AzureRmSubscription | Out-GridView -Title ‘Select your Azure Subscription:’ -PassThru)
Select-AzureRmSubscription -SubscriptionId $subscriptionId.Id
  
 
# Select a Resource Group
$rgName = (Get-AzureRmResourceGroup | Out-GridView -Title ‘Select your Azure Resource Group:’ -PassThru).ResourceGroupName
 
# Set the NSG name and Azure region
$nsgName = "Trusted-Nsg01"
$location = "West Europe"
$source1 = "8.8.8.8/32"
$source2 = "8.8.4.4/32"
$source3 = "*"
$dest1="3389"
$dest2="443"
$dest3="80"
$tag="blog"

#Below are Sample Rules
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
-SourceAddressPrefix $source1 -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange $dest1

$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule2 -Description "Allow Port" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 101 `
-SourceAddressPrefix $source2 -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange $dest2

$rule3 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule3 -Description "Allow Port" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 103 `
-SourceAddressPrefix $source3 -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange $dest3

$rule4 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule4 -Description "Allow Port" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 104 `
-SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 88 


#applying the Rules
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name $nsgName -SecurityRules $rule1,$rule2,$rule3,$rule4

# Display default and security rules for NSG
 
(Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName).SecurityRules | Select-Object * | Out-GridView
(Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName).DefaultSecurityRules | Select-Object * | Out-GridView

#Remove NSG

#Remove-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName