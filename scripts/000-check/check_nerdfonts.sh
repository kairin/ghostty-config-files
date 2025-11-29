#!/bin/bash
# Check if Nerd Fonts are installed

VERSION="v3.4.0"
FONTS_DIR="$HOME/.local/share/fonts"

# Fonts to check
FONT_FAMILIES=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CascadiaCode" "SourceCodePro" "IBMPlexMono" "Iosevka")

# Count installed fonts
INSTALLED_COUNT=0
for family in "${FONT_FAMILIES[@]}"; do
    if fc-list : family | grep -qi "${family}.*Nerd"; then
        ((INSTALLED_COUNT++))
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

    # Output with font count info
    echo "INSTALLED|$VERSION|$METHOD|$FONTS_DIR^fonts: $INSTALLED_COUNT/8|$VERSION"
else
    echo "Not Installed|-|-|-|$VERSION"
fi
