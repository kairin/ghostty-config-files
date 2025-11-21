#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Checking context menu prerequisites..."
    
    if verify_context_menu_works; then
        log "INFO" "↷ Ghostty context menu already installed"
        exit 2
    fi
    
    if ! verify_nautilus_installed; then
        log "ERROR" "✗ Nautilus file manager not found"
        log "ERROR" "  Install with: sudo apt install nautilus"
        exit 1
    fi
    
    if ! command_exists "ghostty"; then
        log "ERROR" "✗ Ghostty not installed - required for context menu"
        exit 1
    fi
    
    log "SUCCESS" "✓ Prerequisites check passed"
    exit 0
}

main "$@"
