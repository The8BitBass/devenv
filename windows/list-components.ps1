[CmdletBinding()]
param(
    [string]$Order = "run"
)

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
$liteComponents = Get-LiteRunComponentList
$sappsComponents = Get-SappsComponentList
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

[array]$rows = foreach ($component in $orderedComponents) {
    $componentScript = Join-Path $componentRoot "$component.ps1"

    [pscustomobject]@{
        Component = $component
        Script    = Test-Path -LiteralPath $componentScript
        Desired   = ($component -in $desiredComponents)
        Default   = ($component -in $defaultComponents)
        Lite      = ($component -in $liteComponents)
        SApp      = ($component -in $sappsComponents)
    }
}

if ($Order -eq "alpha") {
    $rows = @($rows | Sort-Object -Property Component)
}
else {
    $Order = "run"
}

Write-Step "Display order: $Order"

$columns = @(
    "Component",
    "Script",
    "Desired",
    "Default",
    "Lite",
    "SApp"
)

$widths = @{}

foreach ($column in $columns) {
    $widths[$column] = $column.Length
}

foreach ($row in $rows) {
    foreach ($column in $columns) {
        $value = $row.PSObject.Properties[$column].Value
        $valueLength = ([string]$value).Length

        if ($valueLength -gt $widths[$column]) {
            $widths[$column] = $valueLength
        }
    }
}

$formatParts = for ($i = 0; $i -lt $columns.Count; $i++) {
    $column = $columns[$i]
    "{" + $i + ",-" + $widths[$column] + "}"
}

$format = $formatParts -join "  "

Write-Host ""

[object[]]$headerValues = $columns
Write-Host ([string]::Format($format, $headerValues)) -ForegroundColor Cyan

[object[]]$separatorValues = foreach ($column in $columns) {
    "-" * $widths[$column]
}

Write-Host ([string]::Format($format, $separatorValues)) -ForegroundColor DarkCyan

$rowColors = @(
    [ConsoleColor]::Red,
    [ConsoleColor]::Yellow,
    [ConsoleColor]::Green,
    [ConsoleColor]::Blue
)

$rowIndex = 0

foreach ($row in $rows) {
    [object[]]$rowValues = foreach ($column in $columns) {
        [string]$row.PSObject.Properties[$column].Value
    }

    $rowColor = $rowColors[$rowIndex % $rowColors.Count]

    Write-Host ([string]::Format($format, $rowValues)) -ForegroundColor $rowColor

    $rowIndex++
}

if (-not $desiredStateExists) {
    Write-Host ""
    Write-Host "No desired-state file exists yet." -ForegroundColor Yellow
}
