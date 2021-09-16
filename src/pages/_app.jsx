import AppInsightsContextProvider from '~/components/AppInsights/ContextProvider'
import '~/styles/globals.css'

function MyApp({ Component, pageProps }) {
  return (
    <AppInsightsContextProvider>
      {/* eslint-disable-next-line react/jsx-props-no-spreading */}
      <Component {...pageProps} />
    </AppInsightsContextProvider>
  )
}

export default MyApp
