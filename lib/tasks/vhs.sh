#!/usr/bin/env bash
#
# lib/tasks/vhs.sh - VHS terminal recorder installation task
#
# Purpose: Install VHS and dependencies (ffmpeg, ttyd) for demo generation
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Terminal recorder for automated documentation
# - Part of Charm Bracelet TUI ecosystem
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly VHS_MIN_VERSION="0.7.0"
readonly VHS_APT_PACKAGE="vhs"
readonly FFMPEG_MIN_VERSION="4.0"
readonly TTYD_MIN_VERSION="1.7.0"

# Export for modular installer
export VHS_MIN_VERSION
export VHS_APT_PACKAGE
export FFMPEG_MIN_VERSION
export TTYD_MIN_VERSION

# Verify VHS installation
verify_vhs_installed() {
    if command -v vhs >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f verify_vhs_installed
