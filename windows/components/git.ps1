[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

$packageId = "Git.Git"

Write-Step "Ensuring Git"

Set-WingetPackage -Id $packageId

Write-Step "Git complete"
