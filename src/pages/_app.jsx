/* eslint-disable react/jsx-props-no-spreading */

import AppInsightsContextProvider from '~/components/AppInsightsContextProvider'
import '~/styles/globals.css'

function MyApp({ Component, pageProps }) {
  return (
    <AppInsightsContextProvider>
      <Component {...pageProps} />
    </AppInsightsContextProvider>
  )
}

export default MyApp
