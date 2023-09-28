import { useAzureMonitor } from '@azure/monitor-opentelemetry'
import type { AzureMonitorOpenTelemetryOptions } from '@azure/monitor-opentelemetry'
import { Resource } from '@opentelemetry/resources'
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions'

const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING

if (connectionString) {
  const resource = new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: "web",
    [SemanticResourceAttributes.SERVICE_NAMESPACE]: "next-azure"
  })

  const options: AzureMonitorOpenTelemetryOptions = {
    azureMonitorExporterOptions: {
      connectionString
    },
    resource,
    samplingRatio: 0.1
  }

  // This is not a hook, it's just named like a hook!
  // eslint-disable-next-line react-hooks/rules-of-hooks
  useAzureMonitor(options)
}
