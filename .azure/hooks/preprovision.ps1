$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Run script to generate `web.settings.json` file used by the infra scripts
& $(Join-Path $scriptDir "../../infra/web.settings.ps1")
