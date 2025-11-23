#!/usr/bin/env bash
#
# Common utilities for Ghostty Snap installation
#
set -euo pipefail

# Ghostty Snap package name
readonly GHOSTTY_SNAP_NAME="ghostty"

# Configuration directory
readonly GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

# Check if Ghostty is installed via Snap
is_ghostty_installed() {
    snap list 2>/dev/null | grep -q "^${GHOSTTY_SNAP_NAME}\s"
}

# Get installed Ghostty version from Snap
get_ghostty_version() {
    if is_ghostty_installed; then
        snap list "${GHOSTTY_SNAP_NAME}" 2>/dev/null | awk 'NR==2 {print $2}'
    else
        echo "none"
    fi
}

# Get latest available Ghostty version from Snap store
get_ghostty_latest_version() {
    snap info "${GHOSTTY_SNAP_NAME}" 2>/dev/null | grep "^latest/stable:" | awk '{print $2}' || echo "unknown"
}

# Check if Ghostty update is available
is_ghostty_update_available() {
    local current_version
    local latest_version

    current_version=$(get_ghostty_version)
    latest_version=$(get_ghostty_latest_version)

    if [ "$current_version" = "none" ]; then
        return 0  # Not installed, so "update" means install
    fi

    if [ "$current_version" != "$latest_version" ] && [ "$latest_version" != "unknown" ]; then
        return 0  # Update available
    fi

    return 1  # Already latest
}

# Check if there's a manual Ghostty installation to clean up
has_manual_ghostty_installation() {
    # Check for manually built Ghostty in common locations
    if [ -f "/usr/local/bin/ghostty" ] || [ -f "$HOME/.local/bin/ghostty" ] || [ -d "$HOME/Apps/ghostty" ]; then
        return 0
    fi
    return 1
}
