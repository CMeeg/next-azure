const path = require('path')
const fs = require('fs')
const loadConfig = require('next/dist/server/config').default
const nextConfig = require('../next.config')

loadConfig('phase-production-build', path.join(__dirname), nextConfig).then(
  (config) => {
    config.distDir = './.next'
    config.configOrigin = 'next.config.js'
    /* eslint-enable no-param-reassign */

    fs.writeFileSync('next.config.json', JSON.stringify(config))
  }
)
