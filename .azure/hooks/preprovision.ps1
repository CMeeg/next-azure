$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Run script to generate an `env-vars.json` file used by the infra scripts
& $(Join-Path $scriptDir "../scripts/create-infra-env-vars.ps1")
