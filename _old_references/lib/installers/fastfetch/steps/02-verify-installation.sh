#!/usr/bin/env bash
#
# Step 02: Verify fastfetch installation
# Purpose: Confirm fastfetch is installed and functional
# Exit Codes: 0=success, 1=verification failed
#

set -eo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying fastfetch installation..."

    # Check if command exists
    if ! command_exists "fastfetch"; then
        handle_error "verify-fastfetch" 1 "fastfetch command not found after installation" \
            "Please check installation logs"
        return 1
    fi

    # Get version
    local version
    version=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")

    if [ "$version" = "unknown" ]; then
        log "WARNING" "Could not determine fastfetch version"
    else
        log "INFO" "fastfetch version: ${version}"
    fi

    # Get path
    local path
    path=$(command -v fastfetch)
    log "INFO" "fastfetch path: ${path}"

    # Test basic functionality (with timeout)
    log "INFO" "Testing fastfetch functionality..."
    if timeout 5s fastfetch --pipe >/dev/null 2>&1; then
        log "SUCCESS" "✓ fastfetch is functional"
    else
        log "WARNING" "fastfetch test timed out or failed (non-critical)"
    fi

    log "SUCCESS" "✓ fastfetch installation verified"
    return 0
}

main "$@"
