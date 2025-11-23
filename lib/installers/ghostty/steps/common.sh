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
readonly GHOSTTY_VERSION="1.2.3"
readonly GHOSTTY_UBUNTU_VERSION="25.10"
readonly GHOSTTY_DEB_URL="https://github.com/mkasberg/ghostty-ubuntu/releases/download/${GHOSTTY_VERSION}-0-ppa1/ghostty_${GHOSTTY_VERSION}-0.ppa1_amd64_${GHOSTTY_UBUNTU_VERSION}.deb"
readonly GHOSTTY_DEB_FILE="/tmp/ghostty_${GHOSTTY_VERSION}.deb"

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
