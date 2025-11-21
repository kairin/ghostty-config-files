#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing Claude CLI..."
    
    if verify_claude_cli; then
        log "INFO" "↷ Claude CLI already installed"
        exit 2
    fi
    
    if ! npm install -g @anthropic-ai/claude-code; then
        log "ERROR" "✗ Failed to install Claude CLI"
        exit 1
    fi
    
    log "SUCCESS" "✓ Claude CLI installed successfully"
    exit 0
}

main "$@"
