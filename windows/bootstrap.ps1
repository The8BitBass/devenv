[CmdletBinding()]
param(
    [string]$DevenvRepoUrl = "https://github.com/The8BitBass/devenv.git",
    [string]$Branch = "main",
    [switch]$SkipLocalSetup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Get-PathContext {
    [pscustomobject]@{
        UserProfile  = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        LocalAppData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
        ProgramFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
    }
}

function Set-Directory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Get-GitPath {
    $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $paths = Get-PathContext
    $candidates = @(
        (Join-Path $paths.ProgramFiles "Git\cmd\git.exe"),
        "C:\Program Files (x86)\Git\cmd\git.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-PwshPath {
    $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $paths = Get-PathContext
    $candidate = Join-Path $paths.ProgramFiles "PowerShell\7\pwsh.exe"

    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    return $null
}

function Confirm-WingetPackage {
    param([Parameter(Mandatory)][string]$Id)

    $installed = $false

    try {
        $output = winget list --id $Id -e --source winget --accept-source-agreements 2>$null | Out-String
        if ($LASTEXITCODE -eq 0 -and $output -match [regex]::Escape($Id)) {
            $installed = $true
        }
    } catch {
        $installed = $false
    }

    if (-not $installed) {
        winget install `
            --id $Id `
            -e `
            --source winget `
            --silent `
            --accept-package-agreements `
            --accept-source-agreements `
            --disable-interactivity

        if ($LASTEXITCODE -ne 0) {
            throw "winget install failed for $Id"
        }
    }
}

function Set-EnvVar {
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $current = [Environment]::GetEnvironmentVariable($Name, "Machine")
    if ($current -ne $Value) {
        $displayCurrent = if ($null -eq $current) {
            "<not set>" 
        } else {
            $current 
        }

        Write-Host "Updating environment variable '$Name'"
        Write-Host "  Original: '$displayCurrent'"
        Write-Host "  Updated : '$Value'"

        [System.Environment]::SetEnvironmentVariable($Name, $Value, "Machine")
    }
    Set-Item env:$Name -Value $Value  # Also update current session
}

function Initialize-DevenvBaseEnvironment {
    $paths = Get-PathContext

    $driveRoot = [System.IO.Path]::GetPathRoot($paths.UserProfile)
    $devenvRoot = Join-Path $driveRoot "devenv"
    $configHome = Join-Path $driveRoot ".config"
    $dataHome = Join-Path $driveRoot ".local\share"
    $stateHome = Join-Path $driveRoot ".local\state"
    $homeDir = Join-Path $driveRoot "Home"
    $homePersonal = Join-Path $homeDir "personal"

    $directoriesToCreate = @(
        $configHome,
        $dataHome,
        $stateHome,
        $homeDir,
        $homePersonal
    )

    foreach ($directory in $directoriesToCreate) {
        Set-Directory -Path $directory
    }

    $variables = @{
        DEVENV_ROOT     = $devenvRoot
        XDG_CONFIG_HOME = $configHome
        XDG_DATA_HOME   = $dataHome
        XDG_STATE_HOME  = $stateHome
        HOME            = $homeDir
    }

    foreach ($name in $variables.Keys) {
        Set-EnvVar -Name $name -Value ([string]$variables[$name])
    }

    return [pscustomobject]@{
        DevenvRoot   = $devenvRoot
    }
}

function Sync-DevenvRepo {
    param(
        [Parameter(Mandatory)][string]$RepoUrl,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$TargetPath
    )

    $git = Get-GitPath
    if (-not $git) {
        throw "git.exe was not found."
    }

    $parentPath = Split-Path -Path $TargetPath -Parent
    Set-Directory -Path $parentPath

    $targetExists = Test-Path -LiteralPath $TargetPath
    $targetIsDirectory = $targetExists -and (Test-Path -LiteralPath $TargetPath -PathType Container)
    $gitPath = Join-Path $TargetPath ".git"

    if ($targetExists -and -not $targetIsDirectory) {
        throw "Target path exists but is not a directory: $TargetPath"
    }

    $isEmptyDirectory = $false
    if ($targetIsDirectory) {
        $isEmptyDirectory = $null -eq (Get-ChildItem -LiteralPath $TargetPath -Force | Select-Object -First 1)
    }

    if (-not $targetExists -or $isEmptyDirectory) {
        & $git clone --branch $Branch --recurse-submodules $RepoUrl $TargetPath
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed for devenv repo"
        }
        return
    }

    if (-not (Test-Path -LiteralPath $gitPath)) {
        throw "Target path exists but is not a git repository: $TargetPath"
    }

    & $git -C $TargetPath pull --ff-only
    if ($LASTEXITCODE -ne 0) {
        throw "git pull failed for devenv repo"
    }

    if (Test-Path -LiteralPath (Join-Path $TargetPath ".gitmodules")) {
        & $git -C $TargetPath submodule update --init --recursive
        if ($LASTEXITCODE -ne 0) {
            throw "git submodule update failed for devenv repo"
        }
    }
}

Write-Step "Ensuring Git"
if (-not (Get-GitPath)) {
    Confirm-WingetPackage -Id "Git.Git"
}
$git = Get-GitPath
if (-not $git) {
    throw "Git could not be found after installation."
}

Write-Step "Ensuring PowerShell 7"
if (-not (Get-PwshPath)) {
    Confirm-WingetPackage -Id "Microsoft.PowerShell"
}
$pwsh = Get-PwshPath
if (-not $pwsh) {
    throw "PowerShell 7 could not be found after installation."
}

Write-Step "Creating base directories and environment variables"
$envInfo = Initialize-DevenvBaseEnvironment

Write-Step "Cloning or updating devenv repository"
Sync-DevenvRepo `
    -RepoUrl $DevenvRepoUrl `
    -Branch $Branch `
    -TargetPath $envInfo.DevenvRoot

if (-not $SkipLocalSetup) {
    $localSetup = Join-Path $envInfo.DevenvRoot "windows\setup-core.ps1"

    if (-not (Test-Path -LiteralPath $localSetup)) {
        throw "Expected local setup script not found: $localSetup"
    }

    Write-Step "Running local setup orchestrator"
    & $pwsh -NoProfile -ExecutionPolicy Bypass -File $localSetup
    exit $LASTEXITCODE
}

Write-Step "Bootstrap complete"
Write-Host "Devenv root: $($envInfo.DevenvRoot)" -ForegroundColor Green
