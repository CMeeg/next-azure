param location string = resourceGroup().location

param projectName string

param environment string

param sharedResourceGroupName string

param buildId string

@allowed([
  'F1'
  'D1'
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

param webAppNodeVersion object

param webAppSettings object

// This param is currently used to prevent appsettings being updated during "what-if" runs in the build pipeline because it throws an error otherwise
// Looks like we can remove this once this issue is resolved:
// https://github.com/Azure/arm-template-whatif/issues/65
param dryRun bool = false

// Create resource name prefixes for "shared" and "environment" resources

var envResourceGroupName = resourceGroup().name
var envResourceNamePrefix = toLower('${projectName}-${environment}')
var sharedResourceNamePrefix = sharedResourceGroupName == envResourceGroupName ? envResourceNamePrefix : toLower('${projectName}')

// Define the key vault resource if required

var keyVaultName = '${envResourceNamePrefix}-kv'

// The only reason to use key vault (currently) is if we are using a custom SSL cert
var useKeyVault = !empty(webAppCertName)

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if(useKeyVault) {
  name: keyVaultName
}

// Define the app service resources

var webAppName = '${sharedResourceNamePrefix}-app'

var webAppCustomDomain = {
  domainName: webAppDomainName
  certName: webAppCertName
  keyVaultId: useKeyVault ? keyVault.id : null
  keyVaultName: useKeyVault ? keyVaultName : null
}

module webApp 'app-service.bicep' = {
  name: 'web-app'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    location: location
    appServicePlanName: '${sharedResourceNamePrefix}-asp'
    appServiceName: webAppName
    skuName: webAppSkuName
    skuCapacity: webAppSkuCapacity
    nodeVersion: webAppNodeVersion.node
    slotName: webAppSlotName
    customDomain: webAppCustomDomain
  }
}

var webAppServiceId = webApp.outputs.appServiceId
var webAppServiceHostname = webApp.outputs.appServiceHostname

// Define the application insights resource

module webAppInsights 'app-insights.bicep' = {
  name: 'web-app-insights'
  params: {
    location: location
    resourceName: '${envResourceNamePrefix}-ai'
    appServiceId: webAppServiceId
  }
}

var webAppInsightsInstrumentationKey = webAppInsights.outputs.instrumentationKey

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

// These are the base settings required for the deployment
var webAppDeploymentSettings = {
  APP_ENV: environment
  BASE_URL: baseUrl
  NEXT_COMPRESS: 'false'
  NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY: webAppInsightsInstrumentationKey
  NEXT_PUBLIC_BUILD_ID: buildId
  NEXT_PUBLIC_CDN_URL: cdnEndpointUrl
  NODE_ENV: 'production'
  // See https://github.com/projectkudu/kudu/wiki/Configurable-settings#changing-the-timeout-before-external-commands-are-killed
  SCM_COMMAND_IDLE_TIMEOUT: 180
  WEBSITE_NODE_DEFAULT_VERSION: webAppNodeVersion.node
  WEBSITE_NPM_DEFAULT_VERSION: webAppNodeVersion.npm
}

// Merge the default settings into any additional settings provided via the `webAppSettings` parameter
var webAppConfigSettings = union(webAppSettings, webAppDeploymentSettings)

module webAppConfig 'app-service-config.bicep' = if (!dryRun) {
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
output cdnEndpointUrl string = cdnEndpointUrl
