import { createContext, useState } from 'react'
import dynamic from 'next/dynamic'

const AppInsightsContext = createContext(null)

const AppInsightsSdk = dynamic(() => import('./Sdk'), {
  ssr: false
})

const AppInsightsContextProvider = ({ children }) => {
  const connectionString = process.env.NEXT_PUBLIC_APPINSIGHTS_CONNECTION_STRING

  const [instance, setInstance] = useState(null)

  return (
    <AppInsightsContext.Provider value={instance}>
      {connectionString && (
        <AppInsightsSdk
          connectionString={connectionString}
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
