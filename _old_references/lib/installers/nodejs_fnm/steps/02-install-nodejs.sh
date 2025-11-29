#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing Node.js (latest version)..."
    if verify_nodejs_installed; then
        local node_version
        node_version=$(node --version 2>/dev/null || echo "unknown")
        log "INFO" "↷ Node.js already installed: $node_version"
        exit 2
    fi
    
    # Ensure fnm is available
    export PATH="${FNM_DIR}:$PATH"
    
    log "INFO" "Installing Node.js latest version via fnm..."
    if ! fnm install "$NODE_LATEST_VERSION"; then
        log "ERROR" "✗ Node.js installation failed"
        exit 1
    fi
    
    if ! fnm use "$NODE_LATEST_VERSION"; then
        log "ERROR" "✗ Failed to activate Node.js"
        exit 1
    fi
    
    if verify_nodejs_installed; then
        local node_version
        node_version=$(node --version 2>/dev/null)
        log "SUCCESS" "✓ Node.js installed: $node_version (LATEST, not LTS - constitutional)"
        exit 0
    else
        log "ERROR" "✗ Node.js not available after installation"
        exit 1
    fi
}

main "$@"
