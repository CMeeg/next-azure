param location string = resourceGroup().location

param projectName string

param environment string

param sharedResourceGroupName string

param buildId string

@allowed([
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param webAppSkuName string

@minValue(1)
param webAppSkuCapacity int

param webAppSlotName string

param webAppSettings object

// This param is currently used to prevent appsettings being updated during "what-if" runs in the build pipeline because it throws an error otherwise
// Looks like we can remove this once this issue is resolved:
// https://github.com/Azure/arm-template-whatif/issues/65
param dryRun bool = false

var envResourceNamePrefix = toLower('${projectName}-${environment}')
var sharedResourceNamePrefix = toLower('${projectName}')

var webAppName = '${sharedResourceNamePrefix}-app'

var nodeVersion = '12.13.0'

module webApp 'app-service.bicep' = {
  name: 'web-app'
  scope: resourceGroup(sharedResourceGroupName)
  params: {
    location: location
    appServicePlanName: '${sharedResourceNamePrefix}-asp'
    appServiceName: webAppName
    skuName: webAppSkuName
    skuCapacity: webAppSkuCapacity
    nodeVersion: nodeVersion
    slotName: webAppSlotName
  }
}

var webAppServiceId = webApp.outputs.appServiceId
var webAppServiceHostname = webApp.outputs.appServiceHostname

module webAppInsights 'app-insights.bicep' = {
  name: 'web-app-insights'
  params: {
    location: location
    resourceName: '${envResourceNamePrefix}-ai'
    appServiceId: webAppServiceId
  }
}

var webAppInsightsInstrumentationKey = webAppInsights.outputs.instrumentationKey

module cdn 'cdn.bicep' = {
  name: 'cdn'
  params: {
    location: location
    resourceName: '${envResourceNamePrefix}-cdn'
    originHostname: webAppServiceHostname
  }
}

var baseUrl = 'https://${webAppServiceHostname}'
var cdnEndpointHostname = cdn.outputs.endpointHostName
var cdnEndpointUrl = 'https://${cdnEndpointHostname}'

// App service settings depend on outputs from other resources so we do this last
var webAppDeploymentSettings = {
  APP_ENV: environment
  BASE_URL: baseUrl
  NEXT_COMPRESS: 'false'
  NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY: webAppInsightsInstrumentationKey
  NEXT_PUBLIC_BUILD_ID: buildId
  NEXT_PUBLIC_CDN_URL: cdnEndpointUrl
  NODE_ENV: 'production'
  WEBSITE_NODE_DEFAULT_VERSION: nodeVersion
}

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

output webAppEnvironment string = environment
output webAppName string = webAppName
output webAppBaseUrl string = baseUrl
output webAppInsightsInstrumentationKey string = webAppInsightsInstrumentationKey
output cdnEndpointUrl string = cdnEndpointUrl
