# next-azure

## Getting started

### Create and configure your app

* Init a new Git repo for your app and push the "main" branch to a remote e.g. on GitHub
* Create a new feature branch where we will do the basic setup for your app e.g. `feature/create-next-app`
* Run Create Next App using this template
  * TODO: JavaScript or TypeScript
* Edit `.azure/main.parameters.json.template`
  * Change the `value` of the `projectName` parameter
    * This defaults to `next-azure`, but should be something specific to your project
    * It is used in Azure resource names so should be named [appropriately](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules) (alphanumeric and hyphens are generally safe, and safe for the resources used by this template)
* Commit and push changes

### Create resources in Azure portal

There is a choice to make before you continue - do you want to deploy your application to:

1. One app service per environment
2. One app service with one [deployment slot](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots) per environment

Steps that are prefixed with **Slots** are only applicable if you choose option 2. Steps without the prefix are applicable to both options.

> See the [FAQ section](#should-i-use-app-service-deployment-slots) for more info on why you might choose one option over the other.

It is assumed that you have an active Azure Subscription into which you can deploy your resources.

#### Create resource groups

* Create resource group for "preview" environment resources e.g. `next-azure-preview-rg`
* Create resource group for "production" environment resources e.g. `next-azure-prod-rg`
* **Slots** Create resource group for "shared" resources e.g. `next-azure-rg`
  * "shared" here meaning that the resources in this group are shared between more than one environment e.g. the app service is in this group because it has a slot per environment

> The name of the resource groups don't really "matter" in that they can be whatever you want them to be, but the convention used in the Bicep files that will be used to create the resources required by the app is generally `{projectName}-{envName}-{resourceSuffix}` so that's what is used in the examples. You can change these conventions if you like though - see the [FAQ](#how-can-i-change-the-resource-naming-conventions).

### Create Azure DevOps pipeline

It is assumed that you have an active Azure DevOps account in which you can create your pipeline.

#### Create service connections

* Create or enter the Azure DevOps project where you will create your pipeline
* Go to Projects settings > Pipelines > Service connections
* Create a new service connection for the `preview` environment
  * Select `Azure resource manager` as connection type
  * Select `Service principal (automatic)` as authentication method
  * When prompted, sign in using credentials that have access to the subscription and resources groups you have setup in the Azure Portal
  * Select your scope level as `Subscription` and select the Subscription and Resource group that is to be used for `preview` resources e.g. `next-app-preview-rg`
  * Set the service connection name e.g. `next-azure-app-preview`
  * Add a description if you wish
  * Choose to "Grant access to all pipelines"
  * Save
* Repeat all of the above steps to create a separate service connection for the `production` environment
* **Slots** Give the Service Principal(s) permissions to contribute to resources in the "shared" resource group
  * Choose to edit any of your new Service Connections
  * From the Overview tab, click on `Manage Service Principal`
  * Copy the `Display name` of the service principal
  * Navigate to your "shared" resource group in the Azure Portal
  * Click on Access Control (IAM) > Role Assignments
  * Click Add > Add role assignment
    * Choose the Contributor role, click Next
    * Choose Assign access to User, group, or service principal, click Select members
    * Paste the `Display name` of the service principal you copied earlier
    * Select all of the matches
    * Add a description if you wish
    * Review + assign your changes

> The choice to "Grant access to all pipelines" when creating the Service Principal(s) is done for convenience in these getting started instructions, but you can choose not to do this and configure specific [pipeline permissions](https://docs.microsoft.com/en-us/azure/devops/pipelines/policies/permissions?view=azure-devops#set-service-connection-permissions) if you wish.

#### Create environments

* Go to Pipelines > Environments, and create a New environment
  * Name it `preview`
  * Give it a description if you want to
  * Leave all other settings as their defaults, and click Create
* Repeat the above to create another environment named `production`
* Edit the `production` environment
* Click More actions > Approvals and checks
* Click Add
  * Select Approvals, click Next
  * Add Approvers e.g. yourself
  * Set other options as you want
  * Click Create

> Approvals and checks is optional, so feel free to skip that if you want.

#### Create variable groups

* Go to Pipelines > Library, and create the following variable groups:
  * `next-app-env-vars`
    * `WebAppSkuName` = {The name of the SKU you want your app service to use - `F1` (Free) is the minimum unless you are using **Slots** in which case `B1` is the minimum Dev/Test SKU, and `S1` is the minimum production SKU}
    * `WebAppSkuCapacity` = {The number of app service instances you wish to scale out to by default e.g. `1`}
    * **Slots** `AzureSharedResourceGroup` = {Name of your "shared" resource group}
  * `next-app-env-vars-preview`
    * `AzureResourceGroup` = {Name of your "preview" resource group}
    * `AzureServiceConnection` = {Name of your "preview" service connection}
    * **Slots** `WebAppSlotName` = `preview`
  * `next-app-env-vars-production`
    * `AzureResourceGroup` = {Name of your "production" resource group}
    * `AzureServiceConnection` = {Name of your "production" service connection}
    * **Slots** `WebAppSlotName` = `production`

> You may want to change the name of these variable groups, in which case you will also need to update the names in `.azure/azure-pipelines.yml` where they are referenced. Don't forget to commit and push any changes that you make before creating and running the pipeline.

#### Create the pipeline

* Go to Pipelines > Pipelines, and create a pipeline
* Choose the relevant option for where your repo is located (e.g. GitHub), and authorise as requested
* Once authorised, select your repository and authorise as requested here also
* Select `Existing Azure Pipelines YAML file` to configure your pipeline
* Select the branch (this will be the feature branch you created earlier) and path to your `.azure/azure-pipelines.yml` file, and continue
* Save the pipeline (you will need to use the dropdown next to the "Run" button)

### Run the pipeline

* Create a new pull request from your feature branch targeting your "main" branch to kick off a new pipeline run targeting your preview environment
* Merge the pull request in to your "main" branch to kick off a new pipeline run targeting your production environment

> Manual runs will use the `preview` environment settings because that is the default set in the pipeline yaml.

✔️ That's the basics done! Please read through the rest of this document for some more ideas and instructions of how to use this pipeline.

## Usage

### Add support for additional target environments

TODO

### Add custom domain name and SSL

TODO: Mention there will be a problem with CDN endpoint origin - will need to delete and recreate resource

### Variable group settings

TODO: List variables that can be used, what they do, if they're required, if slot-specific etc

* AzureResourceGroup
* AzureServiceConnection
* AzureSharedResourceGroup
* WebAppSkuName
* WebAppSkuCapacity
* WebAppSlotName
* WebAppDomainName
* WebAppCertName

## FAQ

### Should I use app service deployment slots?

During the "Getting started" section of this documentation you were asked to make a choice - do you want to deploy your application to:

1. One app service per environment
2. One app service with one deployment slot per environment

If this is / will be a "dev/test" app or you want to keep costs low then option 1 should be fine, but bear in mind that the "F" (free) and "D" (cheap, relatively) app service SKUs are quite limited in their capabilities.

If this is / will be a "production" app then option 2 will be more cost effective in the long run as you pay for the app service plan and the slots "come for free" - currently 5 slots on an S1 plan.

However, you can choose to go with option 1 to begin with until you a) outgrow it; or b) are ready to go into production, and then switch to option 2 at that point.

### How can I change the resource naming conventions?

TODO

### Can I use GitHub Actions instead of Azure DevOps pipelines?

TODO




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
  * `src/lib/env.js`
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

### App Insights

The Application Insights implementation included in this sample app uses the [Node SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/nodejs) for tracking initial requests to the server as well as the [JavaScript SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/javascript) for tracking client requests including "page views" when navigating via routing.

If you want to review and change the configuration you can:

* Find the server config in `./server.js`
* Find the client config in `./src/components/AppInsights/Sdk.jsx`

If you want to use the Application Insights to track custom metrics you can import and use the provided hook, which will give you access to the Application Insights instance. You should only use this instance inside `useEffect` though as it's client-side only:

```javascript
import { useAppInsights } from '~/components/AppInsights'

// This gives you access to the app insights instance
const appInsights = useAppInsights()
```

## FAQ

### Why a Windows app service and not Linux?

Linux for the app service should be fine too, but I've not tested this myself - feel free to change to Linux if you prefer, but consider the [limitations](https://docs.microsoft.com/en-us/azure/app-service/overview#limitations) if you have not already.

### What app service plan SKU should I choose?

This sample project runs fine on a Free SKU, but you may quickly become limited by it if you are planning to develop any non-trivial application. The minimum SKU that your app can run under ultimately depends on your requirements. For example:

* you should not run a production application on anything below an `S1` tier
* if you require a custom domain and SSL then you will need to to select at least a Basic tier SKU
* if your app needs to run under a 64-bit process you will need to select at least a Basic tier SKU
* if you wish to use deployment slots then you will need to select at least a Standard tier SKU

Feel free to choose whatever plan you is right for you and your project, but it's worth doing a bit of planning and research up front as to what your minimum requirements are and what SKUs are suitable, and how much that will [cost](https://azure.microsoft.com/pricing/calculator/) you.

### Do I have to add Application Insights?

In short, no, but it is assumed in the sample app that you will be using Application Insights.

If you don't want to use Application Insights you will need to make some adjustments to the sample app code as you copy it across and not follow some of related steps - it should hopefully be easy enough to pull it out if you don't want it in there.

You will also need to modify the bicep files in `.azure/infra` so that the Application Insights resource does not get created or referenced.

### Do I need a CDN?

In short, no, but it is assumed in the sample app that you will be using a CDN.

If you don't want to use a CDN then you can modify the bicep files in `.azure/infra` to not create the CDN resources in Azure and remove the related code - have a search in your project for `cdn`.

### How long does the pipeline take to run?

It depends on a few factors (e.g. whether the infrastructure resources already exist or need to be created by the pipeline, the size and complexity of your app, the app service plan SKU that you have chosen), but from running this sample a few times it has taken anywhere between 3 - 15 mins to run to completion.

The first time the pipeline runs or after any changes to `package.json` dependencies (anything that causes a change in the `yarn.lock` file) will be the slowest as these runs will not benefit from a `node_modules` cache task present in the pipeline.

There is also a second hit from `yarn install` in this case as it runs during the build step in the pipeline, but it also gets executed on the app service because the node server needs access to production node module dependencies. The `node_modules` output from the build step is not deployed with the rest of the build output because a) it includes `devDependencies` that we don't need on the server; and b) deploying `node_modules` from the pipeline to the app service along with the rest of the application files via zip deploy has proven to be much slower than running a production-only `yarn install` post-deployment.

As mentioned, caching is in place in the pipeline (based on the contents of the `yarn.lock` file) for subsequent runs, and if no changes have been made to dependencies then the time required to run `yarn install` in the pipeline and on the app service is much reduced.
