param name string
param location string = resourceGroup().location
param tags object = {}
param logAnalyticsWorkspaceId string
param acrPullPrincipalIds array

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    // This is enabled because of an error when running `azd deploy`: "Cannot perform credential operations for {resourceGroupPath}/providers/Microsoft.ContainerRegistry/registries/{containerRegistryName} as admin user is disabled" - would prefer to disable though
    adminUserEnabled: true
  }
}

// See: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in acrPullPrincipalIds: {
  scope: containerRegistry
  name: guid(subscription().id, resourceGroup().id, principalId, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}]

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: containerRegistry
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        timeGrain: 'PT1M'
      }
    ]
  }
}

output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
