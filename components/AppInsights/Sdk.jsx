import { useEffect } from 'react'
import { ApplicationInsights } from '@microsoft/applicationinsights-web'

export default function AppInsightsSdk({
  connectionString,
  instance,
  setInstance
}) {
  useEffect(() => {
    if (instance) {
      // We already have an instance

      return
    }

    if (!connectionString) {
      // If we have no connection string then we can't load app insights

      return
    }

    // Load app insights

    const appInsights = new ApplicationInsights({
      config: {
        connectionString,
        enableAutoRouteTracking: true
      }
    })

    appInsights.loadAppInsights()

    // Manually track the initial page view after load, but app insights will automtically track route changes

    appInsights.trackPageView()

    // app insights has loaded

    setInstance(appInsights)
  }, [instance, connectionString, setInstance])

  return <></>
}
