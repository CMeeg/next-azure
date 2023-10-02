import { MetadataRoute } from 'next'
import { environment, currentEnvironment } from '@/lib/environment'
import { getAbsoluteUrl } from '@/lib/url'

export default function robots(): MetadataRoute.Robots {
  if (currentEnvironment !== environment.production) {
    return {
      rules: {
        userAgent: '*',
        disallow: '/'
      }
    }
  }

  return {
    rules: {
      userAgent: '*',
      allow: '/'
    },
    sitemap: getAbsoluteUrl('sitemap.xml')
  }
}
