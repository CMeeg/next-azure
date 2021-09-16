param location string

param resourceName string

param originHostname string

resource profile 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: resourceName
  location: location
  sku: {
    name: 'Standard_Microsoft'
  }

  resource endpoint 'endpoints' = {
    name: resourceName
    location: location
    properties: {
      originHostHeader: originHostname
      isHttpAllowed: true
      isHttpsAllowed: true
      queryStringCachingBehavior: 'IgnoreQueryString'
      contentTypesToCompress: [
        'application/json'
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
          name: replace(originHostname, '.', '-')
          properties: {
            hostName: originHostname
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
                    operator: 'Equal'
                    selector: 'Origin'
                    negateCondition: false
                    matchValues: [
                      'https://${originHostname}'
                    ]
                    transforms: []
                    '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRequestHeaderConditionParameters'
                }
              }
            ]
            actions: [
              {
                name: 'ModifyResponseHeader'
                parameters: {
                    headerAction: 'Overwrite'
                    headerName: 'Access-Control-Allow-Origin'
                    value: 'https://${originHostname}'
                    '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleHeaderActionParameters'
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
                    '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlPathMatchConditionParameters'
                }
              }
            ]
            actions: [
              {
                name: 'ModifyResponseHeader'
                parameters: {
                    headerAction: 'Overwrite'
                    headerName: 'Access-Control-Allow-Origin'
                    value: 'https://${originHostname}'
                    '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleHeaderActionParameters'
                }
              }
            ]
          }
        ]
      }
    }
  }
}

output endpointHostName string = profile::endpoint.properties.hostName
