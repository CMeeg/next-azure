<#

.SYNOPSIS
Configures deployment slots for a next-azure project.

.DESCRIPTION
Creates a new "shared" Resource Group and updates Service Connections and Variable Groups in Azure and Azure DevOps so that the next-azure deployment Pipeline will use deployment slots.

.PARAMETER SkuName
The name of SKU that you want to use for your App Service Plan - `B1` is the minimum Dev/Test SKU, and `S1` is the minimum Production SKU. Defaults to 'S1'.

.PARAMETER Force
Use this switch to force this script to run. Use with caution as this may cause existing resources to be updated.

.INPUTS
None

.OUTPUTS
None

.LINK
https://github.com/CMeeg/next-azure

.LINK
https://azure.microsoft.com/pricing/calculator/

#>
[CmdletBinding()]
param(
    [string]$SkuName = 'S1',
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

if ($Config.Settings.UseDeploymentSlots -and !$Force) {
    Write-Error "Project has already been setup to use deployment slots. You can add a -Force switch if you want to continue anyway."

    return
}

$ConfigSettings = @{
    UseDeploymentSlots = $true
}

$Config = Set-NextAzureConfig -Config $Config -Settings $ConfigSettings -InformationAction Continue

# Configure Azure CLI default options from config

Set-AzCliDefaults -Config $Config -InformationAction Continue

Write-Line -InformationAction Continue

# Setup deployment slots

Set-NextAzureUseAppServiceSlots `
-Config $Config `
-WebAppSkuName $SkuName `
-InformationAction continue

Write-Information "`u{2714}`u{FE0F} Done"

$InformationPreference = $OriginalInformationPreference
