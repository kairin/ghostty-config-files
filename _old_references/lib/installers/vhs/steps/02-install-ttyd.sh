#!/usr/bin/env bash
#
# Module: VHS - Install ttyd
# Purpose: Install ttyd (terminal over HTTP, VHS dependency)
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Constants
readonly TTYD_INSTALL_PATH="/usr/local/bin/ttyd"

# Temp file tracking
TEMP_FILE=""

# Cleanup on exit
cleanup_temp_files() {
    if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE" 2>/dev/null || true
    fi
}
trap cleanup_temp_files EXIT ERR INT TERM

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="vhs-ttyd"
    register_task "$task_id" "Installing ttyd"
    start_task "$task_id"

    # Check for source installation and remove it
    if [ -f "$TTYD_INSTALL_PATH" ]; then
        log "INFO" "Found source-installed ttyd at $TTYD_INSTALL_PATH"
        log "INFO" "Removing source installation to replace with APT version..."
        if sudo rm -f "$TTYD_INSTALL_PATH"; then
            log "SUCCESS" "Source-installed ttyd removed"
        else
            log "ERROR" "Failed to remove source-installed ttyd"
            fail_task "$task_id"
            exit 1
        fi
    fi

    # Check if already installed via APT
    if command_exists "ttyd" && [ "$(command -v ttyd)" = "/usr/bin/ttyd" ]; then
        log "INFO" "ttyd already installed via APT, checking version..."
        local version
        if version=$(ttyd --version 2>&1 | grep -oP '\d+\.\d+\.\d+'); then
            log "SUCCESS" "  ✓ ttyd $version installed"
            complete_task "$task_id" 0
            exit 0
        fi
    fi

    log "INFO" "Installing ttyd via APT..."
    
    if sudo apt install -y ttyd; then
        # Verify installation
        if command_exists "ttyd"; then
            local version
            if version=$(ttyd --version 2>&1 | grep -oP '\d+\.\d+\.\d+'); then
                log "SUCCESS" "✓ Installed ttyd $version"
            else
                log "SUCCESS" "✓ Installed ttyd (version unknown)"
            fi
            complete_task "$task_id" 0
            exit 0
        else
            log "ERROR" "ttyd installation failed verification"
            complete_task "$task_id" 1
            exit 1
        fi
    else
        log "ERROR" "Failed to install ttyd via APT"
        complete_task "$task_id" 1
        exit 1
    fi
}

main "$@"
