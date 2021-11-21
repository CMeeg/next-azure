function Set-ResourceGroup {
    param(
        [string]$ResourcePrefix,
        [string]$Environment,
        [string]$Location
    )

    $Name = "$ResourcePrefix-$Environment-rg"

    az group create --name "$Name" --location "$Location"
}
