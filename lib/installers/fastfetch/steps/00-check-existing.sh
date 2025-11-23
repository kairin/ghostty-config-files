#!/usr/bin/env bash
#
# Step 00: Check existing fastfetch installation
# Purpose: Detect if fastfetch is already installed
# Exit Codes: 0=success (found or not found), non-zero=error
#

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking for existing fastfetch installation..."

    if command_exists "fastfetch"; then
        local version
        version=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        local path
        path=$(command -v fastfetch)

        log "INFO" "↷ fastfetch already installed"
        log "INFO" "  Version: ${version}"
        log "INFO" "  Path: ${path}"

        # Check installation method
        if [[ "$path" =~ ^/usr/bin/ ]] && dpkg -l fastfetch 2>/dev/null | grep -q "^ii"; then
            log "INFO" "  Method: APT"
        elif [[ "$path" =~ ^/usr/local/bin/ ]]; then
            log "INFO" "  Method: Source/Manual"
        else
            log "INFO" "  Method: Other"
        fi

        return 0
    else
        log "INFO" "fastfetch not currently installed"
        return 0
    fi
}

main "$@"
