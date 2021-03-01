# next-azure

This is a sample [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app) that exists to demonstrate:

* Next hosted and running in Azure app services
  * Fully suporting [server-rendered and statically generated pages](https://nextjs.org/docs/advanced-features/automatic-static-optimization), plus [Incremental Static Regeneration](https://nextjs.org/docs/basic-features/data-fetching#incremental-static-regeneration)
  * If you just need suport for staticically generated pages via `next export` then check out [Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/deploy-nextjs) instead
* A fully functioning CI/CD pipeline for building and deploying your Next app to Azure app services via Azure DevOps pipelines

## Demo

TODO

## Getting started

The intention is not for this repo to be cloned and used to bootstrap other projects, but to act as a sample that can be copied from as needed into existing Next projects.

This guide will focus on:

* [How to get setup in Azure Portal](#azure-portal-setup)
* [Which files to copy over from this sample project to your app](#app-setup)
* [How to get setup in Azure Pipelines](#azure-pipelines-setup)

### Azure Portal setup

N.B. The setup of the required resources could be scripted (and after writing out the below, scripting it is on my list TODO list 😅), but only manual steps will be described to get setup via the Azure Portal. You may also have your own conventions or best practices that you wish to follow so it's easier to stick to the basic requirements here and you can feel free to adapt and automate as you wish.

An assumption is made before we begin that you have an Azure account and subscription in which to create the following resources.

#### Resource group

* Add a new resource group in your chosen subscription
* Give it a suitable name and select your preferred region
* Add tags if you wish and create the resource group

#### App service

* Add a new app service to your new resource group
* Publish as Code to a `Node 12 LTS` stack on Windows, and select your preferred region
  * Linux should be fine too, but the sample is targeted at Windows and Linux is untested - feel free to change this as you prefer, but beware of [limitations](https://docs.microsoft.com/en-us/azure/app-service/overview#limitations)
* Create a new app service plan and select your preferred SKU and size
  * To get the most out of the pipeline you will need a SKU that provides you with deployment slots so at least `S1` is recommended, but the pipeline can be amended if you don't need or want slots
* Add monitoring with application insights
  * This is optional, but recommended - it is assumed in the sample app that you will use application insights so if you don't you will need to make some adjustments
* Add tags if you wish and create the app service

#### App service configuration

N.B. We are going to set our app service up to support multiple environments using deployment slots, and pushes to our `main` branch will deploy into a `uat` slot with [auto swap](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots#configure-auto-swap) enabled into the `production` slot. This may or may not meet your wants and needs, but if this is the first time following along try it out and then you can adjust as you want once things are up and running.

* After your app service has been created, navigate to it in the portal
* Select the Configuration blade
  * Under Application settings add the following as non-slot settings (remember to click Save and Continue!)
    * `WEBSITE_SWAP_WARMUP_PING_STATUSES` = `200`
  * And the following as slot settings
    * `BASE_URL` = {URL of your app service}
    * `APP_ENV` = `production`
* Select the Deployment slots blade
  * Add the following deployment slots, choosing not to clone settings
    * `preview`
    * `build`
  * On each of these slots, go to the Configuration blade
    * Under Application settings add (or change if it exists) the following as non-slot settings
      * `WEBSITE_NODE_DEFAULT_VERSION` = `12.13.0`
  * And the following as slot settings
    * `BASE_URL` = {URL of the deployment slot}
    * `APP_ENV` = {Name of the slot e.g. `preview`}
* Navigate back up to the main app service and select the Deployment slots blade again
  * Add the following deployment slot, choosing to clone settings from the production (default) slot this time
    * `uat`
  * In the `uat` slot select the Configuration blade
    * Under Application settings change the following slot settings
      * `BASE_URL` = {URL of your `uat` deployment slot}
      * `APP_ENV` = `uat`
    * Under General settings > Deployment slot set
      * `Auto swap enabled` = `On`
      * `Auto swap deployment slot` = `production`

### App setup

* Copy across the following files from this repo
  * `.azure/**`
  * `server.js`
* Amend the following files (use the files in this repo as an example)
  * `next.config.js`
    * Set [compress](https://nextjs.org/docs/api-reference/next.config.js/compression) using the environment variable `NEXT_COMPRESS`
  * `package.json`
    * Change your `start` script to `node server.js`
* Amend the Azure Pipelines yaml (`.azure/azure-pipelines.yml`)
  * Change the following variable values to match the names of the resources you have setup in Azure
    * `AzureAppService` = {Name of your app service}
    * `AzureResourceGroup` = {Name of your resource group}
  * Change the following variable value to something relevant for your project - we will use this in a minute when creating a service connection in Azure DevOps
    * `AzureServiceConnection` = {Your choice of service connection name}
* Commit and push your changes to your `develop` branch
  * Assuming you have a `develop` branch, or you can just use your `main` branch

### Azure pipelines setup

* Create a new project in Azure DevOps, or select an existing project
* Under Projects settings > Pipelines > Service connections, create a new service connection
  * Select `Azure resource manager` as connection type
  * Select `Service principal (automatic)` as authentication method
  * When prompted, sign in using credentials that have access to the subscription and resources you have setup in the Azure Portal
  * Select your scope level as `Subscription` and select the Subscription and Resource group that contains your resources
  * Set the service connection name to whatever you chose when editing the `azure-pipelines.yml` file in the last step, add a description if you wish, and save
* Under Pipelines > Environments, create the following environments, leaving all settings as their defaults
  * `preview`
  * `build`
  * `production`
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
* Go to Pipelines > Pipelines, and create a pipeline
  * Choose the relevant option for where your repo is located, and authorise as prompted
  * Once authorised, select your repository and authorise as prompted here also
  * Select `Existing Azure Pipelines YAML file` to configure your pipeline
  * Select the branch and path to your `azure-pipelines.yml` file, and continue
  * Run the pipeline

N.B. The first time the pipeline runs will be the slowest - the main things that slow the execution of the pipeline down is if this is the first time you have executed `yarn install` in the pipeline or on the app service (slot), or when new dependencies are added. The pipeline must run `yarn install` in the build step, but it also gets executed on the app service (slot) because the node server needs access to production node module dependencies, but deploying them via the pipeline is *extremely* slow. Caching is in place in the pipeline (based on the contents of the `yarn.lock` file) for subsequent runs, and if no changes are made then running `yarn install` on the app service (slot) takes no time at all.
