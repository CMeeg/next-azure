const compress = process.env.NEXT_COMPRESS ? !!process.env.NEXT_COMPRESS : true
const assetPrefix = process.env.NEXT_PUBLIC_CDN_URL || ''
const buildId = process.env.NEXT_PUBLIC_BUILD_ID || null

module.exports = {
  output: 'standalone',
  httpAgentOptions: {
    keepAlive: true,
    maxSockets: 128,
    maxFreeSockets: 128,
    timeout: 60000
  },
  reactStrictMode: true,
  poweredByHeader: false,
  eslint: {
    ignoreDuringBuilds: true
  },
  compress,
  assetPrefix,
  generateBuildId: async () => buildId
}
