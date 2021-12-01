<#

.SYNOPSIS
Removes an environment for a next-azure project.

.DESCRIPTION
Deletes the Resource Group, Service Connection, Environment and Variable Group in Azure and Azure DevOps for a single environment used by this project's next-azure deployment Pipeline.

.PARAMETER Environment
Name of the environment that you would like to remove e.g. `build`.

.PARAMETER Force
Use this switch to force this script to run.

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

# Check to see if environment exists

$EnvironmentExists = Test-NextAzureEnvironment -Config $Config -Environment $Environment -InformationAction Continue

if (!$EnvironmentExists -and !$Force) {
    Write-Error "Environment '$Environment' does not exist. You can add a -Force switch if you want to continue anyway."

    return
}

Write-Line -InformationAction Continue

# Prompt for confirmation

$Confirmation = Read-Host "Are you sure you want to remove the '$Environment' environment? [y/n]"
if ($Confirmation -ne 'y') {
    Write-Information "No action taken" -InformationAction Continue

    return $null
}

Write-Line -InformationAction Continue

# Remove environment

Remove-NextAzureEnvironment -Config $Config -Environment $Environment -InformationAction Continue

Write-Line -InformationAction Continue

Write-Information "`u{2714}`u{FE0F} Done"

$InformationPreference = $OriginalInformationPreference
