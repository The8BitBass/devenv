Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Magenta
}

function Set-Directory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Set-File {
    param([Parameter(Mandatory)][string]$Path)

    Set-Directory -Path (Split-Path -Path $Path -Parent)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

function Get-EnvironmentVariableValue {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ($value) {
        return $value
    }

    $value = [Environment]::GetEnvironmentVariable($Name, "User")
    if ($value) {
        return $value
    }

    $value = [Environment]::GetEnvironmentVariable($Name, "Machine")
    if ($value) {
        return $value
    }

    return $null
}

function Get-DevenvRoot {
    $root = Get-EnvironmentVariableValue -Name "DEVENV_ROOT"

    if (-not $root) {
        throw "DEVENV_ROOT is not set. Run bootstrap.ps1 first."
    }

    if (-not (Test-Path -LiteralPath $root)) {
        throw "DEVENV_ROOT does not exist: $root"
    }

    return $root
}

function Get-DocumentsPath {
    return [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
}

function Get-PwshPath {
    $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
    $candidate = Join-Path $programFiles "PowerShell\7\pwsh.exe"

    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    throw "pwsh.exe was not found."
}

function Get-PwshProfilePath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("AllUsersAllHosts", "AllUsersCurrentHost", "CurrentUserAllHosts", "CurrentUserCurrentHost")]
        [string]$ProfileName
    )

    $pwsh = Get-PwshPath

    $path = & $pwsh -NoProfile -Command "`$PROFILE.$ProfileName"
    if ($LASTEXITCODE -ne 0 -or -not $path) {
        throw "Failed to resolve pwsh profile path for $ProfileName"
    }

    return ($path | Select-Object -First 1).ToString().Trim()
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

function Set-ManagedBlockInFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$Content
    )

    Set-Directory -Path (Split-Path -Path $Path -Parent)

    $startMarker = "# >>> $Tag >>>"
    $endMarker   = "# <<< $Tag <<<"

    $managedBlock = @"
$startMarker
$Content
$endMarker
"@

    $existing = ""
    if (Test-Path -LiteralPath $Path) {
        $existing = Get-Content -LiteralPath $Path -Raw
    }

    $escapedTag = [regex]::Escape($Tag)
    $pattern = "(?ms)^# >>> $escapedTag >>>.*?^# <<< $escapedTag <<<\r?\n?"

    if ($existing -match $pattern) {
        $updated = [regex]::Replace($existing, $pattern, $managedBlock + [Environment]::NewLine, 1)
    } else {
        if ($existing -and -not $existing.EndsWith([Environment]::NewLine)) {
            $existing += [Environment]::NewLine
        }

        $updated = $existing + $managedBlock + [Environment]::NewLine
    }

    Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8
}

function Get-ComponentRoot {
    $devenvRoot = Get-DevenvRoot
    return (Join-Path $devenvRoot "windows\components")
}

function Resolve-ComponentScript {
    param([Parameter(Mandatory)][string]$Name)

    $componentRoot = Get-ComponentRoot
    $scriptPath = Join-Path $componentRoot "$Name.ps1"

    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Unknown component: $Name"
    }

    return $scriptPath
}

function Invoke-DevenvComponent {
    param([Parameter(Mandatory)][string]$Name)

    $scriptPath = Resolve-ComponentScript -Name $Name

    Write-Step "Running component: $Name"

    try {
        & $scriptPath
    } catch {
        throw "Component failed: $Name. $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Write-Step',
    'Set-Directory',
    'Set-File',
    'Get-EnvironmentVariableValue',
    'Get-DevenvRoot',
    'Get-DocumentsPath',
    'Get-PwshPath',
    'Get-PwshProfilePath',
    'Set-EnvVar',
    'Set-ManagedBlockInFile',
    'Get-ComponentRoot',
    'Resolve-ComponentScript',
    'Invoke-DevenvComponent'
)
