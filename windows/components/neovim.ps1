[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

Write-Step "Ensuring Neovim"

# using zig as the C compiler on windows
Set-WingetPackage -Id "zig.zig"
Set-WingetPackage -Id "Neovim.Neovim" -Version 0.11.7

# TODO: clone local nvim plugin repos
Write-Step "Neovim complete"

