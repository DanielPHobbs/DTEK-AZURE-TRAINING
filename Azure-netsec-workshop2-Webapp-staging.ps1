# Replace the following URL with a public GitHub repo URL
$gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"
$webappname="DTEKTEST-WE-NETSEC-WebApp1"
$location="West Europe"


$rgName='DTEKTEST-WE-NETSEC-Workshop'

# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappname -Location $location -ResourceGroupName $rgName -Tier Free

# Create a web app.
New-AzWebApp -Name $webappname -Location $location -AppServicePlan $webappname -ResourceGroupName $rgName

# Upgrade App Service plan to Standard tier (minimum required by deployment slots)
Set-AzAppServicePlan -Name $webappname -ResourceGroupName $rgName -Tier Standard

#Create a deployment slot with the name "staging".
New-AzWebAppSlot -Name $webappname -ResourceGroupName $rgName -Slot staging

# Configure GitHub deployment to the staging slot from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgName `
-ResourceType Microsoft.Web/sites/slots/sourcecontrols `
-ResourceName $webappname/staging/web -ApiVersion 2015-08-01 -Force

# Swap the verified/warmed up staging slot into production.
Switch-AzWebAppSlot -Name $webappname -ResourceGroupName $rgName `
-SourceSlotName staging -DestinationSlotName production