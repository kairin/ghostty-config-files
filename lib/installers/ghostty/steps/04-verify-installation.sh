#!/usr/bin/env bash
#
# Module: Ghostty - Verify Installation
# Purpose: Verify Ghostty is properly installed and functional
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
    local task_id="ghostty-verify"
    register_task "$task_id" "Verifying Ghostty installation"
    start_task "$task_id"

    # Check if Ghostty is installed via Snap
    if ! is_ghostty_installed; then
        log "ERROR" "Ghostty is not installed"
        fail_task "$task_id" "not installed"
        exit 1
    fi

    log "INFO" "Ghostty Snap package is installed"

    # Check if ghostty command is accessible
    if ! command -v ghostty &>/dev/null; then
        log "ERROR" "ghostty command not found in PATH"
        log "ERROR" "You may need to restart your terminal or run: source ~/.zshrc"
        fail_task "$task_id" "command not in PATH"
        exit 1
    fi

    log "SUCCESS" "ghostty command is accessible"

    # Get version information
    local version
    version=$(get_ghostty_version)
    log "INFO" "Installed version: $version"

    # Test basic functionality
    log "INFO" "Testing Ghostty --version..."
    if ghostty --version &>/dev/null; then
        log "SUCCESS" "Ghostty --version works"
    else
        log "WARNING" "Ghostty --version command failed (may not be critical)"
    fi

    # Verify configuration
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        local config_count
        config_count=$(find "$GHOSTTY_CONFIG_DIR" -name "*.conf" | wc -l)
        log "INFO" "Found $config_count configuration files in $GHOSTTY_CONFIG_DIR"
    else
        log "WARNING" "Configuration directory not found: $GHOSTTY_CONFIG_DIR"
    fi

    # Check desktop integration
    if snap list "$GHOSTTY_SNAP_NAME" | grep -q "desktop"; then
        log "SUCCESS" "Desktop integration enabled"
    fi

    log "SUCCESS" "Ghostty installation verified successfully"
    complete_task "$task_id"
    exit 0
}

main "$@"
