#!/usr/bin/env bash
#
# Ghostty Uninstallation Manager (Snap Version)
# Purpose: Complete removal of Ghostty Snap installation
# Exit Codes: 0=success, 1=failure, 2=not_installed
#
# Architecture: Modular uninstallation with TUI integration

set -euo pipefail

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

# Source common functions
source "${STEPS_DIR}/common.sh"

# Uninstallation steps
uninstall_ghostty() {
    local removed_items=0
    local task_id="uninstall-ghostty"

    register_task "$task_id" "Uninstalling Ghostty"
    start_task "$task_id"

    log "INFO" "Starting Ghostty uninstallation..."

    # Check if Ghostty Snap is installed
    if ! is_ghostty_installed; then
        log "WARNING" "Ghostty Snap is not installed"

        # Still check for manual installations to clean up
        if has_manual_ghostty_installation; then
            log "INFO" "Found manual installations to clean up"
        else
            log "INFO" "No Ghostty installations found"
            skip_task "$task_id" "not installed"
            exit 2
        fi
    fi

    # Remove Snap package
    if is_ghostty_installed; then
        log "INFO" "Removing Ghostty Snap package..."
        if sudo snap remove "${GHOSTTY_SNAP_NAME}" 2>&1 | tee -a "$(get_log_file)"; then
            log "SUCCESS" "Ghostty Snap package removed"
            ((removed_items++))
        else
            log "ERROR" "Failed to remove Ghostty Snap package"
            fail_task "$task_id" "snap remove failed"
            exit 1
        fi
    fi

    # Clean up any remaining manual installations
    if has_manual_ghostty_installation; then
        log "INFO" "Cleaning up manual installation remnants..."

        # Remove binary from /usr/local/bin
        if [ -f "/usr/local/bin/ghostty" ]; then
            log "INFO" "Removing /usr/local/bin/ghostty"
            sudo rm -f "/usr/local/bin/ghostty" 2>/dev/null && ((removed_items++))
        fi

        # Remove binary from ~/.local/bin
        if [ -f "$HOME/.local/bin/ghostty" ]; then
            log "INFO" "Removing $HOME/.local/bin/ghostty"
            rm -f "$HOME/.local/bin/ghostty" 2>/dev/null && ((removed_items++))
        fi

        # Remove build directory
        if [ -d "$HOME/Apps/ghostty" ]; then
            log "INFO" "Removing $HOME/Apps/ghostty"
            rm -rf "$HOME/Apps/ghostty" 2>/dev/null && ((removed_items++))
        fi

        # Remove Zig compiler
        if [ -d "$HOME/Apps/zig" ]; then
            log "INFO" "Removing Zig compiler (no longer needed)"
            rm -rf "$HOME/Apps/zig" 2>/dev/null && ((removed_items++))
        fi
    fi

    # Note: Configuration files in ~/.config/ghostty are NOT removed
    # Users may want to preserve their settings for reinstallation
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        log "INFO" "Configuration files preserved in $GHOSTTY_CONFIG_DIR"
        log "INFO" "To remove configs: rm -rf $GHOSTTY_CONFIG_DIR"
    fi

    # Summary
    if [ $removed_items -gt 0 ]; then
        log "SUCCESS" "Ghostty uninstalled successfully ($removed_items items removed)"
        complete_task "$task_id"
        exit 0
    else
        log "WARNING" "No Ghostty installation found to remove"
        skip_task "$task_id" "nothing to remove"
        exit 2
    fi
}

# Main execution
main() {
    # Run environment checks
    run_environment_checks || exit 1

    # Perform uninstallation
    uninstall_ghostty
}

main "$@"
