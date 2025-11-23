#!/usr/bin/env bash
#
# Module: Ghostty - Cleanup Manual Installation
# Purpose: Remove any manually built Ghostty installations to avoid conflicts
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-cleanup"
    register_task "$task_id" "Cleaning up manual Ghostty installations"
    start_task "$task_id"

    local cleaned=0

    # Check if there's anything to clean
    if ! has_manual_ghostty_installation; then
        log "INFO" "No manual installations to clean up"
        skip_task "$task_id" "nothing to clean"
        exit 2  # Skipped
    fi

    log "INFO" "Removing manual Ghostty installations..."

    # Remove binary from /usr/local/bin
    if [ -f "/usr/local/bin/ghostty" ]; then
        log "INFO" "Removing /usr/local/bin/ghostty"
        if sudo rm -f "/usr/local/bin/ghostty" 2>/dev/null; then
            log "SUCCESS" "Removed /usr/local/bin/ghostty"
            ((cleaned++))
        else
            log "WARNING" "Could not remove /usr/local/bin/ghostty"
        fi
    fi

    # Remove binary from ~/.local/bin
    if [ -f "$HOME/.local/bin/ghostty" ]; then
        log "INFO" "Removing $HOME/.local/bin/ghostty"
        if rm -f "$HOME/.local/bin/ghostty" 2>/dev/null; then
            log "SUCCESS" "Removed $HOME/.local/bin/ghostty"
            ((cleaned++))
        else
            log "WARNING" "Could not remove $HOME/.local/bin/ghostty"
        fi
    fi

    # Remove build directory
    if [ -d "$HOME/Apps/ghostty" ]; then
        log "INFO" "Removing $HOME/Apps/ghostty build directory"
        if rm -rf "$HOME/Apps/ghostty" 2>/dev/null; then
            log "SUCCESS" "Removed $HOME/Apps/ghostty"
            ((cleaned++))
        else
            log "WARNING" "Could not remove $HOME/Apps/ghostty"
        fi
    fi

    # Remove Zig installation if present
    if [ -d "$HOME/Apps/zig" ]; then
        log "INFO" "Removing Zig compiler (no longer needed)"
        if rm -rf "$HOME/Apps/zig" 2>/dev/null; then
            log "SUCCESS" "Removed $HOME/Apps/zig"
            ((cleaned++))
        else
            log "WARNING" "Could not remove $HOME/Apps/zig"
        fi
    fi

    # Remove any orphaned desktop entries from manual build
    local manual_desktop_files=(
        "$HOME/.local/share/applications/ghostty.desktop"
        "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
    )

    for desktop_file in "${manual_desktop_files[@]}"; do
        if [ -f "$desktop_file" ]; then
            # Check if it's a manual build entry (not from Snap)
            if ! grep -q "Exec=/snap/bin/ghostty" "$desktop_file" 2>/dev/null; then
                log "INFO" "Removing manual desktop entry: $desktop_file"
                if rm -f "$desktop_file" 2>/dev/null; then
                    log "SUCCESS" "Removed $desktop_file"
                    ((cleaned++))
                fi
            fi
        fi
    done

    if [ $cleaned -gt 0 ]; then
        log "SUCCESS" "Cleaned up $cleaned manual installation items"
        complete_task "$task_id"
        exit 0
    else
        log "INFO" "No items needed cleanup"
        skip_task "$task_id" "nothing to clean"
        exit 2
    fi
}

main "$@"
