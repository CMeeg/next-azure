<#

.SYNOPSIS
Initialises a new next-azure project.

.DESCRIPTION
Creates default Resource Groups, Service Principals, Service Connections, Environments and Variable Groups in Azure and Azure DevOps required for by the next-azure deployment Pipeline.

.PARAMETER SubscriptionId
The ID (GUID) of the Subscription where Azure Resource Groups and resources should be created.

.PARAMETER ResourcePrefix
A string that will be used to prefix resource names for this project - it should be relevant to your project to help identify resources in Azure and Azure DevOps, but as short as possible (5 characters or less is ideal) due to resource name length limits in Azure (see RELATED LINKS).

Please make sure that there are no existing resources using this same prefix as this could lead to unintended changes.

.PARAMETER ProdEnvironment
The name of your production environment. Defaults to `prod`.

.PARAMETER PreProdEnvironments
An array (comma-separated-values) of pre-production environment names that you want to create. Defaults to `preview`.

.PARAMETER Location
The Location name where you want to deploy your Azure resources e.g. westeurope.

.PARAMETER OrgUrl
The URL of your Azure DevOps Organization where your Pipeline will be created eg. https://dev.azure.com/{your_org_name}.

.PARAMETER ProjectName
The name of the Project in Azure where your Pipeline will be created.

.PARAMETER Force
Use this switch to force this script to run. Use with caution as this may cause existing resources to be updated.

.INPUTS
None

.OUTPUTS
None

.LINK
https://github.com/CMeeg/next-azure

.LINK
https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]$ResourcePrefix,
    [string]$ProdEnvironment = 'prod',
    [string[]]$PreProdEnvironments = @('preview'),
    [Parameter(Mandatory=$true)]
    [string]$Location,
    [Parameter(Mandatory=$true)]
    [string]$OrgUrl,
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    [switch]$Force
)

# Ensure latest "version" of NextAzure module is imported

if (Get-Module -Name NextAzure) {
    Remove-Module NextAzure
}

Import-Module "$PSScriptRoot/NextAzure/NextAzure.psm1"

$OriginalInformationPreference = $InformationPreference

$InformationPreference = "Continue"

# Initialise the next-azure config file

$Config = Get-NextAzureConfig -InformationAction Continue

if ($Config -and !$Force) {
    Write-Error "next-azure config file exists - project has already been initialised. You can add a -Force switch if you want to continue anyway."

    return
}

$ConfigSettings = @{
    SubscriptionId = $SubscriptionId
    ResourcePrefix = $ResourcePrefix
    ProductionEnvironment = $ProdEnvironment
    Location = $Location
    OrgUrl = $OrgUrl
    ProjectName = $ProjectName
}

$Config = Set-NextAzureConfig -Config $Config -Settings $ConfigSettings -InformationAction Continue

# Configure Azure CLI default options from config

Set-AzCliDefaults -Config $Config -InformationAction Continue

Write-Line -InformationAction Continue

# Init defaults

Set-NextAzureDefaults -Config $Config -WebAppSkuName 'F1' -WebAppSkuCapacity 1 -InformationAction Continue

Write-Line -InformationAction Continue

# Init prod environment

Set-NextAzureEnvironment -Config $Config -Environment $ProdEnvironment -InformationAction Continue

Write-Line -InformationAction Continue

# Init environments

foreach ($Environment in $PreProdEnvironments) {
    Set-NextAzureEnvironment -Config $Config -Environment $Environment -InformationAction Continue

    Write-Line -InformationAction Continue
}

Write-Information "`u{2714}`u{FE0F} Done"

$InformationPreference = $OriginalInformationPreference
