Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =============================================================================
# Desired state
# =============================================================================

$Force = $false

# If DEVENV_ROOT is not set, this script assumes it lives at:
#   <repo-root>\windows\components\fonts.ps1
$FontsRootRelativePath = "assets\fonts"

$Fonts = @(
    @{
        DisplayName  = "Cascadia Mono NF"
        RelativePath = "cascadia-code\CascadiaMonoNF.ttf"
        FontType     = "TrueType"
    },
    @{
        DisplayName  = "Cascadia Mono"
        RelativePath = "cascadia-code\CascadiaMono.ttf"
        FontType     = "TrueType"
    },
    @{
        DisplayName  = "DaddyTimeMono Nerd Font Mono"
        RelativePath = "nerd-fonts\DaddyTimeMono\DaddyTimeMonoNerdFontMono-Regular.ttf"
        FontType     = "TrueType"
    },
    @{
        DisplayName  = "DepartureMono Nerd Font Mono"
        RelativePath = "nerd-fonts\DepartureMono\DepartureMonoNerdFontMono-Regular.otf"
        FontType     = "OpenType"
    },
    @{
        DisplayName  = "BigBlueTermPlus Nerd Font Mono"
        RelativePath = "nerd-fonts\BigBlueTerminal\BigBlueTermPlusNerdFontMono-Regular.ttf"
        FontType     = "TrueType"
    },
    @{
        DisplayName  = "OpenDyslexicM Nerd Font Mono"
        RelativePath = "nerd-fonts\OpenDyslexic\OpenDyslexicMNerdFontMono-Regular.otf"
        FontType     = "OpenType"
    }
)

# =============================================================================
# Helpers
# =============================================================================

function Get-DevenvRoot {
    if ($env:DEVENV_ROOT) {
        return $env:DEVENV_ROOT
    }

    $componentsDirectory = $PSScriptRoot
    $windowsDirectory = Split-Path -Parent $componentsDirectory
    $repoRoot = Split-Path -Parent $windowsDirectory

    return $repoRoot
}

function Add-FontRefreshType {
    if ("FontRefresh" -as [type]) {
        return
    }

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class FontRefresh
{
    [DllImport("gdi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern int AddFontResourceW(string lpszFilename);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult
    );
}
"@
}

function Publish-FontChange {
    param(
        [Parameter(Mandatory)]
        [string]$FontPath
    )

    Add-FontRefreshType

    [void][FontRefresh]::AddFontResourceW($FontPath)

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_FONTCHANGE = 0x001D
    $SMTO_ABORTIFHUNG = 0x0002

    $result = [UIntPtr]::Zero

    [void][FontRefresh]::SendMessageTimeout(
        $HWND_BROADCAST,
        $WM_FONTCHANGE,
        [UIntPtr]::Zero,
        $null,
        $SMTO_ABORTIFHUNG,
        1000,
        [ref]$result
    )
}

function Test-SameFileHash {
    param(
        [Parameter(Mandatory)]
        [string]$PathA,

        [Parameter(Mandatory)]
        [string]$PathB
    )

    if (-not (Test-Path -LiteralPath $PathA)) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $PathB)) {
        return $false
    }

    $hashA = (Get-FileHash -LiteralPath $PathA -Algorithm SHA256).Hash
    $hashB = (Get-FileHash -LiteralPath $PathB -Algorithm SHA256).Hash

    return $hashA -eq $hashB
}

function Install-UserFont {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Font,

        [Parameter(Mandatory)]
        [string]$FontsRoot,

        [Parameter(Mandatory)]
        [bool]$Force
    )

    $sourcePath = Join-Path $FontsRoot $Font.RelativePath

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Font file was not found: $sourcePath"
    }

    $fontDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Path $fontDirectory -Force | Out-Null

    $fileName = Split-Path -Leaf $sourcePath
    $targetPath = Join-Path $fontDirectory $fileName

    $alreadyInstalled = Test-Path -LiteralPath $targetPath
    $sameFile = $alreadyInstalled -and (Test-SameFileHash -PathA $sourcePath -PathB $targetPath)

    if ($sameFile -and -not $Force) {
        Write-Host "Already installed: $($Font.DisplayName)"
    } else {
        Copy-Item `
            -LiteralPath $sourcePath `
            -Destination $targetPath `
            -Force

        Write-Host "Installed: $($Font.DisplayName)"
    }

    $registryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    New-Item -Path $registryPath -Force | Out-Null

    $registryName = "$($Font.DisplayName) ($($Font.FontType))"

    New-ItemProperty `
        -Path $registryPath `
        -Name $registryName `
        -Value $targetPath `
        -PropertyType String `
        -Force |
        Out-Null

    Publish-FontChange -FontPath $targetPath
}

# =============================================================================
# Main
# =============================================================================

$devenvRoot = Get-DevenvRoot
$fontsRoot = Join-Path $devenvRoot $FontsRootRelativePath

if (-not (Test-Path -LiteralPath $fontsRoot)) {
    throw "Fonts root does not exist: $fontsRoot"
}

Write-Host "Installing fonts from: $fontsRoot"
Write-Host ""

foreach ($font in $Fonts) {
    Install-UserFont `
        -Font $font `
        -FontsRoot $fontsRoot `
        -Force $Force
}

Write-Host ""
Write-Host "Font installation complete."
Write-Host "Restart WezTerm, Neovim, and any other open terminals/editors to ensure they pick up the fonts."
