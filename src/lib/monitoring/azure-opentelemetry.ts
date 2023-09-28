import { useAzureMonitor } from 'applicationinsights'
import type { AzureMonitorOpenTelemetryOptions } from 'applicationinsights'
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
    samplingRatio: 0.5,
    logInstrumentationOptions: {
      console: { enabled: true}
    }
  }

  // This is not a hook, it's just named like a hook!
  // eslint-disable-next-line react-hooks/rules-of-hooks
  useAzureMonitor(options)
}
