param(
    [string]$ResourcePrefix,
    [string]$Location
)

# Ensure latest "version" of NextAzure module is imported

if (Get-Module -Name NextAzure) {
    Remove-Module NextAzure
}

Import-Module "$PSScriptRoot/NextAzure/NextAzure.psm1"

# Init environments

Set-NextAzureEnvironment -ResourcePrefix $ResourcePrefix -Environment "preview" -Location $Location -InformationAction Continue

Set-NextAzureEnvironment -ResourcePrefix $ResourcePrefix -Environment "prod" -Location $Location -InformationAction Continue
