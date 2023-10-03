function Get-ValueOrDefault($value, $default) {
  if ($null -eq $value) {
    return $default
  }

  return $value
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

@"
{
  "container": {
    "containerCpuCoreCount": "$(Get-ValueOrDefault ${env:SERVICE_WEB_CONTAINER_CPU_CORE_COUNT} "0.5")",
    "containerMemory": "$(Get-ValueOrDefault ${env:SERVICE_WEB_CONTAINER_MEMORY} "1.0Gi")",
    "customDomainName": "$(Get-ValueOrDefault ${env:SERVICE_WEB_CUSTOM_DOMAIN_NAME} "")"
  },
  "scale": {
    "containerMinReplicas": $(Get-ValueOrDefault ${env:SERVICE_WEB_CONTAINER_MIN_REPLICAS} 0),
    "containerMaxReplicas": $(Get-ValueOrDefault ${env:SERVICE_WEB_CONTAINER_MAX_REPLICAS} 1)
  },
  "env": [
    {
      "name": "NEXT_COMPRESS",
      "value": "$(Get-ValueOrDefault ${env:NEXT_COMPRESS} "false")"
    },
    {
      "name": "NODE_ENV",
      "value": "$(Get-ValueOrDefault ${env:NODE_ENV} "production")"
    },
    {
      "name": "SERVICE_WEB_MIN_LOG_LEVEL",
      "value": "$(Get-ValueOrDefault ${env:SERVICE_WEB_MIN_LOG_LEVEL} 30)"
    },
    {
      "name": "SERVICE_WEB_SERVICE_NAME",
      "value": "$(Get-ValueOrDefault ${env:SERVICE_WEB_SERVICE_NAME} "node")"
    },
    {
      "name": "SERVICE_WEB_SERVICE_NAMESPACE",
      "value": "$(Get-ValueOrDefault ${env:SERVICE_WEB_SERVICE_NAMESPACE} "unknown_service")"
    }
  ]
}
"@ | Out-File -FilePath "$scriptDir/web.settings.json" -Encoding utf8

