param location string

param appServicePlanName string

param appServiceName string

param skuName string

param skuCapacity int

param slotName string

param containerRegistryName string

param containerRegistrySkuName string = 'Basic'

var isProductionDeploy = empty(slotName)
var isSlotDeploy = !isProductionDeploy

var minTlsVersion = '1.2'

var siteConfig = {
  http20Enabled: true
  minTlsVersion: minTlsVersion
  alwaysOn: true
  acrUseManagedIdentityCreds: true
  appCommandLine: ''
}

// Define the app service plan

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    reserved: true
  }
}

// Define the app service

resource appService 'Microsoft.Web/sites@2020-12-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux,container'
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
    clientAffinityEnabled: false
    siteConfig: siteConfig
  }
}

// N.B. This 'undefined' value is used here only because without it a "What-If" deployment fails - it shouldn't ever actually be used because if `slotName` is empty, `isSlotDeploy` will be `false`
resource appServiceSlot 'Microsoft.Web/sites/slots@2020-12-01' = if(isSlotDeploy) {
  name: '${appService.name}/${empty(slotName) ? 'undefined' : slotName}'
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: siteConfig
  }
}

// Define container registry

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: containerRegistrySkuName
  }
  properties: {
    adminUserEnabled: false
  }
}

// Add AcrPull role so that the app service can pull images using managed identity

// This is the ACR Pull Role Definition Id: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource appServiceAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: containerRegistry
  name: isSlotDeploy ? guid(containerRegistry.id, appServiceSlot.id, acrPullRoleDefinitionId) : guid(containerRegistry.id, appService.id, acrPullRoleDefinitionId)
  properties: {
    principalId: isSlotDeploy ? appServiceSlot.identity.principalId : appService.identity.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

output appServicePlanId string = appServicePlan.id
output appServiceId string = isSlotDeploy ? appServiceSlot.id : appService.id
output appServiceDefaultHostname string = isSlotDeploy ? appServiceSlot.properties.defaultHostName : appService.properties.defaultHostName
output containerRegistryServer string = containerRegistry.properties.loginServer
