param location string

param appServicePlanName string

param appServiceName string

param skuName string

param skuCapacity int

param nodeVersion string

param slotName string

param customDomain object

// "production" is the name of the "default" slot - essentially it means "no slot"
var isSlotDeploy = slotName != 'production'

// "F" and "D" SKUs use shard infrastructure and have more limited features
var isSharedComputeSku = startsWith(skuName, 'F') || startsWith(skuName, 'D')

// Check if we have a custom domain
var hasCustomDomain = !empty(customDomain)

var minTlsVersion = '1.2'

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
    siteConfig: {
      http20Enabled: true
      minTlsVersion: minTlsVersion
      nodeVersion: nodeVersion
      // 64 bit and always on not available on anything lower than Basic SKUs
      use32BitWorkerProcess: isSharedComputeSku
      alwaysOn: !isSharedComputeSku
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
        // 64 bit and always on not available on anything lower than Basic SKUs
        use32BitWorkerProcess: isSharedComputeSku
        alwaysOn: !isSharedComputeSku
      }
    }
  }
}

resource appServiceCertificate 'Microsoft.Web/certificates@2020-12-01' = if(hasCustomDomain) {
  name: '$${appServicePlanName}-${customDomain.certName}'
  location: location
  properties: {
    keyVaultId: customDomain.keyVaultId
    keyVaultSecretName: customDomain.certName
    serverFarmId: appServicePlan.id
  }
}

resource appServiceHostName 'Microsoft.Web/sites/hostNameBindings@2020-12-01' = if(hasCustomDomain && !isSlotDeploy) {
  name: '${appService.name}/${customDomain.domainName}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: appServiceCertificate.properties.thumbprint
  }
}

resource appServiceSlotHostName 'Microsoft.Web/sites/slots/hostNameBindings@2020-12-01' = if(hasCustomDomain && isSlotDeploy) {
  name: '${appServiceName}/${slotName}/${customDomain.domainName}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: appServiceCertificate.properties.thumbprint
  }
}

output appServiceId string = isSlotDeploy ? appService::slot.id : appService.id
output appServiceHostname string = hasCustomDomain ? customDomain.domainName : isSlotDeploy ? appService::slot.properties.defaultHostName : appService.properties.defaultHostName
