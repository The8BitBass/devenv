#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

require_root
require_wsl

log "Configuring XDG directories and environment"

user_exists || die "Cannot configure XDG before user exists: $DEVENV_USER"

home_dir="$(devenv_user_home)"
for dir in \
    "$home_dir/.config" \
    "$home_dir/.local/share" \
    "$home_dir/.local/state" \
    "$home_dir/.cache"; do
    ensure_dir_for_user "$dir"
done

cat > /etc/profile.d/devenv-xdg.sh <<'EOF_PROFILE'
# devenv XDG defaults. These intentionally use $HOME at shell startup time.
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME

# Prefer the Linux clone of the devenv repo when it exists.
if [ -z "${DEVENV_ROOT:-}" ] && [ -d "$HOME/dev/devenv" ]; then
    export DEVENV_ROOT="$HOME/dev/devenv"
fi

case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) export PATH="$HOME/bin:$PATH" ;;
esac
EOF_PROFILE
chmod 0644 /etc/profile.d/devenv-xdg.sh

# Make sure non-login interactive bash shells also get the profile.d values.
bashrc="$home_dir/.bashrc"
if [[ ! -f "$bashrc" ]]; then
    install -o "$DEVENV_USER" -g "$(devenv_user_group)" -m 0644 /dev/null "$bashrc"
fi
ensure_file_contains "$bashrc" 'if [ -f /etc/profile.d/devenv-xdg.sh ]; then . /etc/profile.d/devenv-xdg.sh; fi'
chown "$DEVENV_USER:$(devenv_user_group)" "$bashrc"

log "XDG setup complete"
