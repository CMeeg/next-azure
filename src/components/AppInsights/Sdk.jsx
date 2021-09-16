import { useEffect } from 'react'
import { ApplicationInsights } from '@microsoft/applicationinsights-web'

export default function AppInsightsSdk({
  instrumentationKey,
  instance,
  setInstance
}) {
  useEffect(() => {
    if (instance) {
      // We already have an instance

      return
    }

    if (!instrumentationKey) {
      // If we have no key then we can't load app insights

      return
    }

    // Load app insights

    const appInsights = new ApplicationInsights({
      config: {
        instrumentationKey,
        enableAutoRouteTracking: true
      }
    })

    appInsights.loadAppInsights()

    // Manually track the initial page view after load, but app insights will automtically track route changes

    appInsights.trackPageView()

    // app insights has loaded

    setInstance(appInsights)
  }, [instance, instrumentationKey, setInstance])

  return <></>
}
