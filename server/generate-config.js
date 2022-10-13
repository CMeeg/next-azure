require('dotenv').config({ path: './.env', override: true })
require('dotenv').config({ path: './.env.production', override: true })
require('dotenv').config({ path: './.env.local', override: true })

const path = require('path')
const fs = require('fs')
const loadConfig = require('next/dist/server/config').default
const nextConfig = require('../next.config')

loadConfig('phase-production-build', path.join(__dirname), nextConfig).then(
  (config) => {
    config.distDir = './.next'
    config.configOrigin = 'next.config.js'

    fs.writeFileSync('next.config.json', JSON.stringify(config))
  }
)
