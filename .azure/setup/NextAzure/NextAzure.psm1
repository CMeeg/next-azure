$NextAzureConfigFileName = '.nextazure.json'
$AzDevOpsApiVersion = '6.0-preview'

function Get-NextAzureConfig {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    $ConfigPath = $Path ? $Path : (Get-NextAzureConfigPath -ConfigDir $MyInvocation.PSScriptRoot)

    if (!$ConfigPath) {
        Write-Verbose "Could not find '$NextAzureConfigFileName' config file in project"

        return $null
    }

    if (Test-Path -Path $ConfigPath -PathType Leaf) {
        Write-Verbose "Reading config file '$ConfigPath'"

        return Get-Content -Path $ConfigPath | ConvertFrom-JSON
    }

    Throw "Could not read config file '$ConfigPath'"
}

function Get-NextAzureConfigPath {
    param(
        [string]$ConfigDir
    )

    $ConfigPath = Join-Path $ConfigDir $NextAzureConfigFileName

    Write-Verbose "Searching for '$NextAzureConfigFileName' config file in '$ConfigPath'"

    if (Test-Path -Path $ConfigPath -PathType Leaf) {
        return $ConfigPath
    }

    # `next.config.js` is at the root of a Next.js project so if we have reached that and still not found our config file then there is no need to go further - assume it doesn't exist

    $NextConfigFileName = 'next.config.js'
    $NextConfigPath = Join-Path $ConfigDir $NextConfigFileName

    if (Test-Path -Path $NextConfigPath -PathType Leaf) {
        return $null
    }

    $ParentConfigDir = Split-Path -Path $ConfigDir -Parent

    if ($ParentConfigDir) {
        return Get-NextAzureConfigPath -ConfigDir $ParentConfigDir
    }
}

function Set-NextAzureConfig {
    [CmdletBinding()]
    param(
        [hashtable]$Settings
    )

    $RootPath = $MyInvocation.PSScriptRoot
    $ConfigPath = Get-NextAzureConfigPath -ConfigDir $RootPath
    $Config = Get-NextAzureConfig -Path $ConfigPath

    if ($Config) {
        # "Merge" in each setting

        Write-Information "Updating config file '$ConfigPath'"

        foreach ($Key in $Settings.Keys) {
            $Setting = Get-Member -InputObject $Config -Name $Key -Membertype Properties

            $Value = $Settings[$Key]

            if ($Setting) {
                $Config.$Key = $Value
            }
            else {
                $Config | Add-Member -MemberType NoteProperty -Name $Key -Value $Value
            }
        }
    }
    else {
        # Create new config from settings

        $ConfigPath = Join-Path $RootPath $NextAzureConfigFileName

        Write-Information "Creating config file '$ConfigPath'"

        $Config = [pscustomobject]$Settings
    }

    # Write as json to file

    $Config | ConvertTo-Json -depth 1 | Set-Content -Path $ConfigPath

    return $Config
}

function Set-AzCliDefaults {
    [CmdletBinding()]
    param(
        $Config
    )

    az account set --subscription $Config.SubscriptionId

    Write-Information "az account set"

    az devops configure --defaults organization=$($Config.OrgUrl) project=$($Config.ProjectName)

    Write-Information "az devops config set"
}

function Set-NextAzureDefaults {
    [CmdletBinding()]
    param(
        [string]$ResourcePrefix,
        [string]$WebAppSkuName,
        [int]$WebAppSkuCapacity
    )

    # Set Variable Group

    Write-Information "--- Setting up defaults ---"

    Write-Information "Setting Variable Group"

    $Variables = @{
        WebAppSkuName = $WebAppSkuName
        WebAppSkuCapacity = $WebAppSkuCapacity
    }

    $null = Set-AzVariableGroup -ResourcePrefix $ResourcePrefix -Variables $Variables
}

function Set-NextAzureEnvironment {
    [CmdletBinding()]
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [string]$Location
    )

    Write-Information "--- Setting up '$Environment' environment ---"

    # Set Resource Group

    Write-Information "Setting Resource Group"

    $AzResourceGroup = Set-AzResourceGroup `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment `
    -Location $Location

    Write-Line

    # Set Service Connection

    # TODO: Does the Service Connection have the required access to create permissions in the relevant Resource Group?

    Write-Information "Setting Service Connection"

    $AzServiceConnection = Set-AzServiceConnection `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment

    Write-Line

    # Set Environment

    Write-Information "Setting Environment"

    $null = Set-AzEnvironment `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment

    Write-Line

    # Set Variable Group

    Write-Information "Setting Variable Group"

    $Variables = @{
        AzureResourceGroup = $AzResourceGroup.name
        AzureServiceConnection = $AzServiceConnection.name
    }

    $null = Set-AzVariableGroup `
    -ResourcePrefix $ResourcePrefix `
    -Environment $Environment `
    -Variables $Variables
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

    Write-Information "Creating (or updating existing) Resource Group '$Name'"

    $ResourceGroup = (az group create --name $Name --location $Location | ConvertFrom-Json)

    return $ResourceGroup
}

function Set-AzServicePrincipal {
    param(
        [string]$ResourcePrefix,
        [string]$Environment
    )

    $Name = Get-NextAzureResourceName -Prefix $ResourcePrefix -Environment $Environment -Suffix 'sp'

    Write-Information "Creating (or updating existing) Service Principal '$Name'"

    $ServicePrincipal = (az ad sp create-for-rbac --name $Name | ConvertFrom-Json)

    # We need to update the Service Prinipal to add SPN auth, but we suppress the output
    $VsSpnUrl = 'https://VisualStudio/SPN'

    $null = az ad app update --id $ServicePrincipal.appId --reply-urls $VsSpnUrl --homepage $VsSpnUrl

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

        Write-Information "Service Connection '$Name' already exists - no action taken"

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

    Write-Information "Creating Service Connection '$Name'"

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
        $null = az devops service-endpoint update --id $ServiceConnectionId --enable-for-all
    }
    else {
        Write-Error "Service Connection could not be created"
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
    --api-version $AzDevOpsApiVersion `
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

        Write-Information "Environment '$Name' already exists - no action taken"

        return $AzEnvironment
    }

    # Create the Environment

    Write-Information "Creating Environment '$Name'"

    # This `invoke` request requires that we send json via the `--in-file` param so we will create a temporary file
    $RequestPayload = @{
        name = $Name
    }

    $TempDrive = Get-PSDrive Temp
    $TempPath = $TempDrive.Root

    $RequestPayloadPath = Join-Path $TempPath 'AzDevOpsEnvBody.json'

    Set-Content -Path $RequestPayloadPath -Value ($RequestPayload | ConvertTo-Json)

    $null = az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters "project=$Project" `
    --org $Organization `
    --http-method POST `
    --in-file $RequestPayloadPath `
    --api-version $AzDevOpsApiVersion

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
    --query "[?name=='$Name'] | [0]" `
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
        # Update the Variable Group

        Write-Information "Updating Variable Group '$Name'"

        $VariableGroup = Set-AzVariableGroupVariables -VariableGroupId $($VariableGroup.id) -Variables $Variables

        return $VariableGroup
    }

    # Create the Variable Group

    Write-Information "Creating Variable Group '$Name'"

    $VariablesArgs = @()
    foreach($Key in $Variables.Keys)
    {
        $VariablesArgs += '{0}="{1}"' -f $Key, $Variables[$Key]
    }

    $VariableGroup = (az pipelines variable-group create `
    --name $Name `
    --authorize `
    --variables $VariablesArgs `
    | ConvertFrom-Json)

    return $VariableGroup
}

function Set-AzVariableGroupVariables {
    param(
        [int]$VariableGroupId,
        [hashtable]$Variables
    )

    $GroupVariables = (az pipelines variable-group variable list --group-id $VariableGroupId | ConvertFrom-Json)

    foreach($Key in $Variables.Keys) {
        $GroupVariable = Get-Member -InputObject $GroupVariables -Name $Key -Membertype Properties

        $Value = $Variables[$Key]

        if ($GroupVariable) {
            Write-Verbose "Updating Variable '$Key'"

            $null = Set-AzVariableGroupVariable -VariableGroupId $VariableGroupId -Name $Key -Value $Value
        }
        else {
            Write-Verbose "Creating Variable '$Key'"

            $null = New-AzVariableGroupVariable -VariableGroupId $VariableGroupId -Name $Key -Value $Value
        }
    }

    $VariableGroup = Get-AzVariableGroup -Id $VariableGroupId

    return $VariableGroup
}

function New-AzVariableGroupVariable {
    param(
        [int]$VariableGroupId,
        [string]$Name,
        [string]$Value
    )

    $Variable = (az pipelines variable-group variable create `
    --group-id $VariableGroupId `
    --name $Name `
    --value $Value `
    | ConvertFrom-Json)

    return $Variable
}

function Set-AzVariableGroupVariable {
    param(
        [int]$VariableGroupId,
        [string]$Name,
        [string]$Value
    )

    $Variable = (az pipelines variable-group variable update `
    --group-id $VariableGroupId `
    --name $Name `
    --value $Value `
    | ConvertFrom-Json)

    return $Variable
}

function Write-Line {
    [CmdletBinding()]
    param()

    Write-Information ''
}

Export-ModuleMember -Function Get-NextAzureConfig
Export-ModuleMember -Function Set-NextAzureConfig
Export-ModuleMember -Function Set-AzCliDefaults
Export-ModuleMember -Function Set-NextAzureDefaults
Export-ModuleMember -Function Set-NextAzureEnvironment
Export-ModuleMember -Function Write-Line
