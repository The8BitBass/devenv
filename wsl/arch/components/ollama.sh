#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Installing Ollama"

pacman -S --needed --noconfirm ollama

if [[ -d /run/systemd/system ]]; then
    if systemctl list-unit-files ollama.service >/dev/null 2>&1; then
        systemctl enable --now ollama.service || warn "Could not enable/start ollama.service. Check with: systemctl status ollama.service"
    else
        warn "ollama.service was not found after package installation. Run 'ollama serve' manually if needed."
    fi
else
    warn "systemd is not running. Restart WSL after bootstrap, or run 'ollama serve' manually."
fi

if command -v ollama >/dev/null 2>&1; then
    log "Ollama command available: $(command -v ollama)"
else
    warn "ollama command was not found on PATH after installation."
fi

log "No models were pulled automatically. Pull models explicitly, for example: ollama pull llama3.2"
log "Ollama setup complete"
