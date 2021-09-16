const next = require('next')
const { createServer } = require('http')
const appInsights = require('applicationinsights')

const initAppInsights = (instrumentationKey) => {
  if (!instrumentationKey) {
    return false
  }

  appInsights
    .setup(instrumentationKey)
    .setAutoCollectConsole(true, true)
    .setSendLiveMetrics(true)
    .start()

  return true
}

const startServer = async (config) => {
  const serverOptions = {
    dev: config.env === 'development',
    dir: '.',
    quiet: false
  }

  const app = next(serverOptions)
  const handleNextRequests = app.getRequestHandler()

  const srv = createServer((req, res) => {
    if (config.useAppInsights) {
      appInsights.defaultClient.trackNodeHttpRequest({
        request: req,
        response: res
      })
    }

    handleNextRequests(req, res)
  })

  await new Promise((resolve, reject) => {
    // This code catches EADDRINUSE error if the port is already in use
    srv.on('error', reject)
    srv.on('listening', () => resolve())
    srv.listen(config.port, config.hostname)
  })

  // It's up to caller to run `app.prepare()`, so it can notify that the server
  // is listening before starting any intensive operations.
  return app
}

const startTime = Date.now()

const developmentEnv = 'development'

const serverConfig = {
  hostname: 'localhost',
  port: process.env.PORT || 3000,
  env: process.env.APP_ENV || process.env.NODE_ENV || developmentEnv,
  useAppInsights: initAppInsights(
    process.env.NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY
  )
}

startServer(serverConfig)
  .then(async (app) => {
    // eslint-disable-next-line no-console
    console.log(
      `started server on host ${serverConfig.hostname}, port ${serverConfig.port}, env ${serverConfig.env}`
    )

    if (serverConfig.useAppInsights) {
      const duration = Date.now() - startTime

      appInsights.defaultClient.trackMetric({
        name: 'server startup time',
        value: duration
      })
    }

    await app.prepare()
  })
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error(err)

    process.exit(1)
  })
