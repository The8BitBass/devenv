#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Installing Neovim and Linux C build tools"

if [[ -L /usr/local/bin/nvim ]] && [[ "$(readlink /usr/local/bin/nvim)" == /opt/nvim/bin/nvim ]]; then
    rm -f /usr/local/bin/nvim
fi

rm -f /opt/nvim
rm -rf /opt/nvim-linux-x86_64-0.11.7 /opt/nvim-linux-arm64-0.11.7

pacman -S --needed --noconfirm \
    neovim \
    clang \
    cmake \
    make \
    tree-sitter-cli \
    unzip

log "Neovim setup complete"
