import { MetadataRoute } from 'next'
import { getAbsoluteUrl } from '@/lib/url'

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: getAbsoluteUrl(),
      lastModified: new Date(),
      changeFrequency: 'yearly',
      priority: 1
    }
  ]
}
