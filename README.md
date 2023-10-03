

This is a [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/basic-features/font-optimization) to automatically optimize and load Inter, a custom Google Font.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js/) - your feedback and contributions are welcome!

## Deploy to Azure

TODO

## Run in Docker

* Install Docker on your machine
* Build your container: `docker build -t next-azure .`
* Run your container: `docker run -p 3000:3000 next-azure`

## Environment variables

When developing your app use environment variables as per the Next [documentation](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables):

* Set defaults for all environments in `.env`
* Use `.env.development` for default development environment (i.e. `next dev`) vars
* Use `.env.production` for default production environment (i.e. `next build`) vars
* Use `.env.local` for secrets or overrides of any defaults

### How azd uses environment variables in this template

When running `azd provision`:

* The `.azure/hooks/preprovision.ps1` script runs, which
  * Loads vars from `.env`, `.env.production` and `.env.local` (if they exist) into the current environment (current process scope)
  * Runs `infra/settings.ps1` to generate a `setting.json` file - this file can use values from the current environment, or fallback to default values if not set in the environment
    * Feel free to edit and change this template as required - the format of the json this file produces doesn't need to follow any set schema, but you will need to update the Bicep files to be able to read and use whatever changes you make
    * This template allows for setting some container properties like memory and cpu settings, scale values, a custom domain name, and environment variables, but this can be extended as required
    * If you extend this template to include other resources or services you could replicate this script to describe settings for those additional resources or services
* `azd` runs the `main.bicep` file, which loads the `settings.json` file to be used during provisioning of the infrastructure
  * The `main.bicep` file sets environment variables that are required at runtime on the container app so if you need certain environment variables to be available at runtime you should add them via editing the `settings.ps1` script
  * For example, if I wanted to add an environment variable named `MY_VAR` with the value `env_value` I would:
    * First add `MY_VAR="env_value"` to the appropriate env file (`.env`, `.env.production`, or `.env.local`)
    * Then add `{ "name": "MY_VAR", "value": "$(Get-ValueOrDefault ${env:MY_VAR} "default_value")" }` to the `settings.ps1` script under the `env` "key"
  * The `MY_VAR` environment variable will then be available at build time through the env file, and at runtime through the container environment variables
* `azd` writes any `output` from the `main.bicep` file to `.azure/{AZURE_ENV_NAME}/.env`
  * This is standard behaviour of `azd provision` and not specific to this template
* The `.azure/hooks/postprovision.ps1` script runs, which
  * Merges the `.azure/{AZURE_ENV_NAME}/.env` with the `.env.local` file and writes the output to `.env.azure`
  * The `.env.azure` file is used by `azd deploy` - see below

When running `azd deploy`:

* The `Dockerfile` copies all `.env*` files from the local disk into the `builder` layer
* It then copies `.env.azure` and renames and overwrites `.env.local` with it
* `next build` then runs as normal and has access to all environment variables needed at build time, both from local context and from the output of `azd provision`

### How to provide environment variables when running in a pipeline

When running in a pipeline (AZDO Pipelines or GitHub Actions) you will need to be able to provide all environment variables required by your app at build and runtime, but tailored specific to the target environment. Typically what is missing is anything that you would place in your `.env.local` file as this file is not committed to your repo, but you may have additional variables to provide.

How these variables are created and maintained is different depending on which whether you are using AZDO or GitHub - see the documentation for AZDO Pipelines and GitHub Actions - but the approach this template takes to using these variables is the same:

* Create environment variables that can be surfaced to the pipeline using the following naming convention: `AZD_{AZURE_ENV_NAME}_{VAR_NAME}`
  * For example, if I need a variable named `MY_VAR` and had two environments, `dev` and `prod`, I would create two environments variables named `AZD_DEV_MY_VAR` and `AZD_PROD_MY_VAR` - the values may be the same or different, or if it's not needed in one environment then you can omit it
* The pipelines included with this template will look for environment variables that are named following this convention and write them to a `.env.local` file prior to running `azd provision`
  * This means that the `azd provision` and `azd deploy` commands then work the same as when running `azd` locally (as described above)
