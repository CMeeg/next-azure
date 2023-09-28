$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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

function Register-EnvVars {
    param(
        [Parameter(Mandatory=$true)]
        [string]$path
    )

    if (!(Test-Path $path -PathType Leaf)) {
        # File does not exist so there is nothing to do

        return
    }

    $env = Get-Content -raw $path | ConvertFrom-StringData

    $env.GetEnumerator() | Foreach-Object {
        $name, $value = $_.Name, $_.Value

        if ($null -eq $value) {
            continue
        }

        $value = Remove-Quotes -value $value -quoteChar '"'
        $value = Remove-Quotes -value $value -quoteChar "'"

        if ($value -eq "") {
            continue
        }

        Set-Content -Path "env:\$name" -Value $value
    }
}

# Load vars from local `.env*` files and register them environment variables in process scope
Register-EnvVars -path $(Join-Path $scriptDir "../../.env")
Register-EnvVars -path $(Join-Path $scriptDir "../../.env.production")
Register-EnvVars -path $(Join-Path $scriptDir "../../.env.local")

# Run script to generate `web.settings.json` file used by the infra scripts
& $(Join-Path $scriptDir "../../infra/web.settings.ps1")
