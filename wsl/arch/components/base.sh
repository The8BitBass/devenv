#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Installing base development tools"

pacman -S --needed --noconfirm \
    base-devel \
    bat \
    curl \
    fd \
    fzf \
    jq \
    less \
    man-db \
    openssh \
    ripgrep \
    rsync \
    unzip \
    wget \
    which \
    zip

log "Base tools setup complete"
