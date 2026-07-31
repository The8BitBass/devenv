# TODO

| Status | Priority | Item | Plan | Notes |
| --- | --- | --- | --- | --- |
| Done | High | OpenCode dotfiles | Add `env/.config/opencode/opencode.json` with the provided permissions, `autoupdate`, schema, plus initial review and plan workflows. | Validated with `opencode debug config` and `opencode debug agent`. |
| Done | High | Windows WezTerm shell tabs | Add launcher-only entries for PowerShell 7, cmd, and Git Bash, plus `LEADER+t` to show launch menu items. | Validated Lua parsing with Neovim. |
| Done | High | WSL `DEVENV_ROOT` environment | Ensure WSL profile setup exports the configured Linux devenv clone path. | Uses `DEVENV_CLONE_DIR` when available, with `$HOME/dev/devenv` fallback. |
| Deferred | Medium | Backgrounds git repo | Manage wallpapers outside this repo for now. | WezTerm should assume `XDG_DATA_HOME/devenv/wallpapers` may exist. |
| Done | Medium | WezTerm repo backgrounds | Add Git repo-root `.devenv/project.json` lookup from active pane CWD and map project + OS context to background image. | Mapping lives in `XDG_DATA_HOME/devenv/wallpapers/projects.json`; nested `.devenv` folders are ignored, Linux is supported, default images use env-derived paths, and per-image HSB is supported. |
| Done | Medium | Lightweight docs | Add docs for bootstrap differences, defaults, dotfiles, WezTerm backgrounds, and AI documentation expectations. | Future implementation final answers must include a `Documentation:` line. |
| Pending | Medium | Python install script | Add Python install/setup component script. | Scope TBD: decide versions, package managers, and Windows/WSL coverage before implementation. |
| Pending | Medium | Docker install script | Add Docker install/setup component script. | Scope TBD: decide Windows, WSL, or both before implementation. |
| Pending | Medium | MonoGame Windows component | Add Windows component for templates, desktop tooling, Android mobile support, and .NET 8/9/10 where possible. | `monogame` is already ordered but missing a script. |
| Pending | Medium | MonoGame WSL component | Add WSL component for Linux desktop development and shared tooling. | No Android-in-WSL setup. |
| Pending | Low | NeoVim 0.12.x+ config | Do compatibility fixes and selected modern API updates. | NeoVim work stays last. |
| Pending | Low | MonoGame NeoVim integration | Add LSP/completion, build/run/test, debugging, MGCB asset support, and mobile deploy commands. | Depends on MonoGame tooling and NeoVim compatibility work. |
