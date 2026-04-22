[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

Write-Step "Ensuring PowerShell 7"
Set-WingetPackage -Id "Microsoft.PowerShell"

$pwshPath = Get-PwshPath
Write-Step "powershell complete"
Write-Host "pwsh: $pwshPath" -ForegroundColor Green
