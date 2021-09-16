import { useContext } from 'react'
import { AppInsightsContext } from './ContextProvider'

const useAppInsights = () => useContext(AppInsightsContext)

export { useAppInsights }
