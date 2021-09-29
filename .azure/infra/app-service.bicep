param location string

param appServicePlanName string

param appServiceName string

param skuName string

param skuCapacity int

param nodeVersion string

param slotName string

var isSlotDeploy = slotName != 'production'

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
      use32BitWorkerProcess: false
      alwaysOn: true
      localMySqlEnabled: false
      netFrameworkVersion: 'v4.6'
    }
  }

  resource slot 'slots' = if(isSlotDeploy) {
    name: slotName
    location: location
    properties: {
      httpsOnly: true
      siteConfig: {
        http20Enabled: true
        minTlsVersion: minTlsVersion
        nodeVersion: nodeVersion
        use32BitWorkerProcess: false
        alwaysOn: true
        localMySqlEnabled: false
        netFrameworkVersion: 'v4.6'
      }
    }
  }
}

output appServiceId string = isSlotDeploy ? appService::slot.id : appService.id
output appServiceHostname string = isSlotDeploy ? appService::slot.properties.defaultHostName : appService.properties.defaultHostName
