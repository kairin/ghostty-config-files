#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing Nerd Fonts..."

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

# List of fonts to install
FONTS=("JetBrainsMono" "Hack" "FiraCode" "Meslo")
VERSION="v3.2.1" # Latest stable version as of late 2024/2025

for font in "${FONTS[@]}"; do
    log "INFO" "Downloading $font..."
    URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${font}.zip"
    ZIP_FILE="/tmp/${font}.zip"
    
    if curl -L -o "$ZIP_FILE" "$URL"; then
        log "SUCCESS" "Downloaded $font"
        log "INFO" "Unzipping $font..."
        if unzip -o "$ZIP_FILE" -d "$FONTS_DIR"; then
            log "SUCCESS" "Installed $font"
        else
            log "ERROR" "Failed to unzip $font"
            exit 1
        fi
        rm "$ZIP_FILE"
    else
        log "ERROR" "Failed to download $font from $URL"
        exit 1
    fi
done

log "INFO" "Updating font cache..."
if fc-cache -fv; then
    log "SUCCESS" "Font cache updated"
else
    log "WARNING" "Failed to update font cache"
fi
