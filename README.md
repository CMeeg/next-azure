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

>  This guide isn't supposed to be exhaustive - it's just a sample project after all - and you may want or need to do more (or less) outside of what is written here, but at least for the first time through it's recommended to [stick to the script](#why-not-automate-or-script-the-setup) (so to speak) and then adapt as you see fit after you have something successfully up and running.
>
> Having said that, you may have your own conventions or best practices etc so feel free to deviate if you want to!

## Azure Portal setup

An assumption is made before we begin that you have an Azure account and subscription in which to create the following resources.

### Resource group

> You may already have a resource group where you want to place the required resources, in which case you can skip this step.

* Add a new resource group in your chosen subscription
* Give it a suitable name and select your preferred region
* Add tags if you wish and create the resource group

### App service

* Add a new app service to your resource group
* Publish as Code to a `Node 12 LTS` stack on [Windows](#why-a-windows-app-service-and-not-linux), and select your preferred region
* Create a new app service plan and select your [preferred SKU](#what-app-service-plan-sku-should-i-choose) and size
* Add monitoring with [application insights](#do-i-have-to-add-application-insights)
* Add tags if you wish and create the app service

### CDN

* Create a new [CDN profile](#do-i-need-a-cdn)
* Give it a name, add it to the same resource group as the app service, and choose the `Standard Microsoft` pricing tier
* Create a CDN endpoint now and give it a name
* Set the origin type to `Web app` and choose your app service as the origin hostname
* Create the CDN profile and endpoint

### App service configuration

* After your app service and CDN have been created, navigate to the app service in the portal
* Select the `Configuration` blade
  * Under `Application settings` add the following as **slot settings**
    * `BASE_URL` = {URL of your app service}
    * `APP_ENV` = `production`
    * `NEXT_PUBLIC_CDN_URL` = {URL of your CDN endpoint}
  * Rename the following setting and make it a **slot setting**
    * `APPINSIGHTS_INSTRUMENTATIONKEY` to `NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY`
  * Change the following setting to be a **slot setting**
    * `APPLICATIONINSIGHTS_CONNECTION_STRING`

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

## Azure pipelines setup

An assumption is made before we begin that you have an Azure DevOps account and project in which to create the pipeline.

### Service connection

* Under Projects settings > Pipelines > Service connections, create a new service connection
* Select `Azure resource manager` as connection type
* Select `Service principal (automatic)` as authentication method
* When prompted, sign in using credentials that have access to the subscription and resources you have setup in the Azure Portal
* Select your scope level as `Subscription` and select the Subscription and Resource group that contains your resources
* Set the service connection name, add a description if you wish, and save

### Environments

* Under Pipelines > Environments, create a `production` environment
* Leave all settings as their defaults and save

### Variable groups

* Under Pipelines > Library, create the following variable groups, leaving all settings as their defaults, but adding the variables stated
  * `next-app-env-vars`
    * `AzureAppService` = {Name of your app service}
    * `AzureResourceGroup` = {Name of your resource group}
    * `AzureServiceConnection` = {Name of your service connection}
    * `NEXT_COMPRESS` = `false`
  * `next-app-env-vars-production`
    * `APP_ENV` = `production`
    * `AzureAppServiceSlot` = `production`
    * `BASE_URL` = {URL of your app service}
    * `NEXT_PUBLIC_APPINSIGHTS_INSTRUMENTATIONKEY` = {Your application insights instrumentation key}
    * `NEXT_PUBLIC_CDN_URL` = {URL of your CDN endpoint}

### Pipeline

* Go to Pipelines > Pipelines, and create a pipeline
* Choose the relevant option for where your repo is located (e.g. GitHub), and authorise as requested
* Once authorised, select your repository and authorise as requested here also
* Select `Existing Azure Pipelines YAML file` to configure your pipeline
* Select the branch and path to your `.azure/azure-pipelines.yml` file, and continue
* Run the pipeline and make sure it runs to completion and you can browse to your app, which is now hosted successfully in Azure app services

## Usage

From this point forward any push to your `main` branch will trigger the pipeline and should result in your app being built and deployed to the app service.

You may want to customise or extend the pipeline, for example, to build and deploy to other environments when commits are pushed to different branches or pull requests are pushed targeting specific branches.

## FAQ

### Why not automate or script the setup?

The setup of the Azure resources could be scripted and automated (and if this was a "real" project I would definitely do that 😅), but only manual steps are provided for a few reasons:

* I considered a few ways of scripting it - Farmer, Pulumi, ARM templates - but I don't know who the audience for this sample will be (or even if there will be an audience) and what the "tool of choice" would be for them so it seemed more pragmatic to just describe manual steps for now
* If and when I automate it for my own needs I can contribute it back here later!

### Why a Windows app service and not Linux?

Linux for the app service should be fine too, but I've not tested this myself - feel free to change to Linux if you prefer, but consider the [limitations](https://docs.microsoft.com/en-us/azure/app-service/overview#limitations) if you have not already.

### What app service plan SKU should I choose?

This sample project is functional on a free plan, but feel free to choose whatever you wish.

### Do I have to add application insights?

In short, no, but it is assumed in the sample app and the setup steps that you will be using application insights.

If you don't want to use application insights you will need to make some adjustments to the sample app code as you copy it across and not follow some of related steps - it should hopefully be easy enough to pull it out if you don't want it in there.

### Do I need a CDN?

In short, no, but it is assumed in the sample app and the setup steps that you will be using a CDN.

If you don't want to use a CDN then you can skip creating the resources in the Azure portal and then just not set the `NEXT_PUBLIC_CDN_URL` environment variable. You could remove the related code, but it won't harm to keep it in place and then it's there if you change your mind later.

### How long does the pipeline take to run?

It depends on a few factors (e.g. the size and complexity of your app and the app service plan SKU that you have chosen), but from running this sample a few times it has taken anywhere between 3 - 10 mins to run to completion.

The first time the pipeline runs or after any changes to `npm` dependencies (anything that causes a change in the `yarn.lock` file) will be the slowest as these runs will not benefit from cached files.

There is a double hit from `yarn install` in that case as it runs during the build step, but it also gets executed on the app service because the node server needs access to production node module dependencies, and deploying them from the pipeline to the app service along with the rest of the applicaiton files is *extremely* slow.

As mentioned, caching is in place in the pipeline (based on the contents of the `yarn.lock` file) for subsequent runs, and if no changes have been made to dependencies then running `yarn install` on the app service does not take much time either.
