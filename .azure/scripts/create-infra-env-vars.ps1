function Remove-Quotes {
    param(
        [Parameter(Mandatory=$true)]
        [string]$value,
        [string]$quoteChar = '"'
    )

    if ($value.StartsWith($quoteChar) -and $value.EndsWith($quoteChar)) {
        return $value.Substring(1, $value.Length - 2)
    }

    return $value
}

function Read-EnvVars {
    param(
        [Parameter(Mandatory=$true)]
        [string]$path
    )

    $envVars = @{}

    if (!(Test-Path $path -PathType Leaf)) {
        # File does not exist so there is nothing to do

        return $envVars
    }

    $content = Get-Content -raw $path | ConvertFrom-StringData

    $content.GetEnumerator() | Foreach-Object {
        $key, $value = $_.Name, $_.Value

        if (($null -eq $value) -or ($value -eq "")) {
            $envVars[$key] = ""
        } else {
            $value = Remove-Quotes -value $value -quoteChar '"'
            $value = Remove-Quotes -value $value -quoteChar "'"

            $envVars[$key] = $value
        }
    }

    return $envVars
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Read `.env`, `.env.production` and `.env.local` files into memory

$envPath = Join-Path $scriptDir "../../.env"
$env = Read-EnvVars -path $envPath

$envProductionPath = Join-Path $scriptDir "../../.env.production"
$envProduction = Read-EnvVars -path $envProductionPath

$envLocalPath = Join-Path $scriptDir "../../.env.local"
$envLocal = Read-EnvVars -path $envLocalPath

# Merge `.env.production` and `.env.local` into `.env` (duplicate keys will be overwritten)

$env += $envProduction
$env += $envLocal

# Produce a `env-vars.json` file that can be used by the infra scripts

$outputPath = Join-Path $scriptDir "../../infra/env-vars.json"

$env | ConvertTo-Json | Out-File -FilePath $outputPath -Encoding utf8
