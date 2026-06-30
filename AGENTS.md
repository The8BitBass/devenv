# AGENTS.md

## Repo Shape
- This is a personal dev-environment bootstrap repo, not an app project; there are no package manifests, test runner configs, or CI workflows at the root.
- `windows/` is the Windows bootstrap/component system. `wsl/arch/` is a separate Arch-on-WSL bootstrap plus Linux `devenv` shim.
- `env/.config/nvim` is a git submodule from `https://github.com/The8BitBass/config.nvim.git`; keep submodule behavior in mind when cloning/updating.

## Entry Points
- Windows bootstrap is admin PowerShell: `windows/bootstrap.ps1`. README invokes it remotely with `Invoke-RestMethod` and it clones/updates to machine `DEVENV_ROOT`, sets XDG-style machine env vars, configures GitHub SSH URL rewriting, then runs `windows/setup-core.ps1` unless `-SkipLocalSetup` is passed.
- Windows local command shim is `windows/bin/devenv.ps1`: `devenv install <component...>`, `devenv update`, `devenv list`, `devenv lista`, and `devenv dotfiles`.
- Arch WSL bootstrap is `wsl/arch/bootstrap.sh`; it must run as root inside WSL and intentionally clones a separate Linux repo at `DEVENV_CLONE_DIR` (default `/home/$DEVENV_USER/dev/devenv`) instead of reusing the Windows checkout.
- WSL command shim is `wsl/arch/bin/devenv`: `devenv install <target...>`, `devenv update`, `devenv list`, `devenv dotfiles`, and `devenv doctor`; `devenv install lite` expands to `base`, `bin`, `zsh`, `neovim`, `dotfiles` in WSL-defined order.

## Component State And Ordering
- Windows component ordering and presets live in `windows/common/devenv.state.psm1`; do not infer order from filenames.
- Windows default run is `env`, `sudo`, `powershell`, `git`, `terminal`, `bin`, `powershell-profile`; `lite` expands to `neovim`, `fonts`, `wezterm`, `dotfiles`, `base`; `sapps` expands to `gimp`, `inkscape`.
- Windows desired state is stored at `$env:XDG_STATE_HOME\devenv\desired-state.json`; `devenv update` reruns only desired components and fails if that file does not exist.
- Some names in `Get-OrderedComponentList` may not have matching scripts yet; use `windows/list-components.ps1` or `devenv list` before suggesting component names.

## Gotchas
- `devenv dotfiles` deletes only target entries whose names exist as direct children of `env/.config`, then copies those entries fresh; unrelated folders under `XDG_CONFIG_HOME` should be left alone.
- Both Windows and WSL bootstrap configure repo-local `url.git@github.com:.insteadOf https://github.com/` for this repo/submodules only; do not add a global rewrite because it breaks unrelated HTTPS clones such as lazy.nvim plugins.
- WSL component scripts generally call `require_root` and `require_wsl`; run focused installs with `sudo devenv install <component>` when the script needs root.
- EditorConfig requires LF generally, but `*.ps1` files use CRLF; preserve PowerShell line endings when editing existing scripts.

## Verification
- Shell syntax check: `bash -n wsl/arch/bootstrap.sh wsl/arch/lib/common.sh wsl/arch/components/*.sh wsl/arch/bin/devenv`.
- PowerShell syntax/import smoke check, when `pwsh` is available: `pwsh -NoProfile -Command "Get-ChildItem windows -Recurse -Include *.ps1,*.psm1 | ForEach-Object { $null = [scriptblock]::Create((Get-Content -Raw -LiteralPath $_.FullName)) }"`.
