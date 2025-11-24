#!/usr/bin/env bash
#
# Common utilities for Ghostty .deb installation
#
set -eo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
fi

# Ghostty version and download configuration
# To update: Change GHOSTTY_VERSION to latest from https://github.com/mkasberg/ghostty-ubuntu/releases
readonly GHOSTTY_VERSION="1.2.3"
readonly GHOSTTY_PPA_VERSION="0.ppa1"  # PPA build version (usually 0.ppa1)
readonly GHOSTTY_UBUNTU_VERSION="25.10"

# Construct filenames (maintains consistency)
readonly GHOSTTY_DEB_FILENAME="ghostty_${GHOSTTY_VERSION}-${GHOSTTY_PPA_VERSION}_amd64_${GHOSTTY_UBUNTU_VERSION}.deb"
readonly GHOSTTY_DEB_URL="https://github.com/mkasberg/ghostty-ubuntu/releases/download/${GHOSTTY_VERSION}-0-ppa1/${GHOSTTY_DEB_FILENAME}"
readonly GHOSTTY_DEB_FILE="/tmp/${GHOSTTY_DEB_FILENAME}"

# Configuration directory
readonly GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

# Check if Ghostty is installed
is_ghostty_installed() {
    command -v ghostty >/dev/null 2>&1
}

# Get installed Ghostty version
get_ghostty_version() {
    if is_ghostty_installed; then
        ghostty --version 2>/dev/null | awk '{print $2}' || echo "unknown"
    else
        echo "none"
    fi
}

# Get latest Ghostty version from GitHub releases
get_latest_ghostty_version() {
    # Query GitHub API for latest release
    if command -v curl &>/dev/null; then
        curl -s https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest \
            | grep '"tag_name"' \
            | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/' 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Check if manual Ghostty installation exists
# Returns 0 (true) if any manual/legacy installation is detected
# Returns 1 (false) if no manual installations found
has_manual_ghostty_installation() {
    # Check for manual build binaries
    [ -f "/usr/local/bin/ghostty" ] && return 0
    [ -f "$HOME/.local/bin/ghostty" ] && return 0
    [ -f "$HOME/.local/share/ghostty/bin/ghostty" ] && return 0

    # Check for build directories
    [ -d "$HOME/Apps/ghostty" ] && return 0
    [ -d "$HOME/Apps/zig" ] && return 0

    # Check for Snap installation (legacy)
    if command -v snap &>/dev/null; then
        snap list ghostty &>/dev/null 2>&1 && return 0
    fi
    [ -f "/snap/bin/ghostty" ] && return 0
    [ -d "/snap/ghostty" ] && return 0
    [ -d "$HOME/snap/ghostty" ] && return 0

    # Check for manual desktop files
    [ -f "$HOME/.local/share/applications/ghostty.desktop" ] && return 0
    [ -f "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop" ] && return 0
    [ -f "/usr/share/applications/ghostty.desktop" ] && return 0
    [ -f "/usr/share/applications/com.mitchellh.ghostty.desktop" ] && return 0

    # Nothing found
    return 1
}
