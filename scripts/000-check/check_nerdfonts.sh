#!/bin/bash
# Check if Nerd Fonts are installed

VERSION="v3.4.0"
FONTS_DIR="$HOME/.local/share/fonts"

# Fonts to check
FONT_FAMILIES=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CascadiaCode" "SourceCodePro" "IBMPlexMono" "Iosevka")

# Count installed fonts and build status list
INSTALLED_COUNT=0
FONT_STATUS=""

for family in "${FONT_FAMILIES[@]}"; do
    if fc-list : family | grep -qi "${family}.*Nerd"; then
        ((INSTALLED_COUNT++))
        FONT_STATUS="$FONT_STATUS^   ✓ $family"
    else
        FONT_STATUS="$FONT_STATUS^   ✗ $family"
    fi
done

if [ $INSTALLED_COUNT -gt 0 ]; then
    # Determine installation method
    FONT_PATH=$(fc-list : family file | grep -i "Nerd" | head -n 1 | cut -d: -f1)

    if [[ "$FONT_PATH" == *"$HOME/.local/share/fonts"* ]]; then
        METHOD="Script"
    else
        METHOD="System"
    fi

    # Output with font count + individual status lines
    echo "INSTALLED|$VERSION|$METHOD|$FONTS_DIR^fonts: $INSTALLED_COUNT/8$FONT_STATUS|$VERSION"
else
    echo "Not Installed|-|-|-|$VERSION"
fi
