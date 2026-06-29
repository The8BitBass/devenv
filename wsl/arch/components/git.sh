#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Installing and configuring git"

pacman -S --needed --noconfirm git openssh

user_exists || die "Cannot configure git before user exists: $DEVENV_USER"

# Keep this intentionally minimal. Personal identity belongs in your dotfiles or
# a later git component, not in the bootstrap.
run_as_devenv_user git config --global pull.ff only

log "Git setup complete"
