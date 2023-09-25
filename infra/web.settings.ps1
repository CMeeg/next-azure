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
    "containerCpuCoreCount": "$(Get-ValueOrDefault ${env:WEB_APP_CONTAINER_CPU_CORE_COUNT} "0.5")",
    "containerMemory": "$(Get-ValueOrDefault ${env:WEB_APP_CONTAINER_MEMORY} "1.0Gi")",
    "customDomainName": "$(Get-ValueOrDefault ${env:WEB_APP_CUSTOM_DOMAIN_NAME} "")"
  },
  "scale": {
    "containerMinReplicas": $(Get-ValueOrDefault ${env:WEB_APP_CONTAINER_MIN_REPLICAS} 0),
    "containerMaxReplicas": $(Get-ValueOrDefault ${env:WEB_APP_CONTAINER_MAX_REPLICAS} 1)
  },
  "env": {}
}
"@ | Out-File -FilePath "$scriptDir/web.settings.json" -Encoding utf8

