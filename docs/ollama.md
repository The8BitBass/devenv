# Ollama

## Components

- Windows component: `ollama`.
- WSL component: `ollama`.
- Install directly with `devenv install ollama` on Windows or `sudo devenv install ollama` in WSL.

## Windows Behavior

- Installs or updates `Ollama.Ollama` with winget.
- Does not pull any models automatically.
- If `ollama.exe` is not immediately on `PATH`, restart the terminal after installation.

## WSL Behavior

- Installs the Arch `ollama` package with pacman.
- If systemd is running, enables and starts `ollama.service`.
- If systemd is not running, install still succeeds and Ollama can be started manually with `ollama serve`.
- Does not pull any models automatically.

## Model Setup

Pull models explicitly after install. Example:

```sh
ollama pull llama3.2
```

No default model is configured by this repo yet.
