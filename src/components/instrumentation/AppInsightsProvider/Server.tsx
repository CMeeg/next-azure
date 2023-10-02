import 'server-only'
import { PropsWithChildren } from 'react'
import { AppInsightsContextProvider } from './Client'

const AppInsightsProvider = ({ children }: PropsWithChildren) => {
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING

  if (!connectionString) {
    return children
  }

  return (
    <AppInsightsContextProvider connectionString={connectionString}>
      {children}
    </AppInsightsContextProvider>
  )
}

export { AppInsightsProvider }
