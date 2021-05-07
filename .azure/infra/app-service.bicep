param location string

param appServicePlanName string

param appServiceName string

param skuName string

param skuCapacity int

param nodeVersion string

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
      minTlsVersion: '1.2'
      nodeVersion: nodeVersion
      appSettings: [
        {
          name: 'APP_ENV'
          value: 'production'
        }
        {
          name: 'BASE_URL'
          value: '' // Not known yet - will be set later
        }
        {
          name: 'NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '' // Not known yet - will be set later
        }
        {
          name: 'NEXT_PUBLIC_CDN_URL'
          value: '' // Not known yet - will be set later
        }
      ]
    }
  }

  // This is purely here to define which app settings are deployment slot settings
  resource webAppSlotSettings 'config' = {
    name: 'slotConfigNames'
    properties: {
      appSettingNames: [
        'APP_ENV'
        'BASE_URL'
        'NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY'
        'NEXT_PUBLIC_CDN_URL'
      ]
    }
  }
}

output appServiceId string = appService.id
output appServiceHostname string = appService.properties.defaultHostName
