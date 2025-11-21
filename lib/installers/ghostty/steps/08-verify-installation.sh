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
    local installed_version
    if installed_version=$("$ghostty_bin" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1); then
        log "SUCCESS" "Ghostty binary is functional: v$installed_version"

        # Check for updates from GitHub releases
        log "INFO" "Checking for Ghostty updates..."
        local latest_version
        if latest_version=$(curl -sf --max-time 5 https://api.github.com/repos/ghostty-org/ghostty/releases/latest 2>/dev/null | grep -oP '"tag_name":\s*"v?\K[0-9.]+'); then
            if [ -n "$latest_version" ]; then
                if version_greater "$latest_version" "$installed_version"; then
                    log "WARNING" "Ghostty update available: v$latest_version (installed: v$installed_version)"
                    log "INFO" "Run installation again to update"
                    # Return exit code 2 to signal "update available" (for future automation)
                    echo "UPDATE_AVAILABLE|$installed_version|$latest_version"
                else
                    log "SUCCESS" "Ghostty is up-to-date (v$installed_version)"
                    echo "UP_TO_DATE|$installed_version"
                fi
            fi
        else
            log "INFO" "Could not check for updates (network unavailable or rate limited)"
            echo "VERSION_CHECK_FAILED|$installed_version"
        fi
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
