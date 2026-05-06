[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "common\devenv.state.psm1") -Force

$devenvRoot = Get-DevenvRoot
$componentRoot = Get-ComponentRoot

if (-not (Test-Path -LiteralPath $componentRoot)) {
    throw "Components directory not found: $componentRoot"
}

$orderedComponents = Get-OrderedComponentList
$desiredStatePath = Get-DesiredStatePath

if (-not (Test-Path -LiteralPath $desiredStatePath)) {
    throw "Desired state file does not exist: $desiredStatePath"
}

$desiredComponents = Get-DesiredState `
    -OrderedComponents $orderedComponents `
    -Path $desiredStatePath

if (-not $desiredComponents -or $desiredComponents.Count -eq 0) {
    Write-Warning "Desired state file exists, but no desired components were found."
    return
}

Write-Step "Using devenv root: $devenvRoot"
Write-Step "Desired state file: $desiredStatePath"
Write-Step "Updating all desired components: $($desiredComponents -join ', ')"

foreach ($component in $orderedComponents) {
    if ($component -in $desiredComponents) {
        Invoke-DevenvComponent -Name $component
    }
}

Write-Step "update-all complete"
