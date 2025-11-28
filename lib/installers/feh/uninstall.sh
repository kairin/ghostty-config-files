#!/usr/bin/env bash
#
# Feh Uninstallation Manager
# Purpose: Complete removal of feh installation (built-from-source and APT versions)
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
uninstall_feh() {
    local removed_items=0
    local task_id="uninstall-feh"

    register_task "$task_id" "Uninstalling Feh"
    start_task "$task_id"

    log "INFO" "Starting Feh uninstallation..."

    # Note: We proceed even if feh command is not in PATH
    # to clean up orphaned installation files

    # 1. Remove built-from-source installation (if exists)
    local feh_binary="$FEH_INSTALL_PREFIX/bin/feh"
    if [ -f "$feh_binary" ]; then
        log "INFO" "Removing built-from-source feh binary: $feh_binary"
        if sudo rm -f "$feh_binary" 2>/dev/null; then
            log "SUCCESS" "Binary removed: $feh_binary"
            ((removed_items++))
        else
            log "WARNING" "Could not remove binary: $feh_binary"
        fi
    fi

    # 2. Remove man pages installed from source
    local man_files=(
        "$FEH_INSTALL_PREFIX/share/man/man1/feh.1"
        "$FEH_INSTALL_PREFIX/share/man/man1/feh-menu.1"
        "$FEH_INSTALL_PREFIX/share/man/man1/feh-button.1"
    )

    for man_file in "${man_files[@]}"; do
        if [ -f "$man_file" ]; then
            log "INFO" "Removing man page: $man_file"
            if sudo rm -f "$man_file" 2>/dev/null; then
                log "SUCCESS" "Man page removed: $man_file"
                ((removed_items++))
            else
                log "WARNING" "Could not remove man page: $man_file"
            fi
        fi
    done

    # 3. Remove desktop entry
    local desktop_file="$HOME/.local/share/applications/feh.desktop"
    if [ -f "$desktop_file" ]; then
        log "INFO" "Removing desktop entry: $desktop_file"
        if rm -f "$desktop_file" 2>/dev/null; then
            log "SUCCESS" "Desktop entry removed: $desktop_file"
            ((removed_items++))
        else
            log "WARNING" "Could not remove desktop entry: $desktop_file"
        fi
    fi

    # 3b. Remove user icon symlinks (created for desktop integration)
    local user_icon_files=(
        "$HOME/.local/share/icons/hicolor/48x48/apps/feh.png"
        "$HOME/.local/share/icons/hicolor/scalable/apps/feh.svg"
    )

    for icon_file in "${user_icon_files[@]}"; do
        if [ -L "$icon_file" ] || [ -f "$icon_file" ]; then
            log "INFO" "Removing user icon symlink: $icon_file"
            if rm -f "$icon_file" 2>/dev/null; then
                log "SUCCESS" "Icon symlink removed: $icon_file"
                ((removed_items++))
            else
                log "WARNING" "Could not remove icon symlink: $icon_file"
            fi
        fi
    done

    # 4. Remove build directory (if it exists)
    if [ -d "$FEH_BUILD_DIR" ]; then
        log "INFO" "Removing build directory: $FEH_BUILD_DIR"
        if rm -rf "$FEH_BUILD_DIR" 2>/dev/null; then
            log "SUCCESS" "Build directory removed: $FEH_BUILD_DIR"
            ((removed_items++))
        else
            log "WARNING" "Could not remove build directory: $FEH_BUILD_DIR"
        fi
    fi

    # 5. Remove APT version if installed
    if is_feh_apt_installed; then
        log "INFO" "Removing APT version of feh..."
        if sudo apt-get remove -y feh 2>/dev/null; then
            log "SUCCESS" "APT version removed"
            ((removed_items++))
        else
            log "WARNING" "Could not remove APT version"
        fi
    fi

    # 6. Update desktop database (with timeout protection)
    if command_exists "update-desktop-database"; then
        log "INFO" "Updating desktop database..."
        timeout 10 update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    # Note: Configuration files in ~/.config/feh are NOT removed
    # Users may want to preserve their settings for reinstallation
    log "INFO" "Configuration files preserved in ~/.config/feh"

    # Summary
    if [ $removed_items -gt 0 ]; then
        log "SUCCESS" "Feh uninstalled successfully ($removed_items items removed)"
        complete_task "$task_id"
        exit 0
    else
        log "WARNING" "No Feh installation found to remove"
        skip_task "$task_id" "nothing to remove"
        exit 2
    fi
}

# Main execution
main() {
    # Run environment checks
    run_environment_checks || exit 1

    # Perform uninstallation
    uninstall_feh
}

main "$@"
