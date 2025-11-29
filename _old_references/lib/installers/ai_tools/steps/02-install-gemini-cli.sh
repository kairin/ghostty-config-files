#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing Gemini CLI..."
    
    if verify_gemini_cli; then
        log "INFO" "↷ Gemini CLI already installed"
        exit 2
    fi
    
    if ! npm install -g @google/gemini-cli; then
        log "ERROR" "✗ Failed to install Gemini CLI"
        exit 1
    fi
    
    log "SUCCESS" "✓ Gemini CLI installed successfully"
    exit 0
}

main "$@"
