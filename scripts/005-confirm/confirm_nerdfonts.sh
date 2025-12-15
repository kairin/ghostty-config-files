#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming Nerd Fonts installation..."

# fc-list search patterns (Nerd Fonts uses different names for licensing)
# CascadiaCode → CaskaydiaCove, SourceCodePro → SauceCodePro, IBMPlexMono → BlexMono
SEARCH_PATTERNS=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CaskaydiaCove" "SauceCodePro" "BlexMono" "Iosevka")
DISPLAY_NAMES=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CascadiaCode" "SourceCodePro" "IBMPlexMono" "Iosevka")
INSTALLED=0

for i in "${!SEARCH_PATTERNS[@]}"; do
    pattern="${SEARCH_PATTERNS[$i]}"
    display="${DISPLAY_NAMES[$i]}"
    if fc-list : family | /bin/grep -qi "${pattern}.*Nerd"; then
        log "SUCCESS" "$display Nerd Font installed"
        ((INSTALLED++))
    else
        log "WARNING" "$display Nerd Font not found"
    fi
done

log "INFO" "Installed: $INSTALLED/8 fonts"

if [ $INSTALLED -ge 4 ]; then
    log "SUCCESS" "Nerd Fonts installation verified"

    # Generate artifact manifest for future verification
    # Use font count as "version" since there's no actual version
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM="${INSTALLED}-fonts"
    "$SCRIPT_DIR/generate_manifest.sh" nerdfonts "$VERSION_NUM" script > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"

    exit 0
else
    log "ERROR" "Installation incomplete - less than 4 fonts detected"
    exit 1
fi
