[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    sudo config --enable normal
} catch {
    Write-Host "Unable to setup sudo for windows" -ForegroundColor Red
}
