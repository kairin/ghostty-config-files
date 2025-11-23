#!/usr/bin/env bash
#
# Module: Feh - Uninstall APT Version
# Purpose: Remove apt-installed feh if present
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
    local task_id="uninstall-apt-feh"
    register_task "$task_id" "Removing APT-installed feh"
    start_task "$task_id"

    log "INFO" "Checking for APT-installed feh..."

    # Check if feh is installed via apt
    if ! is_feh_apt_installed; then
        log "INFO" "No APT-installed feh found (already removed or never installed)"
        complete_task "$task_id"
        exit 0
    fi

    local current_version
    current_version=$(get_feh_version)
    log "INFO" "Found APT-installed feh version: $current_version"

    # Uninstall via apt
    log "INFO" "Uninstalling APT version to replace with build-from-source..."
    if sudo apt remove -y feh; then
        log "SUCCESS" "APT-installed feh removed successfully"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to remove APT-installed feh"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
