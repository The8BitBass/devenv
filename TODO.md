# TODO

| Status | Priority | Item | Plan | Notes |
| --- | --- | --- | --- | --- |
| Done | High | OpenCode dotfiles | Add `env/.config/opencode/opencode.json` with the provided permissions, `autoupdate`, schema, plus initial review and plan workflows. | Validated with `opencode debug config` and `opencode debug agent`. |
| Done | High | Windows WezTerm shell tabs | Add launcher-only entries for PowerShell 7, cmd, and Git Bash, plus `LEADER+t` to show launch menu items. | Validated Lua parsing with Neovim. |
| Pending | Medium | Backgrounds git repo | Add component-managed clone/update flow under XDG data, likely `XDG_DATA_HOME/devenv/backgrounds`. | Repo URL is intentionally TBD. |
| Pending | Medium | WezTerm repo backgrounds | Add `.devenv/project.json` project metadata lookup and map project + OS context to background image. | Uses Windows/WSL context from existing repo picker. |
| Pending | Medium | MonoGame Windows component | Add Windows component for templates, desktop tooling, Android mobile support, and .NET 8/9/10 where possible. | `monogame` is already ordered but missing a script. |
| Pending | Medium | MonoGame WSL component | Add WSL component for Linux desktop development and shared tooling. | No Android-in-WSL setup. |
| Pending | Low | NeoVim 0.12.x+ config | Do compatibility fixes and selected modern API updates. | NeoVim work stays last. |
| Pending | Low | MonoGame NeoVim integration | Add LSP/completion, build/run/test, debugging, MGCB asset support, and mobile deploy commands. | Depends on MonoGame tooling and NeoVim compatibility work. |
