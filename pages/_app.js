import AppInsightsContextProvider from '../components/AppInsights/ContextProvider'
import '../styles/globals.css'

function MyApp({ Component, pageProps }) {
  return (
    <AppInsightsContextProvider>
      <Component {...pageProps} />
    </AppInsightsContextProvider>
  )
}

export default MyApp
