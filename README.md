# next-azure

> [!NOTE]
> I've created a new [template for deploying a Next.js v13 app to Azure using the Azure Developer CLI](https://github.com/CMeeg/nextjs-aca). The new template retains all of the functionality of this one so I recommend using it for new projects.
>
> I will no longer maintain the code in this repository, but I will be keeping it here for reference.

---

This repository contains a [Create Next App](https://nextjs.org/docs/api-reference/create-next-app) example for deploying a Next.js v12 app to Microsoft Azure App Services (including a CDN for static assets, and Application Insights for monitoring) via Azure DevOps Pipelines.

The Next.js app included in this example is the same app created by the default Create Next App output, but with some additional files, components and config changes to support deployment to Azure.

Changes have been kept to a minimum, but are enough to get you up and running with:

* PowerShell scripts for quickly creating and tearing down environments
  * The scripts will run on Windows, MacOS, or Linux using PowerShell Core
* An Azure DevOps Pipeline for building and deploying a Next.js app to Azure
  * The Pipeline will provision the necessary infrastructure for you in Azure using the included [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) files
* A Next.js app hosted and running in Azure App Services with full support for SSR and SSG scenarios including [Automatic Static Optimization](https://nextjs.org/docs/advanced-features/automatic-static-optimization), and [Incremental Static Regeneration](https://nextjs.org/docs/basic-features/data-fetching#incremental-static-regeneration) and [middleware](https://nextjs.org/docs/middleware)
  * The app is deployed as a Linux "[Web App for Containers](https://azure.microsoft.com/en-gb/services/app-service/containers/)" using Docker Compose - one container running nginx as a reverse proxy to another container running the Next app
* A CDN for caching static assets, and [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) for application monitoring
  * The aim is to provide a solid infrastructure ready for production apps

> If you only need support for [statically generated pages](https://nextjs.org/docs/advanced-features/static-html-export) via `next export` then check out [Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/deploy-nextjs) instead as it may be better suited for your needs.

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

There is some initial setup required to create the resources required for the deployment environments targeted by the Pipeline. This can be achieved by running a PowerShell script provided in this repo.

The script creates:

* Resource Groups in Azure into which the resources required for your app will be deployed
* Service Connections, Environments and Variable Groups in Azure DevOps that will be used by the Pipeline

It is assumed that you already have:

* An Azure account and a Subscription where the resources for your project will be deployed; and
* An Azure DevOps organization and Project where the Pipeline for deploying your project will be situated

#### Install (or update) required software

The scripts use PowerShell and the Azure CLI so you will need to have the following software installed:

* [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) (i.e. PowerShell Core)
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Azure CLI Azure DevOps extension](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)

> If you already have them installed it might be a good idea to make sure you have updated to the latest versions.

You will also need to install the following task into your Azure DevOps organisation:

* [Env Transform](https://marketplace.visualstudio.com/items?itemName=joachimdalen.env-transform)

#### Run the Azure initialisation script

The initialisation script will create the necessary resources in Azure and Azure DevOps for two environments, `preview` and `prod` ([additional environments are supported](#add-additional-target-environments)).

To use the initialisation script:

* Login to your Azure Account
  * `az login`
* Run the initialisation script
  * `./.azure/setup/init.ps1 -SubscriptionId {subscription_id} -ResourcePrefix {resource_prefix} -Location {location} -OrgUrl {devops_org_url} -ProjectName {devops_project_name}`
  * To see a full description of the script and its parameters, run `Get-Help .azure/setup/init.ps1 -Full`
* Commit and push the generated config file `.nextazure.json`
  * This config file is used by other scripts in this repo (see the [Usage](#usage) section) and saves you having to type the options provided to the initialisation script out each time

> The name of the Resource Groups is based on a naming convention of `{resourcePrefix}-{environment}-{resourceSuffix}`. If you don't like this you can [change the naming convention](#change-the-resource-naming-conventions).

> The Service Connections created by the script "Grant access to all pipelines", which is done for convenience, but you can choose not to do this and configure specific [pipeline permissions](https://docs.microsoft.com/en-us/azure/devops/pipelines/policies/permissions?view=azure-devops#set-service-connection-permissions) if you wish.

> Three Variable Groups are created by the script - the `{resourcePrefix}-env-vars` Variable Group is used to hold "default" or "shared" values applicable to all target environments, and the `{resourcePrefix}-env-vars-{environment}` Variable Groups hold environment-specific Variables or can override Variables with the same name in the "default" Variable Group.

#### Create the Pipeline

When the Pipeline runs it will provision the infrastructure in Azure required to host your app for the target environment, and build and deploy your application to that infrastructure.

> You will set the Pipeline up manually because you need to be able to authorise the Pipeline to connect to your project's repository, and it's not practical for this example repo to try to cover all options. Thankfully setting up the Pipeline manually is pretty painless.

To create the Pipeline:

* Go to Pipelines > Pipelines, and create a Pipeline
* Choose the relevant option for where your repo is located (e.g. GitHub), and authorise as requested
* Once authorised, select your repository and authorise as requested here also if prompted
* Select `Existing Azure Pipelines YAML file` to configure your pipeline
* Select the branch and path to your `.azure/azure-pipelines.yml` file, and continue
* Save the Pipeline (i.e. don't Run the Pipeline yet - you will need to use the dropdown next to the "Run" button)

### Run the Pipeline

The Pipeline is now ready to run. It can be triggered by pushing commits to your repository, which we will now do.

* Edit `.azure/azure-pipelines.yml`
  * Search for `na-js-env-vars`
  * Replace all occurrences of the above with `{resourcePrefix}-env-vars` so that these match up with the Variable Group names created by the initialisation script
    * Where `{resourcePrefix}` matches the `ResourcePrefix` in your `.nextazure.json` config file
* Commit and push your changes
* Create a new pull request from your feature branch to your "main" branch - this will start a new pipeline run and deploy your app to your `preview` environment
* If you're happy with the `preview` deployment, merge the pull request into your "main" branch - this will start a new pipeline run and deploy your app to your `production` environment

> You may be required to grant permissions to your Variable Groups and/or Environments the first time the Pipeline runs - keep an eye on the progress of the Pipeline in the Azure DevOps UI.

> You will need to review and approve pipeline runs if you set up [Approvals and checks](#add-approvals-and-checks-to-an-environment) for the Azure DevOps Environment.

✔️ And you're done! Your app will now be deployed to your `preview` environment each time commits are pushed to a PR targeting your "main" branch; and to your `production` environment when commits are pushed to your "main" branch.

> ⚠️ The App Services are configured to use deployment slots, which require a "Standard" or higher service plan and will [cost you money](https://azure.microsoft.com/en-gb/pricing/details/app-service/linux/). If you are just trying this out you may want to [remove all of the resources](#remove-all-environments) from your subscription when you're done.

## Usage

Please read through the below sections to familiarise yourself with the additional features provided by the app in this example repo and options for customising the pipeline.

* [Orientation](#orientation)
* [Running Docker Compose locally](#running-docker-compose-locally)
* [Add additional target environments](#add-additional-target-environments)
* [Add Approvals and Checks to an Environment](#add-approvals-and-checks-to-an-environment)
* [Add custom domain name and SSL](#add-custom-domain-name-and-ssl)
* [Add DNS records](#add-dns-records)
* [Add additional App Settings](#add-additional-app-settings)
* [Prevent automatic deploy to the `preview` environment](#prevent-automatic-deploy-to-the-preview-environment)
* [Change the resource naming conventions](#change-the-resource-naming-conventions)
* [Use the `useApplicationInsights` hook](#use-the-useapplicationinsights-hook)
* [Remove a target environment](#remove-a-target-environment)
* [Remove all environments](#remove-all-environments)

### Orientation

If you're familiar with the output of "Create Next App" then you will be mostly familiar with the structure and contents of this repository. Below is a description of some of the main areas of this app that have been added or changed from the default Create Next App output:

* `./azure/`
  * This directory contains the Azure Pipelines yaml file, Bicep files, PowerShell scripts etc that are used to deploy the app to Azure
* `components/AppInsights/`
  * Components used to render the [Application Insights JavaScript SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/javascript) for client-side monitoring
* `lib/env.js`
  * Constants and functions that can be used for getting absolute URLs and CDN URLs for the current environment
* `nginx/`
  * Config for the nginx reverse proxy used in production builds - this can be modified to suit your needs such as adding redirect or rewrite rules for your app
* `pages/_app.js`
  * A [custom `App`](https://nextjs.org/docs/advanced-features/custom-app) component that includes the Application Insights context provider that is used by the `useApplicationInsights` hook that can be [used](#use-the-useapplicationinsights-hook) in your app's components
* `Dockerfile`
  * This is the Dockerfile for the production Next app build
* `.env.template`
  * This shows all of the environment variables that can be used with this application - though none of these are required in development and are set by the Pipeline for use in Azure
* `next.config.js`
  * The configuration values provided by environment variables are required to be set when deployed in Azure (and are provided by the build pipeline)
* `server.js`
  * Requests to the App Service are routed through to this [custom server](https://nextjs.org/docs/advanced-features/custom-server) implementation - it ultimately passes requests through to Next.js, but it ensures requests are passed on the correct port and also includes calls to the [Application Insights Node SDK](https://docs.microsoft.com/en-us/azure/azure-monitor/app/nodejs) for server-side monitoring

> If you have an existing Next.js app that you are looking to deploy to Azure you could use the above as a rough guide for where to look for code that you can copy from this example repo to your own project.

### Running Docker Compose locally

It can be useful to run Docker Compose locally to test a production build without having to release through the pipeline.

You can review the [Docker Compose docs](https://docs.docker.com/compose/) for basic usage if you're not familiar with the tool, but as a quick start:

* Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (if you haven't already)
* In a terminal at the root of the repository
  * Run `docker compose up -d` to start your containers
    * Or do not use the `-d` switch if you want to run your containers in the foreground to see build and app/service output
  * Run `docker compose stop` to stop the containers; or
  * Run `docker compose down` to stop and remove the containers
* When the containers are running you will be able to browse the app at [`http://localhost:3001/`](http://localhost:3001/)

### Add additional target environments

By default, the initialisation scripts creates two environments: `preview` and `prod` (production). You may wish to give these different names or create more or less environments, which you can do during initialisation; or you may wish to add additional target environments to the Pipeline at a later phase of your project after initialisation.

For example, if you maintain a long-running `develop` branch that is used for integrating "feature" branches before they are merged into the "main" branch - you may want to deploy merges to `develop` into a `build` environment.

* During initialisation
  * You can specify which environments to create during [initialisation](#run-the-azure-initialisation-script) by using the `ProdEnvironment` and `PreProdEnvironments` parameters
  * Run the `Get-Help` cmdlet on the `init.ps1` script for more info
* After initialisation
  * Run the script `./.azure/setup/add-environment.ps1 -Environment {environment_name}`
    * To see a full description of the script and its parameters, run `Get-Help .azure/setup/add-environment.ps1 -Full`

You must then alter your Pipeline to add a trigger and condition for deploying to the new target environment(s):

* Edit `.azure/azure-pipelines.yml`
  * Modify the `trigger` to include the relevant branch
  * Use a [conditional insertion](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions?view=azure-devops#conditional-insertion) expression to ensure that the Variables from the new environment's Variable Group are made available to the Pipeline
    * Search for `-group` in the Pipeline yml file to see an example of how this is done for the `production` environment, which checks that the "source branch" is the "main" branch

### Add Approvals and Checks to an Environment

Environments are used to track deployments in Azure DevOps and to allow for Approvals and Checks to be put in place (if desired), which requires one or more reviewers to Approve or Reject a deployment before it can run the deployment. An email notification is sent to all reviewers when there is a deployment to review.

To add Approvals and Checks to an Environment:

* Go to Pipelines > Environments
* Edit the Environment you want to add Approvals and Checks to
  * Click More actions > Approvals and checks
  * Click Add
    * Select Approvals, click Next
    * Add Approvers e.g. yourself
    * Set other options as you want
    * Click Create

> Approvals and checks is optional, but useful if you want to check the output of the "build" Pipeline stages before proceeding with the "deploy" stages - outputs from the build stages are available as Pipeline artifacts that can be downloaded and inspected before making a decision to proceed with the deploy stages.

### Add custom domain name and SSL

Azure App Services come with a default `{app-service-name}.azurewebsites.net` domain and SSL included. This is great for getting started, but you will more than likely want to add your own domain to your app with SSL when it's time to go to production (though custom domains and SSL are equally supported on deployment slots also).

Adding a custom domain and SSL can be done through the Pipeline, but requires a bit of manual setup to get the correct DNS records and SSL certificate in place.

> It is possible to also add a custom domain and SSL to the CDN endpoint, but it is unfortunately not easy to achieve through Bicep (or the underlying ARM templates) so is not currently a feature of this example repo.

Assuming you have followed the [Getting started](#getting-started) guide and the Pipeline has been or is ready to run, you can modify your setup in the following ways to add custom domains and SSL:

#### Add DNS records

Azure validates that you "own" any custom domain that you add to an App Service by checking the DNS records of the domain. You will need to [add two DNS records](https://docs.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain?tabs=cname#4-create-the-dns-records) to your domain:

* A `CNAME` record from `www` or `{subdomain}` to the `azurewebsites.net` default host
* A `TXT` record from `asuid.www` or `asuid.{subdomain}` with "Custom Domain Verification ID" value

> The exact steps required to do this vary depending on your DNS provider so aren't documented here.

The "[Custom Domain Verification ID](https://docs.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain?tabs=cname#3-get-a-domain-verification-id)" is a unique value per Subscription, and the easiest way to get it is by:

* Browsing to any existing App Service or Function App in the Subscription in the Azure Portal
* Clicking on "Custom domains"
* Copying the "Custom Domain Verification ID" value

> This can create a chicken and egg situation if the first App Service to be created in the Subscription is the one you wish to add a custom domain for. Typically however you would deploy to the `preview` environment first, which creates an App Service, and you can grab the ID to use in the DNS records before deploying to `production`. You also may deploy to `production` to begin with using the default `azurewebsites.net` domain, and add the custom domain later.

#### Add SSL certificate

There are a few ways to add an SSL certificate to an App Service, but the method expected by the Pipeline is to add it to a Key Vault. The Key Vault and its Keys, Secrets and Certificates will not be created or managed by the Pipeline - the Pipeline just expects it to exist.

To create a Key Vault and add your SSL certificate to it, please follow the [Import a certificate in Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/certificates/tutorial-import-certificate) tutorial, but make sure that:

* The Key Vault is created in the Resource Group related to the target environment you will be adding the custom domain to
* The Key Vault is named `{resourcePrefix}-{environment}-kv` (though you can [change this naming convention](#change-the-resource-naming-conventions))

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
  * Update the following variables
    * `WebAppDomainName` = {The custom domain name}
    * `WebAppCertName` = {The name of the SSL cert in the Key Vault}

The next time the Pipeline runs for the target environment the custom domain and SSL will be added to the App Service.

> If you are adding a custom domain name and SSL to an existing environment you will need to first delete the CDN endpoint for that environment because the CDN origin will need to change to point to the new custom domain name, but for some reason it cannot be updated by the ARM template created by the Bicep scripts. If you delete the CDN endpoint resource it will be recreated the next time the Pipeline runs for that target environment.

### Add additional App Settings

Most applications will have specific configuration variables or settings that are typically accessed in Next.js applications through [Environment Variables](https://nextjs.org/docs/basic-features/environment-variables).

App Services provide you with [App Settings](https://docs.microsoft.com/en-us/azure/app-service/configure-common#configure-app-settings), which are exposed as environment variables and can be access via `process.env.{var_name}` as normal.

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

This is not an ideal situation - a unique deployment for each PR would be preferred, but is not currently supported without your own customisation. Instead you have a few options:

* Put Approvals and checks on the `preview` [Environment](#add-approvals-and-checks-to-an-environment) in Azure DevOps
  * This would allow you to "gate" Pipeline runs branch by branch
  * If you are still reviewing a deployment to the `preview` environment from one branch you can keep other deployments from other branches in the "waiting for approval" state until you are ready to Approve and review them
  * If you introduced a CI stage to the Pipeline (for running unit tests for example) then you could have this stage run prior to Approvals and checks so you are not waiting to Approve and review a deployment that will ultimately fail anyway
* Manually choose what branch to deploy to the `preview` environment and when
  * You can [disable the PR trigger](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml#opting-out-of-pr-validation) in the Pipeline and instead manually run the Pipeline and choose which branch to deploy as and when you want to

### Change the resource naming conventions

The default resource naming convention used in the PowerShell and Bicep scripts is:

`{resourcePrefix}-{environment}-{resourceSuffix}`

Where:

* `resourcePrefix` is the value set during initialisation and can be found in the `.nextazure.json` file
* `environment` is the `EnvironmentName` variable set in the associated Variable Group
  * The `environment` isn't used in "shared" resource names when using [deployment slots](#use-a-deployment-slot-for-pre-production-environments)
* `resourceSuffix` is hardcoded inside the Bicep and PowerShell files and is usually a two to three character string representing the type of resource
  * For example, `app` for App Service, `cdn` for CDN endpoint

You can edit the Bicep and PowerShell scripts to change this convention if it doesn't suit you or your team:

* Check the `main.bicep` file; and
* Search for the `Get-NextAzureResourceName` function in `NextAzure.psm1`

You may also wish to check the Variable Group names referenced `azure-pipelines.yml` because those names have to be hardcoded - search for `-group`.

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

### Remove a target environment

If you want to remove one of the environments for your project you can run the following script:

* `./.azure/setup/remove-environment.ps1 -Environment {environment_name}`
  * To see a full description of the script and its parameters, run `Get-Help .azure/setup/remove-environment.ps1 -Full`

> Please be aware that if you are using deployment slots and choose to delete your production environment then the deployment slots for all other environments will also be deleted.

You must then alter your `.azure/azure-pipelines.yml` Pipeline to remove any trigger or condition associated with the target environment that has been removed.

This script deletes the environment's Resource Group so any resources in that Resource Group will also be deleted when you run this script.

### Remove all environments

If you want to remove all environments for your project you can run the following script:

* `./.azure/setup/teardown.ps1`
  * To see a full description of the script and its parameters, run `Get-Help .azure/setup/teardown.ps1 -Full`

This script deletes all associated Resource Groups so any resources in those Resource Groups will also be deleted when you run this script.

## FAQ

If you have read through the rest of this document and have questions then they may be answered below, but if not please feel free to ask a question by raising an issue on this repo.

### Why would I want to deploy a Next.js app to Azure?

I'm not going to try to pretend that proceeding on this path is comparable with other more "usual" options for hosting a Next.js app - just in terms of simplicity Vercel and Netlify would come out on top no problem!

There will be no sales pitch from me - I am just going to assume that if you're reading this then you already have your reasons for wanting to deploy to Azure. For me the reason was mostly due to having committed to the Azure platform in terms of other related pieces of infrastructure on the project I was working on in my day job, and having everything hosted on the same provider made things easier in terms of observability and governance.

What I can say is that deploying Next.js and hosting in Azure has worked out well for me on the projects I have worked on so it's by no means a bad choice, and hopefully works out for you too!

### Can I deploy to a Windows (IIS) App Service?

Yes - in fact that's what this example used to do, but was switched over to target a Linux App Service because:

* I made an assumption that Linux would be better suited for this project in terms of meeting expectations if coming from other hosting providers where Linux is the defualt (or only) choice
* The behaviour and performance of the pipeline is more predictable as it eliminates the need to run npm install (or equivalent) both in the pipeline and on the app service post-deploy, which can sometimes fail, or take much longer than you would expect (it could be unpredictable)
* It opens up possibilities such as using tools like pnpm, which are not supported on Windows app service due to lack of support for symlinks - essentially I think it provides more freedom of choice when using this example as a starting point for your app
* You can more easily spin up the "production environment" locally using Docker if you want to do some testing locally before pushing through the pipeline

If you want to use Windows, you can checkout the `v1.0.0` tag of this repo and use that as a starting point, but I don't currently have plans to maintain that approach any further so cannot guarantee there won't be issues at some point in the future as the underlying tech moves on.

### Can I use TypeScript with this example?

Next.js fully supports TypeScript, but the code specific to this example repo is currently not "typed". I do have typed versions of this code in another project that I will bring across to here when I find time.

### Can I use GitHub Actions instead of Azure DevOps Pipelines?

I don't see why not, but I haven't "ported" the Pipeline over yet myself. It is on my TODO list for this project, but not particularly high up so hopefully I will find the time at some point.

There are not really equivalents for Azure DevOps Environments or Variable Groups in GitHub Actions though so replacing usage of these features requires a bit of thought.

If you're reading this and think you could take on porting this over to GitHub Actions then I would appreciate the contribution!

### Do I have to use Application Insights?

In short, no. If you don't want to use Application Insights you will need to make some adjustments to the Bicep files and Pipeline and remove the components from the app - it should hopefully be easy enough to pull it out if you don't want it in there.

I don't exactly love Application Insights myself, but I figured having some monitoring in place by default was better than not, and it should be easy enough to rip out if you have something better in mind!

### Do I need a CDN?

In short, no, but it is recommended for the performance of your app. If you don't want to use a CDN or want to use a CDN provided by someone other than Microsoft then you can modify the Bicep files and Pipeline to not create the CDN resources in Azure and remove / change the related code in the app - have a search in the project files for `cdn`.

### How long does the pipeline take to run?

It depends on a few factors (e.g. whether the infrastructure resources already exist or need to be created or updated by the pipeline, the size and complexity of your app, the app service plan SKU that you have chosen), but from running this sample a few times it has taken anywhere between 5 - 15 mins to run to completion.

### Do I have to use npm, or can I use Yarn, or pnpm?

npm is being used because it seems like a sensible default - it is installed alongside node so it's safer to assume people will be using that over Yarn, which requires a separate install.

Yarn or pnpm should work equally well though, but you will need to make some changes both to use locally in development and in the Dockerfile for the production build. Search for `npm` and replace the npm commands with the equivalent Yarn/pnpm commands as appropriate.
