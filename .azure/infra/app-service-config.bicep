param appServiceName string

param appSettings object

resource webAppConfig 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${appServiceName}/appsettings'
  properties: appSettings
}
