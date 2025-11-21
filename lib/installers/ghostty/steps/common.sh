#!/usr/bin/env bash
#
# Module: Ghostty Common
# Purpose: Shared variables and functions for Ghostty tasks
#
set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
fi

# Installation constants
export GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"
export GHOSTTY_BUILD_DIR="/tmp/ghostty-build"
export GHOSTTY_INSTALL_DIR="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}"
export ZIG_MIN_VERSION="0.15.2"
export ZIG_DOWNLOAD_URL="https://ziglang.org/download/${ZIG_MIN_VERSION}/zig-x86_64-linux-${ZIG_MIN_VERSION}.tar.xz"
export ZIG_INSTALL_DIR="$HOME/Apps/zig"
export ZIG_LINK_NAME="zig"

# Add Zig to PATH
if [ -d "$ZIG_INSTALL_DIR" ]; then
    export PATH="$ZIG_INSTALL_DIR:$PATH"
fi

# Helper function to get Zig version
get_zig_version() {
    if command_exists "zig"; then
        zig version 2>&1 | head -n 1
    else
        echo "none"
    fi
}
