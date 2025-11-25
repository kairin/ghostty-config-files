#!/usr/bin/env bash
#
# Module: Feh - Install APT Version
# Purpose: Install feh via apt
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
    local task_id="install-apt-feh"
    register_task "$task_id" "Installing feh via APT"
    start_task "$task_id"

    log "INFO" "Updating package lists..."
    if ! sudo apt update; then
        log "WARNING" "Failed to update package lists (continuing anyway)"
    fi

    log "INFO" "Installing feh..."
    if sudo apt install -y feh; then
        log "SUCCESS" "feh installed successfully via APT"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to install feh via APT"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
