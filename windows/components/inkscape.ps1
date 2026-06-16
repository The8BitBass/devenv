[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

$packageId = "Inkscape.Inkscape"

Write-Step "Ensuring Inkscape"

Set-WingetPackage -Id $packageId

Write-Step "Inkscape complete"


