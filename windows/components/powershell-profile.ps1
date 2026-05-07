[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "..\common\devenv.psm1") -Force

$pwshAllUsersAllHosts = Get-PwshProfilePath -ProfileName "AllUsersAllHosts"
Set-File -Path $pwshAllUsersAllHosts

$profileContent = @'
function prompt {
    $p = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ""
    if ($p.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $p.ProviderPath -Replace "\\", "/"
        $osc7 = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}${ansi_escape}\"
    }
    "${osc7}PS $p$('>' * ($nestedPromptLevel + 1)) ";
}
'@

Write-Step "Updating PowerShell 7 AllUsersAllHosts profile"
Set-ManagedBlockInFile `
    -Path $pwshAllUsersAllHosts `
    -Tag "DEVENV PROMPT" `
    -Content $profileContent

Write-Step "powershell-profile complete"

