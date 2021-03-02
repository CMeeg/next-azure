# next-azure

This is a sample [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app) that exists to demonstrate:

* A Next.js app hosted and running in Azure app services with full support for SSR and SSG scenarios including [Automatic Static Optimization](https://nextjs.org/docs/advanced-features/automatic-static-optimization), and [Incremental Static Regeneration](https://nextjs.org/docs/basic-features/data-fetching#incremental-static-regeneration)
* A CI/CD pipeline for building and deploying a Next.js app to Azure app services via Azure DevOps pipelines

> If you only need support for [statically generated pages](https://nextjs.org/docs/advanced-features/static-html-export) via `next export` then check out [Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/deploy-nextjs) instead.

## Getting started

The intention is not for this repo to be cloned and used to bootstrap other projects, but to act as a sample that can be copied from as needed into existing Next projects.

This guide will focus on:

* [How to get setup in Azure Portal](#azure-portal-setup)
* [Which files to copy over from this sample project to your app](#app-setup)
* [How to get setup in Azure Pipelines](#azure-pipelines-setup)

## Azure Portal setup

> The setup of the resources described below could be scripted and automated (and after writing out the below, this is on my list TODO list 😅), but only manual steps will be provided for now.
>
> This guide isn't supposed to be exhaustive, and you may want or need to do more (or less) outside of what is written here, but at least for your first time through it's recommended to stick to the script (so to speak) and then adapt as you see fit after you have something successfully up and running.
>
> Having said that, you may have your own conventions or best practices etc so feel free to deviate where necessary!

An assumption is made before we begin that you have an Azure account and subscription in which to create the following resources.

### Resource group

* Add a new resource group in your chosen subscription
* Give it a suitable name and select your preferred region
* Add tags if you wish and create the resource group

### App service

* Add a new app service to your new resource group
* Publish as Code to a `Node 12 LTS` stack on Windows, and select your preferred region
  * Linux should be fine too, but I've not tested this myself - feel free to change this to Linux if you prefer, but beware of [limitations](https://docs.microsoft.com/en-us/azure/app-service/overview#limitations)
* Create a new app service plan and select your preferred SKU and size
  * To get the most out of the pipeline you will need a SKU that provides you with deployment slots so at least `S1` is recommended, but the pipeline can be amended if you don't need or want slots
* Add monitoring with application insights
  * This is optional, but it is assumed in the sample app that you will use application insights - if you don't you will need to make some adjustments and not follow some of the other related steps below
* Add tags if you wish and create the app service

### App service configuration

> We are going to setup our app service to support multiple environments using deployment slots, and pushes to our `main` branch will deploy into a `uat` slot with [auto swap](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots#configure-auto-swap) enabled into the `production` slot.

* After your app service has been created, navigate to it in the portal
* Select the Configuration blade
  * Under Application settings add the following as **non-slot settings** (remember to click Save and Continue!)
    * `WEBSITE_SWAP_WARMUP_PING_STATUSES` = `200`
  * And the following as **slot settings**
    * `BASE_URL` = {URL of your app service}
    * `APP_ENV` = `production`
  * Rename the following setting and make it a **slot setting**
    * `APPINSIGHTS_INSTRUMENTATIONKEY` to `NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY`
  * Change the following setting to be a **slot settings**
    * `APPLICATIONINSIGHTS_CONNECTION_STRING`
* Select the Deployment slots blade
  * Add the following deployment slots, choosing **not to clone** settings
    * `preview`
    * `build`
  * On each of these slots, go to the Configuration blade
    * Under Application settings add (or change if it exists) the following as **non-slot settings**
      * `WEBSITE_NODE_DEFAULT_VERSION` = `12.13.0` (or whatever version your main app service slot is set to)
  * And the following as **slot settings**
    * `BASE_URL` = {URL of the deployment slot}
    * `APP_ENV` = {Name of the slot e.g. `preview`}
* Navigate back up to the main app service and select the Deployment slots blade again
  * Add the following deployment slot, choosing to **clone settings** from the production (default) slot this time
    * `uat`
  * In the `uat` slot select the Configuration blade
    * Under Application settings change the following **slot settings**
      * `BASE_URL` = {URL of your `uat` deployment slot}
      * `APP_ENV` = `uat`
    * Under General settings > Deployment slot set
      * `Auto swap enabled` = `On`
      * `Auto swap deployment slot` = `production`

You should now have the app service setup and configured with four deployment slots:

* `production` (default)
* `uat`
* `build`
* `preview`

### CDN

> We are going to use a CDN for static assets (CSS, Javascript bundles) built by Next, and for other static assets in our app e.g. files in our `public` folder.

* Create a new CDN profile
  * Give it a name, add it to the same resource group as the app service, and choose the `Standard Microsoft` pricing tier
  * Create a CDN endpoint now and give it a name
  * Set the origin type to `Web app` and choose your app service as the origin hostname
  * Create the CDN profile and endpoint
* After the CDN profile and endpoint have been created, copy the endpoint hostname (URL)
* Switch back to your app service and select the Configuration blade
  * Under Application settings add the following **slot setting**
    * `NEXT_PUBLIC_CDN_URL` = {Your CDN endpoint hostname (URL)}

## App setup

* Copy across the following files from this repo
  * `.azure/**/*`
  * `src/components/**/*`
    * Place these wherever you place React components in your project
  * `server.js`
* Add the following dependencies
  * `@microsoft/applicationinsights-react-js`
  * `@microsoft/applicationinsights-web`
  * `applicationinsights`
* Amend the following files (use the files in this repo as an example)
  * `next.config.js`
    * Set [compress](https://nextjs.org/docs/api-reference/next.config.js/compression) using the environment variable `NEXT_COMPRESS`
    * Set [assetPrefix](https://nextjs.org/docs/api-reference/next.config.js/cdn-support-with-asset-prefix) using the environment variable `NEXT_PUBLIC_CDN_URL`
    * Set the [Build ID](https://nextjs.org/docs/api-reference/next.config.js/configuring-the-build-id) using the environment variable `NEXT_PUBLIC_BUILD_ID`
  * `package.json`
    * Change your `start` script to `node server.js`
  * [Custom `App`](https://nextjs.org/docs/advanced-features/custom-app)
    * Import the `AppInsightsContextProvider` component and wrap it around the `<Component />` element
  * `.env.template`
    * If you maintain an env template settings file you may want to copy the contents of this file over
  * `src/lib/utils.js`
    * There are some constants and functions in here that you may find of use in your project - feel free to change the name and location of the file
    * In particular the `getCdnUrl` function is useful to generate URLs with the Build ID in so that they be cached by the CDN and busted by a new build - see the `favicon` in `src/pages/index.jsx` as an example
* Amend the Azure Pipelines yaml (`.azure/azure-pipelines.yml`)
  * Change the following variable values to match the names of the resources you have setup in Azure
    * `AzureAppService` = {Name of your app service}
    * `AzureResourceGroup` = {Name of your resource group}
  * Change the following variable value to something relevant for your project - we will use this in a minute when creating a service connection in Azure DevOps
    * `AzureServiceConnection` = {Your choice of service connection name}
* Commit and push your changes to your `develop` branch
  * Or whatever branch you are making these changes on

Your app should now be prepared for hosting in Azure app services.

## Azure pipelines setup

An assumption is made before we begin that you have an Azure DevOps account and project in which to create the pipeline.

### Service connection

* Under Projects settings > Pipelines > Service connections, create a new service connection
  * Select `Azure resource manager` as connection type
  * Select `Service principal (automatic)` as authentication method
  * When prompted, sign in using credentials that have access to the subscription and resources you have setup in the Azure Portal
  * Select your scope level as `Subscription` and select the Subscription and Resource group that contains your resources
  * Set the service connection name to whatever you chose when editing the `azure-pipelines.yml` file in the [last step](#app-setup), add a description if you wish, and save

### Environments

* Under Pipelines > Environments, create the following environments, leaving all settings as their defaults
  * `preview`
  * `build`
  * `production`

### Variable groups

* Under Pipelines > Library, create the following variable groups, leaving all settings as their defaults unless otherwise stated
  * `next-app-env-vars`
    * Add variable
      * `NEXT_COMPRESS` = `false`
  * `next-app-env-vars-preview`
    * Add variables
      * `BASE_URL` = {URL of your `preview` deployment slot}
      * `APP_ENV` = `preview`
      * `AzureAppServiceSlot` = `preview`
  * `next-app-env-vars-build`
    * Add variables
      * `BASE_URL` = {URL of your `build` deployment slot}
      * `APP_ENV` = `build`
      * `AzureAppServiceSlot` = `build`
  * `next-app-env-vars-production`
    * Add variables
      * `BASE_URL` = {URL of your `production` deployment slot}
      * `APP_ENV` = `production`
      * `AzureAppServiceSlot` = `uat`
      * `NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY` = {Your application insights instrumentation key}
      * `NEXT_PUBLIC_CDN_URL` = {Your CDN endpoint hostname (URL)}

### Pipeline

* Go to Pipelines > Pipelines, and create a pipeline
  * Choose the relevant option for where your repo is located, and authorise as prompted
  * Once authorised, select your repository and authorise as prompted here also
  * Select `Existing Azure Pipelines YAML file` to configure your pipeline
  * Select the branch and path to your `azure-pipelines.yml` file, and continue
  * Run the pipeline

> The first time the pipeline runs will be the slowest - the main things that slow the execution of the pipeline down are: if this is the first time you have executed `yarn install` in the pipeline or on the app service (slot); or when new dependencies are added.
>
> The pipeline must run `yarn install` in the build step, but it also gets executed on the app service (slot) because the node server needs access to production node module dependencies, but deploying them via the pipeline is *extremely* slow.
>
> Caching is in place in the pipeline (based on the contents of the `yarn.lock` file) for subsequent runs, and if no changes are made then running `yarn install` on the app service (slot) takes no time at all.

You should now have a a functioning CI/CD pipeline for your Next.js project that will build and deploy:

* Pull requests targeting `develop` to a `preview` environment (slot)
* Pushes to `develop` to a `build` environment (slot)
* Pushes to `main` to a `uat` environment (slot) that auto-swaps into `production`
