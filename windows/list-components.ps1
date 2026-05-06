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
$defaultComponents = Get-DefaultRunComponentList
$desiredStatePath = Get-DesiredStatePath

$desiredComponents = @()
$desiredStateExists = Test-Path -LiteralPath $desiredStatePath

if ($desiredStateExists) {
    $desiredComponents = Get-DesiredState `
        -OrderedComponents $orderedComponents `
        -Path $desiredStatePath
}

Write-Step "Using devenv root: $devenvRoot"

if ($desiredStateExists) {
    Write-Step "Desired state file: $desiredStatePath"
}
else {
    Write-Step "Desired state file not found"
}

$rows = foreach ($component in $orderedComponents) {
    $componentScript = Join-Path $componentRoot "$component.ps1"

    [pscustomobject]@{
        Component = $component
        Script    = Test-Path -LiteralPath $componentScript
        Default   = ($component -in $defaultComponents)
        Desired   = ($component -in $desiredComponents)
    }
}

$rows | Format-Table -AutoSize

if (-not $desiredStateExists) {
    Write-Host ""
    Write-Host "No desired-state file exists yet." -ForegroundColor Yellow
}
