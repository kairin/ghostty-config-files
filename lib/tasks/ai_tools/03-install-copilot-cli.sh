#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing GitHub Copilot CLI..."
    
    if verify_copilot_cli; then
        log "INFO" "↷ GitHub Copilot CLI already installed"
        exit 2
    fi
    
    if ! npm install -g @githubnext/github-copilot-cli; then
        log "WARNING" "⚠ Failed to install GitHub Copilot CLI (non-fatal)"
        exit 0  # Non-fatal - continue
    fi
    
    log "SUCCESS" "✓ GitHub Copilot CLI installed successfully"
    exit 0
}

main "$@"
