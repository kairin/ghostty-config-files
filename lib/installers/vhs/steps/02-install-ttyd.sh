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
readonly TTYD_BINARY_URL="https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64"
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

    # Check if already installed
    if command_exists "ttyd"; then
        log "INFO" "ttyd already installed, checking version..."
        local version
        if version=$(ttyd --version 2>&1 | grep -oP '\d+\.\d+\.\d+'); then
            log "SUCCESS" "  ✓ ttyd $version installed"
            complete_task "$task_id" 0
            exit 0
        fi
    fi

    log "INFO" "Installing ttyd from GitHub releases..."
    echo "  ⠋ Downloading latest ttyd binary..."

    TEMP_FILE=$(mktemp)

    if ! curl -fL --progress-bar "$TTYD_BINARY_URL" -o "$TEMP_FILE" 2>&1; then
        log "ERROR" "Failed to download ttyd binary"
        complete_task "$task_id" 1
        exit 1
    fi

    echo "  ⠋ Installing binary to /usr/local/bin..."
    if ! sudo install -m 755 "$TEMP_FILE" "$TTYD_INSTALL_PATH"; then
        log "ERROR" "Failed to install ttyd binary"
        complete_task "$task_id" 1
        exit 1
    fi

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
}

main "$@"
