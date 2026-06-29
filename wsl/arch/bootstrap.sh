#!/usr/bin/env bash
set -Eeuo pipefail

# Initial bootstrap for Arch running inside WSL.
# Intended to be run as root from the checked-out Windows repo or from a copied
# bootstrap directory. It then clones a separate Linux copy of the devenv repo.

# -----------------------------------------------------------------------------
# Edit these values for your environment.
# -----------------------------------------------------------------------------
DEVENV_USER="${DEVENV_USER:-the8bitbass}"
DEVENV_SHELL="${DEVENV_SHELL:-/bin/bash}"
DEVENV_CLONE_DIR="${DEVENV_CLONE_DIR:-/home/${DEVENV_USER}/dev/devenv}"

# Hard-coded on purpose: WSL should choose its own branch/state independent of
# whatever the Windows clone is doing.
DEVENV_REPO_URL="https://github.com/The8BitBass/devenv.git"

# Set to false if you do not want WSL systemd enabled.
DEVENV_ENABLE_SYSTEMD="${DEVENV_ENABLE_SYSTEMD:-true}"

# Set to true if you want Windows executables on PATH inside WSL.
DEVENV_APPEND_WINDOWS_PATH="${DEVENV_APPEND_WINDOWS_PATH:-false}"

# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

export DEVENV_USER DEVENV_SHELL DEVENV_CLONE_DIR DEVENV_ENABLE_SYSTEMD DEVENV_APPEND_WINDOWS_PATH

run_component() {
    local name="$1"
    local script="$SCRIPT_DIR/components/${name}.sh"
    [[ -f "$script" ]] || die "Component script not found: $script"
    log "Running bootstrap component: $name"
    bash "$script"
}

write_wsl_conf() {
    require_root

    local systemd_value="false"
    if [[ "$DEVENV_ENABLE_SYSTEMD" == "true" ]]; then
        systemd_value="true"
    fi

    local append_windows_path="false"
    if [[ "$DEVENV_APPEND_WINDOWS_PATH" == "true" ]]; then
        append_windows_path="true"
    fi

    log "Writing /etc/wsl.conf"
    cat > /etc/wsl.conf <<EOF_WSL_CONF
[boot]
systemd=${systemd_value}

[user]
default=${DEVENV_USER}

[interop]
enabled=true
appendWindowsPath=${append_windows_path}

[automount]
enabled=true
root=/mnt/
options=metadata,umask=22,fmask=11
EOF_WSL_CONF
}

clone_devenv_repo() {
    require_root
    user_exists || die "Cannot clone before user exists: $DEVENV_USER"

    local parent_dir
    parent_dir="$(dirname "$DEVENV_CLONE_DIR")"
    ensure_dir_for_user "$parent_dir"

    if [[ -d "$DEVENV_CLONE_DIR/.git" ]]; then
        log "Linux devenv repo already exists: $DEVENV_CLONE_DIR"
        log "Leaving its branch/worktree alone. Use 'devenv update' later when you want to pull."
    else
        log "Cloning Linux devenv repo"
        log "Repo: $DEVENV_REPO_URL"
        log "Path: $DEVENV_CLONE_DIR"
        run_as_devenv_user git clone --recurse-submodules "$DEVENV_REPO_URL" "$DEVENV_CLONE_DIR"
    fi
}

configure_github_ssh_instead_of() {
    require_root
    user_exists || die "Cannot configure git before user exists: $DEVENV_USER"

    log "Configuring GitHub SSH URL rewrite"
    run_as_devenv_user git config --global url.git@github.com:.insteadOf https://github.com/

    if [[ -d "$DEVENV_CLONE_DIR/.git" ]]; then
        run_as_devenv_user git -C "$DEVENV_CLONE_DIR" config url.git@github.com:.insteadOf https://github.com/

        if [[ -f "$DEVENV_CLONE_DIR/.gitmodules" ]]; then
            run_as_devenv_user git -C "$DEVENV_CLONE_DIR" submodule sync --recursive
            run_as_devenv_user git -C "$DEVENV_CLONE_DIR" submodule foreach --recursive \
                'git config url.git@github.com:.insteadOf https://github.com/'
        fi
    fi
}

print_ssh_setup_reminder() {
    cat <<'EOF_SSH'

SSH checkpoint: the repo is cloned, and GitHub HTTPS URLs now bend toward git@github.com:.
Before future pulls start asking awkward questions, plant your SSH key and test it with:

    ssh -T git@github.com

EOF_SSH
}

install_devenv_command() {
    require_root

    local command_path="$DEVENV_CLONE_DIR/wsl/arch/bin/devenv"
    if [[ ! -f "$command_path" ]]; then
        warn "Cannot install devenv command yet because this file does not exist in the cloned repo: $command_path"
        warn "After the repo is updated, run: sudo ln -sfn '$command_path' /usr/local/bin/devenv"
        return
    fi

    chmod +x "$command_path"
    ln -sfn "$command_path" /usr/local/bin/devenv
    log "Installed command shim: /usr/local/bin/devenv -> $command_path"
}

print_next_steps() {
    local distro_name="${WSL_DISTRO_NAME:-Arch}"

    cat <<EOF_NEXT

Bootstrap complete.

Next, from PowerShell or Windows Terminal, restart this WSL distro so /etc/wsl.conf
is applied:

    wsl --terminate ${distro_name}

Then open Arch again. It should start as '${DEVENV_USER}'. Run:

    cd ${DEVENV_CLONE_DIR}
    devenv doctor
    devenv list
    devenv dotfiles

After that, you can install components with commands like:

    devenv install neovim

If a component says it requires root, run:

    sudo devenv install neovim

EOF_NEXT
}

main() {
    require_root
    require_wsl

    run_component pacman
    run_component user
    run_component sudo
    run_component xdg
    run_component git

    write_wsl_conf
    clone_devenv_repo
    configure_github_ssh_instead_of
    print_ssh_setup_reminder
    install_devenv_command
    print_next_steps
}

main "$@"
