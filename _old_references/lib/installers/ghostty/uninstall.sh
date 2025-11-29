#!/usr/bin/env bash
#
# Ghostty Uninstallation Manager (.deb Version)
# Purpose: Complete removal of Ghostty .deb installation
# Exit Codes: 0=success, 1=failure, 2=not_installed
#
# Architecture: Modular uninstallation with TUI integration

set -eo pipefail

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

    # Check if Ghostty is installed via apt
    if ! is_ghostty_installed; then
        log "WARNING" "Ghostty is not installed via apt"

        # Still check for manual installations to clean up
        if has_manual_ghostty_installation; then
            log "INFO" "Found manual installations to clean up"
        else
            log "INFO" "No Ghostty installations found"
            skip_task "$task_id" "not installed"
            exit 2
        fi
    fi

    # Remove .deb package via apt
    if is_ghostty_installed; then
        log "INFO" "Removing Ghostty .deb package..."
        if sudo apt remove -y ghostty 2>&1 | tee -a "$(get_log_file)"; then
            log "SUCCESS" "Ghostty package removed"
            : $((removed_items++))
        else
            log "ERROR" "Failed to remove Ghostty package"
            fail_task "$task_id" "apt remove failed"
            exit 1
        fi

        # Optionally purge configuration files installed by the package
        log "INFO" "Purging Ghostty package configuration..."
        if sudo apt purge -y ghostty 2>&1 | tee -a "$(get_log_file)"; then
            log "SUCCESS" "Ghostty package purged"
            : $((removed_items++))
        else
            log "WARNING" "Failed to purge Ghostty package configuration"
        fi
    fi

    # Clean up any remaining manual installations
    if has_manual_ghostty_installation; then
        log "INFO" "Cleaning up manual installation remnants..."

        # Remove binary from /usr/local/bin
        if [ -f "/usr/local/bin/ghostty" ]; then
            log "INFO" "Removing /usr/local/bin/ghostty"
            if sudo rm -f "/usr/local/bin/ghostty" 2>/dev/null; then
                : $((removed_items++))
            fi
        fi

        # Remove binary from ~/.local/bin
        if [ -f "$HOME/.local/bin/ghostty" ]; then
            log "INFO" "Removing $HOME/.local/bin/ghostty"
            if rm -f "$HOME/.local/bin/ghostty" 2>/dev/null; then
                : $((removed_items++))
            fi
        fi

        # Remove binary from ~/.local/share/ghostty/bin
        if [ -f "$HOME/.local/share/ghostty/bin/ghostty" ]; then
            log "INFO" "Removing $HOME/.local/share/ghostty/bin/ghostty"
            if rm -f "$HOME/.local/share/ghostty/bin/ghostty" 2>/dev/null; then
                : $((removed_items++))
            fi

            # Remove empty parent directories if they exist
            if [ -d "$HOME/.local/share/ghostty/bin" ] && [ -z "$(ls -A "$HOME/.local/share/ghostty/bin")" ]; then
                rmdir "$HOME/.local/share/ghostty/bin" 2>/dev/null || true
            fi
            if [ -d "$HOME/.local/share/ghostty" ] && [ -z "$(ls -A "$HOME/.local/share/ghostty")" ]; then
                rmdir "$HOME/.local/share/ghostty" 2>/dev/null || true
            fi
        fi

        # Remove build directory
        if [ -d "$HOME/Apps/ghostty" ]; then
            log "INFO" "Removing $HOME/Apps/ghostty"
            if rm -rf "$HOME/Apps/ghostty" 2>/dev/null; then
                : $((removed_items++))
            fi
        fi

        # Remove Zig compiler
        if [ -d "$HOME/Apps/zig" ]; then
            log "INFO" "Removing Zig compiler (no longer needed)"
            if rm -rf "$HOME/Apps/zig" 2>/dev/null; then
                : $((removed_items++))
            fi
        fi

        # Remove Snap installation if present (legacy cleanup)
        if command -v snap &>/dev/null && snap list ghostty &>/dev/null 2>&1; then
            log "INFO" "Removing Snap-based Ghostty installation"
            if sudo snap remove ghostty 2>/dev/null; then
                log "SUCCESS" "Removed Ghostty Snap package"
                : $((removed_items++))
            fi
        fi

        # Remove Snap directories if present
        if [ -d "/snap/ghostty" ]; then
            log "INFO" "Removing Snap system directory: /snap/ghostty"
            if sudo rm -rf "/snap/ghostty" 2>/dev/null; then
                : $((removed_items++))
            fi
        fi

        if [ -d "$HOME/snap/ghostty" ]; then
            log "INFO" "Removing Snap user directory: ~/snap/ghostty"
            if rm -rf "$HOME/snap/ghostty" 2>/dev/null; then
                : $((removed_items++))
            fi
        fi

        # Remove desktop files (user-specific)
        local manual_desktop_files=(
            "$HOME/.local/share/applications/ghostty.desktop"
            "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
        )

        for desktop_file in "${manual_desktop_files[@]}"; do
            if [ -f "$desktop_file" ]; then
                log "INFO" "Removing desktop entry: $desktop_file"
                if rm -f "$desktop_file" 2>/dev/null; then
                    : $((removed_items++))
                fi
            fi
        done

        # Remove system-wide desktop files
        local system_desktop_files=(
            "/usr/share/applications/ghostty.desktop"
            "/usr/share/applications/com.mitchellh.ghostty.desktop"
        )

        for desktop_file in "${system_desktop_files[@]}"; do
            if [ -f "$desktop_file" ]; then
                log "INFO" "Removing system desktop entry: $desktop_file"
                if sudo rm -f "$desktop_file" 2>/dev/null; then
                    : $((removed_items++))
                fi
            fi
        done
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
