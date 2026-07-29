# WezTerm Backgrounds

## Overview

WezTerm backgrounds are selected from the active pane's current working directory.

- The resolver walks upward from the pane CWD until it finds `.git`.
- Only the Git repo root is considered.
- It reads `<repo-root>/.devenv/project.json`.
- Nested `.devenv` folders below the repo root are ignored.
- If no repo root, project metadata, wallpaper mapping, or image exists, the default background is used.

## Project Metadata

Create this in the project repo:

```json
{
    "id": "my-project"
}
```

Accepted keys are `id`, `project`, or `name`; `id` is preferred.

## Wallpaper Mapping

The mapping file is:

```text
$XDG_DATA_HOME/devenv/wallpapers/projects.json
```

Simple form:

```json
{
    "projects": {
        "my-project": {
            "windows": "my-project/windows.jpg",
            "linux": "my-project/linux.jpg",
            "wsl": "my-project/wsl.jpg",
            "default": "my-project/default.jpg"
        }
    }
}
```

Per-image metadata form:

```json
{
    "images": {
        "my-project-windows": {
            "path": "my-project/windows.jpg",
            "hsb": {
                "hue": 1.0,
                "brightness": 0.12,
                "saturation": 0.9
            }
        }
    },
    "projects": {
        "my-project": {
            "windows": "my-project-windows",
            "default": {
                "image": "my-project/default.jpg",
                "hsb": {
                    "hue": 1.0,
                    "brightness": 0.1,
                    "saturation": 1.0
                }
            }
        }
    }
}
```

Context lookup order is the current OS context, then `default`.

## Default Background

The default background uses environment-derived paths only.

Lookup candidates include:

- `$XDG_DATA_HOME/devenv/wallpapers/default.jpg`
- `$XDG_DATA_HOME/devenv/wallpapers/default.jpeg`
- `$XDG_DATA_HOME/devenv/wallpapers/default.png`
- `$XDG_CONFIG_HOME/wezterm/default.jpg`
- `$DEVENV_ROOT/env/.config/wezterm/default.jpg`

If no default image exists, WezTerm uses a solid dark color.

## Caching

- CWD to repo-root lookups are cached.
- Project metadata is cached by repo root.
- Wallpaper mapping is loaded once per WezTerm config load.
- A config reload is the simplest way to pick up mapping or HSB changes.
