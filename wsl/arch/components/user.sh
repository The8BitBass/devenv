#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Configuring user: $DEVENV_USER"

if user_exists; then
    log "User already exists: $DEVENV_USER"
else
    useradd \
        --create-home \
        --user-group \
        --shell "$DEVENV_SHELL" \
        "$DEVENV_USER"
    log "Created user: $DEVENV_USER"
fi

if ! getent group wheel >/dev/null; then
    groupadd wheel
fi

usermod -aG wheel "$DEVENV_USER"

# Keep the root account recoverable after /etc/wsl.conf switches the default user.
root_status="$(passwd -S root 2>/dev/null | awk '{print $2}' || true)"
if [[ "$root_status" != "P" ]]; then
    if [[ -t 0 ]]; then
        warn "Root does not appear to have a password. Set one now so root remains recoverable."
        passwd root
    else
        warn "Root does not appear to have a password, but stdin is not interactive. Run 'passwd root' before terminating WSL."
    fi
else
    log "Root password already appears to be set"
fi

home_dir="$(devenv_user_home)"
ensure_dir_for_user "$home_dir/dev"
ensure_dir_for_user "$home_dir/bin"

log "User setup complete"
