const compress = process.env.NEXT_COMPRESS ? process.env.NEXT_COMPRESS === 'true' : true
const assetPrefix = process.env.NEXT_PUBLIC_CDN_URL || ''
const buildId = process.env.NEXT_PUBLIC_BUILD_ID || null

const remotePatterns = []
const rewrites = {}

if (assetPrefix) {
  remotePatterns.push({
    protocol: 'https',
    hostname: process.env.NEXT_PUBLIC_CDN_HOSTNAME
  })
}

if (buildId) {
  rewrites.beforeFiles = [
    {
      source: `/${buildId}/:path*`,
      destination: '/:path*'
    }
  ]
}

/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    instrumentationHook: true
  },
  output: 'standalone',
  reactStrictMode: true,
  poweredByHeader: false,
  eslint: {
    ignoreDuringBuilds: true
  },
  compress,
  assetPrefix,
  generateBuildId: async () => {
    return buildId
  },
  images: {
    remotePatterns
  },
  async rewrites() {
    return rewrites
  }
}

module.exports = nextConfig
