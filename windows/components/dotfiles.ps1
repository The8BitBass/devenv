#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force

$devenvRoot = Get-DevenvRoot
$configHome = Get-EnvironmentVariableValue "XDG_CONFIG_HOME"

if ([string]::IsNullOrWhiteSpace($configHome)) {
    Write-Warning "XDG_CONFIG_HOME is not set. Skipping dotfiles setup."
    return
}

$sourceConfig = Join-Path $devenvRoot "env\.config"
$targetConfig = $configHome

if (-not (Test-Path -LiteralPath $sourceConfig -PathType Container)) {
    throw "Source config directory does not exist: $sourceConfig"
}

$resolvedTargetConfig = [System.IO.Path]::GetFullPath($targetConfig).TrimEnd('\', '/')

if (-not $resolvedTargetConfig.EndsWith(".config", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to delete config directory because XDG_CONFIG_HOME does not end with '.config': $resolvedTargetConfig"
}

Write-Host "[dotfiles] Source: $sourceConfig"
Write-Host "[dotfiles] Target: $targetConfig"

New-Item -ItemType Directory -Path $targetConfig -Force | Out-Null

Write-Host "[dotfiles] Removing existing config files..."
Get-ChildItem -LiteralPath $targetConfig -Force |
    Remove-Item -Recurse -Force

Write-Host "[dotfiles] Copying config files..."
Get-ChildItem -LiteralPath $sourceConfig -Force |
    Copy-Item -Destination $targetConfig -Recurse -Force

Write-Host "[dotfiles] Complete."
