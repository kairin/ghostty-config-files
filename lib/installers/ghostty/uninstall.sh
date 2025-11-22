#!/usr/bin/env bash
#
# Ghostty Uninstallation Manager
# Purpose: Complete removal of Ghostty installation (binary, config, desktop entry)
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

    # Check if Ghostty is installed
    if ! command_exists "ghostty"; then
        log "INFO" "Ghostty is not installed"
        skip_task "$task_id"
        exit 2  # Not installed
    fi

    # 1. Remove binary
    local binary_path
    binary_path=$(command -v ghostty 2>/dev/null || echo "")

    if [ -n "$binary_path" ]; then
        log "INFO" "Removing binary: $binary_path"
        if rm -f "$binary_path" 2>/dev/null; then
            log "SUCCESS" "Binary removed: $binary_path"
            ((removed_items++))
        else
            log "WARNING" "Could not remove binary: $binary_path"
        fi
    fi

    # 2. Remove installation directory
    if [ -d "$GHOSTTY_INSTALL_DIR" ]; then
        log "INFO" "Removing installation directory: $GHOSTTY_INSTALL_DIR"
        if rm -rf "$GHOSTTY_INSTALL_DIR" 2>/dev/null; then
            log "SUCCESS" "Installation directory removed: $GHOSTTY_INSTALL_DIR"
            ((removed_items++))
        else
            log "WARNING" "Could not remove directory: $GHOSTTY_INSTALL_DIR"
        fi
    fi

    # 3. Remove desktop entry
    local desktop_file="$HOME/.local/share/applications/ghostty.desktop"
    if [ -f "$desktop_file" ]; then
        log "INFO" "Removing desktop entry: $desktop_file"
        if rm -f "$desktop_file" 2>/dev/null; then
            log "SUCCESS" "Desktop entry removed: $desktop_file"
            ((removed_items++))
        else
            log "WARNING" "Could not remove desktop entry: $desktop_file"
        fi
    fi

    # 4. Remove build directory (if it exists)
    if [ -d "$GHOSTTY_BUILD_DIR" ]; then
        log "INFO" "Removing build directory: $GHOSTTY_BUILD_DIR"
        if rm -rf "$GHOSTTY_BUILD_DIR" 2>/dev/null; then
            log "SUCCESS" "Build directory removed: $GHOSTTY_BUILD_DIR"
            ((removed_items++))
        else
            log "WARNING" "Could not remove build directory: $GHOSTTY_BUILD_DIR"
        fi
    fi

    # 5. Update desktop database (with timeout protection)
    if command_exists "update-desktop-database"; then
        log "INFO" "Updating desktop database..."
        timeout 10 update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    # 6. Clear icon cache (with timeout protection)
    if command_exists "gtk-update-icon-cache"; then
        log "INFO" "Updating icon cache..."
        timeout 10 gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
    fi

    # Note: Configuration files in ~/.config/ghostty are NOT removed
    # Users may want to preserve their settings for reinstallation
    log "INFO" "Configuration files preserved in ~/.config/ghostty"

    # Summary
    if [ $removed_items -gt 0 ]; then
        log "SUCCESS" "Ghostty uninstalled successfully ($removed_items items removed)"
        complete_task "$task_id"
        exit 0
    else
        log "WARNING" "No Ghostty installation found to remove"
        skip_task "$task_id"
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
