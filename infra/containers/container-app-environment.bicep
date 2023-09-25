param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string
param webAppServiceCustomDomainName string = ''

resource environment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
      }
    }
  }
}

resource webAppManagedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2022-11-01-preview' = if (!empty(webAppServiceCustomDomainName)) {
  parent: environment
  name: '${environment.name}-certificate'
  location: location
  tags: tags
  properties: {
    subjectName: webAppServiceCustomDomainName
    domainControlValidation: 'CNAME'
  }
}

output id string = environment.id
output name string = environment.name
output defaultDomain string = environment.properties.defaultDomain
output webAppServiceCertificateId string = !empty(webAppServiceCustomDomainName) ? webAppManagedCertificate.id : ''
