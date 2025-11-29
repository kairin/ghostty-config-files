#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Attempting to uninstall Nerd Fonts..."

FONTS_DIR="$HOME/.local/share/fonts"
FONTS=("JetBrainsMono" "Hack" "FiraCode" "Meslo")

if [ -d "$FONTS_DIR" ]; then
    log "INFO" "Removing font files..."
    for font in "${FONTS[@]}"; do
        if ls "$FONTS_DIR/$font"* &> /dev/null; then
            rm "$FONTS_DIR/$font"*
            log "SUCCESS" "Removed $font"
        fi
    done
    
    log "INFO" "Updating font cache..."
    if fc-cache -fv; then
        log "SUCCESS" "Font cache updated"
    else
        log "WARNING" "Failed to update font cache"
    fi
else
    log "INFO" "Fonts directory not found, nothing to do."
fi
