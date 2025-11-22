#!/usr/bin/env bash
#
# lib/init.sh - Core Bootstrap & Initialization
#
# This script serves as the single entry point for all scripts in the repository.
# It ensures that:
# 1. The repository root is correctly identified regardless of CWD.
# 2. All core libraries are sourced in the correct order.
# 3. The environment is initialized (logging, TUI, state).
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/init.sh"
#   # OR if you are in a subdirectory
#   source "$(git rev-parse --show-toplevel)/lib/init.sh"
#

set -euo pipefail

# Source guard
[ -z "${INIT_SH_LOADED:-}" ] || return 0
INIT_SH_LOADED=1

# ═════════════════════════════════════════════════════════════
# REPOSITORY DISCOVERY
# ═════════════════════════════════════════════════════════════

# Function to find repo root
find_repo_root() {
    local current_dir
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Traverse up until we find .git or reach root
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.git" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Fallback: assume this script is in lib/init.sh, so root is one level up
    # This handles cases where .git might not be present (e.g. tarball)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(dirname "$script_dir")"
}

export REPO_ROOT="$(find_repo_root)"
export LIB_DIR="${REPO_ROOT}/lib"
export SCRIPTS_DIR="${REPO_ROOT}/scripts"
export CONFIG_DIR="${REPO_ROOT}/configs"

# ═════════════════════════════════════════════════════════════
# LIBRARY LOADING
# ═════════════════════════════════════════════════════════════

# Helper to source a library if it exists
source_lib() {
    local lib_path="${LIB_DIR}/$1"
    if [[ -f "$lib_path" ]]; then
        source "$lib_path"
    else
        echo "ERROR: Could not find library: $lib_path" >&2
        exit 1
    fi
}

# Core Libraries (Order matters)
source_lib "core/logging.sh"
source_lib "core/utils.sh"
source_lib "core/errors.sh"
source_lib "core/state.sh"

# UI Libraries
# source_lib "ui/boxes.sh"  # DEPRECATED: Now using gum for all box drawing (priority 0)
source_lib "ui/tui.sh"
source_lib "ui/collapsible.sh"
source_lib "ui/progress.sh"

# Verification Libraries
source_lib "verification/health_checks.sh"
source_lib "verification/environment.sh"

# ═════════════════════════════════════════════════════════════
# INITIALIZATION
# ═════════════════════════════════════════════════════════════

# Initialize logging
init_logging

# Initialize TUI (auto-detect)
init_tui

# Export common variables
export VERBOSE_MODE=${VERBOSE_MODE:-false}

log "DEBUG" "Initialized environment. Root: $REPO_ROOT"
