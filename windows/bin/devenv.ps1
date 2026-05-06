[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-DevenvRoot {
    $root = [Environment]::GetEnvironmentVariable("DEVENV_ROOT", "Process")
    if (-not $root) {
        $root = [Environment]::GetEnvironmentVariable("DEVENV_ROOT", "User")
    }
    if (-not $root) {
        $root = [Environment]::GetEnvironmentVariable("DEVENV_ROOT", "Machine")
    }
    if (-not $root) {
        throw "DEVENV_ROOT is not set."
    }
    return $root
}

function Show-DevenvHelp {
    @"
devenv commands:

  devenv install <component...>
  devenv update
  devenv list
  devenv dotfiles

examples:
  devenv install neovim fzf wezterm
  devenv update
  devenv list
  devenv dotfiles
"@
}

$devenvRoot = Get-DevenvRoot
$windowsRoot = Join-Path $devenvRoot "windows"

switch ($Command.ToLowerInvariant()) {
    "install" {
        $setupCore = Join-Path $windowsRoot "setup-core.ps1"

        & $setupCore -Components $Arguments
        break
    }

    "update" {
        $updateAll = Join-Path $windowsRoot "update-all.ps1"
        if (-not (Test-Path -LiteralPath $updateAll)) {
            throw "update-all.ps1 not found: $updateAll"
        }

        & $updateAll
        break
    }

    "list" {
        $listScript = Join-Path $windowsRoot "list-components.ps1"
        if (-not (Test-Path -LiteralPath $listScript)) {
            throw "list-components.ps1 not found: $listScript"
        }

        & $listScript
        break
    }

    "dotfiles" {
        $dotfilesComponent = Join-Path $windowsRoot "components\dotfiles.ps1"
        if (-not (Test-Path -LiteralPath $dotfilesComponent)) {
            throw "dotfiles component not found: $dotfilesComponent"
        }

        & $dotfilesComponent
        break
    }

    "help" {
        Show-DevenvHelp
        break
    }

    default {
        throw "Unknown command: $Command"
    }
}
