param location string

param appServicePlanName string

param appServiceName string

param skuName string

param skuCapacity int

param nodeVersion string

var minTlsVersion = '1.2'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

resource appService 'Microsoft.Web/sites@2020-12-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    'hidden-related:${appServicePlan.id}': 'empty'
    displayName: 'Website'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      http20Enabled: true
      minTlsVersion: minTlsVersion
      nodeVersion: nodeVersion
      // If your app service plan allows it then it's recommended to uncomment these settings
      // use32BitWorkerProcess: false
      // alwaysOn: true
    }
  }
}

output appServiceId string = appService.id
output appServiceHostname string = appService.properties.defaultHostName
