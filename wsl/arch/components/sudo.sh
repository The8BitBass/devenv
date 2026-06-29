#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Configuring sudo"

pacman -S --needed --noconfirm sudo

user_exists || die "Cannot configure sudo before user exists: $DEVENV_USER"
usermod -aG wheel "$DEVENV_USER"

sudoers_file="/etc/sudoers.d/10-devenv-${DEVENV_USER}"
cat > "$sudoers_file" <<EOF_SUDOERS
${DEVENV_USER} ALL=(ALL:ALL) NOPASSWD: ALL
EOF_SUDOERS
chmod 0440 "$sudoers_file"
visudo -cf "$sudoers_file" >/dev/null

log "Sudo setup complete"
