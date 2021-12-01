<#

.SYNOPSIS
Adds a new deployment environment for a next-azure project.

.DESCRIPTION
Creates a new Resource Group, Service Connection, Environment and Variable Group (and sets up the deployment slot if being used) in Azure and Azure DevOps ready for deploying to as a new target environment by the next-azure deployment Pipeline.

.PARAMETER Environment
Name of the environment that you would like to add e.g. `build`.

.PARAMETER Force
Use this switch to force this script to run. Use with caution as this may cause existing resources to be updated.

.INPUTS
None

.OUTPUTS
None

.LINK
https://github.com/CMeeg/next-azure

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    [switch]$Force
)

# Ensure latest "version" of NextAzure module is imported

if (Get-Module -Name NextAzure) {
    Remove-Module NextAzure
}

Import-Module "$PSScriptRoot/NextAzure/NextAzure.psm1"

$OriginalInformationPreference = $InformationPreference

$InformationPreference = "Continue"

# Load the next-azure config file

$Config = Get-NextAzureConfig -InformationAction Continue

if (!$Config) {
    Write-Error "next-azure config file not found - project has not been initialised."

    return
}

# Configure Azure CLI default options from config

Set-AzCliDefaults -Config $Config -InformationAction Continue

# Check to see if environment already exists

$EnvironmentExists = Test-NextAzureEnvironment -Config $Config -Environment $Environment -InformationAction Continue

if ($EnvironmentExists -and !$Force) {
    Write-Error "Environment '$Environment' already exists. You can add a -Force switch if you want to continue anyway."

    return
}

Write-Line -InformationAction Continue

# Setup environment

Set-NextAzureEnvironment -Config $Config -Environment $Environment -InformationAction Continue

Write-Line -InformationAction Continue

Write-Information "`u{2714}`u{FE0F} Done"

$InformationPreference = $OriginalInformationPreference
