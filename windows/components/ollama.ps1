[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

Write-Step "Ensuring Ollama"

# Ollama's documented PowerShell install path is:
#   irm https://ollama.com/install.ps1 | iex
# Keep winget as the managed devenv path, but use that if winget causes issues.
Set-WingetPackage -Id "Ollama.Ollama"

$ollama = Get-Command ollama.exe -ErrorAction SilentlyContinue
if ($ollama -and $ollama.Source) {
    Write-Step "Ollama command available: $($ollama.Source)"
}
else {
    Write-Warning "ollama.exe was not found on PATH. Restart the terminal after installation if this is a fresh install."
}

Write-Step "Ollama complete"
