#!/usr/bin/env bash
#
# Module: Feh - Cleanup Existing Installations
# Purpose: Remove ALL existing feh installations (APT, Snap, Source) to avoid conflicts
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
    local task_id="feh-cleanup"
    register_task "$task_id" "Cleaning up existing feh installations"
    start_task "$task_id"

    local cleaned=0

    # Check if there's anything to clean
    if ! has_any_feh_installation; then
        log "INFO" "No existing feh installations found"
        skip_task "$task_id" "nothing to clean"
        exit 0
    fi

    log "INFO" "Detecting and removing existing feh installations..."

    # Phase 1: Remove APT installation
    if is_feh_apt_installed; then
        log "INFO" "Found APT-installed feh, removing..."
        # Use subshell to isolate error handling - don't let apt failure stop cleanup
        if (set +e; sudo apt-get remove -y --allow-change-held-packages feh 2>&1 || true); then
            if ! is_feh_apt_installed; then
                log "SUCCESS" "Removed APT feh package"
                : $((cleaned++))
            else
                log "WARNING" "APT feh removal may have failed (will retry with purge)"
                sudo apt-get purge -y feh 2>/dev/null || true
            fi
        fi
    fi

    # Phase 2: Remove Snap installation
    if is_feh_snap_installed; then
        log "INFO" "Found Snap-installed feh, removing..."
        if sudo snap remove feh 2>/dev/null; then
            log "SUCCESS" "Removed Snap feh package"
            : $((cleaned++))
        else
            log "WARNING" "Could not remove Snap feh (continuing anyway)"
        fi
    fi

    # Remove orphaned Snap directories
    if [ -d "/snap/feh" ]; then
        log "INFO" "Removing Snap system directory: /snap/feh"
        sudo rm -rf "/snap/feh" 2>/dev/null && : $((cleaned++))
    fi
    if [ -d "$HOME/snap/feh" ]; then
        log "INFO" "Removing Snap user directory: ~/snap/feh"
        rm -rf "$HOME/snap/feh" 2>/dev/null && : $((cleaned++))
    fi

    # Phase 3: Remove source-built installation
    if [ -f "/usr/local/bin/feh" ]; then
        log "INFO" "Found source-installed feh at /usr/local/bin/feh, removing..."
        sudo rm -f "/usr/local/bin/feh" \
                   "/usr/local/share/man/man1/feh.1"* \
                   "/usr/local/share/applications/feh.desktop" 2>/dev/null
        sudo rm -rf "/usr/local/share/doc/feh" "/usr/local/share/feh" 2>/dev/null
        log "SUCCESS" "Removed source-installed feh"
        : $((cleaned++))
    fi

    # Phase 4: Remove user binary installation
    if [ -f "$HOME/.local/bin/feh" ]; then
        log "INFO" "Removing user binary: $HOME/.local/bin/feh"
        rm -f "$HOME/.local/bin/feh" 2>/dev/null && : $((cleaned++))
    fi

    # Phase 5: Remove orphaned desktop entries
    local desktop_files=(
        "$HOME/.local/share/applications/feh.desktop"
        "/usr/share/applications/feh.desktop"
        "/usr/local/share/applications/feh.desktop"
    )

    for desktop_file in "${desktop_files[@]}"; do
        if [ -f "$desktop_file" ]; then
            log "INFO" "Removing desktop entry: $desktop_file"
            if [[ "$desktop_file" == /usr/* ]]; then
                sudo rm -f "$desktop_file" 2>/dev/null && : $((cleaned++))
            else
                rm -f "$desktop_file" 2>/dev/null && : $((cleaned++))
            fi
        fi
    done

    # Phase 6: Remove orphaned icons
    local icon_files=(
        "/usr/local/share/icons/hicolor/48x48/apps/feh.png"
        "/usr/local/share/icons/hicolor/scalable/apps/feh.svg"
        "$HOME/.local/share/icons/hicolor/48x48/apps/feh.png"
        "$HOME/.local/share/icons/hicolor/scalable/apps/feh.svg"
    )

    for icon in "${icon_files[@]}"; do
        if [ -f "$icon" ]; then
            log "INFO" "Removing orphaned icon: $icon"
            if [[ "$icon" == /usr/* ]]; then
                sudo rm -f "$icon" 2>/dev/null && : $((cleaned++))
            else
                rm -f "$icon" 2>/dev/null && : $((cleaned++))
            fi
        fi
    done

    if [ $cleaned -gt 0 ]; then
        log "SUCCESS" "Cleaned up $cleaned items"
    else
        log "INFO" "No items needed cleanup"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
