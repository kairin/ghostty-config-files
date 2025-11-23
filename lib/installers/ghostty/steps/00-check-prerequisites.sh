#!/usr/bin/env bash
#
# Module: Ghostty - Check Prerequisites (Snap Installation)
# Purpose: Verify Snap is available and check for manual installations to clean
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
    local task_id="ghostty-prereqs"
    register_task "$task_id" "Checking Ghostty prerequisites"
    start_task "$task_id"

    # Check if Snap is installed
    log "INFO" "Checking for Snap package manager..."
    if ! command -v snap &>/dev/null; then
        log "ERROR" "Snap is not installed. Please install snapd first:"
        log "ERROR" "  sudo apt update && sudo apt install snapd"
        fail_task "$task_id" "Snap not available"
        exit 1
    fi

    log "SUCCESS" "Snap package manager is available"

    # Check for manual Ghostty installations
    if has_manual_ghostty_installation; then
        log "WARNING" "Detected manual Ghostty installation(s)"
        log "WARNING" "Found manual Ghostty installations in:"

        [ -f "/usr/local/bin/ghostty" ] && log "WARNING" "  - /usr/local/bin/ghostty"
        [ -f "$HOME/.local/bin/ghostty" ] && log "WARNING" "  - $HOME/.local/bin/ghostty"
        [ -d "$HOME/Apps/ghostty" ] && log "WARNING" "  - $HOME/Apps/ghostty (build directory)"

        log "INFO" "These will be removed to avoid conflicts with Snap installation"
    else
        log "INFO" "No conflicting manual installations detected"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
