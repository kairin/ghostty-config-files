#!/usr/bin/env bash
#
# Module: Feh Common
# Purpose: Shared variables and functions for Feh tasks
#
set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
fi

# Installation constants
export FEH_REPO="https://github.com/derf/feh.git"
export FEH_BUILD_DIR="/tmp/feh-build"
export FEH_INSTALL_PREFIX="/usr/local"
export FEH_MIN_VERSION="3.10.0"

# Helper function to get feh version
get_feh_version() {
    if command_exists "feh"; then
        feh --version 2>&1 | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown"
    else
        echo "none"
    fi
}

# Helper function to check if apt version installed
is_feh_apt_installed() {
    dpkg -l feh 2>/dev/null | grep -q "^ii"
}

# Check for Snap installation
is_feh_snap_installed() {
    command -v snap &>/dev/null && snap list feh &>/dev/null 2>&1
}

# Check for any feh installation (comprehensive)
has_any_feh_installation() {
    is_feh_apt_installed && return 0
    is_feh_snap_installed && return 0
    [ -f "/usr/local/bin/feh" ] && return 0
    [ -f "$HOME/.local/bin/feh" ] && return 0
    [ -f "$HOME/.local/share/applications/feh.desktop" ] && return 0
    return 1
}
