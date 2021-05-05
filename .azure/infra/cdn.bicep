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
    }
  }
}

output endpointHostName string = profile::endpoint.properties.hostName
