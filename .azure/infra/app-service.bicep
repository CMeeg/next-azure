param location string

param appServicePlanName string

param appServiceName string

param skuName string

param skuCapacity int

param nodeVersion string

param slotName string

param swapSlotName string

// "production" is the name of the "default" slot - essentially it means "no slot"
var isSlotDeploy = slotName != 'production'

// "F" and "D" SKUs use shard infrastructure and have more limited features
var isSharedComputeSku = startsWith(skuName, 'F') || startsWith(skuName, 'D')

var minTlsVersion = '1.2'

var hasSwapSlot = !empty(swapSlotName)

var siteConfig = {
  http20Enabled: true
  minTlsVersion: minTlsVersion
  nodeVersion: nodeVersion
  // 64 bit and always on not available on anything lower than Basic SKUs
  use32BitWorkerProcess: isSharedComputeSku
  alwaysOn: !isSharedComputeSku
}

// Define the app service plan

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

// Define the app service

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
    siteConfig: siteConfig
  }
}

resource appServiceSlot 'Microsoft.Web/sites/slots@2020-12-01' = if(isSlotDeploy) {
  name: '${appService.name}/${slotName}'
  location: location
  properties: {
    httpsOnly: true
    siteConfig: siteConfig
  }
}

// The swap slot will auto swap to the target slot
var swapSlotSiteConfig = union(siteConfig, {
  autoSwapSlotName: slotName
})

resource appServiceSwapSlot 'Microsoft.Web/sites/slots@2020-12-01' = if(hasSwapSlot) {
  name: '${appService.name}/${hasSwapSlot ? swapSlotName : 'undefined'}' // `undefined` won't ever be used - it is only there because without it a `What-If` ARM deployment fails
  location: location
  properties: {
    httpsOnly: true
    siteConfig: swapSlotSiteConfig
  }
}

output appServicePlanId string = appServicePlan.id
output appServiceId string = isSlotDeploy ? appServiceSlot.id : appService.id
output appServiceDefaultHostname string = isSlotDeploy ? appServiceSlot.properties.defaultHostName : appService.properties.defaultHostName
