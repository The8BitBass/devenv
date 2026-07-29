# Bootstrap And Components

## Windows Bootstrap

- Entry point: `windows/bootstrap.ps1`, run as administrator.
- Default repo root: drive root plus `devenv`, for example `C:\devenv`.
- Sets machine environment variables: `DEVENV_ROOT`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `HOME`.
- Configures GitHub HTTPS-to-SSH rewriting only inside this repo and its submodules.
- Runs `windows/setup-core.ps1` unless `-SkipLocalSetup` is passed.

## WSL Bootstrap

- Entry point: `wsl/arch/bootstrap.sh`, run as root inside WSL.
- Default Linux repo root: `/home/$DEVENV_USER/dev/devenv`.
- The Linux repo is intentionally separate from the Windows checkout.
- Writes `/etc/profile.d/devenv-xdg.sh` for XDG defaults, `PATH`, and `DEVENV_ROOT`.
- `DEVENV_ROOT` uses the configured `DEVENV_CLONE_DIR` when that clone exists, with `$HOME/dev/devenv` as fallback.
- Installs `/usr/local/bin/devenv` as a symlink to the Linux repo shim.

## Dotfile Flow

- Source dotfiles live under `env/.config` in the devenv repo.
- Windows `devenv dotfiles` copies direct children of `env/.config` into `XDG_CONFIG_HOME`.
- WSL `devenv dotfiles` copies direct children of `env/.config` into the target user's `.config` or `XDG_CONFIG_HOME`.
- Managed target entries with the same names as `env/.config` children are deleted before copying.
- Unrelated directories under the target config home should be left alone.
- Some configs, especially NeoVim, may need `DEVENV_ROOT` because their source lives in the repo while installed dotfiles live elsewhere.

## Component Conventions

- Windows components are PowerShell scripts in `windows/components`.
- Windows component order and presets are defined in `windows/common/devenv.state.psm1`.
- WSL components are shell scripts in `wsl/arch/components`.
- WSL component order and presets are defined in `wsl/arch/bin/devenv`.
- Prefer small idempotent components that can be safely rerun.
- Root-requiring WSL components should call `require_root` and `require_wsl`.
- Verify shell scripts with `bash -n wsl/arch/bootstrap.sh wsl/arch/lib/common.sh wsl/arch/components/*.sh wsl/arch/bin/devenv`.
- Verify PowerShell syntax with the command in `AGENTS.md` when `pwsh` is available.
