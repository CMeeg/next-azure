import 'server-only'
import pino from 'pino'
import { TelemetryClient } from 'applicationinsights'
import { currentEnvironment, environment } from '@/lib/environment'

const createLogger = () => {
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING

  if (connectionString) {
    // Create a pino logger instance using the pino-appinsights transport
    const telemetryClient = new TelemetryClient(connectionString)

    const transport = pino.transport({
      target: 'pino-appinsights-transport',
      options: {
        telemetryClient,
        minLevel: process.env.SERVICE_WEB_MIN_LOG_LEVEL || 30
      }
    })

    return pino(transport)
  }

  if (currentEnvironment === environment.development) {
    // Create a pino logger instance using the pino-pretty transport
    const transport = pino.transport({
      target: 'pino-pretty'
    })

    return pino(transport)
  }

  // Create a pino logger instance using the default transport
  return pino()
}

const logger = createLogger()

export { logger }
