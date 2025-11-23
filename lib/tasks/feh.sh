#!/usr/bin/env bash
#
# lib/tasks/feh.sh - Feh image viewer installation (build from source)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Build from source with ALL compile-time features enabled
# - Replaces apt version (3.10.3) with latest (3.11.0+)
# - ALL features: curl, exif, inotify, verscmp, xinerama
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-053: Idempotency (skip if already installed)
# - Build dependencies: libimlib2-dev, libcurl4-openssl-dev, etc.
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
readonly FEH_MIN_VERSION="3.11.0"
readonly FEH_REPO="https://github.com/derf/feh.git"
readonly FEH_BUILD_DIR="/tmp/feh-build"
readonly FEH_INSTALL_PREFIX="/usr/local"

# Export for modular installer
export FEH_MIN_VERSION
export FEH_REPO
export FEH_BUILD_DIR
export FEH_INSTALL_PREFIX

# Export functions
export -f verify_feh_installed
