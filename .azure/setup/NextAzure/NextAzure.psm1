function Set-NextAzureEnvironment {
    [CmdletBinding()]
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [string]$Location
    )

    Write-Information "Setting up '$Environment' environment"

    # Create or update Resource Group

    Write-Information "Setting Resource Group"

    $ResourceGroup = Set-ResourceGroup `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment `
    -Location $Location

    $ResourceGroupName = $ResourceGroup.name

    Write-Information "Resource Group '$ResourceGroupName' is set"

    # Create or update Service Connection

    # TODO: Does the Service Connection have the required access to create permissions in the relevant Resource Group?

    Write-Information "Setting Service Connection"

    $ServiceConnection = Set-ServiceConnection `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment

    $ServiceConnectionName = $ServiceConnection.name

    Write-Information "Service Connection '$ServiceConnectionName' is set"

    # TODO: Create Azure DevOps Environment

    # TODO: Create Azure DevOps Variable Group
}

function Get-CurrentSubscription {
    $Subscription = (az account show | ConvertFrom-Json)

    return $Subscription
}

function Set-ResourceGroup {
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [string]$Location
    )

    $Name = "$ResourcePrefix-$Environment-rg"

    $ResourceGroup = (az group create --name "$Name" --location "$Location" | ConvertFrom-Json)

    return $ResourceGroup
}

function Set-ServicePrincipal {
    param(
        [string]$ResourcePrefix,
        [string]$Environment
    )

    $Name = "$ResourcePrefix-$Environment-sp"

    $ServicePrincipal = (az ad sp create-for-rbac --name "$Name" | ConvertFrom-Json)

    # We need to update the Service Prinipal to add SPN auth, but we suppress the output
    $VsSpnUrl = "https://VisualStudio/SPN"

    az ad app update --id $ServicePrincipal.appId --reply-urls "$VsSpnUrl" --homepage "$VsSpnUrl" | Out-Null

    return $ServicePrincipal
}

function Get-ServiceConnection {
    param(
        [string]$Name
    )

    $ServiceConnection = (az devops service-endpoint list --query "[?name == '$Name']|[0]" | ConvertFrom-Json)

    return $ServiceConnection
}

function Set-ServiceConnection {
    param(
        [string]$ResourcePrefix,
        [string]$Environment
    )

    $Name = "$ResourcePrefix-$Environment"

    $ServiceConnection = Get-ServiceConnection -Name $Name

    if ($ServiceConnection) {
        # If the Service Connection laready exists there is nothing more to do

        return $ServiceConnection
    }

    # To create a Service Connection we need a Service Principal

    $ServicePrincipal = Set-ServicePrincipal -ResourcePrefix $ResourcePrefix -Environment $Environment

    $ServicePrincipalId = $ServicePrincipal.appId
    $ServicePrincipalPassword = $ServicePrincipal.password

    # The Service Principal password must be available via an environment variable for the Service Connection
    $env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$ServicePrincipalPassword

    # We also need Subscription info

    $Subscription = Get-CurrentSubscription
    $SubscriptionId = $Subscription.id
    $SubscriptionName = $Subscription.name
    $TenantId = $Subscription.tenantId

    # Now we can create the Service Connection

    $ServiceConnection = (az devops service-endpoint azurerm create `
    --azure-rm-service-principal-id "$ServicePrincipalId" `
    --azure-rm-subscription-id "$SubscriptionId" `
    --azure-rm-subscription-name "$SubscriptionName" `
    --azure-rm-tenant-id "$TenantId" `
    --name "$Name" `
    | ConvertFrom-Json)

    if ($ServiceConnection) {
        $ServiceConnectionId = $ServiceConnection.id

        # Grant access permission to all pipelines and suppress output
        az devops service-endpoint update --id $ServiceConnectionId --enable-for-all | Out-Null
    }

    return $ServiceConnection
}

Export-ModuleMember -Function Set-NextAzureEnvironment
