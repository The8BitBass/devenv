[CmdletBinding()]
param(
    [string[]]$Components
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "\common\devenv.state.psm1") -Force

$devenvRoot = Get-DevenvRoot
$componentRoot = Get-ComponentRoot

if (-not (Test-Path -LiteralPath $componentRoot)) {
    throw "Components directory not found: $componentRoot"
}

$orderedComponents = Get-OrderedComponentList

$defaultRunComponents = Resolve-ComponentSet `
    -CandidateComponents (Get-DefaultRunComponentList) `
    -Source "default component list"

$desiredStatePath = Get-DesiredStatePath
$desiredStateExists = Test-Path -LiteralPath $desiredStatePath

$requestedComponents = @()
if ($Components -and $Components.Count -gt 0) {
    $requestedComponents = Resolve-ComponentSet `
        -CandidateComponents $Components `
        -Source "command line"
}

if ($requestedComponents.Count -gt 0) {
    $desiredComponents = Add-DesiredComponents `
        -ComponentsToAdd $requestedComponents `
        -Path $desiredStatePath

    $runComponents = $requestedComponents
}
else {
    if (-not $desiredStateExists) {
        Set-DesiredState -Components $defaultRunComponents
    }

    $desiredComponents = Get-DesiredState

    $runComponents = $defaultRunComponents
}

Write-Step "Using devenv root: $devenvRoot"
Write-Step "Desired components: $($desiredComponents -join ', ')"
Write-Step "Run components: $($runComponents -join ', ')"

foreach ($component in $orderedComponents) {
    if ($component -in $runComponents) {
        Invoke-DevenvComponent -Name $component
    }
}

Write-Step "setup-core complete"
