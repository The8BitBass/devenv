# Defaults And Assumptions

## Environment Defaults

- Windows `DEVENV_ROOT`: drive root plus `devenv`.
- Windows `XDG_CONFIG_HOME`: drive root plus `.config`.
- Windows `XDG_DATA_HOME`: drive root plus `.local\share`.
- Windows `XDG_STATE_HOME`: drive root plus `.local\state`.
- Windows `HOME`: drive root plus `Home`.
- WSL `DEVENV_USER`: `the8bitbass` unless overridden.
- WSL `DEVENV_CLONE_DIR`: `/home/$DEVENV_USER/dev/devenv` unless overridden.
- WSL XDG defaults: `$HOME/.config`, `$HOME/.local/share`, `$HOME/.local/state`, `$HOME/.cache`.

## Install Defaults

- Windows default run: `env`, `sudo`, `powershell`, `git`, `terminal`, `bin`, `powershell-profile`.
- Windows `lite`: `neovim`, `fonts`, `wezterm`, `dotfiles`, `base`.
- Windows `sapps`: `gimp`, `inkscape`.
- WSL `lite`: `base`, `bin`, `zsh`, `neovim`, `dotfiles`.
- Windows `.NET` currently installs SDKs `9`, `8`, `7`, and `6`.
- WSL `.NET` uses Arch packages `dotnet-sdk` and `aspnet-runtime`.
- Windows WezTerm installs `wez.wezterm.nightly`.
- Windows Ollama installs winget package `Ollama.Ollama`.
- WSL Ollama installs Arch package `ollama` and starts `ollama.service` when systemd is running.
- Ollama components do not pull models automatically.

## Assumptions

- The NeoVim config source may need to read files from `DEVENV_ROOT`, not only from copied dotfiles.
- Wallpapers are managed outside this repo for now.
- Wallpaper files and their mapping may exist under `XDG_DATA_HOME/devenv/wallpapers`.
- `env/.config/nvim` is a git submodule; keep submodule behavior in mind when cloning or updating.
