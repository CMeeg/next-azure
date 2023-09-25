param profileName string
param endpointName string
param location string = resourceGroup().location
param tags object = {}
param originHostName string

var originUri = 'https://${originHostName}'

resource profile 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: profileName
  location: location
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2022-11-01-preview' = {
  name: endpointName
  location: location
  tags: tags
  parent: profile
  properties: {
    originHostHeader: originHostName
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'UseQueryString'
    contentTypesToCompress: [
      'application/javascript'
      'application/json'
      'font/woff2'
      'image/svg+xml'
      'text/css'
      'text/html'
      'text/javascript'
      'text/js'
      'text/plain'
      'text/xml'
    ]
    isCompressionEnabled: true
    optimizationType: 'GeneralWebDelivery'
    origins: [
      {
        name: replace(originHostName, '.', '-')
        properties: {
          hostName: originHostName
          priority: 1
        }
      }
    ]
    deliveryPolicy: {
      rules: [
        {
          name: 'CORSOrigin'
          order: 1
          conditions: [
            {
              name: 'RequestHeader'
              parameters: {
                  operator: length(originUri) > 64 ? 'BeginsWith' : 'Equal'
                  selector: 'Origin'
                  negateCondition: false
                  // A match value longer than 64 characters will cause an error
                  matchValues: [
                    length(originUri) > 64 ? take(originUri, 64) : originUri
                  ]
                  transforms: []
                  typeName: 'DeliveryRuleRequestHeaderConditionParameters'
              }
            }
          ]
          actions: [
            {
              name: 'ModifyResponseHeader'
              parameters: {
                  headerAction: 'Overwrite'
                  headerName: 'Access-Control-Allow-Origin'
                  value: originUri
                  typeName: 'DeliveryRuleHeaderActionParameters'
              }
            }
          ]
        }
        {
          name: 'CORSNext'
          order: 2
          conditions: [
            {
              name: 'UrlPath'
              parameters: {
                  operator: 'BeginsWith'
                  negateCondition: false
                  matchValues: [
                    '_next/'
                  ]
                  transforms: []
                  typeName: 'DeliveryRuleUrlPathMatchConditionParameters'
              }
            }
          ]
          actions: [
            {
              name: 'ModifyResponseHeader'
              parameters: {
                  headerAction: 'Overwrite'
                  headerName: 'Access-Control-Allow-Origin'
                  value: originUri
                  typeName: 'DeliveryRuleHeaderActionParameters'
              }
            }
          ]
        }
      ]
    }
  }
}

output endpointHostName string = endpoint.properties.hostName
output endpointUri string = 'https://${endpoint.properties.hostName}'
