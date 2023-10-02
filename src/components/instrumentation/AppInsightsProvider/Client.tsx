'use client'

import {
  AppInsightsContext,
  ReactPlugin
} from '@microsoft/applicationinsights-react-js'
import { ApplicationInsights } from '@microsoft/applicationinsights-web'
import { PropsWithChildren } from 'react'

interface State {
  appInsights: ApplicationInsights
  reactPlugin: ReactPlugin
}

// Store the AI state on `window` so we aren't constantly re-initializing it on every hot-reload during `npm run dev` (we can't use a `Symbol` for this, as we'd get a new symbol on every hot-reload)
const getState = () =>
  (typeof window !== 'undefined' &&
    ((window as any).__AI_STATE__ as State | undefined)) ||
  undefined

const setState = (state: State) => {
  if (typeof window !== 'undefined') {
    ;(window as any).__AI_STATE__ = state
  }
}

function getOrInit(connectionString: string): State | undefined {
  // We don't want to run this AI setup server-side - that has a separate setup in `instrumentation.ts`
  if (process.env.NEXT_RUNTIME) {
    return undefined
  }

  // We need a connection string
  if (!connectionString) {
    return undefined
  }

  let state = getState()
  if (state) {
    return state
  }

  const reactPlugin = new ReactPlugin()
  const appInsights = new ApplicationInsights({
    config: {
      connectionString: connectionString,
      enableAutoRouteTracking: true,
      extensions: [reactPlugin],
      extensionConfig: {
        [reactPlugin.identifier]: {}
      }
    }
  })

  appInsights.loadAppInsights()

  state = {
    appInsights,
    reactPlugin
  }

  setState(state)

  return state
}

interface AppInsightsContextProviderProps extends PropsWithChildren {
  connectionString: string
}

function AppInsightsContextProvider({
  connectionString,
  children
}: AppInsightsContextProviderProps) {
  return (
    <AppInsightsContext.Provider
      value={getOrInit(connectionString)?.reactPlugin!}
    >
      {children}
    </AppInsightsContext.Provider>
  )
}

export { AppInsightsContextProvider }

export type { AppInsightsContextProviderProps }
