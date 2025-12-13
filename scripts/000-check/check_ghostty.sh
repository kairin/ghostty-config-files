#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking for existing ghostty installation..."

if command -v ghostty &> /dev/null; then
    VERSION=$(ghostty --version | head -n 1)
    LOCATION=$(command -v ghostty)
    
    METHOD="Unknown"
    if [[ "$LOCATION" == "/usr/local/bin/ghostty" ]]; then
        METHOD="Source"
    elif snap list ghostty &> /dev/null; then
        METHOD="Snap"
    fi
    
    log "SUCCESS" "ghostty is installed: $VERSION"

    # Check context menu integration
    CONTEXT_MENU="${HOME}/.local/share/nautilus/scripts/Open in Ghostty"
    if [[ -x "$CONTEXT_MENU" ]]; then
        log "SUCCESS" "Context menu: Installed"
        echo "INSTALLED|$VERSION|$METHOD|$LOCATION|CONTEXT_MENU"
    else
        log "INFO" "Context menu: Not installed (run Reinstall to add)"
        echo "INSTALLED|$VERSION|$METHOD|$LOCATION|NO_CONTEXT_MENU"
    fi
else
    log "WARNING" "ghostty is NOT installed"
    echo "NOT_INSTALLED|-|-|-|-"
fi
