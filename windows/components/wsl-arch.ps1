#requires -Version 7.0
#requires -RunAsAdministrator

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force

$DistroName = "archlinux"
$LinuxUser = "the8bitbass"

function Test-WslReady {
    try {
        & wsl --status *> $null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Get-WslDistroNames {
    $output = & wsl --list --quiet 2>$null

    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    return @(
        $output |
            ForEach-Object { ($_ -replace "`0", "").Trim() } |
            Where-Object { $_ }
    )
}

function Get-OnlineWslDistroNames {
    $output = (& wsl --list --online | Out-String) -replace "`0", ""

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to list online WSL distributions."
    }

    return @(
        $output -split "`r?`n" |
            ForEach-Object { $_.Trim() } |
            Where-Object {
                $_ -and
                $_ -notmatch '^The following' -and
                $_ -notmatch '^Install using' -and
                $_ -notmatch '^NAME\s+FRIENDLY NAME'
            } |
            ForEach-Object {
                ($_ -split '\s{2,}')[0].Trim()
            } |
            Where-Object { $_ }
    )
}

function Test-WslDistroCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Command
    )

    & wsl --distribution $DistroName --user root --exec sh -lc $Command *> $null
    return $LASTEXITCODE -eq 0
}

function Wait-WslDistroReady {
    $maxAttempts = 12

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        if (Test-WslDistroCommand "command -v sh >/dev/null") {
            return
        }

        Write-Host "Waiting for WSL distro to become ready: $DistroName ($attempt/$maxAttempts)"
        Start-Sleep -Seconds 2
    }

    throw "WSL distro was installed but is not ready for root commands: $DistroName"
}

function Install-Distro {
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        throw "wsl was not found. This machine may not support WSL or Windows may need updating."
    }

    if (-not (Test-WslReady)) {
        throw "WSL has not been installed. Run: sudo devenv install wsl"
    }

    $installedDistros = Get-WslDistroNames

    if ($installedDistros -contains $DistroName) {
        Write-Host "WSL distro already installed: $DistroName"
        return
    }

    $onlineDistroNames = Get-OnlineWslDistroNames

    $matchingDistro = $onlineDistroNames |
        Where-Object { $_ -ieq $DistroName } |
        Select-Object -First 1

    if (-not $matchingDistro) {
        Write-Host "Available WSL distributions:"
        $onlineDistroNames | ForEach-Object {
            Write-Host "  $_"
        }

        throw "Could not find '$DistroName' in 'wsl --list --online'."
    }

    Write-Host "Installing WSL distro: $DistroName"

    # Explicit form is easier to read and matches Microsoft's docs.
    & wsl --install -d $matchingDistro

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install WSL distro: $matchingDistro"
    }
}

function Invoke-LinuxBootstrap {
    $repoRoot = Get-DevenvRoot
    $bootstrapWindowsPath = Join-Path $repoRoot "wsl\arch\bootstrap.sh"

    if (-not (Test-Path $bootstrapWindowsPath)) {
        throw "Missing Linux bootstrap script: $bootstrapWindowsPath"
    }

    Wait-WslDistroReady

    $bootstrapLinuxPath = (
        & wsl --distribution $DistroName --user root --exec wslpath -a $bootstrapWindowsPath
    ).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($bootstrapLinuxPath)) {
        throw "Failed to convert bootstrap path to WSL path."
    }

    Write-Host "Running Linux bootstrap:"
    Write-Host "  Distro: $DistroName"
    Write-Host "  User:   $LinuxUser"
    Write-Host "  Script: $bootstrapLinuxPath"

    & wsl --distribution $DistroName --user root --exec env `
        "DEVENV_USER=$LinuxUser" `
        bash $bootstrapLinuxPath

    if ($LASTEXITCODE -ne 0) {
        throw "Linux bootstrap failed."
    }
}

function Restart-WslDistro {
    Write-Host "Terminating WSL distro so /etc/wsl.conf is applied: $DistroName"
    & wsl --terminate $DistroName

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to terminate WSL distro: $DistroName"
    }
}

Write-Step "Installing WSL arch linux"

Install-Distro
Invoke-LinuxBootstrap
Restart-WslDistro

Write-Step "WSL arch linux installed"
Write-Host ""
Write-Host "Open Arch again, then run:"
Write-Host "  cd ~/dev/devenv"
Write-Host "  devenv doctor"
Write-Host "  devenv list"
Write-Host "  devenv dotfiles"
