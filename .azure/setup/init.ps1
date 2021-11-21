param(
    [string]$ResourcePrefix,
    [string]$Location
)

# Ensure latest "version" of NextAzure module is imported
if (Get-Module -ListAvailable -Name NextAzure) {
    Remove-Module NextAzure
}

Import-Module "$PSScriptRoot/NextAzure/NextAzure.psm1"

Set-ResourceGroup -ResourcePrefix $ResourcePrefix -Environment "preview" -Location $Location
Set-ResourceGroup -ResourcePrefix $ResourcePrefix -Environment "prod" -Location $Location
