Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "devenv.psm1") -Force

function Test-Winget {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

function Get-WingetPath {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue

    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    throw "winget.exe was not found."
}

function Test-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id
    )

    if (-not (Test-Winget)) {
        throw "winget.exe was not found."
    }

    try {
        $output = winget list `
            --id $Id `
            -e `
            --source winget `
            --accept-source-agreements 2>$null | Out-String

        return ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($Id))
    }
    catch {
        return $false
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Version
    )

    if (-not (Test-Winget)) {
        throw "winget.exe was not found."
    }

    $arguments = @(
        "install",
        "--id", $Id,
        "-e",
        "--source", "winget",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    if ($Version) {
        $arguments += @("--version", $Version)
    }

    & winget @arguments

    if ($LASTEXITCODE -ne 0) {
        if ($Version) {
            throw "winget install failed for $Id version $Version"
        }

        throw "winget install failed for $Id"
    }
}

function Update-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Version
    )

    if (-not (Test-Winget)) {
        throw "winget.exe was not found."
    }

    $arguments = @(
        "upgrade",
        "--id", $Id,
        "-e",
        "--source", "winget",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    if ($Version) {
        $arguments += @("--version", $Version)
    }

    & winget @arguments

    if ($LASTEXITCODE -ne 0) {
        if ($Version) {
            throw "winget upgrade failed for $Id version $Version"
        }

        throw "winget upgrade failed for $Id"
    }
}

function Set-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Version
    )

    if (Test-WingetPackage -Id $Id) {
        if ($Version) {
            Write-Step "Updating $Id to version $Version"
        }
        else {
            Write-Step "Updating $Id"
        }

        Update-WingetPackage -Id $Id -Version $Version
        return
    }

    if ($Version) {
        Write-Step "Installing $Id version $Version"
    }
    else {
        Write-Step "Installing $Id"
    }

    Install-WingetPackage -Id $Id -Version $Version
}

Export-ModuleMember -Function `
    Test-Winget, `
    Get-WingetPath, `
    Test-WingetPackage, `
    Install-WingetPackage, `
    Update-WingetPackage, `
    Set-WingetPackage
