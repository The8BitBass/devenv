[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

$packageIds = @(
    "BurntSushi.ripgrep.MSVC",
    "GIMP.GIMP.3"
)

Write-Step "Ensuring Base components"

foreach ($packageId in $packageIds) {
    Set-WingetPackage -Id $packageId
}

Write-Step "Base components complete"

