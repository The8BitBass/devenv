[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

$packageId = "GIMP.GIMP.3"

Write-Step "Ensuring GIMP"

Set-WingetPackage -Id $packageId

Write-Step "GIMP complete"


