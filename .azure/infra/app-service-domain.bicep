param location string

param appServicePlanId string

param appServiceName string

param slotName string

param isSlotDeploy bool

param domainName string

param certName string

param keyVaultId string

param keyVaultName string

resource appServiceCertificate 'Microsoft.Web/certificates@2020-12-01' =  {
  name: '${keyVaultName}-${certName}'
  location: location
  properties: {
    keyVaultId: keyVaultId
    keyVaultSecretName: certName
    serverFarmId: appServicePlanId
  }
}

resource appServiceHostName 'Microsoft.Web/sites/hostNameBindings@2020-12-01' = if(!isSlotDeploy) {
  name: '${appServiceName}/${domainName}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: appServiceCertificate.properties.thumbprint
  }
}

resource appServiceSlotHostName 'Microsoft.Web/sites/slots/hostNameBindings@2020-12-01' = if(isSlotDeploy) {
  name: '${appServiceName}/${slotName}/${domainName}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: appServiceCertificate.properties.thumbprint
  }
}
