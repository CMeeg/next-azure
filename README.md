# next-azure

This repository contains a [Create Next App](https://nextjs.org/docs/api-reference/create-next-app) example for deploying a Next.js v12 app to Microsoft Azure App Services (including a CDN for static assets, and Application Insights for monitoring) via Azure DevOps Pipelines.

The Next.js app included in this example is the same app created by the default Create Next App output, but with some additional files, components and config changes to support deployment to Azure.

Changes have been kept to a minimum, but are enough to get you up and running with:

* A CI/CD pipeline for building and deploying a Next.js app to Azure
  * The pipeline will provision the necessary infrastructure for you in Azure as described in the included [Bicep](https://github.com/Azure/bicep) files
* A Next.js app hosted and running in Azure App Services with full support for SSR and SSG scenarios including [Automatic Static Optimization](https://nextjs.org/docs/advanced-features/automatic-static-optimization), and [Incremental Static Regeneration](https://nextjs.org/docs/basic-features/data-fetching#incremental-static-regeneration)
* A CDN for caching static assets, and [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) for application monitoring

> If you only need support for [statically generated pages](https://nextjs.org/docs/advanced-features/static-html-export) via `next export` then check out [Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/deploy-nextjs) instead.

## Getting started

There are three steps to getting started:

* [Use Create Next App](#use-create-next-app) to create a new Next.js app using this example as a template
* [Create Azure Resource Groups and Pipeline](#create-azure-resource-groups-and-pipeline) for deploying your app
* [Run the Pipeline](#run-the-pipeline) to deploy your app

### Use Create Next App

You can use the Create Next App tool to initialise your project using this example repo as a template:

* Init a new Git repo for your app and push the "main" branch to a remote e.g. on GitHub
* Create a new feature branch where you will do the basic setup for your app e.g. `feature/create-next-app`
* Follow the [Create Next App docs](https://nextjs.org/docs/api-reference/create-next-app) to create a Next.js app using this example repo as a template - you will need to use the `-e, --example` option
  * For example: `npx create-next-app@latest -e https://github.com/CMeeg/next-azure`
* Commit and push your changes

> N.B. This example is currently [not using TypeScript](#can-i-use-typescript-with-this-example).

### Create Azure Resource Groups and Pipeline

There is some manual setup required in Azure:

* Resource Groups must be created in the Azure Portal into which the resources required for your app will be deployed
* Service Connections and Variable Groups must be created in Azure DevOps that will be used by the Pipeline

#### Create Resource Groups via the Azure Portal

You will be creating one Resource Group for each target environment. By default, two environments are supported, but [more can be added](#add-additional-target-environments).

To create the Resource Groups:

* Create or switch to the Subscription in the [Azure Portal](https://portal.azure.com/) where you will deploy your app
* Create a Resource Group for `preview` environment resources e.g. `next-azure-preview-rg`
* Create a Resource Group for `production` environment resources e.g. `next-azure-prod-rg`

> The name of the Resource Groups don't really "matter" (i.e. they can be whatever you want them to be), but the convention used in the Bicep files for resource names is generally `{projectName}-{environment}-{resourceSuffix}`. You can change these conventions if you like though - see the [Usage section](#change-the-resource-naming-conventions).

#### Create Service Connections in Azure DevOps

Service Connections will be used to authenticate and authorise deployment operation from the Pipeline to the Resource Groups.

To create the Service Connections:

* Create or enter the [Azure DevOps](https://dev.azure.com/) Project where you will create your Pipeline
* Go to Projects settings > Pipelines > Service connections
* Create a new service connection for the `preview` environment
  * Select `Azure resource manager` as connection type
  * Select `Service principal (automatic)` as authentication method
  * When prompted, sign in using credentials that have access to the Subscription and Resource Groups you have setup in the Azure Portal
  * Select your scope level as `Subscription` and select the Subscription and Resource Group that is to be used for `preview` environment resources
  * Set the service connection name e.g. `next-azure-preview`
  * Add a description if you wish
  * Choose to "Grant access to all pipelines"
  * Save
* Repeat all of the above steps to create a separate Service Connection for the `production` environment

> The choice to "Grant access to all pipelines" when creating the Service Principal(s) is done for convenience in these getting started instructions, but you can choose not to do this and configure specific [pipeline permissions](https://docs.microsoft.com/en-us/azure/devops/pipelines/policies/permissions?view=azure-devops#set-service-connection-permissions) if you wish.

#### Create Environments in Azure DevOps

Environments will be used to track deployments in Azure DevOps and to allow for approvals and checks to be put in place (if desired).

To create the Environments:

* Go to Pipelines > Environments, and create a New environment
  * Name it `preview`
  * Give it a description if you want to
  * Leave all other settings as their defaults, and click Create
* Repeat the above to create another environment named `prod` (production)
* Edit the `prod` environment
  * Click More actions > Approvals and checks
  * Click Add
    * Select Approvals, click Next
    * Add Approvers e.g. yourself
    * Set other options as you want
    * Click Create

> Approvals and checks is optional, but useful if you want to check the output of the "build" Pipeline stages before proceeding with the "deploy" stages - outputs from the build stages are available as Pipeline artifacts that can be downloaded and inspected before making a decision to proceed with the deploy stages. You may want to consider putting Approvals and checks on your `preview` environment also, even if just for the first few runs, as it will give you an opportunity to make sure the pipeline is doing what you expect.

#### Create Variable Groups in Azure DevOps

Variable Groups are used to define variables that are used by the Pipeline. The `next-app-env-vars` Variable Group is used to hold "default" or "shared" values applicable to all target environments, and the `next-app-env-vars-preview` and `next-app-env-vars-prod` Variable Groups hold environment-specific Variables or can override Variables with the same name in the `next-app-env-vars` Variable Group.

To create the Variable Groups:

* Go to Pipelines > Library, and create the following Variable Groups and Variables:
  * `next-app-env-vars`
    * `WebAppSkuName` = {The name of the SKU you want your app service to use - `F1` (Free) is the minimum}
    * `WebAppSkuCapacity` = {The number of app service instances you wish to scale out to by default e.g. `1`}
  * `next-app-env-vars-preview`
    * `AzureResourceGroup` = {Name of your `preview` environment Resource Group}
    * `AzureServiceConnection` = {Name of your `preview` environment Service Connection}
  * `next-app-env-vars-prod`
    * `AzureResourceGroup` = {Name of your `production` Resource Group}
    * `AzureServiceConnection` = {Name of your `production` Service Connection}

> You may want to change the name of these Variable Groups, in which case you will also need to update the names in `.azure/azure-pipelines.yml` where they are referenced.

#### Create the pipeline

The Pipeline will provision your infrastructure in Azure, and build and deploy your application to that infrastructure.

To create the Pipeline:

* Go to Pipelines > Pipelines, and create a Pipeline
* Choose the relevant option for where your repo is located (e.g. GitHub), and authorise as requested
* Once authorised, select your repository and authorise as requested here also
* Select `Existing Azure Pipelines YAML file` to configure your pipeline
* Select the branch and path to your `.azure/azure-pipelines.yml` file, and continue
* Save the Pipeline (i.e. don't Run the Pipeline yet - you will need to use the dropdown next to the "Run" button)

### Run the Pipeline

The Pipeline is now ready to run. It can be triggered by pushing commits to your repository.

Edit `.azure/infra/main.parameters.json.template`:

* Change the `value` of the `projectName` parameter
  * It is used in the names of the Azure resources created by the Pipeline so should be named [appropriately](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)
  * Alphanumeric and hyphens are generally safe, and safe for the resources used by this template
* Commit and push your changes

> By default the pipeline will deploy your app into separate "Free tier" App Services for the `preview` and `production` environments - you may want to take a look at the [Usage section](#usage) before proceeding to see what other options there are, such as [using deployment slots](#use-a-deployment-slot-for-the-preview-environment), or [adding a custom domain and SSL](#add-custom-domain-name-and-ssl).

Create a new pull request from your feature branch to your "main" branch - this will start a new pipeline run and deploy your app to your `preview` environment.

> You may be required to grant permissions to your Variable Groups the first time the Pipeline runs - keep an eye on the progress of the Pipeline in the Azure DevOps UI.

If you're happy with the `preview` deployment, merge the pull request - this will start a new pipeline run and deploy your app to your `production` environment.

> You will need to review and approve pipeline runs if you set up "Approvals and checks" for the Azure DevOps Environment.

✔️ And we're done! Your app will now be deployed to your `preview` environment each time commits are pushed to a PR targeting your "main" branch; and to your `production` environment when commits are pushed to your "main" branch.

## Usage

Please read through the below sections to familiarise yourself with the additional features provided by the app in this example repo and options for customising the pipeline.

### Orientation

If you're familiar with the output of "Create Next App" then you will be mostly familiar with the structure and contents of this repository. Below is a description of some of the main areas of this app that have been added or changed from the default Create Next App output:

* `./azure/`
  * This directory contains the Azure Pipelines yaml file, Bicep files, PowerShell scripts etc that are used to deploy the app to Azure
* `components/AppInsights/`
  * Components used to render the [Application Insights JavaScript SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/javascript) for client-side monitoring
* `lib/env.js`
  * Constants and functions that can be used for getting absolute URLs and CDN URLs for the current environment
* `pages/_app.js`
  * A [custom `App`](https://nextjs.org/docs/advanced-features/custom-app) component that includes the Application Insights context provider that is used by the `useApplicationInsights` hook that can be [used](#use-the-useapplicationinsights-hook) in your app's components
* `.env.template`
  * This shows all of the environment variables that can be used with this application - though none of these are required in development and are set by the Pipeline for use in Azure
* `next.config.js`
  * The configuration values provided by environment variables are required to be set when deployed in Azure (and are provided by the build pipeline)
* `server.js`
  * Requests to the App Service are routed through to this [custom server](https://nextjs.org/docs/advanced-features/custom-server) implementation - it ultimately passes requests through to the default server provided by Next.js, but it ensures requests are passed on the correct port and also includes calls to the [Application Insights Node SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/nodejs) for server-side monitoring

> If you have an existing Next.js app that you are looking to deploy to Azure you could use the above as a rough guide for where to look for code that you can copy from this example repo to your own project.

### Use a deployment slot for the preview environment

By default, the Pipeline will deploy your app to a separate App Service per target environment, but it also supports deploying to a single App Service using [deployment slots](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots) for each target environment.

Using deployment slots is the [preferred way](https://docs.microsoft.com/en-us/azure/app-service/deploy-best-practices#use-deployment-slots) to approach deploying to multiple environments for a single application, but is an opt-in feature as it requires you to make [an informed decision](#should-i-use-app-service-deployment-slots) because there is a cost involved.

> The Pipeline deploys to one slot per environment, and supports [auto swap](#configure-auto-swap-for-the-production-environment).

Assuming you have followed the [Getting started](#getting-started) guide and the Pipeline has been or is ready to run, you can modify your setup in the following ways to use deployment slots:

#### Create a Resource Group for "shared" resources

When using deployment slots the App Service is "shared" between more than one environment so a new Resource Group will be used to deploy the App Service to rather than deploying it to an existing "environment" Resource Group.

To create the Resource Group:

* Select the Subscription in the [Azure Portal](https://portal.azure.com/) where you will deploy your app
* Create a Resource Group for "shared" environment resources e.g. `next-azure-rg`

#### Allow your Service Connections to deploy to the "shared" Resource Group

The Service Connections used by the Pipeline to deploy to your environment-specific Resource Groups need permission to deploy to your "shared" Resource Group. Unfortunately you cannot modify the Service Connections directly to add these, but you can assign the Contributor role to your Service Connections on the "shared" Resource Group.

To assign the Contributor role for your Service Connections:

* Choose to edit any of your project's Service Connections in Azure DevOps
  * From the Overview tab, click on `Manage Service Principal`
  * Copy the `Display name` of the service principal
* Navigate to your "shared" Resource Group in the Azure Portal
  * Click on Access Control (IAM) > Role Assignments
  * Click Add > Add role assignment
    * Choose the Contributor role, click Next
    * Choose Assign access to User, group, or service principal, click Select members
    * Paste the `Display name` of the service principal you copied earlier
    * Select all of the matches
    * Add a description if you wish
    * Review + assign your changes

#### Update Variable Groups

You will need to update the Variable Groups with Variables so that the Pipeline knows the name of the "shared" Resource Group and the name of the deployment slot for each target environment.

To update the Variable Groups:

* Go to Pipelines > Library in your Azure DevOps project, and edit the following Variable Groups (or equivalents if you have renamed them):
  * `next-app-env-vars`
    * `WebAppSkuName` = {`B1` is the minimum Dev/Test SKU, and `S1` is the minimum Production SKU}
    * `AzureSharedResourceGroup` = {Name of your "shared" Resource Group}
  * `next-app-env-vars-preview`
    * `WebAppSlotName` = `preview`
  * `next-app-env-vars-prod`
    * `WebAppSlotName` = `production`

### Configure auto swap for the production environment

[Auto swap](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots#configure-auto-swap) involves deploying the app to a "source" deployment slot that automatically swaps to a "target" deployment slot. It is useful because it:

* Minimises downtime - the app will be "warmed up" in the source slot before it is swapped with the target slot
* Enables easy rollback - if there is an issue post-deployment and you require rollback you can swap the target slot with the source slot (that now holds the previous version of your app)

You can configure auto swap for any target deployment slot, but it is most common to use it just for the production environment because typically that's the only environment where the above benefits will really matter, plus it effectively consumes one of your available slots so you wouldn't want to use it for every environment.

Assuming you have already setup [deployment slots](#use-a-deployment-slot-for-the-preview-environment) you can modify your setup in the following way to use auto swap for your production environment:

* Go to Pipelines > Library in your Azure DevOps project, and edit the following Variable Group (or equivalent if you have renamed it):
  * `next-app-env-vars-prod`
    * `WebAppSwapSlotName` = `prodswap` (or feel free to name it what you like!)

### Add custom domain name and SSL

Azure App Services come with a default `{app-service-name}.azurewebsites.net` domain and SSL included. This is great for getting started, but you will more than likely want to add your own domain to your app with SSL when it's time to go to production (though custom domains and SSL are equally supported on deployment slots also).

Adding a custom domain and SSL can be done through the Pipeline, but requires a bit of manual setup to get the correct DNS records and SSL certificate in place.

> It is possible to also add a custom domain and SSL to the CDN endpoint, but it is unfortunately not easy to achieve through Bicep (or the underlying ARM templates) so is not currently a feature of this example repo.

Assuming you have followed the [Getting started](#getting-started) guide and the Pipeline has been or is ready to run, you can modify your setup in the following ways to add custom domains and SSL:

#### Add DNS records

Azure validates that you "own" any custom domain that you add to an App Service by checking the DNS records of the domain. You will need to add two DNS records to your domain:

* A `CNAME` record from `www` or `{subdomain}` to the `azurewebsites.net` default host
* A `TXT` record from `asuid.www` or `asuid.{subdomain}` with "Custom Domain Verification ID" value

> The exact steps required to do this vary depending on your DNS provider so aren't documented here.

The "Custom Domain Verification ID" is a unique value per Subscription, and the easiest way to get it is by:

* Browsing to any existing App Service or Function App in the Subscription in the Azure Portal
* Clicking on "Custom domains"
* Copying the "Custom Domain Verification ID" value

> This can create a chicken and egg situation if the first App Service to be created in the Subscription is the one you wish to add a custom domain for. Typically however you would deploy to the `preview` environment first, which creates an App Service, and you can grab the ID to use in the DNS records before deploying to `production`. You also may deploy to `production` to begin with using the default `azurewebsites.net` domain, and add the custom domain later.

#### Add SSL certificate

There are a few ways to add an SSL certificate to an App Service, but the method expected by the Pipeline is to add it to a Key Vault. The Key Vault and its Keys, Secrets and Certificates will not be created or managed by the Pipeline - the Pipeline just expects it to exist.

To create a Key Vault and add your SSL certificate to it, please follow the [Import a certificate in Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/certificates/tutorial-import-certificate) tutorial, but make sure that:

* The Key Vault is created in the Resource Group related to the target environment you will be adding the custom domain to
* The Key Vault is named `{projectName}-{environment}-kv` (though you can [change this naming convention](#change-the-resource-naming-conventions))

Once you have your Key Vault and SSL certificate in place, you will need to add an Access Policy to allow the App Service to get the certificate from the Key Vault:

* Browse to the Key Vault in the Azure Portal
* Click on "Access policies"
* Click "Add Access Policy"
* Under "Secret permissions", add `Get`
* Under "Certificate permissions", add `Get`
* Under "Select principal", search for and add `Microsoft Azure App Service`
* Click "Add"

> This Access Policy applies to all App Services in the Subscription so if you want to use this Key Vault for other secrets those other secrets will also be available to every App Service. This may or may not be a problem for you, but it's something to at least be aware of.

#### Add the custom domain name and SSL certificate name to a Variable Group

The last thing to do is to update the appropriate Variable Group in Azure DevOps so that the custom domain name and SSL certificate are added to the resource definition of the App Service in the infrastructure deployment made by the Pipeline.

To update the Variable Group:

* Go to Pipelines > Library in your Azure DevOps project, and edit the Variable Group related to the target environment you will be adding the custom domain to
  * Add the following variables
    * `WebAppDomainName` = {The custom domain name}
    * `WebAppCertName` = {The name of the SSL cert in the Key Vault}

The next time the Pipeline runs for the target environment the custom domain and SSL will be added to the App Service.

> If you are adding a custom domain name and SSL to an existing environment you will need to first delete the CDN endpoint for that environment because the CDN origin will need to change to point to the new custom domain name, but for some reason it cannot be updated by the ARM template created by the Bicep scripts.

### Add additional App Settings

Most applications will have specific configuration variables or settings that are typically accessed in Next.js applications through [Environment Variables](https://nextjs.org/docs/basic-features/environment-variables).

App Services provide you with [App Settings](https://docs.microsoft.com/en-us/azure/app-service/configure-common#configure-app-settings), which are (thankfully) exposed as environment variables.

The Pipeline automatically adds a few App Settings that it uses to provide things such as the `buildId` and `assetPrefix` in `next.config.js`, but you can customise the Pipeline to add additional App Settings that your application needs to build and run.

To add additional App Settings:

* Edit `.azure/infra/main.parameters.json.template`:
  * Find `webAppSettings`, and edit its `value` object
    * The key of each object entry will be the name of an App Setting
    * The value of each object entry will be the value of the App Setting
      * The value can be hard-coded e.g. `"SomeHardCodedValue"`; or
      * It can be a template token e.g. `"{{tokenName}}"`

To set up token replacement:

* Add a new Variable to the relevant Variable Group(s) in your Azure DevOps project
  * For example, `Foo` = `Bar`
* Edit `.azure/azure-pipelines.yml`:
  * Find the `Create ARM parameters file` task
    * Add the token you want to replace in the `main.parameters.json.template` file to the `-Tokens` hashtable
      * For example, if the template token in the parameters template is `"{{foo}}"`, and the Variable was named `Foo` you would add ``foo="$(Foo)" ` ``

> Remember that you can add Variables to the "default" Variable Group and override them in the "environment" Variable Groups as needed.

### Prevent automatic deploy to the `preview` environment

If you are working on a project where there could be multiple pull requests opened from different "feature" branches this could lead to a scenario where you have deployments to your `preview` environment being triggered from multiple branches in a "last one wins" situation.

This is not an ideal situation to be in - a unique deployment for each PR would be preferred, but is not currently supported. Instead you have a few options:

* Put Approvals and checks on the `preview` [Environment](#create-environments-in-azure-devops) in Azure DevOps
  * This would allow you to "gate" Pipeline runs branch by branch
  * If you are still reviewing a deployment to the `preview` environment from one branch you can keep other deployments from other branches in the "waiting for approval" state until you are ready to Approve and review them
  * If you introduced a CI stage to the Pipeline (for running unit tests for example) then you could have this stage run prior to Approvals and checks so you are not waiting to Approve and review a deployment that will ultimately fail anyway
* Manually choose what branch to deploy to the `preview` environment and when
  * You can [disable the PR trigger](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml#opting-out-of-pr-validation) in the Pipeline and instead manually run the Pipeline and choose which branch to deploy as and when you want to

### Add additional target environments

Depending on your branching and release strategy you may wish to add additional target environments to the Pipeline. For example, if you maintain a long-running `develop` branch that is used for integrating "feature" branches before they are merged into the "main" branch - you may want to deploy merges to `develop` into a `build` environment.

To add an additional target environment you should:

* [Add a Resource Group](#create-resource-groups-via-the-azure-portal) for the new environment
* [Add a Service Connection](#create-service-connections-in-azure-devops) for the new environment
  * [Add permissions on the "shared" Resource Group](#allow-your-service-connections-to-deploy-to-the-shared-resource-group) if using deployment slots
* [Add an Environment](#create-environments-in-azure-devops) for the new environment
* [Add a Variable Group](#create-variable-groups-in-azure-devops) for the new environment
  * [Add deployment slot Variables](#update-variable-groups) if using deployment slots
* Edit `.azure/azure-pipelines.yml`
  * Modify the `trigger` to include the relevant branch
  * Use a [conditional insertion](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions?view=azure-devops#conditional-insertion) expression to ensure that the Variables from the new environment's Variable Group are made available to the Pipeline
    * Search for `-group` in the Pipeline yml file to see an example of how this is done for the `production` environment, which checks that the "source branch" is the "main" branch

### Change the resource naming conventions

The default resource naming convention used in the Bicep scripts is:

`{projectName}-{environment}-{resourceSuffix}`

Where:

* `projectName` is the value set in the `main.parameters.json.template` file
* `environment` is the `TargetEnv` variable set in `azure-pipelines.yml`
  * This isn't used in "shared" resource names when using [deployment slots](#use-a-deployment-slot-for-the-preview-environment)
* `resourceSuffix` is hardcoded inside the Bicep files and is usually a two to three character string representing the type of resource e.g. `app` for App Service, `cdn` for CDN endpoint

You can edit the Bicep scripts to change this convention if it doesn't suit you or your team.

> Feel free to change the names of any resources created outside of the Bicep scripts also, but do a search in your repo to make sure they are not hardcoded anywhere - this shouldn't be the case except for the [Variable Group](#create-variable-groups-in-azure-devops) names because those names have to be hardcoded in the `azure-pipelines.yml`.

### Use the `useApplicationInsights` hook

The Application Insights implementation included in this sample app uses the [Node SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/nodejs) for tracking initial requests to the server as well as the [JavaScript SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/javascript) for tracking client requests including "page views" when navigating via client-side routing.

If you want to review and change the configuration you can:

* Find the server config in `server.js`
* Find the client config in `components/AppInsights/Sdk.jsx`

If you want to use Application Insights to track custom events or metrics you can import and use the provided hook, which will give you access to the Application Insights instance. You should only use this instance inside `useEffect` though as it's client-side only:

```javascript
import { useAppInsights } from './components/AppInsights'

// This gives you access to the app insights instance
const appInsights = useAppInsights()
```

You can then call [functions of the telemetry client](https://docs.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics) on that instance as needed.

## FAQ

If you have read through the rest of this document and have questions then they may be answered below, but if not please feel free to ask a question by raising an issue on this repo.

### Why would I want to deploy a Next.js app to Azure?

I'm certainly not going to try to say this path is on a par with other more popular options. Having used Vercel and Netlify for deploying and hosting Next.js apps it's certainly not on the same level in terms of simplicity! For me the reason was mostly due to having committed to the Azure platform in terms of other related pieces of infrastructure on the project I was working on in my day job, and having everything hosted on the same provider made things easier in terms of observability and governance.

So no sales pitch from me - and I am going to assume that if you're reading this then you already have your reasons for wanting to deploy to Azure - but I can say that deploying Next.js and hosting in Azure has worked out well for me on the projects I have worked on so it's by no means a bad choice!

### Should I use App Service deployment slots?

The Pipeline included in the example repo has support for deploying the Next.js app into:

1. One App Service per target environment (i.e. multiple App Services)
2. One App Service with one deployment slot per target environment (i.e. one App Service total)

If this is / will be a "dev/test" app or you want to keep costs low then option 1 should be fine, but bear in mind that the "F" (free) and "D" (relatively cheap) App Service SKUs are quite limited in their capabilities.

If this is / will be a "production" app then option 2 will be more cost effective in the long run because you pay for only one App Service and the slots "come for free" - currently 5 slots are available on an App Service using the "S1" SKU.

The reason the "Getting started" instructions in this doc don't use slots by default is because it is assumed that if you're only just getting started then you will want to limit costs as far as is possible until you are sure this setup will work for your project, at which point you will probably want to switch to using slots as it is more suitable for production apps.

If you have only just set up your account, or are a Visual Studio subscriber you may have a certain amount of credit, which will negate or limit costs in which case it may just be better to go with slots from the start.

### Can I use TypeScript with this example?

Next.js fully supports TypeScript, but the code specific to this example repo is currently not "typed". I do have typed versions of this code in another project that I will bring across to here when I find time.

### Can I use GitHub Actions instead of Azure DevOps pipelines?

I don't see why not, but I haven't "ported" the Pipeline over yet myself. It is on my TODO list for this project, but not particularly high up so hopefully I will find the time at some point.

If you're reading this and think you could take that on then I would appreciate the contribution!

### Why a Windows app service and not Linux?

Linux for the app service should be fine too, but I've not tested this myself - feel free to change to Linux if you prefer, but consider the [limitations](https://docs.microsoft.com/en-us/azure/app-service/overview#limitations) if you have not already.

### Why deploy directly to App Services and not use containers?

To be honest it was just what I had more experience with when I started this project, and I haven't tried using containers (yet). The Next.js docs now includes a section on [deploying with Docker containers](https://nextjs.org/docs/deployment#docker-image) so this is something I plan on revisting when I find time.

### Do I have to use Application Insights?

In short, no. If you don't want to use Application Insights you will need to make some adjustments to the Bicep files and Pipeline and remove the components from the app - it should hopefully be easy enough to pull it out if you don't want it in there.

I don't exactly love Application Insights myself, but I figured having some monitoring in place by default was better than not, and it should be easy enough to rip out if you have something better in mind!

### Do I need a CDN?

In short, no, but it is recommended for the performance of your app. If you don't want to use a CDN then you can modify the Bicep files and Pipeline to not create the CDN resources in Azure and remove the related code from the app - have a search in the project files for `cdn`.

### How long does the pipeline take to run?

It depends on a few factors (e.g. whether the infrastructure resources already exist or need to be created or updated by the pipeline, the size and complexity of your app, the app service plan SKU that you have chosen), but from running this sample a few times it has taken anywhere between 5 - 15 mins to run to completion.

The first time the pipeline runs or after any changes to `package.json` dependencies (anything that causes a change in the `package-lock.json` file) will be the slowest as these runs will not benefit from a `node_modules` cache task present in the pipeline.

There is also a second hit from `npm install` in this case as it runs during the build step in the pipeline, but it also gets executed on the app service because the node server needs access to production node module dependencies. The `node_modules` output from the build step is not deployed with the rest of the build output because a) it includes `devDependencies` that you don't need on the server; and b) deploying `node_modules` from the pipeline to the app service along with the rest of the application files via zip deploy has proven to be much slower than running a production-only `npm install` post-deployment.

As mentioned, caching is in place in the pipeline (based on the contents of the `package-lock.json` file) for subsequent runs, and if no changes have been made to dependencies then the time required to run `npm install` in the pipeline and on the app service is much reduced.

### Do I have to use npm, or can I use Yarn, or pnpm?

npm and Yarn v1 (Yarn Classic) will both work equally well.

npm is being used in the Pipeline because it seems like a sensible default - it is installed alongside node so it's safer to assume people will be using that over Yarn, which requires a separate install.

If you are using Yarn v1 though you can:

* Edit `.azure/azure-pipelines.yml`
  * Replace references to `package-lock.json` with `yarn.lock`
  * Replace the `npm` commands with their `yarn` equivalents
* Edit `.azure/web-app/deploy.cmd`
  * Reverse the changes made in [this commit](https://github.com/CMeeg/next-azure/commit/9967d3969b51a1f658c4e657cfdf9e6c3309947f#diff-04ffbb94a2cebcdd1803a5a947b790e7e9e756fb01358055242b439125963502L100-L111)

It is possible that other versions of Yarn will work, but I haven't tried anything above v1 so cannot say for sure.

I have tried pnpm but had issues because of limited support for [symlinks](https://github.com/projectkudu/kudu/wiki/Azure-Web-App-sandbox#symbolic-link-creation) within the App Service sandbox and couldn't find a way forward. Please raise an issue if you know a way!
