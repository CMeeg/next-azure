const compress = process.env.NEXT_COMPRESS ? !!process.env.NEXT_COMPRESS : true
const assetPrefix = process.env.NEXT_PUBLIC_CDN_URL || ''
const buildId = process.env.NEXT_PUBLIC_BUILD_ID || null

module.exports = {
  reactStrictMode: true,
  poweredByHeader: false,
  productionBrowserSourceMaps: true,
  eslint: {
    ignoreDuringBuilds: true
  },
  compress,
  assetPrefix,
  generateBuildId: async () => buildId
}
