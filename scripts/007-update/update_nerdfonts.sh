#!/bin/bash
# update_nerdfonts.sh - Update Nerd Fonts in-place
#
# Re-downloads fonts only if version differs, preserving existing fonts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

FONTS_DIR="$HOME/.local/share/fonts/NerdFonts"

log "INFO" "Checking current Nerd Fonts installation..."

# Use the existing install script which handles updates properly
# The install script already checks versions and only downloads if needed
log "INFO" "Running Nerd Fonts installer..."

if bash "$SCRIPT_DIR/../004-reinstall/install_nerdfonts.sh"; then
    log "SUCCESS" "Nerd Fonts updated"

    # Refresh font cache
    log "INFO" "Refreshing font cache..."
    fc-cache -fv "$FONTS_DIR" 2>/dev/null

    log "SUCCESS" "Nerd Fonts update complete"
else
    log "ERROR" "Nerd Fonts update failed"
    exit 1
fi
