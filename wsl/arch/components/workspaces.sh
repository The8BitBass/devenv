#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

user_exists || die "Cannot create workspace directories before user exists: $DEVENV_USER"

home_dir="$(devenv_user_home)"

log "Creating personal and work directories"

ensure_dir_for_user "$home_dir/personal/dev"
ensure_dir_for_user "$home_dir/work/dev"

log "Workspace directories setup complete"
