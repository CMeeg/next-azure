process.env.NODE_ENV = 'production'
process.chdir(__dirname)

const NextServer = require('next/dist/server/next-server').default
const http = require('http')
const path = require('path')
const url = require('url')
const appInsights = require('applicationinsights')
const nextConfig = require('./next.config.json')

// Make sure commands gracefully respect termination signals (e.g. from Docker)
process.on('SIGTERM', () => process.exit(0))
process.on('SIGINT', () => process.exit(0))

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

const initAppInsights = (connectionString) => {
  if (!connectionString) {
    return false
  }

  appInsights
    .setup(connectionString)
    .setAutoCollectConsole(true, true)
    .setSendLiveMetrics(true)
    .start()

  return true
}

const useAppInsights = initAppInsights(
  process.env.NEXT_PUBLIC_APPINSIGHTS_CONNECTION_STRING
)

let nextRequestHandler

const server = http.createServer(async (req, res) => {
  if (useAppInsights) {
    appInsights.defaultClient.trackNodeHttpRequest({
      request: req,
      response: res
    })
  }

  const parsedUrl = url.parse(req.url, true)

  try {
    await nextRequestHandler(req, res, parsedUrl)
  } catch (err) {
    if (useAppInsights) {
      appInsights.defaultClient.trackException({ exception: err })
    }

    // eslint-disable-next-line no-console
    console.error(err)

    res.statusCode = 500
    res.end('internal server error')
  }
})

const serverEnv = getEnv('production')

const serverConfig = {
  hostname: '0.0.0.0',
  port: getPort(3000),
  dir: path.join(__dirname),
  dev: serverEnv === 'development',
  conf: nextConfig
}

server.listen(serverConfig.port, serverConfig.hostname, (err) => {
  if (err) {
    if (useAppInsights) {
      appInsights.defaultClient.trackException({ exception: err })
    }

    // eslint-disable-next-line no-console
    console.error('Failed to start server', err)

    process.exit(1)
  }

  const nextServer = new NextServer(serverConfig)

  nextRequestHandler = nextServer.getRequestHandler()

  // eslint-disable-next-line no-console
  console.log(
    `> Server listening at http://${serverConfig.hostname}:${serverConfig.port} as ${serverEnv} env`
  )
})
