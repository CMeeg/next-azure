# next-azure

This is a sample [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app) that exists to demonstrate:

* A Next.js app hosted and running in Azure app services with full support for SSR and SSG scenarios including [Automatic Static Optimization](https://nextjs.org/docs/advanced-features/automatic-static-optimization), and [Incremental Static Regeneration](https://nextjs.org/docs/basic-features/data-fetching#incremental-static-regeneration)
* A CI/CD pipeline for building and deploying a Next.js app to Azure app services via Azure DevOps pipelines
  * The pipeline will also provision the necessary infrastructure for you in Azure as described in the included [Bicep](https://github.com/Azure/bicep) files

> If you only need support for [statically generated pages](https://nextjs.org/docs/advanced-features/static-html-export) via `next export` then check out [Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/deploy-nextjs) instead.

## Getting started

The intention is not for this repo to be cloned and used to bootstrap other projects, but to act as a sample that can be copied from as needed into existing Next projects.

This guide will focus on:

* [Which files to copy over from this sample project to your app](#app-setup)
* [How to get setup in Azure Portal](#azure-portal-setup)
* [How to get setup in Azure Pipelines](#azure-pipelines-setup)

>  This guide isn't supposed to be exhaustive - it's just a sample project after all - and you may want or need to do more (or less) outside of what is written here, but at least for the first time through it's recommended to stick to the script (so to speak) and then adapt as you see fit after you have something successfully up and running.
>
> Having said that, you may have your own conventions or best practices etc so feel free to deviate if you want to!

## App setup

* Copy across the following files from this repo
  * `.azure/**/*`
  * `src/components/**/*`
    * Place these wherever you place React components in your project
  * `server.js`
* Add the following `npm` dependencies
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
    * There are some constants and functions in here that you may find of use in your project - feel free to change the name and location of the file, or ignore anything you don't want or need
    * If there is one thing to take from here it would be the `getCdnUrl` function, which is used to generate URLs with the Build ID in the path so that they be cached by the CDN and busted by a new build - see the `favicon` in `src/pages/index.jsx` as an example

## Azure Portal setup

An assumption is made before we begin that you have an Azure account and subscription in which to create the following resources.

### Resource group

* Add a new resource group in your chosen subscription that will be used for resources for the `preview` [environment](#environments)
  * The name doesn't really matter, as long as you are happy with it!
* Give it a suitable name and select your preferred region
  * Ensure that your preferred region supports all of the required resource types (app service, cdn, Application Insights)
* Add tags if you wish and create the resource group
* Repeat to create a separate resource group for resources in the `production` environment

> This is assuming you wish to have a separate resource group per environment - it's perfectly possible to have a single resource group too if that's what you prefer - you will just need to use the single resource group when creating your [service connections](#service-connection) and [variable groups](#variable-groups) for your pipeline.

## Azure pipelines setup

An assumption is made before we begin that you have an Azure DevOps account and project in which to create the pipeline.

### Service connection

* Under Projects settings > Pipelines > Service connections, create a new service connection for the `preview` environment
  * The name doesn't really matter, as long as you are happy with it!
* Select `Azure resource manager` as connection type
* Select `Service principal (automatic)` as authentication method
* When prompted, sign in using credentials that have access to the subscription and resources you have setup in the Azure Portal
* Select your scope level as `Subscription` and select the Subscription and Resource group that is to be used for `preview` resources
* Set the service connection name, add a description if you wish, and save
* Repeat to create a separate service connection for the `production` environment and connect it to the `production` resource group

### Environments

* Under Pipelines > Environments, create an environment named `prod`
  * This name does matter because it needs to match up with the `TargetEnv` variable set in the pipeline yaml file
* Leave all settings as their defaults and save
* Repeat the above to also create an environment named `preview`

### Variable groups

* Under Pipelines > Library, create the following variable groups, leaving all settings as their defaults, but adding the variables stated
  * `next-app-env-vars`
    * `WebAppSkuCapacity` = `1`
    * `WebAppSkuName` = `F1`
    * `WebAppSlot` = `production`
  * `next-app-env-vars-preview`
    * `AzureResourceGroup` = {Name of your `preview` resource group}
    * `AzureServiceConnection` = {Name of your `preview` service connection}
  * `next-app-env-vars-prod`
    * `AzureResourceGroup` = {Name of your `production` resource group}
    * `AzureServiceConnection` = {Name of your `production` service connection}

> Feel free to [change](#what-app-service-plan-sku-should-i-choose) the `WebAppSku*` variables. If you wish to change them for one environment and not the other then just add the adjusted variable to the relevant group e.g. if the production app service should be `S1` then add a `WebAppSkuName` variable to the `next-app-env-vars-prod` group - `next-app-env-vars` are effectively "default settings" and are overridden by variables with the same name in more "specific" groups.

### Pipeline

* Go to Pipelines > Pipelines, and create a pipeline
* Choose the relevant option for where your repo is located (e.g. GitHub), and authorise as requested
* Once authorised, select your repository and authorise as requested here also
* Select `Existing Azure Pipelines YAML file` to configure your pipeline
* Select the branch and path to your `.azure/azure-pipelines.yml` file, and continue
* Run the pipeline and make sure it runs to completion and you can browse to your app, which is now hosted successfully in Azure app services

> You can run the pipeline manually if you just wish to test it and it's not convenient to push to or create a PR to `main` to kick it off automatically. Manual runs will use the `preview` environment settings because that is the default set in the pipeline yaml.

## Usage

From this point forward any push to your `main` branch or pull request targeting `main` will trigger the pipeline and should result in your app being built and deployed to the relevant app service:

* PR targeting `main` deploys to `preview` resources
* Push to `main` deploys to `prod` resources

You may want to customise or extend the pipeline, for example, to build and deploy to other environments when commits are pushed to different branches or pull requests are pushed targeting specific branches.

### Deploying additional app settings

The pipeline can be modified to pass additional app settings through to the app service if required. To do so you pass a `webAppSettings` parameter through to the `az deployment` command in the `Run ARM template` task.

For example, to pass the app setting `FOO`, modify the `inlineScript` of the `Run ARM template` task like this:

```bash
az account show
# webAppSettings is a JSON string (the example shows the value coming from a variable, but it could be hard-coded)
webAppSettings='{"FOO": "$(FOO)"}'
# webAppSettings is then passed as an additional parameter to the az deployment command
az deployment group create -f "$(Build.ArtifactStagingDirectory)/main.json" -g $(AzureResourceGroup) --parameters environment=$(TargetEnv) buildId=$(NEXT_PUBLIC_BUILD_ID) webAppSkuName=$(WebAppSkuName) webAppSkuCapacity=$(WebAppSkuCapacity) webAppSettings="$webAppSettings"
```
These app settings will be merged with the default app settings that are required for the Next app to run in Azure. App settings passed in like in the above example will overwrite default settings with the same name. Be careful that you do not override one of the default app settings unless you really mean to do so!

The default app settings are:

* `APP_ENV`
* `BASE_URL`
* `NEXT_COMPRESS`
* `NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY`
* `NEXT_PUBLIC_BUILD_ID`
* `NEXT_PUBLIC_CDN_URL`
* `NODE_ENV`
* `WEBSITE_NODE_DEFAULT_VERSION`

## FAQ

### Why a Windows app service and not Linux?

Linux for the app service should be fine too, but I've not tested this myself - feel free to change to Linux if you prefer, but consider the [limitations](https://docs.microsoft.com/en-us/azure/app-service/overview#limitations) if you have not already.

### What app service plan SKU should I choose?

This sample project runs fine on a free plan, but feel free to choose whatever you wish.

### Do I have to add Application Insights?

In short, no, but it is assumed in the sample app that you will be using Application Insights.

If you don't want to use Application Insights you will need to make some adjustments to the sample app code as you copy it across and not follow some of related steps - it should hopefully be easy enough to pull it out if you don't want it in there.

You will also need to modify the bicep files in `.azure/infra` so that the Application Insights resource does not get created or referenced.

### Do I need a CDN?

In short, no, but it is assumed in the sample app that you will be using a CDN.

If you don't want to use a CDN then you can modify the bicep files in `.azure/infra` to not create the CDN resources in Azure and remove the related code - have a search in your project for `cdn`.

### How long does the pipeline take to run?

It depends on a few factors (e.g. whether the infrastructure resources already exist or need to be created by the pipeline, the size and complexity of your app, the app service plan SKU that you have chosen), but from running this sample a few times it has taken anywhere between 3 - 15 mins to run to completion.

The first time the pipeline runs or after any changes to `npm` dependencies (anything that causes a change in the `yarn.lock` file) will be the slowest as these runs will not benefit from cached files.

There is a double hit from `yarn install` in that case as it runs during the build step, but it also gets executed on the app service because the node server needs access to production node module dependencies, and deploying them from the pipeline to the app service along with the rest of the application files is *extremely* slow.

As mentioned, caching is in place in the pipeline (based on the contents of the `yarn.lock` file) for subsequent runs, and if no changes have been made to dependencies then running `yarn install` on the app service does not take much time either.
