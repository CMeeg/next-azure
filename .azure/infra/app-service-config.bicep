param appServiceName string

param slotName string

param appSettings object

var productionSlotName = 'production'

var isProductionDeploy = slotName == productionSlotName

// "production" is the name of the "default" slot - essentially it means "no slot"
var isSlotDeploy = !isProductionDeploy

// Deploy directly to the app or directly to the slot as appropriate

resource webAppConfig 'Microsoft.Web/sites/config@2020-12-01' = if(isProductionDeploy) {
  name: '${appServiceName}/appsettings'
  properties: appSettings
}

resource webAppSlotConfig 'Microsoft.Web/sites/slots/config@2020-12-01' = if(isSlotDeploy) {
  name: '${appServiceName}/${slotName}/appsettings'
  properties: appSettings
}
