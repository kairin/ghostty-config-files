#!/usr/bin/env bash
#
# Module: Ghostty - Verify Installation
# Purpose: Verify Ghostty is properly installed and functional
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
    local task_id="ghostty-verify"
    register_task "$task_id" "Verifying Ghostty installation"
    start_task "$task_id"

    # Check if Ghostty is installed
    if ! is_ghostty_installed; then
        log "ERROR" "Ghostty is not installed"
        fail_task "$task_id" "not installed"
        exit 1
    fi

    log "SUCCESS" "Ghostty binary found in PATH"

    # Get version information
    local version
    version=$(get_ghostty_version)
    log "INFO" "Installed version: $version"

    # Verify configuration
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        local config_count
        config_count=$(find "$GHOSTTY_CONFIG_DIR" -name "*.conf" 2>/dev/null | wc -l)
        log "INFO" "Found $config_count configuration files in $GHOSTTY_CONFIG_DIR"
    else
        log "WARNING" "Configuration directory not found: $GHOSTTY_CONFIG_DIR"
    fi

    log "SUCCESS" "Ghostty installation verified successfully"
    complete_task "$task_id"
    exit 0
}

main "$@"
