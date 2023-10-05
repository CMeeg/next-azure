const compress = process.env.NEXT_COMPRESS
  ? process.env.NEXT_COMPRESS === 'true'
  : true
const assetPrefix = process.env.NEXT_PUBLIC_CDN_URL || ''
const buildId = process.env.NEXT_PUBLIC_BUILD_ID || null
const customDomainName = process.env.SERVICE_WEB_CUSTOM_DOMAIN_NAME || ''

const remotePatterns = []
const rewrites = {}
const redirects = []

if (assetPrefix) {
  // Allow the Image component to load images from the CDN
  remotePatterns.push({
    protocol: 'https',
    hostname: process.env.NEXT_PUBLIC_CDN_HOSTNAME
  })
}

if (buildId) {
  // If the `buildId` is present in the path, remove it
  rewrites.beforeFiles = [
    {
      source: `/${buildId}/:path*`,
      destination: '/:path*'
    }
  ]
}

if (customDomainName) {
  // Add a canonical host name redirect
  redirects.push({
    source: `/:path*`,
    missing: [
      {
        type: 'host',
        value: customDomainName
      }
    ],
    destination: `https://${customDomainName}/:path*`,
    permanent: true
  })
}

/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    instrumentationHook: true,
    serverComponentsExternalPackages: ['applicationinsights', 'pino']
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
  },
  async redirects() {
    return redirects
  }
}

module.exports = nextConfig
