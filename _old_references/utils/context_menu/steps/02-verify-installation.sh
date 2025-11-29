#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Verifying context menu installation..."
    
    if verify_nautilus_installed; then
        log "SUCCESS" "✓ Nautilus file manager installed"
    else
        log "ERROR" "✗ Nautilus not found"
        exit 1
    fi
    
    if verify_context_menu_script; then
        log "SUCCESS" "✓ Context menu script installed at $GHOSTTY_SCRIPT"
    else
        log "ERROR" "✗ Context menu script not found"
        exit 1
    fi
    
    log "SUCCESS" "════════════════════════════════════════"
    log "SUCCESS" "✓ Ghostty context menu installed"
    log "SUCCESS" "════════════════════════════════════════"
    log "INFO" "Next steps:"
    log "INFO" "  1. Restart Nautilus: nautilus -q"
    log "INFO" "  2. Right-click any folder → Scripts → Open in Ghostty"
    exit 0
}

main "$@"
