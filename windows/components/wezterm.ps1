[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

Write-Step "Ensuring WezTerm"

Set-WingetPackage -Id "wez.wezterm.nightly"

Write-Step "WezTerm complete"

