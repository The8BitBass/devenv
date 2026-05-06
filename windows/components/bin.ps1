[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force

function ConvertTo-PathEntryKey {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $trimmed = $Path.Trim().Trim('"')

    if ($trimmed.Length -gt 3) {
        $trimmed = $trimmed.TrimEnd('\')
    }

    return $trimmed.ToLowerInvariant()
}

function Test-PathValueContainsEntry {
    param(
        [Parameter(Mandatory)][string]$PathValue,
        [Parameter(Mandatory)][string]$Candidate
    )

    $candidateKey = ConvertTo-PathEntryKey -Path $Candidate

    foreach ($entry in ($PathValue -split ';')) {
        if (-not [string]::IsNullOrWhiteSpace($entry)) {
            if ((ConvertTo-PathEntryKey -Path $entry) -eq $candidateKey) {
                return $true
            }
        }
    }

    return $false
}

$devenvRoot = Get-DevenvRoot
$xdg_home = Get-EnvironmentVariableValue "home"
$sourceBin = Join-Path $devenvRoot "windows\bin"
$targetBin = Join-Path $xdg_home "bin"

if (-not (Test-Path -LiteralPath $sourceBin)) {
    throw "Source bin directory not found: $sourceBin"
}

Write-Step "Ensuring target bin directory exists"
Set-Directory -Path $targetBin

Write-Step "Copying bin files from $sourceBin to $targetBin"
Get-ChildItem -LiteralPath $sourceBin -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetBin $_.Name) -Force
}

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if (-not (Test-PathValueContainsEntry -PathValue $machinePath -Candidate $targetBin)) {
    Write-Step "Adding $targetBin to Machine PATH"

    if ([string]::IsNullOrWhiteSpace($machinePath)) {
        $newPath = $targetBin
    }
    else {
        $newPath = $machinePath.TrimEnd(';') + ';' + $targetBin
    }

    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not (Test-PathValueContainsEntry -PathValue $userPath -Candidate $targetBin)) {
    Write-Step "Adding $targetBin to User PATH"

    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $newPath = $targetBin
    }
    else {
        $newPath = $userPath.TrimEnd(';') + ';' + $targetBin
    }

    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

if (-not (Test-PathValueContainsEntry -PathValue $env:Path -Candidate $targetBin)) {
    if ([string]::IsNullOrWhiteSpace($env:Path)) {
        $env:Path = $targetBin
    }
    else {
        $env:Path = $env:Path.TrimEnd(';') + ';' + $targetBin
    }
}

Write-Step "bin component complete"
Write-Host "bin: $targetBin" -ForegroundColor Green
