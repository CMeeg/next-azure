param(
    [string]$SubscriptionId,
    [string]$ResourcePrefix,
    [string]$Location,
    [string]$OrgUrl,
    [string]$ProjectName,
    [switch]$Force = $False
)

# Ensure latest "version" of NextAzure module is imported

if (Get-Module -Name NextAzure) {
    Remove-Module NextAzure
}

Import-Module "$PSScriptRoot/NextAzure/NextAzure.psm1"

# Initialise the next-azure config file

$Config = Get-NextAzureConfig

if ($Config -and !$Force) {
    Write-Error "next-azure config file exists - project has already been initialised"

    return
}

$ConfigSettings = @{
    SubscriptionId = $SubscriptionId
    ResourcePrefix = $ResourcePrefix
    Location = $Location
    OrgUrl = $OrgUrl
    ProjectName = $ProjectName
}

$Config = Set-NextAzureConfig -Settings $ConfigSettings

# Configure Azure CLI default options from config

Set-AzCliDefaults -Config $Config -InformationAction Continue

# Init defaults

Set-NextAzureDefaults -ResourcePrefix $ResourcePrefix -WebAppSkuName 'F1' -WebAppSkuCapacity 1 -InformationAction Continue

# Init environments

Set-NextAzureEnvironment -ResourcePrefix $ResourcePrefix -Environment 'preview' -Location $Location -InformationAction Continue

Set-NextAzureEnvironment -ResourcePrefix $ResourcePrefix -Environment 'prod' -Location $Location -InformationAction Continue
