const next = require('next')
const { createServer } = require('http')
const appInsights = require('applicationinsights')

// See https://github.com/vercel/next.js/blob/canary/packages/next/server/next.ts
const getRequestHandler = (app, config) => {
  return async (req, res, parsedUrl) => {
    if (config.useAppInsights) {
      appInsights.defaultClient.trackNodeHttpRequest({
        request: req,
        response: res
      })
    }

    const nextRequestHandler = app.getRequestHandler()

    return nextRequestHandler(req, res, parsedUrl)
  }
}

// See https://github.com/vercel/next.js/blob/canary/packages/next/server/lib/start-server.ts
const startServer = async (config) => {
  const serverOptions = {
    dev: config.env === 'development',
    dir: '.',
    quiet: false
  }

  const app = next(serverOptions)

  const srv = createServer(getRequestHandler(app, config))

  await new Promise((resolve, reject) => {
    // This code catches EADDRINUSE error if the port is already in use
    srv.on('error', reject)
    srv.on('listening', () => resolve())
    srv.listen(config.port, config.hostname)
  })

  // It's up to caller to run `app.prepare()`, so it can notify that the server
  // is listening before starting any intensive operations.
  const addr = srv.address()

  return {
    app,
    actualPort: addr && typeof addr === 'object' ? addr.port : config.port
  }
}

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

const getPort = (defaultPort) => {
  const envPort = process.env.PORT

  if (typeof envPort === 'undefined') {
    return defaultPort
  }

  const parsedPort = parseInt(envPort, 10)

  return Number.isNaN(parsedPort) ? envPort : parsedPort
}

const getEnv = (defaultEnv) => {
  const env = process.env.APP_ENV || process.env.NODE_ENV

  if (typeof env !== 'undefined') {
    return env
  }

  return defaultEnv
}

const startTime = Date.now()

const serverConfig = {
  hostname: 'localhost',
  port: getPort(3000),
  env: getEnv('development'),
  useAppInsights: initAppInsights(
    process.env.NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY
  )
}

startServer(serverConfig)
  .then(async ({ app, actualPort }) => {
    // eslint-disable-next-line no-console
    console.log(
      `started server on host ${serverConfig.hostname}, port ${actualPort}, env ${serverConfig.env}`
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
