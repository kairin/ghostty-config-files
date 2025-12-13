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

    # Check context menu integration (nautilus-open-any-terminal extension)
    CONTEXT_MENU_STATUS="NO_CONTEXT_MENU"

    # Check for nautilus-open-any-terminal extension (preferred modern approach)
    EXT_FILE="${HOME}/.local/share/nautilus-python/extensions/nautilus_open_any_terminal.py"
    if [[ -f "$EXT_FILE" ]]; then
        CONFIGURED_TERMINAL=$(gsettings get com.github.stunkymonkey.nautilus-open-any-terminal terminal 2>/dev/null | tr -d "'")
        if [[ "$CONFIGURED_TERMINAL" == "ghostty" ]]; then
            log "SUCCESS" "Context menu: Extension installed (Ghostty)"
            CONTEXT_MENU_STATUS="CONTEXT_MENU_EXTENSION"
        else
            log "INFO" "Context menu: Extension installed (not configured for Ghostty)"
            CONTEXT_MENU_STATUS="CONTEXT_MENU_OTHER"
        fi
    # Fallback: check legacy script (deprecated in Nautilus 49+)
    elif [[ -x "${HOME}/.local/share/nautilus/scripts/Open in Ghostty" ]]; then
        log "WARNING" "Context menu: Legacy script (hidden in Scripts submenu)"
        CONTEXT_MENU_STATUS="CONTEXT_MENU_LEGACY"
    else
        log "INFO" "Context menu: Not installed (run Reinstall to add)"
    fi

    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$CONTEXT_MENU_STATUS"
else
    log "WARNING" "ghostty is NOT installed"
    echo "NOT_INSTALLED|-|-|-|-"
fi
