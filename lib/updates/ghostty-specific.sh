#!/usr/bin/env bash
# lib/updates/ghostty-specific.sh - Ghostty-specific update operations (Orchestrator)
# Sources build and install modules for complete Ghostty update workflow
#
# This file acts as an orchestrator, sourcing modular components:
# - lib/updates/ghostty/build.sh   - Build operations
# - lib/updates/ghostty/install.sh - Installation operations

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_GHOSTTY_SPECIFIC_SOURCED:-}" ]] && return 0
readonly _GHOSTTY_SPECIFIC_SOURCED=1

# Determine script directory for relative sourcing
SCRIPT_DIR="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# Source modular components
# shellcheck source=lib/updates/ghostty/build.sh
if [[ -f "${SCRIPT_DIR}/ghostty/build.sh" ]]; then
    source "${SCRIPT_DIR}/ghostty/build.sh"
fi

# shellcheck source=lib/updates/ghostty/install.sh
if [[ -f "${SCRIPT_DIR}/ghostty/install.sh" ]]; then
    source "${SCRIPT_DIR}/ghostty/install.sh"
fi

#######################################
# Get Ghostty version from installed binary
# Outputs:
#   Version string or empty if not installed
# Returns:
#   0 always
#######################################
get_ghostty_version() {
    if command -v ghostty &> /dev/null; then
        local version_output
        version_output=$(ghostty --version 2>/dev/null | head -n 1 | awk '{print $NF}')
        if [[ -n "$version_output" ]]; then
            echo "$version_output"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

#######################################
# Get step status message with emoji
# Arguments:
#   $1 - Step name
#   $2 - Status (start|progress|success|warning|error)
# Outputs:
#   Formatted status message
#######################################
get_step_status() {
    local step="$1"
    local status="$2"
    case "$status" in
        "start") echo "Starting: $step" ;;
        "progress") echo "In progress: $step" ;;
        "success") echo "Completed: $step" ;;
        "warning") echo "Warning in: $step" ;;
        "error") echo "Failed: $step" ;;
        *) echo "$step: $status" ;;
    esac
}

#######################################
# Get process details for logging
# Arguments:
#   $1 - Process name
#   $2 - Detail message
# Outputs:
#   Formatted process detail
#######################################
get_process_details() {
    local process="$1"
    local detail="$2"
    echo "   - $process: $detail"
}

#######################################
# Print Ghostty update summary
# Arguments:
#   $1 - Old version
#   $2 - New version
#   $3 - Config updated flag (true/false)
#   $4 - App updated flag (true/false)
#######################################
print_update_summary() {
    local old_version="$1"
    local new_version="$2"
    local config_updated="$3"
    local app_updated="$4"

    echo "======================================="
    echo "         Ghostty Update Summary"
    echo "======================================="

    if [[ "$config_updated" == "true" ]]; then
        echo "Ghostty config: Updated"
    else
        echo "Ghostty config: Already up to date"
    fi

    if [[ "$app_updated" == "true" ]]; then
        echo "Ghostty app: Updated to version $new_version"
    elif [[ -n "$new_version" ]]; then
        echo "Ghostty app: Already at version $new_version"
    else
        echo "Ghostty app: Not found or not updated"
    fi

    if [[ -z "$old_version" ]] && [[ -z "$new_version" ]]; then
        echo "Overall Status: Failed (Ghostty not found)"
    elif [[ "$config_updated" == "true" ]] || [[ "$app_updated" == "true" ]]; then
        echo "Overall Status: Success (Updates applied)"
    else
        echo "Overall Status: Already up to date"
    fi
    echo "======================================="
}

# Export orchestrator functions
export -f get_ghostty_version get_step_status get_process_details
export -f print_update_summary

# Re-export functions from sourced modules for backward compatibility
# Build functions (from ghostty/build.sh)
export -f verify_critical_build_tools print_dependency_instructions 2>/dev/null || true
export -f verify_gtk4_libadwaita build_ghostty 2>/dev/null || true
export -f verify_build_output clean_build_artifacts 2>/dev/null || true

# Install functions (from ghostty/install.sh)
export -f kill_ghostty_processes install_ghostty 2>/dev/null || true
export -f verify_ghostty_installation update_desktop_database 2>/dev/null || true
export -f backup_ghostty_config restore_ghostty_config 2>/dev/null || true
export -f test_ghostty_config attempt_config_fix 2>/dev/null || true
