#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing Ghostty context menu..."
    
    if verify_context_menu_script; then
        log "INFO" "↷ Context menu script already installed"
        exit 2
    fi
    
    mkdir -p "$NAUTILUS_SCRIPTS_DIR"
    
    cat > "$GHOSTTY_SCRIPT" << 'NAUTILUS_SCRIPT'
#!/usr/bin/env bash
# Nautilus script: Open in Ghostty terminal
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    DIR=$(dirname "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")
    ghostty --working-directory="$DIR" &
else
    ghostty &
fi
NAUTILUS_SCRIPT
    
    chmod +x "$GHOSTTY_SCRIPT"
    
    if ! verify_context_menu_script; then
        log "ERROR" "✗ Failed to create context menu script"
        exit 1
    fi
    
    log "SUCCESS" "✓ Ghostty context menu installed"
    log "INFO" "  Restart Nautilus to see changes: nautilus -q"
    exit 0
}

main "$@"
