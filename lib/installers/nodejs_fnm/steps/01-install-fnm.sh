#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing fnm (Fast Node Manager)..."
    if verify_fnm_binary; then
        log "INFO" "↷ fnm already installed at $FNM_BINARY"
        exit 2
    fi
    
    log "INFO" "Downloading fnm installer from $FNM_INSTALL_URL..."
    if ! curl -fsSL "$FNM_INSTALL_URL" | bash; then
        log "ERROR" "✗ fnm installation failed"
        exit 1
    fi
    
    if ! verify_fnm_binary; then
        log "ERROR" "✗ fnm binary not found after installation"
        exit 1
    fi
    
    log "SUCCESS" "✓ fnm installed successfully at $FNM_BINARY"
    exit 0
}

main "$@"
