#!/usr/bin/env bash
set -Eeuo pipefail

# Shared helpers for WSL Arch bootstrap/component scripts.

: "${DEVENV_USER:=jay}"
: "${DEVENV_CLONE_DIR:=/home/${DEVENV_USER}/dev/devenv}"
: "${DEVENV_SHELL:=/bin/bash}"

log() {
    printf '\033[1;34m[devenv]\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m[devenv:warn]\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31m[devenv:error]\033[0m %s\n' "$*" >&2
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "This script must be run as root. Re-run with sudo, or run the initial bootstrap as root."
    fi
}

is_wsl() {
    grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null
}

require_wsl() {
    if ! is_wsl; then
        die "This script is intended for WSL only."
    fi
}

user_exists() {
    id "$DEVENV_USER" >/dev/null 2>&1
}

devenv_user_home() {
    getent passwd "$DEVENV_USER" | cut -d: -f6
}

devenv_user_group() {
    id -gn "$DEVENV_USER"
}

run_as_devenv_user() {
    require_root
    user_exists || die "User does not exist: $DEVENV_USER"
    sudo -Hiu "$DEVENV_USER" "$@"
}

ensure_dir_for_user() {
    require_root
    local path="$1"
    local group
    group="$(devenv_user_group)"
    install -d -o "$DEVENV_USER" -g "$group" "$path"
}

ensure_file_contains() {
    local file="$1"
    local line="$2"

    touch "$file"
    if ! grep -Fxq "$line" "$file"; then
        printf '%s\n' "$line" >> "$file"
    fi
}
