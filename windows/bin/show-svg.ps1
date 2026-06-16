#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    # Examples: auto, 80%, 100, 800px
    [string] $Width = "auto",

    # Examples: auto, 50%, 40, 600px
    [string] $Height = "auto",

    # By default, crop the output to the drawing.
    # Use this switch to render the full SVG page instead.
    [switch] $UsePage,

    # Useful for black drawings when using a dark terminal theme.
    [switch] $WhiteBackground
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Find-Executable {
    param(
        [Parameter(Mandatory)]
        [string[]] $Names,

        [string[]] $FallbackPaths = @()
    )

    foreach ($name in $Names) {
        $command = Get-Command $name `
            -CommandType Application `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -ne $command) {
            return $command.Source
        }
    }

    foreach ($fallbackPath in $FallbackPaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($fallbackPath) -and
            (Test-Path -LiteralPath $fallbackPath -PathType Leaf)
        ) {
            return $fallbackPath
        }
    }

    throw "Could not find any of these commands: $($Names -join ', ')"
}

$resolvedPath = Resolve-Path -LiteralPath $Path
$svgPath = $resolvedPath.Path

if ([System.IO.Path]::GetExtension($svgPath) -ine ".svg") {
    throw "Expected an SVG file: $svgPath"
}

$inkscapePath = Find-Executable `
    -Names @("inkscape", "inkscape.exe", "inkscape.com") `
    -FallbackPaths @(
        (Join-Path $env:ProgramFiles "Inkscape\bin\inkscape.com")
    )

$weztermFallbacks = @(
    (Join-Path $env:ProgramFiles "WezTerm\wezterm.exe")
)

if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $weztermFallbacks += Join-Path `
        $env:LOCALAPPDATA `
        "Programs\WezTerm\wezterm.exe"
}

$weztermPath = Find-Executable `
    -Names @("wezterm", "wezterm.exe") `
    -FallbackPaths $weztermFallbacks

$tempPng = Join-Path `
    ([System.IO.Path]::GetTempPath()) `
    ("wezterm-svg-{0}.png" -f [guid]::NewGuid())

try {
    $inkscapeArgs = @(
        $svgPath
        "--export-type=png"
        "--export-filename=$tempPng"
        "--export-width=2560"
    )

    if ($UsePage) {
        $inkscapeArgs += "--export-area-page"
    }
    else {
        $inkscapeArgs += "--export-area-drawing"
    }

    if ($WhiteBackground) {
        $inkscapeArgs += "--export-background=white"
    }

    & $inkscapePath @inkscapeArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Inkscape failed with exit code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $tempPng -PathType Leaf)) {
        throw "Inkscape did not produce the expected PNG: $tempPng"
    }

    & $weztermPath imgcat `
        --width $Width `
        --height $Height `
        $tempPng

    if ($LASTEXITCODE -ne 0) {
        throw "wezterm imgcat failed with exit code $LASTEXITCODE."
    }
}
finally {
    Remove-Item -LiteralPath $tempPng -Force -ErrorAction SilentlyContinue
}
