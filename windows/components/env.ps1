[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force

Write-Step "Ensuring Environment Variables and Directories"

$UserProfile  = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)

$driveRoot = [System.IO.Path]::GetPathRoot($UserProfile)
$devenvRoot = Join-Path $driveRoot "devenv"
$configHome = Join-Path $driveRoot ".config"
$localHome = Join-Path $driveRoot ".local"
$dataHome = Join-Path $localHome "share"
$stateHome = Join-Path $localHome "state"
$homeDir = Join-Path $driveRoot "Home"
$homePersonal = Join-Path $homeDir "personal"

$directoriesToCreate = @(
    $configHome,
    $localHome,
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

Write-Step "EnvVar complete"

