#!/usr/bin/env bash
#
# Module: Glow - Check Existing Installation
# Purpose: Detect existing glow installation and version
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
    local task_id="glow-check"
    register_task "$task_id" "Checking existing glow installation"
    start_task "$task_id"

    log "INFO" "Checking for existing glow installation..."

    if command_exists "glow"; then
        local glow_path
        glow_path=$(command -v glow)
        log "INFO" "  Found: $glow_path"

        # Get version
        local version
        if version=$(glow --version 2>&1 | head -n 1 | grep -oP '\d+\.\d+\.\d+'); then
            log "INFO" "  Version: $version"
        else
            log "WARNING" "  Could not determine version"
        fi

        # Detect installation method
        case "$glow_path" in
            /usr/bin/glow)
                log "INFO" "  Method: APT package"
                ;;
            /snap/bin/glow)
                log "INFO" "  Method: Snap"
                ;;
            "$HOME/.local/bin/glow")
                log "INFO" "  Method: User binary"
                ;;
            /usr/local/bin/glow)
                log "INFO" "  Method: System binary"
                ;;
            *)
                log "INFO" "  Method: Other ($glow_path)"
                ;;
        esac
    else
        log "INFO" "  ✗ glow not installed"
    fi

    complete_task "$task_id" 0
    exit 0
}

main "$@"
