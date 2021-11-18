import { createContext, useState } from 'react'
import dynamic from 'next/dynamic'

const AppInsightsContext = createContext(null)

const AppInsightsSdk = dynamic(() => import('./Sdk'), {
  ssr: false
})

const AppInsightsContextProvider = ({ children }) => {
  const instrumentationKey =
    process.env.NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY

  const [instance, setInstance] = useState(null)

  return (
    <AppInsightsContext.Provider value={instance}>
      {instrumentationKey && (
        <AppInsightsSdk
          instrumentationKey={instrumentationKey}
          instance={instance}
          setInstance={setInstance}
        />
      )}

      {children}
    </AppInsightsContext.Provider>
  )
}

export default AppInsightsContextProvider

export { AppInsightsContext }
