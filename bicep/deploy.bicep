targetScope = 'subscription'

@description('The name of the resource group')
param resourceGroupName string = 'rg-dotnet-app-${uniqueString(subscription().subscriptionId)}'

@description('The location for the resource group')
param location string = 'East US'

@description('The name of the web app')
param webAppName string = 'webapp-dotnet-${uniqueString(subscription().subscriptionId)}'

@description('The SKU of App Service Plan (F1 = Free tier)')
@allowed([
  'F1'
  'D1'
  'B1'
])
param sku string = 'F1'

@description('The .NET version')
param dotnetVersion string = 'v8.0'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

// Deploy the main infrastructure
module appService 'main.bicep' = {
  scope: resourceGroup
  name: 'appServiceDeployment'
  params: {
    webAppName: webAppName
    sku: sku
    location: location
    dotnetVersion: dotnetVersion
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output webAppName string = appService.outputs.webAppName
output webAppUrl string = appService.outputs.webAppUrl
