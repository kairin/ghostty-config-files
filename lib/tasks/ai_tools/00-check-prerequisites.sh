#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking AI tools prerequisites..."
    
    if verify_all_ai_tools; then
        log "INFO" "↷ All AI tools already installed"
        exit 2
    fi
    
    if ! verify_nodejs_available; then
        log "ERROR" "✗ Node.js/npm not available - required for AI CLI tools"
        exit 1
    fi
    
    local node_version=$(node --version 2>/dev/null)
    local npm_version=$(npm --version 2>/dev/null)
    log "SUCCESS" "✓ Node.js $node_version, npm v$npm_version available"
    log "SUCCESS" "✓ Prerequisites check passed"
    exit 0
}

main "$@"
