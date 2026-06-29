#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

user_exists || die "Cannot install bin scripts before user exists: $DEVENV_USER"

DEVENV_ROOT="${DEVENV_ROOT:-$(cd -- "$SCRIPT_DIR/../../.." && pwd)}"
source_bin="$DEVENV_ROOT/wsl/arch/bin"
home_dir="$(devenv_user_home)"
target_bin="$home_dir/bin"
group="$(devenv_user_group)"

[[ -d "$source_bin" ]] || die "Source bin directory not found: $source_bin"

log "Installing WSL bin scripts"
log "Source: $source_bin"
log "Target: $target_bin"

ensure_dir_for_user "$target_bin"

for source_file in "$source_bin"/*; do
    [[ -f "$source_file" ]] || continue

    target_file="$target_bin/$(basename "$source_file")"
    install -o "$DEVENV_USER" -g "$group" -m 0755 "$source_file" "$target_file"
done

log "WSL bin setup complete"
