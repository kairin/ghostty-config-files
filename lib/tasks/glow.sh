#!/usr/bin/env bash
#
# lib/tasks/glow.sh - Glow markdown viewer installation task
#
# Purpose: Install glow markdown viewer from Charm repository
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - CLI tool for beautiful markdown display
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
readonly GLOW_MIN_VERSION="2.0.0"
readonly GLOW_APT_PACKAGE="glow"

# Export for modular installer
export GLOW_MIN_VERSION
export GLOW_APT_PACKAGE

# Verify glow installation
verify_glow_installed() {
    if command -v glow >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f verify_glow_installed
