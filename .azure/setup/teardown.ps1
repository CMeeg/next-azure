<#

.SYNOPSIS
Removes all environments for a next-azure project.

.DESCRIPTION
Deletes all Resource Groups, Service Connections, Environments and Variable Groups in Azure and Azure DevOps for a all environments used by this project's next-azure deployment Pipeline.

.INPUTS
None

.OUTPUTS
None

.LINK
https://github.com/CMeeg/next-azure

#>
[CmdletBinding()]
param()

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

Write-Line -InformationAction Continue

# Prompt for confirmation

$Confirmation = Read-Host "Are you sure you want to remove ALL existing environments? [y/n]"
if ($Confirmation -ne 'y') {
    Write-Information "No action taken" -InformationAction Continue

    return $null
}

Write-Line -InformationAction Continue

# Remove defaults

$null = Remove-NextAzureDefaults -Config $Config -InformationAction Continue

Write-Line -InformationAction Continue

# Remove environments

$null = Remove-AllNextAzureEnvironments -Config $Config -InformationAction Continue

Write-Information "`u{2714}`u{FE0F} Done"

$InformationPreference = $OriginalInformationPreference
