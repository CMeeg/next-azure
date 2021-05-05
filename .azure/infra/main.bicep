param location string = resourceGroup().location

param projectName string = 'next-azure'

param environment string = 'live'

var resourceNameSuffix = toLower('${projectName}-${environment}')

var webAppName = 'app-${resourceNameSuffix}'

module webApp 'app-service.bicep' = {
  name: 'web-app'
  params: {
    location: location
    appServicePlanName: 'asp-${resourceNameSuffix}'
    appServiceName: webAppName
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

var cdnEndpointHostname = cdn.outputs.endpointHostName

resource webAppSettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${webAppName}/appsettings'
  properties: {
    APP_ENV: 'production'
    BASE_URL: 'https://${webAppServiceHostname}'
    NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY: webAppInsightsInstrumentationKey
    NEXT_PUBLIC_CDN_URL: 'https://${cdnEndpointHostname}'
  }
}
