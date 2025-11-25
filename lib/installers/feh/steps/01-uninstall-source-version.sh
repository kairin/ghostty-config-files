#!/usr/bin/env bash
#
# Module: Feh - Uninstall Source Version
# Purpose: Remove source-installed feh if present to avoid conflicts
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
    local task_id="uninstall-source-feh"
    register_task "$task_id" "Removing source-installed feh"
    start_task "$task_id"

    log "INFO" "Checking for source-installed feh..."

    # Check if feh is installed in /usr/local/bin
    if [ -f "/usr/local/bin/feh" ]; then
        log "INFO" "Found source-installed feh at /usr/local/bin/feh"
        
        log "INFO" "Removing source installation..."
        # Remove binary and common artifacts
        if sudo rm -f "/usr/local/bin/feh" \
                      "/usr/local/share/man/man1/feh.1" \
                      "/usr/local/share/applications/feh.desktop"; then
            
            # Try to remove other potential artifacts
            sudo rm -rf "/usr/local/share/doc/feh" 2>/dev/null || true
            sudo rm -rf "/usr/local/share/feh" 2>/dev/null || true
            
            log "SUCCESS" "Source-installed feh removed successfully"
            complete_task "$task_id"
            exit 0
        else
            log "ERROR" "Failed to remove source-installed feh"
            fail_task "$task_id"
            exit 1
        fi
    else
        log "INFO" "No source-installed feh found"
        complete_task "$task_id"
        exit 0
    fi
}

main "$@"
