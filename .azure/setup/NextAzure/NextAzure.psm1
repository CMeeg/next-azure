function Set-NextAzureDefaults {
    [CmdletBinding()]
    param(
        [string]$ResourcePrefix,
        [string]$WebAppSkuName,
        [int]$WebAppSkuCapacity
    )

    # Set Variable Group

    Write-Information "Setting Variable Group"

    $AzVariableGroup = Set-AzVariableGroup `
    -ResourcePrefix $ResourcePrefix `
    -Variables @{
        WebAppSkuName = $WebAppSkuName
        WebAppSkuCapacity = $WebAppSkuCapacity
    }

    $VariableGroupName = $AzVariableGroup.name

    Write-Information "Variable Group '$VariableGroupName' is set"
}

function Set-NextAzureEnvironment {
    [CmdletBinding()]
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [string]$Location
    )

    Write-Information "Setting up '$Environment' environment"

    # Set Resource Group

    Write-Information "Setting Resource Group"

    $AzResourceGroup = Set-AzResourceGroup `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment `
    -Location $Location

    $ResourceGroupName = $AzResourceGroup.name

    Write-Information "Resource Group '$ResourceGroupName' is set"

    # Set Service Connection

    # TODO: Does the Service Connection have the required access to create permissions in the relevant Resource Group?

    Write-Information "Setting Service Connection"

    $AzServiceConnection = Set-AzServiceConnection `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment

    $ServiceConnectionName = $AzServiceConnection.name

    Write-Information "Service Connection '$ServiceConnectionName' is set"

    # Set Environment

    Write-Information "Setting Environment"

    $AzEnvironment = Set-AzEnvironment `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment

    $EnvironmentName = $AzEnvironment.name

    Write-Information "Environment '$EnvironmentName' is set"

    # Set Variable Group

    Write-Information "Setting Variable Group"

    $AzVariableGroup = Set-AzVariableGroup `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment `
    -Variables @{
        AzureResourceGroup = $AzResourceGroup.name
        AzureServiceConnection = $AzServiceConnection.name
    }

    $VariableGroupName = $AzVariableGroup.name

    Write-Information "Variable Group '$VariableGroupName' is set"
}

function Get-NextAzureResourceName {
    param(
        [string]$Prefix,
        [string]$Environment,
        [string]$Suffix,
        [string]$Delimiter = '-'
    )

    $Name = @($Prefix)

    if ($Environment) {
        $Name += $Environment
    }

    if ($Suffix) {
        $Name += $Suffix
    }

    return $Name -join $Delimiter
}

function Get-CurrentAzSubscription {
    $Subscription = (az account show | ConvertFrom-Json)

    return $Subscription
}

function Get-CurrentAzDevOpsConfig {
    $RawConfig = (az devops configure --list | Out-String)

    $ProjectResult = Select-String -Pattern "(?m)^project = (.+)$" -InputObject $RawConfig
    $OrganizationResult = Select-String -Pattern "(?m)^organization = (.+)$" -InputObject $RawConfig

    $Project = ""
    if ($ProjectResult.Matches.Groups.Count -gt 0) {
        $Project = $ProjectResult.Matches.Groups[1].Value
    }

    $Organization = ""
    if ($OrganizationResult.Matches.Groups.Count -gt 0) {
        $Organization = $OrganizationResult.Matches.Groups[1].Value
    }

    $Config = [PSCustomObject]@{
        Project = $Project
        Organization = $Organization
    }

    return $Config
}

function Set-AzResourceGroup {
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [string]$Location
    )

    $Name = Get-NextAzureResourceName -Prefix $ResourcePrefix -Environment $Environment -Suffix 'rg'

    $ResourceGroup = (az group create --name $Name --location $Location | ConvertFrom-Json)

    return $ResourceGroup
}

function Set-AzServicePrincipal {
    param(
        [string]$ResourcePrefix,
        [string]$Environment
    )

    $Name = Get-NextAzureResourceName -Prefix $ResourcePrefix -Environment $Environment -Suffix 'sp'

    $ServicePrincipal = (az ad sp create-for-rbac --name $Name | ConvertFrom-Json)

    # We need to update the Service Prinipal to add SPN auth, but we suppress the output
    $VsSpnUrl = 'https://VisualStudio/SPN'

    az ad app update --id $ServicePrincipal.appId --reply-urls $VsSpnUrl --homepage $VsSpnUrl | Out-Null

    return $ServicePrincipal
}

function Get-AzServiceConnection {
    param(
        [string]$Name
    )

    $ServiceConnection = (az devops service-endpoint list --query "[?name == '$Name'] | [0]" | ConvertFrom-Json)

    return $ServiceConnection
}

function Set-AzServiceConnection {
    param(
        [string]$ResourcePrefix,
        [string]$Environment
    )

    $Name = Get-NextAzureResourceName -Prefix $ResourcePrefix -Environment $Environment

    $ServiceConnection = Get-AzServiceConnection -Name $Name

    if ($ServiceConnection) {
        # If the Service Connection already exists there is nothing more to do

        return $ServiceConnection
    }

    # To create a Service Connection we need a Service Principal

    $ServicePrincipal = Set-AzServicePrincipal -ResourcePrefix $ResourcePrefix -Environment $Environment

    $ServicePrincipalId = $ServicePrincipal.appId
    $ServicePrincipalPassword = $ServicePrincipal.password

    # The Service Principal password must be available via an environment variable for the Service Connection
    $env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$ServicePrincipalPassword

    # We also need Subscription info

    $Subscription = Get-CurrentAzSubscription
    $SubscriptionId = $Subscription.id
    $SubscriptionName = $Subscription.name
    $TenantId = $Subscription.tenantId

    # Now we can create the Service Connection

    $ServiceConnection = (az devops service-endpoint azurerm create `
    --azure-rm-service-principal-id $ServicePrincipalId `
    --azure-rm-subscription-id $SubscriptionId `
    --azure-rm-subscription-name $SubscriptionName `
    --azure-rm-tenant-id $TenantId `
    --name $Name `
    | ConvertFrom-Json)

    if ($ServiceConnection) {
        $ServiceConnectionId = $ServiceConnection.id

        # Grant access permission to all pipelines and suppress output
        az devops service-endpoint update --id $ServiceConnectionId --enable-for-all | Out-Null
    }

    return $ServiceConnection
}

function Get-AzEnvironment {
    param(
        [string]$Name,
        [string]$Project,
        [string]$Organization
    )

    # There is no `environment` subcommand so we have to use `invoke`, but the invoke command doesn't pick up the default project from config so we use a param

    $Environment = (az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters "project=$Project" `
    --org $Organization `
    --query "value[?name=='$Name'] | [0]" `
    --api-version '6.0-preview' `
    --output json `
    | ConvertFrom-Json)

    return $Environment
}

function Set-AzEnvironment {
    param(
        [string]$ResourcePrefix,
        [string]$Environment
    )

    $Name = Get-NextAzureResourceName -Prefix $ResourcePrefix -Environment $Environment

    # There is no `environment` subcommand so we have to use `invoke`, but the invoke command doesn't pick up the default config values so we need to get it by reading the config ourselves
    $Config = Get-CurrentAzDevOpsConfig
    $Project = $Config.Project
    $Organization = $Config.Organization

    $AzEnvironment = Get-AzEnvironment -Name $Name -Project $Project -Organization $Organization

    if ($AzEnvironment) {
        # If the Environment already exists there is nothing more to do

        return $AzEnvironment
    }

    # Create the Environment

    # This `invoke` request requires that we send json via the `--in-file` param so we will create a temporary file
    $RequestPayload = @{
        name = $Name
    }

    $TempDrive = Get-PSDrive Temp
    $TempPath = $TempDrive.Root

    $RequestPayloadPath = Join-Path $TempPath 'AzDevOpsEnvBody.json'

    Set-Content -Path $RequestPayloadPath -Value ($RequestPayload | ConvertTo-Json)

    az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters "project=$Project" `
    --org $Organization `
    --http-method POST `
    --in-file $RequestPayloadPath `
    --api-version '6.0-preview' `
    --output json `
    | Out-Null

    # Remove the temp payload file
    Remove-Item $RequestPayloadPath -Force

    # The command to create the Environment doesn't return a useful response so we will fetch it and return
    $AzEnvironment = Get-AzEnvironment -Name $Name -Project $Project -Organization $Organization

    return $AzEnvironment
}

function Get-AzVariableGroup {
    param(
        [int]$Id,
        [string]$Name
    )

    if ($Id) {
        $VariableGroup = (az pipelines variable-group show --group-id $Id | ConvertFrom-Json)

        return $VariableGroup
    }

    $VariableGroup = (az pipelines variable-group list `
    --query "[?name=='$Name'] | [0]"
    | ConvertFrom-Json)

    return $VariableGroup
}

function Set-AzVariableGroup {
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [hashtable]$Variables
    )

    $Name = Get-NextAzureResourceName -Prefix "$ResourcePrefix-env-vars" -Environment $Environment

    $VariableGroup = Get-AzVariableGroup -Name $Name

    if ($VariableGroup) {
        $VariableGroup = Set-AzVariableGroupVariables -VariableGroupId $($VariableGroup.id) -Variables $Variables

        return $VariableGroup
    }

    $VariablesArgs = @()
    foreach($Key in $Variables.Keys)
    {
        $VariablesArgs += '{0}="{1}"' -f $Key, $Variables[$Key]
    }

    $VariableGroup = (az pipelines variable-group create `
    --name $Name `
    --authorize `
    --variables $VariablesArgs
    | ConvertFrom-Json)

    return $VariableGroup
}

function Set-AzVariableGroupVariables {
    param(
        [int]$VariableGroupId,
        [hashtable]$Variables
    )

    foreach($Key in $Variables.Keys) {
        Set-AzVariableGroupVariable -VariableGroupId $VariableGroupId -Name $Key -Value $Variables[$Key]
    }

    $VariableGroup = Get-AzVariableGroup -Id $VariableGroupId

    return $VariableGroup
}

function Set-AzVariableGroupVariable {
    param(
        [int]$VariableGroupId,
        [string]$Name,
        [string]$Value
    )

    $Variable = (az pipelines variable-group variable list --group-id $VariableGroupId | ConvertFrom-Json)

    if (Get-Member -InputObject $Variable -Name $Name -Membertype Properties) {
        # Variable already exists - update

        $Variable = (az pipelines variable-group variable update `
        --group-id $VariableGroupId `
        --name $Name `
        --value $Value `
        | ConvertFrom-Json)

        return $Variable
    }

    # Variable does not exist - create

    $Variable = (az pipelines variable-group variable create `
    --group-id $VariableGroupId `
    --name $Name `
    --value $Value `
    | ConvertFrom-Json)

    return $Variable
}

Export-ModuleMember -Function Set-NextAzureDefaults
Export-ModuleMember -Function Set-NextAzureEnvironment
