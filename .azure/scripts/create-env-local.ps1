$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create a `.env.local` file by merging values from the current environment with a template

$templatePath = Join-Path $scriptDir "../../.env.local.template"

if (!(Test-Path $templatePath -PathType Leaf)) {
    # Template file does not exist so we can't go any further

    return
}

$outputPath = Join-Path $scriptDir "../../.env.local"

if (Test-Path $outputPath -PathType Leaf) {
    # We only want to create the `.env.local` file if it does not already exist
    # In the development environment the developer should be in control of their `.env.local` file so it should exist
    # In CI the `.env.local` file should not exist as it should not be comitted to the repo

    return
}

# Read the template file

$template = Get-Content -raw $templatePath | ConvertFrom-StringData

# For each key in the template, check if there is a corresponding environment variable and if so, add it to an object

$envVars = @{}

$template.GetEnumerator() | ForEach-Object {
    $key = $_.Name

    if (Test-Path "env:$key") {
        $value = Get-ChildItem "env:$key" | Select-Object -ExpandProperty Value

        $envVars[$key] = $value
    } else {
        $envVars[$key] = ""
    }
}

# Write the object to the output file in env file format

$envVars.Keys | Sort-Object | ForEach-Object {
    "$_=$($envVars[$_])"
} | Out-File $outputPath
