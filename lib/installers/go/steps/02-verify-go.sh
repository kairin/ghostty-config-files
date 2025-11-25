#!/usr/bin/env bash
#
# Module: Go - Verify Installation
# Purpose: Verify Go is working
#
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

main() {
    log "INFO" "Verifying Go installation..."

    # Ensure PATH is updated for this script
    export PATH=$PATH:/usr/local/go/bin

    if ! command -v go >/dev/null 2>&1; then
        log "ERROR" "go command not found in PATH"
        exit 1
    fi

    local version
    version=$(go version)
    log "SUCCESS" "✓ Go is operational: $version"
    exit 0
}

main "$@"
