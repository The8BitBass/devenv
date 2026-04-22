[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\common\devenv.winget.psm1") -Force

$packageId = "Microsoft.PowerShell"

Write-Step "Ensuring PowerShell 7"

try {
    Set-WingetPackage -Id $packageId

    $pwshPath = Get-PwshPath
    Write-Step "powershell complete"
    Write-Host "pwsh: $pwshPath" -ForegroundColor Green
}
catch {
    Write-Warning "PowerShell 7 install/update via winget failed."
    Write-Warning "This can happen when PowerShell is updating itself while in use."
    Write-Warning "Manual uninstall and reinstall is probably required."
    Write-Warning "Original error: $($_.Exception.Message)"

    try {
        $pwshPath = Get-PwshPath
        Write-Warning "PowerShell 7 still appears to exist at: $pwshPath"
        $global:LASTEXITCODE = 0
    }
    catch {
        throw "PowerShell 7 could not be found after the failed install/update attempt."
    }

    Write-Step "powershell component finished with warnings"
}
