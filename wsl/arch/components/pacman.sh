#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Configuring pacman"

# Make pacman output nicer and parallel downloads faster without duplicating lines.
if grep -q '^#Color' /etc/pacman.conf; then
    sed -i 's/^#Color/Color/' /etc/pacman.conf
elif ! grep -q '^Color' /etc/pacman.conf; then
    sed -i '/^\[options\]/a Color' /etc/pacman.conf
fi

if grep -q '^#ParallelDownloads' /etc/pacman.conf; then
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
elif grep -q '^ParallelDownloads' /etc/pacman.conf; then
    sed -i 's/^ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
else
    sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
fi

# Some WSL Arch rootfs builds need their local pacman keyring created before
# package installation will work reliably.
if [[ ! -f /etc/pacman.d/gnupg/pubring.gpg ]]; then
    log "Initializing pacman keyring"
    pacman-key --init
    pacman-key --populate archlinux
fi

log "Updating base system and installing bootstrap package set"
pacman -Syu --needed --noconfirm \
    archlinux-keyring \
    base \
    base-devel \
    ca-certificates \
    curl \
    gnupg \
    pacman-contrib \
    reflector \
    rsync \
    unzip \
    which

log "Pacman setup complete"
