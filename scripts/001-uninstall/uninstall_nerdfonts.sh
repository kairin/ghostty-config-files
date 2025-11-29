#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Attempting to uninstall Nerd Fonts..."

FONTS_DIR="$HOME/.local/share/fonts"

# Font file patterns (using Nerd Fonts naming convention)
# Note: Some fonts have different names in Nerd Fonts:
#   CascadiaCode → CaskaydiaCove
#   SourceCodePro → SauceCodePro
#   IBMPlexMono → BlexMono
FONT_PATTERNS=(
    "JetBrainsMono*NerdFont*"
    "FiraCode*Nerd*"
    "Hack*Nerd*"
    "Meslo*Nerd*"
    "CaskaydiaCove*Nerd*"
    "SauceCodePro*Nerd*"
    "BlexMono*Nerd*"
    "Iosevka*Nerd*"
)

if [ -d "$FONTS_DIR" ]; then
    log "INFO" "Removing Nerd Font files..."
    REMOVED_COUNT=0
    for pattern in "${FONT_PATTERNS[@]}"; do
        # Count and remove matching files
        matching_files=$(find "$FONTS_DIR" -maxdepth 1 -name "$pattern" -type f 2>/dev/null)
        if [ -n "$matching_files" ]; then
            count=$(echo "$matching_files" | wc -l)
            rm -f "$FONTS_DIR"/$pattern 2>/dev/null
            log "SUCCESS" "Removed $count files matching $pattern"
            ((REMOVED_COUNT += count))
        fi
    done

    if [ $REMOVED_COUNT -gt 0 ]; then
        log "INFO" "Updating font cache..."
        fc-cache -fv "$FONTS_DIR" > /dev/null 2>&1
        log "SUCCESS" "Removed $REMOVED_COUNT font files total"
    else
        log "INFO" "No matching Nerd Font files found"
    fi
else
    log "INFO" "Fonts directory not found, nothing to do."
fi
