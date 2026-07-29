# AI Change Checklist

Use this checklist for OpenCode, LLM, or AI-assisted changes.

## Required Final Answer Section

Every implementation final answer should include a `Documentation` line.

Use one of these forms:

- `Documentation: updated docs/...`
- `Documentation: not needed; change only affected internal implementation with no behavior, command, env var, default, or file-contract change.`
- `Documentation: still needed; added/left TODO for ...`

## When To Update Docs

Review docs when a change affects:

- Bootstrap behavior or environment variables.
- Windows vs WSL/Linux differences.
- Component names, ordering, presets, or verification.
- Dotfile source, target, copy, or delete behavior.
- Defaults such as installed SDK/tool versions.
- Optional setup needed to make a feature work.
- File contracts like `.devenv/project.json` or wallpaper mapping JSON.
- Keybindings, command shims, or user-facing commands.

## Keep Docs Lightweight

- Prefer short focused pages over long prose.
- Document contracts, defaults, assumptions, and setup steps.
- Avoid duplicating full script logic unless it helps explain a gotcha.
