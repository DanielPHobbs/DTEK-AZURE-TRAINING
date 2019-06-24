# Replace the following URL with a public GitHub repo URL
$gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"
$webappname1="DTEKTEST-WE-NETSEC-WebApp1"
$webappname1="DTEKTEST-WE-NETSEC-WebApp2"
$location="West Europe"

$rgName='DTEKTEST-WE-NETSEC-Workshop'


# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappname1 -Location $location -ResourceGroupName $rgName -Tier Free

# Create a web app.
New-AzWebApp -Name $webappname1 -Location $location -AppServicePlan $webappname1 -ResourceGroupName $rgName
New-AzWebApp -Name $webappname2 -Location $location -AppServicePlan $webappname1 -ResourceGroupName $rgName

# Configure GitHub deployment from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
    isManualIntegration = "true";
}
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgName -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname1/web -ApiVersion 2015-08-01 -Force
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rgName -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname2/web -ApiVersion 2015-08-01 -Force
