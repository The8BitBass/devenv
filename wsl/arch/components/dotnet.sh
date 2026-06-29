#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Installing .NET SDK"

pacman -S --needed --noconfirm \
    dotnet-sdk \
    aspnet-runtime

log ".NET setup complete"
