Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "devenv.psm1") -Force

function Get-XdgStateHome {
    $path = Get-EnvironmentVariableValue -Name "XDG_STATE_HOME"

    if (-not $path) {
        throw "XDG_STATE_HOME is not set. Run bootstrap.ps1 first."
    }

    return $path
}

function Get-DevenvStateRoot {
    $xdgStateHome = Get-XdgStateHome
    $stateRoot = Join-Path $xdgStateHome "devenv"
    Set-Directory -Path $stateRoot
    return $stateRoot
}

function Get-DesiredStatePath {
    $stateRoot = Get-DevenvStateRoot
    return (Join-Path $stateRoot "desired-state.json")
}

function Get-OrderedComponentList {
    return @(
        "powershell",
        "git",
        "terminal",
        "base",
        "wezterm",
        "neovim",
        "dotfiles",
        "zoxide",
        "fzf",
        "dotnet",
        "powershell-profile",
        "wsl",
        "arch-wsl"
    )
}

function Get-DefaultRunComponentList {
    return @(
        "powershell"
        # "git",
        # "terminal",
        # "base",
        # "neovim",
        # "powershell-profile"
    )
}

function Resolve-ComponentSet {
    param(
        [Parameter(Mandatory)][string[]]$CandidateComponents,
        [Parameter(Mandatory)][string]$Source,
        [string[]]$OrderedComponents = (Get-OrderedComponentList),
        [switch]$IgnoreUnknown
    )

    $unknown = @()

    foreach ($component in $CandidateComponents) {
        if ($component -notin $OrderedComponents) {
            $unknown += $component
        }
    }

    if ($unknown.Count -gt 0) {
        $message = "Unknown component(s) in ${Source}: $($unknown -join ', ')"

        if ($IgnoreUnknown) {
            Write-Warning $message
        }
        else {
            throw $message
        }
    }

    $resolved = New-Object System.Collections.Generic.List[string]

    foreach ($orderedComponent in $OrderedComponents) {
        if ($CandidateComponents -contains $orderedComponent) {
            $resolved.Add($orderedComponent)
        }
    }

    return $resolved.ToArray()
}

function Get-DesiredState {
    param(
        [string[]]$OrderedComponents = (Get-OrderedComponentList),
        [string]$Path = (Get-DesiredStatePath)
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable

        if (-not $raw) {
            return @()
        }

        if (-not $raw.ContainsKey("Components")) {
            Write-Warning "Desired state file does not contain a 'Components' property. Ignoring it."
            return @()
        }

        $components = @($raw["Components"] | ForEach-Object { [string]$_ })

        return (Resolve-ComponentSet `
            -OrderedComponents $OrderedComponents `
            -CandidateComponents $components `
            -Source "desired-state file" `
            -IgnoreUnknown)
    }
    catch {
        Write-Warning "Could not read desired state file at '$Path'. Ignoring it."
        return @()
    }
}

function Set-DesiredState {
    param(
        [Parameter(Mandatory)][string[]]$Components,
        [string]$Path = (Get-DesiredStatePath)
    )

    Set-File -Path $Path

    @{
        Components = @($Components)
    } |
        ConvertTo-Json |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Add-DesiredComponents {
    param(
        [Parameter(Mandatory)][string[]]$ComponentsToAdd,
        [string[]]$OrderedComponents = (Get-OrderedComponentList),
        [string]$Path = (Get-DesiredStatePath)
    )

    $existing = Get-DesiredState `
        -OrderedComponents $OrderedComponents `
        -Path $Path

    $combined = @($existing + $ComponentsToAdd)

    $updated = Resolve-ComponentSet `
        -OrderedComponents $OrderedComponents `
        -CandidateComponents $combined `
        -Source "merged desired state"

    Set-DesiredState -Components $updated -Path $Path

    return $updated
}

function Test-DesiredComponent {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string[]]$OrderedComponents = (Get-OrderedComponentList),
        [string]$Path = (Get-DesiredStatePath)
    )

    $desired = Get-DesiredState `
        -OrderedComponents $OrderedComponents `
        -Path $Path

    return ($Name -in $desired)
}

function Get-DesiredStateObject {
    param(
        [string[]]$OrderedComponents = (Get-OrderedComponentList),
        [string]$Path = (Get-DesiredStatePath)
    )

    $components = Get-DesiredState `
        -OrderedComponents $OrderedComponents `
        -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Components = $components
    }
}

Export-ModuleMember -Function `
    Get-XdgStateHome, `
    Get-DevenvStateRoot, `
    Get-DesiredStatePath, `
    Resolve-ComponentSet, `
    Get-DesiredState, `
    Set-DesiredState, `
    Add-DesiredComponents, `
    Test-DesiredComponent, `
    Get-DesiredStateObject
