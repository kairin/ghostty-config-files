#!/usr/bin/env bash
#
# Common functions for fastfetch installation
# Purpose: Shared utilities for fastfetch installation steps
#

set -eo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
fi

# Installation constants
export FASTFETCH_MIN_VERSION="2.0.0"

# Helper function to get fastfetch version
get_fastfetch_version() {
    if command_exists "fastfetch"; then
        fastfetch --version 2>&1 | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown"
    else
        echo "none"
    fi
}

# Helper function to check if apt version installed
is_fastfetch_apt_installed() {
    dpkg -l fastfetch 2>/dev/null | grep -q "^ii"
}
