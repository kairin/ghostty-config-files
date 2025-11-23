#!/usr/bin/env bash
#
# Module: Ghostty - Install .deb Package
# Purpose: Install Ghostty from downloaded .deb package
#
set -eo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-install"
    register_task "$task_id" "Installing Ghostty from .deb"
    start_task "$task_id"

    # Verify .deb file exists
    if [ ! -f "$GHOSTTY_DEB_FILE" ]; then
        log "ERROR" "Package file not found: $GHOSTTY_DEB_FILE"
        fail_task "$task_id" "package not found"
        exit 1
    fi

    log "INFO" "Installing Ghostty from $GHOSTTY_DEB_FILE..."

    # Install using apt (handles dependencies automatically)
    if sudo apt install -y "$GHOSTTY_DEB_FILE" 2>&1 | tee >(cat >&2); then
        log "SUCCESS" "Ghostty installed successfully"

        # Cleanup .deb file
        rm -f "$GHOSTTY_DEB_FILE"
        log "INFO" "Cleaned up temporary package file"

        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to install Ghostty package"
        fail_task "$task_id" "apt install failed"
        exit 1
    fi
}

main "$@"
