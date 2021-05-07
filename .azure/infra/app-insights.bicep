param location string

param resourceName string

param appServiceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: resourceName
  location: location
  tags: {
    'hidden-link:${appServiceId}': 'Resource'
    displayName: 'AppInsightsComponent'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
