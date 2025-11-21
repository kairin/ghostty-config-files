#!/usr/bin/env bash
#
# Module: Ghostty - Verify Installation
# Purpose: Verify Ghostty installation
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="verify-ghostty"
    register_task "$task_id" "Verifying Ghostty installation"
    start_task "$task_id"

    local ghostty_bin="$GHOSTTY_INSTALL_DIR/bin/ghostty"
    
    if [ ! -x "$ghostty_bin" ]; then
        log "ERROR" "Ghostty binary not found or not executable at $ghostty_bin"
        fail_task "$task_id"
        exit 1
    fi

    log "INFO" "Checking Ghostty version..."
    if "$ghostty_bin" --version; then
        log "SUCCESS" "Ghostty binary is functional"
    else
        log "ERROR" "Ghostty binary failed to execute"
        fail_task "$task_id"
        exit 1
    fi

    local desktop_entry="$HOME/.local/share/applications/ghostty.desktop"
    if [ -f "$desktop_entry" ]; then
        log "SUCCESS" "Desktop entry found"
    else
        log "WARNING" "Desktop entry not found"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
