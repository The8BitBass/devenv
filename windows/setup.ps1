[System.IO.Directory]::CreateDirectory("C:\.config")
[System.IO.Directory]::CreateDirectory("C:\.local")
[System.IO.Directory]::CreateDirectory("C:\.local\share")
[System.IO.Directory]::CreateDirectory("C:\.local\state")
[System.IO.Directory]::CreateDirectory("C:\Home")
[System.IO.Directory]::CreateDirectory("C:\Home\personal")

winget install microsoft.powershell

winget install --id Microsoft.WindowsTerminal -e
# winget install --id wez.wezterm.nightly -e

winget install --id Git.Git -e --source winget
Write-Host "Remember to run git config --global user.name and git config --global user.email" -ForegroundColor DarkGreen -BackgroundColor White

function Set-EnvVar {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

        [System.Environment]::SetEnvironmentVariable($Name, $Value, "Machine")
        Set-Item env:$Name -Value $Value  # Also update current session
}

Set-EnvVar -Name "XDG_CONFIG_HOME" -Value "C:/.config"
Set-EnvVar -Name "XDG_DATA_HOME" -Value "C:/.local/share"
Set-EnvVar -Name "XDG_STATE_HOME" -Value "C:/.local/state"
Set-EnvVar -Name "HOME" -Value "C:/Home"

# install chocolatey because getting zig through winget is broken for 0.14.0
# winget install --id chocolatey.chocolatey --source winget
# $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
# choco install zig
# winget uninstall --id chocolatey.chocolatey

winget install -e --id zig.zig

winget install BurntSushi.ripgrep.MSVC

winget install Neovim.Neovim -v 0.11.7

# get configs
git clone https://github.com/The8BitBass/config.nvim.git "${env:XDG_CONFIG_HOME}\nvim"
git clone https://github.com/The8BitBass/config.wez.git "${env:XDG_CONFIG_HOME}\wezterm"

# install DotNet versions
winget install Microsoft.DotNet.SDK.9
winget install Microsoft.DotNet.SDK.8
winget install Microsoft.DotNet.SDK.7
winget install Microsoft.DotNet.SDK.6

