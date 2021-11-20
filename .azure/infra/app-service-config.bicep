param appServiceName string

param slotName string

param swapSlotName string

param appSettings object

// "production" is the name of the "default" slot - essentially it means "no slot"
var isSlotDeploy = slotName != 'production'

var hasSwapSlot = !empty(swapSlotName)

// If we have a swap slot then we want settings to be deployed to that as they will reach the "target" when the swap happens; otherwise we deploy directly to the app or directly to the slot as appropriate

resource webAppConfig 'Microsoft.Web/sites/config@2020-12-01' = if(!isSlotDeploy && !hasSwapSlot) {
  name: '${appServiceName}/appsettings'
  properties: appSettings
}

resource webAppSlotConfig 'Microsoft.Web/sites/slots/config@2020-12-01' = if(isSlotDeploy && !hasSwapSlot) {
  name: '${appServiceName}/${slotName}/appsettings'
  properties: appSettings
}

resource webAppSwapSlotConfig 'Microsoft.Web/sites/slots/config@2020-12-01' = if(hasSwapSlot) {
  name: '${appServiceName}/${hasSwapSlot ? swapSlotName : 'undefined'}/appsettings' // `undefined` won't ever be used - it is only there because without it ARM deployment fails
  properties: appSettings
}
