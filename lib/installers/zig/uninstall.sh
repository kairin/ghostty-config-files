#!/usr/bin/env bash
#
# Zig Compiler Uninstallation Manager
# Purpose: Complete removal of Zig compiler installation
# Exit Codes: 0=success, 1=failure, 2=not_installed
#
# Architecture: Modular uninstallation with TUI integration

set -euo pipefail

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source init.sh for common functions
if [ -f "${SCRIPT_DIR}/../init.sh" ]; then
    source "${SCRIPT_DIR}/../init.sh"
elif [ -f "$(git rev-parse --show-toplevel)/lib/init.sh" ]; then
    source "$(git rev-parse --show-toplevel)/lib/init.sh"
fi

# Zig installation constants (same as Ghostty common.sh)
ZIG_INSTALL_DIR="$HOME/Apps/zig"

# Uninstallation logic
uninstall_zig() {
    local removed_items=0
    local task_id="uninstall-zig"

    register_task "$task_id" "Uninstalling Zig compiler"
    start_task "$task_id"

    log "INFO" "Starting Zig compiler uninstallation..."

    # Check if Zig is installed
    if ! command_exists "zig" && [ ! -d "$ZIG_INSTALL_DIR" ]; then
        log "INFO" "Zig compiler is not installed"
        skip_task "$task_id"
        exit 2  # Not installed
    fi

    # 1. Remove Zig directory (symlink)
    if [ -e "$ZIG_INSTALL_DIR" ]; then
        log "INFO" "Removing Zig installation: $ZIG_INSTALL_DIR"

        # If it's a symlink, get the target directory
        if [ -L "$ZIG_INSTALL_DIR" ]; then
            local target
            target=$(readlink -f "$ZIG_INSTALL_DIR" 2>/dev/null || echo "")

            # Remove symlink
            rm -f "$ZIG_INSTALL_DIR" || log "WARNING" "Could not remove symlink: $ZIG_INSTALL_DIR"
            ((removed_items++))

            # Remove actual directory
            if [ -n "$target" ] && [ -d "$target" ]; then
                log "INFO" "Removing actual Zig directory: $target"
                rm -rf "$target" || log "WARNING" "Could not remove directory: $target"
                ((removed_items++))
            fi
        elif [ -d "$ZIG_INSTALL_DIR" ]; then
            # Direct directory (no symlink)
            rm -rf "$ZIG_INSTALL_DIR" || log "WARNING" "Could not remove directory: $ZIG_INSTALL_DIR"
            ((removed_items++))
        fi
    fi

    # 2. Remove any backup directories (zig-old-backup-*)
    local backup_count=0
    if [ -d "$HOME/Apps" ]; then
        for backup in "$HOME/Apps"/zig-old-backup-*; do
            if [ -d "$backup" ]; then
                log "INFO" "Removing backup: $backup"
                rm -rf "$backup" || log "WARNING" "Could not remove backup: $backup"
                ((backup_count++))
                ((removed_items++))
            fi
        done

        if [ $backup_count -gt 0 ]; then
            log "INFO" "Removed $backup_count backup directories"
        fi
    fi

    # 3. Remove Zig extracted directories (zig-x86_64-linux-*)
    if [ -d "$HOME/Apps" ]; then
        local extracted_count=0
        for extracted in "$HOME/Apps"/zig-x86_64-linux-*; do
            if [ -d "$extracted" ]; then
                log "INFO" "Removing extracted Zig: $extracted"
                rm -rf "$extracted" || log "WARNING" "Could not remove: $extracted"
                ((extracted_count++))
                ((removed_items++))
            fi
        done

        if [ $extracted_count -gt 0 ]; then
            log "INFO" "Removed $extracted_count extracted Zig directories"
        fi
    fi

    # 4. Remove Zig tarballs from /tmp
    if [ -d "/tmp" ]; then
        local tarball_count=0
        for tarball in /tmp/zig-*.tar.xz; do
            if [ -f "$tarball" ]; then
                log "INFO" "Removing tarball: $tarball"
                rm -f "$tarball" || log "WARNING" "Could not remove: $tarball"
                ((tarball_count++))
                ((removed_items++))
            fi
        done

        if [ $tarball_count -gt 0 ]; then
            log "INFO" "Removed $tarball_count tarballs"
        fi
    fi

    if [ $removed_items -gt 0 ]; then
        log "SUCCESS" "Zig compiler uninstalled successfully ($removed_items items removed)"
        log "INFO" "Note: PATH modifications in shell config files were not removed"
        complete_task "$task_id"
        exit 0
    else
        log "WARNING" "No Zig installation found to remove"
        skip_task "$task_id"
        exit 2
    fi
}

# Main execution
main() {
    # Run environment checks
    run_environment_checks || exit 1

    # Perform uninstallation
    uninstall_zig
}

main "$@"
