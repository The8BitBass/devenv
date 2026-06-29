#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

user_exists || die "Cannot configure zsh before user exists: $DEVENV_USER"

log "Installing zsh and Oh My Zsh"

pacman -S --needed --noconfirm \
    curl \
    git \
    zsh

zsh_path="$(command -v zsh)"
DEVENV_ROOT="${DEVENV_ROOT:-$(cd -- "$SCRIPT_DIR/../../.." && pwd)}"
home_dir="$(devenv_user_home)"
group="$(devenv_user_group)"
oh_my_zsh_dir="$home_dir/.oh-my-zsh"
zshrc="$home_dir/.zshrc"
source_zshrc="$DEVENV_ROOT/wsl/arch/config/zsh/.zshrc"

[[ -f "$source_zshrc" ]] || die "Zsh profile not found: $source_zshrc"

if [[ "$(getent passwd "$DEVENV_USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    log "Setting $DEVENV_USER shell to $zsh_path"
    chsh -s "$zsh_path" "$DEVENV_USER"
fi

if [[ -d "$oh_my_zsh_dir" ]]; then
    log "Oh My Zsh is already installed"
else
    log "Installing Oh My Zsh"
    run_as_devenv_user env \
        RUNZSH=no \
        CHSH=no \
        KEEP_ZSHRC=yes \
        sh -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh'
fi

if [[ -f "$zshrc" ]] && ! cmp -s "$source_zshrc" "$zshrc"; then
    backup_zshrc="$zshrc.pre-devenv"
    if [[ ! -f "$backup_zshrc" ]]; then
        log "Backing up existing .zshrc to $backup_zshrc"
        cp "$zshrc" "$backup_zshrc"
        chown "$DEVENV_USER:$group" "$backup_zshrc"
    fi
fi

log "Installing zsh profile: $zshrc"
install -o "$DEVENV_USER" -g "$group" -m 0644 "$source_zshrc" "$zshrc"

log "zsh setup complete"
