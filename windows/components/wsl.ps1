#requires -Version 7.0
#requires -RunAsAdministrator

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force

function Test-WslReady {
    try {
        & wsl --status *> $null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Install-WslHost {
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        throw "wsl.exe was not found. This machine may not support WSL or Windows may need updating."
    }

    if (-not (Test-WslReady)) {
        wsl --install --no-distribution

        if (-not (Test-WslReady)) {
            throw "WSL installation was started. Restart Windows, then re-run this script."
        }
    }

    wsl --update
}

Write-Step "Configuring WSL"

Install-WslHost

Write-Step "WSL setup complete."
# Write-Host "Run this once to apply WSL config changes:"
# Write-Host "  wsl --shutdown"

