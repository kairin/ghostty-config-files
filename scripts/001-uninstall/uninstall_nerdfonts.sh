#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

FONTS_DIR="$HOME/.local/share/fonts"
NERDFONTS_SUBDIR="$FONTS_DIR/NerdFonts"

# Accept optional font family argument for single-font uninstall
SINGLE_FONT="${1:-}"

# Map font display names to their file patterns
get_font_pattern() {
    local font_name="$1"
    case "$font_name" in
        "JetBrainsMono") echo "JetBrainsMono*NerdFont*" ;;
        "FiraCode")      echo "FiraCode*Nerd*" ;;
        "Hack")          echo "Hack*Nerd*" ;;
        "Meslo")         echo "Meslo*Nerd*" ;;
        "CascadiaCode")  echo "CaskaydiaCove*Nerd*" ;;
        "SourceCodePro") echo "SauceCodePro*Nerd*" ;;
        "IBMPlexMono")   echo "BlexMono*Nerd*" ;;
        "Iosevka")       echo "Iosevka*Nerd*" ;;
        *)               echo "" ;;
    esac
}

if [ -n "$SINGLE_FONT" ]; then
    # Single font uninstallation mode
    log "INFO" "Uninstalling single Nerd Font: $SINGLE_FONT"

    PATTERN=$(get_font_pattern "$SINGLE_FONT")
    if [ -z "$PATTERN" ]; then
        log "ERROR" "Unknown font family: $SINGLE_FONT"
        exit 1
    fi

    REMOVED_COUNT=0

    # Check NerdFonts subdirectory
    if [ -d "$NERDFONTS_SUBDIR" ]; then
        matching_files=$(find "$NERDFONTS_SUBDIR" -name "$PATTERN" -type f 2>/dev/null)
        if [ -n "$matching_files" ]; then
            count=$(echo "$matching_files" | wc -l)
            find "$NERDFONTS_SUBDIR" -name "$PATTERN" -type f -delete 2>/dev/null
            log "SUCCESS" "Removed $count files from NerdFonts directory"
            ((REMOVED_COUNT += count))
        fi
    fi

    # Check legacy location
    matching_files=$(find "$FONTS_DIR" -maxdepth 1 -name "$PATTERN" -type f 2>/dev/null)
    if [ -n "$matching_files" ]; then
        count=$(echo "$matching_files" | wc -l)
        rm -f "$FONTS_DIR"/$PATTERN 2>/dev/null
        log "SUCCESS" "Removed $count files from fonts directory"
        ((REMOVED_COUNT += count))
    fi

    # Refresh font cache
    log "INFO" "Updating font cache..."
    fc-cache -fv "$FONTS_DIR" > /dev/null 2>&1

    if [ $REMOVED_COUNT -gt 0 ]; then
        log "SUCCESS" "$SINGLE_FONT uninstallation complete ($REMOVED_COUNT files removed)"
        exit 0
    else
        log "WARNING" "$SINGLE_FONT was not found - nothing to remove"
        exit 0
    fi
fi

# Full uninstallation mode (no argument provided)
log "INFO" "Attempting to uninstall all Nerd Fonts..."

# Check if NerdFonts subdirectory exists (preferred location)
if [ -d "$NERDFONTS_SUBDIR" ]; then
    log "INFO" "Found NerdFonts directory at $NERDFONTS_SUBDIR"

    # Count files before removal
    FILE_COUNT=$(find "$NERDFONTS_SUBDIR" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)

    if [ "$FILE_COUNT" -gt 0 ]; then
        log "INFO" "Removing $FILE_COUNT font files..."
        rm -rf "$NERDFONTS_SUBDIR"
        log "SUCCESS" "Removed NerdFonts directory"
    else
        log "INFO" "NerdFonts directory is empty"
        rm -rf "$NERDFONTS_SUBDIR"
    fi
fi

# Also clean up any fonts directly in FONTS_DIR (legacy installations)
# Font file patterns (using Nerd Fonts naming convention)
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

REMOVED_COUNT=0
for pattern in "${FONT_PATTERNS[@]}"; do
    matching_files=$(find "$FONTS_DIR" -maxdepth 1 -name "$pattern" -type f 2>/dev/null)
    if [ -n "$matching_files" ]; then
        count=$(echo "$matching_files" | wc -l)
        rm -f "$FONTS_DIR"/$pattern 2>/dev/null
        log "SUCCESS" "Removed $count files matching $pattern"
        ((REMOVED_COUNT += count))
    fi
done

# Clean up LICENSE/README files that came with the fonts
for file in LICENSE LICENSE.md LICENSE.txt OFL.txt README.md; do
    if [ -f "$FONTS_DIR/$file" ]; then
        rm -f "$FONTS_DIR/$file"
        log "INFO" "Removed $file"
    fi
done

# Refresh font cache
log "INFO" "Updating font cache..."
fc-cache -fv "$FONTS_DIR" > /dev/null 2>&1

log "SUCCESS" "Nerd Fonts uninstallation complete"
