param appServiceName string

param slotName string

param appSettings object

var isSlotDeploy = slotName != 'production'

resource webAppConfig 'Microsoft.Web/sites/config@2020-12-01' = if(!isSlotDeploy) {
  name: '${appServiceName}/appsettings'
  properties: appSettings
}

resource webAppSlotConfig 'Microsoft.Web/sites/slots/config@2020-12-01' = if(isSlotDeploy) {
  name: '${appServiceName}/${slotName}/appsettings'
  properties: appSettings
}

// This defines which app settings are deployment slot settings
resource webAppSlotSettings 'Microsoft.Web/sites/config@2020-12-01' = if(isSlotDeploy) {
  name: '${appServiceName}/slotConfigNames'
  properties: {
    appSettingNames: [
      'APP_ENV'
      'BASE_URL'
      'NEXT_COMPRESS'
      'NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY'
      'NEXT_PUBLIC_BUILD_ID'
      'NEXT_PUBLIC_CDN_URL'
    ]
  }
}
