param location string = resourceGroup().location

param projectName string = 'next-azure'

param environment string = 'live'

param buildId string

// This param is currently used to prevent appsettings being updated during "what-if" runs in the build pipeline because it throws an error otherwise
// Looks like we can remove this once this issue is resolved:
// https://github.com/Azure/arm-template-whatif/issues/65
param dryRun bool = false

var resourceNameSuffix = toLower('${projectName}-${environment}')

var webAppName = 'app-${resourceNameSuffix}'

var nodeVersion = '12.13.0'

module webApp 'app-service.bicep' = {
  name: 'web-app'
  params: {
    location: location
    appServicePlanName: 'asp-${resourceNameSuffix}'
    appServiceName: webAppName
    nodeVersion: nodeVersion
  }
}

var webAppServiceId = webApp.outputs.appServiceId
var webAppServiceHostname = webApp.outputs.appServiceHostname

module webAppInsights 'app-insights.bicep' = {
  name: 'web-app-insights'
  params: {
    location: location
    resourceName: 'ai-${resourceNameSuffix}'
    appServiceId: webAppServiceId
  }
}

var webAppInsightsInstrumentationKey = webAppInsights.outputs.instrumentationKey

module cdn 'cdn.bicep' = {
  name: 'cdn'
  params: {
    location: location
    resourceName: 'cdn-${resourceNameSuffix}'
    originHostname: webAppServiceHostname
  }
}

var baseUrl = 'https://${webAppServiceHostname}'
var cdnEndpointHostname = cdn.outputs.endpointHostName
var cdnEndpointUrl = 'https://${cdnEndpointHostname}'

resource webAppSettings 'Microsoft.Web/sites/config@2020-12-01' = if(!dryRun) {
  name: '${webAppName}/appsettings'
  properties: {
    APP_ENV: 'production'
    BASE_URL: baseUrl
    NEXT_COMPRESS: 'false'
    NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY: webAppInsightsInstrumentationKey
    NEXT_PUBLIC_BUILD_ID: buildId
    NEXT_PUBLIC_CDN_URL: cdnEndpointUrl
    WEBSITE_NODE_DEFAULT_VERSION: nodeVersion
  }
}

output webAppName string = webAppName
output webAppInsightsInstrumentationKey string = webAppInsightsInstrumentationKey
output cdnEndpointUrl string = cdnEndpointUrl
