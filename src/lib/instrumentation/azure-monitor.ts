import { useAzureMonitor } from 'applicationinsights'
import type { AzureMonitorOpenTelemetryOptions } from 'applicationinsights'
import { Resource } from '@opentelemetry/resources'
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions'

const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING

if (connectionString) {
  const resource = new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]:
      process.env.SERVICE_WEB_SERVICE_NAME,
    [SemanticResourceAttributes.SERVICE_NAMESPACE]: process.env.PROJECT_NAME
  })

  const options: AzureMonitorOpenTelemetryOptions = {
    azureMonitorExporterOptions: {
      connectionString
    },
    resource,
    samplingRatio: 0.5,
    instrumentationOptions: {
      azureSdk: { enabled: true },
      http: { enabled: true },
      mongoDb: { enabled: false },
      mySql: { enabled: false },
      postgreSql: { enabled: false },
      redis: { enabled: false },
      redis4: { enabled: false }
    },
    logInstrumentationOptions: {
      console: { enabled: true },
      bunyan: { enabled: false },
      winston: { enabled: false }
    }
  }

  // This is not a hook, it's just named like a hook!
  // eslint-disable-next-line react-hooks/rules-of-hooks
  useAzureMonitor(options)
}
