targetScope = 'subscription'

@minLength(1)
@maxLength(6)
@description('Name of the the environment e.g. `dev`, `uat`, `prod`')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@maxLength(8)
@description('Name of the project/client e.g. `myproj`, `myclient`')
param projectName string

@minLength(1)
@maxLength(8)
@description('Name of the web service/application')
param webAppServiceName string = 'web'

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. For example:
// "resourceGroupName": {
//    "value": "myGroupName"
// }
param applicationInsightsName string = ''
param containerAppEnvironmentName string = ''
param containerAppName string = ''
param containerRegistryName string = ''
param logAnalyticsWorkspaceName string = ''
param resourceGroupName string = ''

param webAppServiceCdnEndpointName string = ''
param webAppServiceCdnProfileName string = ''
param webAppServiceIdentityName string = ''

// Load abbreviations to be used when naming resources
// See: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
var abbrs = loadJsonContent('./abbreviations.json')

// Generate a unique token to be used in naming resources
var resourceToken = take(toLower(uniqueString(subscription().id, environmentName, location, projectName)), 4)

// Functions for building resource names based on a naming convention
// See: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
func buildResourceGroupName(abbr string, projName string, envName string) string => toLower(join([ abbr, projName, envName ], '-'))

func buildProjectResourceName(abbr string, projName string, envName string, token string, useDelimiter bool) string => toLower(join([ abbr, projName, envName, token ], useDelimiter ? '-' : ''))

func buildServiceResourceName(abbr string, projName string, svcName string, envName string, token string, useDelimiter bool) string => toLower(join([ abbr, projName, svcName, envName, token ], useDelimiter ? '-' : ''))

// Tags that should be applied to all resources.
//
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Place all resources in a resource group

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : buildResourceGroupName(abbrs.resources.resource_group, projectName, environmentName)
  location: location
  tags: tags
}

// Deploy resources to the resource group

module logAnalyticsWorkspace './insights/log-analytics-workspace.bicep' = {
  name: 'logAnalyticsWorkspace'
  scope: resourceGroup
  params: {
    name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : buildProjectResourceName(abbrs.insights.log_analytics_workspace, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
  }
}

module appInsights './insights/application-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    name: !empty(applicationInsightsName) ? applicationInsightsName : buildProjectResourceName(abbrs.insights.application_insights, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

// This file is created by a `preprovision` hook - if you're seeing an error here because this file doesn't exist, then run `azd provision` to create it
var webAppSettings = loadJsonContent('./web.settings.json')

var webAppServiceCustomDomainName = webAppSettings.container.customDomainName

module containerAppEnvironment './containers/container-app-environment.bicep' = {
  name: 'containerAppEnvironment'
  scope: resourceGroup
  params: {
    name: !empty(containerAppEnvironmentName) ? containerAppEnvironmentName : buildProjectResourceName(abbrs.containers.container_app_environment, projectName, environmentName, resourceToken, true)
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    webAppServiceCustomDomainName: webAppServiceCustomDomainName
  }
}

module webAppServiceIdentity './security/user-assigned-identity.bicep' = {
  name: '${webAppServiceName}-identity'
  scope: resourceGroup
  params: {
    name: !empty(webAppServiceIdentityName) ? webAppServiceIdentityName : buildServiceResourceName(abbrs.security.user_assigned_identity, projectName, webAppServiceName, environmentName, resourceToken, true)
    location: location
    tags: tags
  }
}

module containerRegistry './containers/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: resourceGroup
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : buildProjectResourceName(abbrs.containers.container_registry, projectName, environmentName, resourceToken, false)
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    acrPullPrincipalIds: [
      webAppServiceIdentity.outputs.principalId
    ]
  }
}

// We need to compute the origin hostname for the web app CDN - if a custom domain name is used, then we can use that, otherwise we need to use the default container app hostname
var webAppServiceContainerAppName = !empty(containerAppName) ? containerAppName : buildServiceResourceName(abbrs.containers.container_app, projectName, webAppServiceName, environmentName, resourceToken, true)

var webAppServiceHostName = !empty(webAppServiceCustomDomainName) ? webAppServiceCustomDomainName : '${webAppServiceContainerAppName}.${containerAppEnvironment.outputs.defaultDomain}'

var webAppServiceUri = 'https://${webAppServiceHostName}'

module webAppServiceCdn './cdn/cdn.bicep' = {
  name: '${webAppServiceName}-cdn'
  scope: resourceGroup
  params: {
    profileName: !empty(webAppServiceCdnProfileName) ? webAppServiceCdnProfileName : buildServiceResourceName(abbrs.cdn.cdn_profile, projectName, webAppServiceName, environmentName, resourceToken, true)
    endpointName: !empty(webAppServiceCdnEndpointName) ? webAppServiceCdnEndpointName : buildServiceResourceName(abbrs.cdn.cdn_endpoint, projectName, webAppServiceName, environmentName, resourceToken, true)
    location: location
    tags: tags
    originHostName: webAppServiceHostName
  }
}

var buildId = uniqueString(resourceGroup.id, deployment().name)
var nodeEnv = 'production'

module webAppServiceContainerApp './containers/container-app.bicep' = {
  name: '${webAppServiceName}-container-app'
  scope: resourceGroup
  params: {
    name: webAppServiceContainerAppName
    location: location
    tags: union(tags, { 'azd-service-name': webAppServiceName })
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    userAssignedIdentityId: webAppServiceIdentity.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerCpuCoreCount: webAppSettings.container.containerCpuCoreCount
    containerMemory: webAppSettings.container.containerMemory
    containerMinReplicas: webAppSettings.scale.containerMinReplicas
    containerMaxReplicas: webAppSettings.scale.containerMaxReplicas
    customDomainName: webAppServiceCustomDomainName
    certificateId: containerAppEnvironment.outputs.webAppServiceCertificateId
    env: [
      {
        name: 'APP_ENV'
        value: environmentName
      }
      {
        name: 'BASE_URL'
        value: webAppServiceUri
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.connectionString
      }
      {
        name: 'NEXT_COMPRESS'
        value: 'false'
      }
      {
        name: 'NEXT_PUBLIC_APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.connectionString
      }
      {
        name: 'NEXT_PUBLIC_BUILD_ID'
        value: buildId
      }
      {
        name: 'NEXT_PUBLIC_CDN_URL'
        value: webAppServiceCdn.outputs.endpointUri
      }
      {
        name: 'NODE_ENV'
        value: nodeEnv
      }
    ]
    targetPort: 3000
  }
}

// TODO: Key vault?
// TODO: Storage?

// azd outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId

// Container outputs
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerAppEnvironment.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

// Web app outputs
output APP_ENV string = environmentName
output BASE_URL string = webAppServiceUri
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output NEXT_COMPRESS bool = false
output NEXT_PUBLIC_APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output NEXT_PUBLIC_BUILD_ID string = buildId
output NEXT_PUBLIC_CDN_URL string = webAppServiceCdn.outputs.endpointUri
output NODE_ENV string = nodeEnv
