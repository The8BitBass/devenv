[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

Write-Step "Ensuring DotNet"

Set-WingetPackage -Id install Microsoft.DotNet.SDK.9
Set-WingetPackage -Id install Microsoft.DotNet.SDK.8
Set-WingetPackage -Id install Microsoft.DotNet.SDK.7
Set-WingetPackage -Id install Microsoft.DotNet.SDK.6

Write-Step "DotNet complete"


