const baseUrl = process.env.BASE_URL || 'http://localhost:3000'

const baseCdnUrl = process.env.NEXT_PUBLIC_CDN_URL || null
const nextBuildId = process.env.NEXT_PUBLIC_BUILD_ID || null

const environment = {
  development: 'development'
}

const currentEnv =
  process.env.APP_ENV || process.env.NODE_ENV || environment.development

const isDevelopmentEnv = () => currentEnv === environment.development

const joinUrlSegments = (segments) => {
  if (!segments?.length) {
    return ''
  }

  const lastSegmentIndex = segments.length - 1

  const urlSegments = segments.map((segment, index) => {
    let urlSegment =
      index > 0 && segment.startsWith('/') ? segment.slice(1) : segment
    urlSegment =
      index < lastSegmentIndex && urlSegment.endsWith('/')
        ? urlSegment.slice(0, -1)
        : urlSegment

    return urlSegment
  })

  return urlSegments.join('/')
}

const getAbsoluteUrl = (path) => {
  if (!path) {
    return baseUrl
  }

  return joinUrlSegments([baseUrl, path])
}

const getCdnUrl = (path) => {
  if (!path || !baseCdnUrl || !nextBuildId) {
    return path
  }

  return joinUrlSegments([baseCdnUrl, nextBuildId, path])
}

export { isDevelopmentEnv, getAbsoluteUrl, getCdnUrl }
