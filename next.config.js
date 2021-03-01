const compress = process.env.NEXT_COMPRESS ? !!process.env.NEXT_COMPRESS : true

module.exports = {
  reactStrictMode: true,
  poweredByHeader: false,
  compress
}
