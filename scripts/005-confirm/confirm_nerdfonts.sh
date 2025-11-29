#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming Nerd Fonts installation..."

FONT_FAMILIES=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CascadiaCode" "SourceCodePro" "IBMPlexMono" "Iosevka")
INSTALLED=0

for family in "${FONT_FAMILIES[@]}"; do
    if fc-list : family | grep -qi "${family}.*Nerd"; then
        log "SUCCESS" "$family Nerd Font installed"
        ((INSTALLED++))
    else
        log "WARNING" "$family Nerd Font not found"
    fi
done

log "INFO" "Installed: $INSTALLED/8 fonts"

if [ $INSTALLED -ge 4 ]; then
    log "SUCCESS" "Nerd Fonts installation verified"
    exit 0
else
    log "ERROR" "Installation incomplete - less than 4 fonts detected"
    exit 1
fi
