#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

# Version and fonts configuration
VERSION="v3.4.0"
FONTS=(
    "JetBrainsMono"
    "FiraCode"
    "Hack"
    "Meslo"
    "CascadiaCode"
    "SourceCodePro"
    "IBMPlexMono"
    "Iosevka"
)
FONTS_DIR="$HOME/.local/share/fonts"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download"

log "INFO" "Installing Nerd Fonts $VERSION (${#FONTS[@]} fonts)..."

# Create fonts directory
mkdir -p "$FONTS_DIR"

# Track installation progress
INSTALLED_COUNT=0
FAILED_COUNT=0

# Download and install each font
for font in "${FONTS[@]}"; do
    log "INFO" "Downloading $font..."

    ARCHIVE_URL="${DOWNLOAD_URL}/${VERSION}/${font}.tar.xz"
    TEMP_FILE="/tmp/${font}.tar.xz"

    if curl -fsSL "$ARCHIVE_URL" -o "$TEMP_FILE"; then
        log "INFO" "Extracting $font..."
        # Extract only font files (ttf or otf)
        if tar -xJf "$TEMP_FILE" -C "$FONTS_DIR" 2>/dev/null; then
            rm -f "$TEMP_FILE"
            log "SUCCESS" "$font installed"
            ((INSTALLED_COUNT++))
        else
            log "WARNING" "Failed to extract $font"
            rm -f "$TEMP_FILE"
            ((FAILED_COUNT++))
        fi
    else
        log "WARNING" "Failed to download $font"
        ((FAILED_COUNT++))
    fi
done

# Refresh font cache
log "INFO" "Refreshing font cache..."
fc-cache -fv "$FONTS_DIR" > /dev/null 2>&1

# Summary
log "INFO" "Installation summary: $INSTALLED_COUNT/${#FONTS[@]} fonts installed"

if [ $INSTALLED_COUNT -ge 4 ]; then
    log "SUCCESS" "Nerd Fonts installation complete"
    exit 0
else
    log "ERROR" "Too many fonts failed to install"
    exit 1
fi
