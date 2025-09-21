@description('The name of the web app that you wish to create.')
param webAppName string = 'webApp-${uniqueString(resourceGroup().id)}'

@description('The SKU of App Service Plan.')
@allowed([
  'F1'
  'D1'
  'B1'
])
param sku string = 'F1'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The .NET Framework version.')
@allowed([
  'v6.0'
  'v7.0'
  'v8.0'
])
param dotnetVersion string = 'v8.0'

@description('The runtime stack of the app.')
param linuxFxVersion string = 'DOTNETCORE|8.0'

var appServicePlanName = 'AppServicePlan-${webAppName}'
var webSiteName = webAppName

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
    tier: sku == 'F1' ? 'Free' : 'Shared'
    size: sku
    family: sku == 'F1' ? 'F' : 'D'
    capacity: 0
  }
  kind: 'linux'
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
      alwaysOn: false // Free tier doesn't support Always On
      ftpsState: 'Disabled'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      requestTracingEnabled: true
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
}

// Output the URL of the web app
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output resourceGroupName string = resourceGroup().name
