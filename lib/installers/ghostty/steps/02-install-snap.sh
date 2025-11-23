#!/usr/bin/env bash
#
# Module: Ghostty - Install from Snap
# Purpose: Install or upgrade Ghostty using Snap package manager
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
    local task_id="ghostty-snap-install"
    register_task "$task_id" "Installing Ghostty from Snap"
    start_task "$task_id"

    local current_version
    local latest_version

    current_version=$(get_ghostty_version)
    latest_version=$(get_ghostty_latest_version)

    log "INFO" "Current Ghostty version: $current_version"
    log "INFO" "Latest available version: $latest_version"

    # Check if already installed and up-to-date
    if is_ghostty_installed; then
        if ! is_ghostty_update_available; then
            log "INFO" "Ghostty is already installed and up-to-date (version: $current_version)"
            skip_task "$task_id" "already up-to-date"
            exit 2  # Skipped
        else
            log "INFO" "Update available: $current_version → $latest_version"
            log "INFO" "Upgrading Ghostty via Snap..."

            if sudo snap refresh "${GHOSTTY_SNAP_NAME}" 2>&1 | tee -a "$(get_log_file)"; then
                local new_version
                new_version=$(get_ghostty_version)
                log "SUCCESS" "Ghostty upgraded successfully: $current_version → $new_version"
                complete_task "$task_id"
                exit 0
            else
                log "ERROR" "Failed to upgrade Ghostty"
                fail_task "$task_id" "snap refresh failed"
                exit 1
            fi
        fi
    else
        log "INFO" "Installing Ghostty from Snap store..."

        if sudo snap install "${GHOSTTY_SNAP_NAME}" 2>&1 | tee -a "$(get_log_file)"; then
            local installed_version
            installed_version=$(get_ghostty_version)
            log "SUCCESS" "Ghostty installed successfully (version: $installed_version)"
            complete_task "$task_id"
            exit 0
        else
            log "ERROR" "Failed to install Ghostty from Snap"
            fail_task "$task_id" "snap install failed"
            exit 1
        fi
    fi
}

main "$@"
