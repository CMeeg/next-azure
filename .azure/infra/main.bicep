param location string = resourceGroup().location

param resourcePrefix string

param environment string

param sharedResourceGroupName string

param buildId string

param buildTag string

@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P1V2'
  'P2V2'
  'P3V2'
  'P1V3'
  'P2V3'
  'P3V3'
])
param webAppSkuName string

@minValue(1)
param webAppSkuCapacity int

param webAppSlotName string

param webAppDomainName string

param webAppCertName string

param webAppSettings object

// Create resource name prefixes for "shared" and "environment" resources

var envResourceGroupName = resourceGroup().name
var envResourceNamePrefix = toLower('${resourcePrefix}-${environment}')
var sharedResourceNamePrefix = sharedResourceGroupName == envResourceGroupName ? envResourceNamePrefix : toLower('${resourcePrefix}')

// Define the app service resources

var webAppName = '${sharedResourceNamePrefix}-app'
var containerRegistryName = '${replace(sharedResourceNamePrefix, '-', '')}cr'

module webApp 'app-service.bicep' = {
  name: 'web-app'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    location: location
    appServicePlanName: '${sharedResourceNamePrefix}-asp'
    appServiceName: webAppName
    skuName: webAppSkuName
    skuCapacity: webAppSkuCapacity
    slotName: webAppSlotName
    containerRegistryName: containerRegistryName
  }
}

var webAppServicePlanId = webApp.outputs.appServicePlanId
var webAppServiceId = webApp.outputs.appServiceId
var webAppServiceDefaultHostname = webApp.outputs.appServiceDefaultHostname
var containerRegistryServer = webApp.outputs.containerRegistryServer
var containerImageName = replace(envResourceNamePrefix, '-', '')
var containerImageTag = buildTag

// Define the app service domain

var hasCustomDomain = !empty(webAppDomainName) && !empty(webAppCertName)

// The only reason to use key vault (currently) is if we are using a custom domain as key vault is used to store the SSL cert
var keyVaultName = '${envResourceNamePrefix}-kv'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if(hasCustomDomain) {
  name: keyVaultName
}

module webAppDomain 'app-service-domain.bicep' = if(hasCustomDomain) {
  name: 'web-app-domain'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    location: location
    appServicePlanId: webAppServicePlanId
    appServiceName: webAppName
    slotName: webAppSlotName
    domainName: webAppDomainName
    certName: webAppCertName
    keyVaultId: hasCustomDomain ? keyVault.id : ''
    keyVaultName: keyVaultName
  }
}

var webAppServiceHostname = hasCustomDomain ? webAppDomainName : webAppServiceDefaultHostname

// Define the application insights resource

module webAppInsights 'app-insights.bicep' = {
  name: 'web-app-insights'
  params: {
    location: location
    resourceName: '${envResourceNamePrefix}-ai'
    workspaceName: '${envResourceNamePrefix}-aiws'
    appServiceId: webAppServiceId
  }
}

var webAppInsightsInstrumentationKey = webAppInsights.outputs.instrumentationKey
var webAppInsightsConnectionString = webAppInsights.outputs.connectionString

// Define the CDN resources

module cdn 'cdn.bicep' = {
  name: 'cdn'
  params: {
    location: location
    resourceName: '${envResourceNamePrefix}-cdn'
    originHostname: webAppServiceHostname
  }
}

// Define the app service settings - these depend on outputs from other resources so cannot be defined earlier as part of the app service definition

var baseUrl = 'https://${webAppServiceHostname}'
var cdnEndpointHostname = cdn.outputs.endpointHostName
var cdnEndpointUrl = 'https://${cdnEndpointHostname}'
var containerRegistryServerUrl = 'https://${containerRegistryServer}'

// These are the base settings required for the deployment
var webAppDeploymentSettings = {
  APP_ENV: environment
  APPINSIGHTS_INSTRUMENTATIONKEY: webAppInsightsInstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: webAppInsightsConnectionString
  BASE_URL: baseUrl
  DOCKER_IMAGE_NAME: containerImageName
  DOCKER_IMAGE_TAG: containerImageTag
  DOCKER_REGISTRY_SERVER: containerRegistryServer
  DOCKER_REGISTRY_SERVER_URL: containerRegistryServerUrl
  NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY: webAppInsightsInstrumentationKey
  NEXT_PUBLIC_APPINSIGHTS_CONNECTION_STRING: webAppInsightsConnectionString
  NEXT_PUBLIC_BUILD_ID: buildId
  NEXT_PUBLIC_CDN_URL: cdnEndpointUrl
}

// Merge the default settings into any additional settings provided via the `webAppSettings` parameter
var webAppConfigSettings = union(webAppSettings, webAppDeploymentSettings)

module webAppConfig 'app-service-config.bicep' = {
  name: 'web-app-config'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    appServiceName: webAppName
    slotName: webAppSlotName
    appSettings: webAppConfigSettings
  }
}

// Set deployment outputs

output webAppEnvironment string = environment
output webAppName string = webAppName
output webAppBaseUrl string = baseUrl
output webAppSettings object = webAppConfigSettings
output webAppInsightsInstrumentationKey string = webAppInsightsInstrumentationKey
output webAppInsightsConnectionString string = webAppInsightsConnectionString
output cdnEndpointUrl string = cdnEndpointUrl
