#!/bin/bash
# confirm_antigravity.sh - Verify Google Antigravity installation

echo "Verifying Google Antigravity installation..."
echo ""

INSTALLED=0

# Check command availability
echo -n "Antigravity binary: "
if command -v antigravity &> /dev/null; then
    LOCATION=$(which antigravity)
    echo "FOUND at $LOCATION"
    INSTALLED=1
else
    echo "NOT FOUND in PATH"
fi

# Check AppImage location
APPIMAGE_PATH="$HOME/.local/share/antigravity/Antigravity.AppImage"
echo -n "Antigravity AppImage: "
if [ -f "$APPIMAGE_PATH" ]; then
    echo "FOUND at $APPIMAGE_PATH"
    INSTALLED=1
else
    echo "NOT FOUND"
fi

# Check dpkg installation
echo -n "Antigravity package: "
if dpkg -l antigravity 2>/dev/null | grep -q '^ii'; then
    VERSION=$(dpkg -l antigravity 2>/dev/null | grep '^ii' | awk '{print $3}')
    echo "INSTALLED (version $VERSION)"
    INSTALLED=1
elif dpkg -l google-antigravity 2>/dev/null | grep -q '^ii'; then
    VERSION=$(dpkg -l google-antigravity 2>/dev/null | grep '^ii' | awk '{print $3}')
    echo "INSTALLED (version $VERSION)"
    INSTALLED=1
else
    echo "NOT INSTALLED via dpkg"
fi

# Check snap installation
echo -n "Antigravity snap: "
if command -v snap &> /dev/null && snap list antigravity 2>/dev/null | grep -q antigravity; then
    VERSION=$(snap list antigravity 2>/dev/null | grep antigravity | awk '{print $2}')
    echo "INSTALLED (version $VERSION)"
    INSTALLED=1
else
    echo "NOT INSTALLED via snap"
fi

# Check desktop entry
echo -n "Desktop entry: "
DESKTOP_FILE="$HOME/.local/share/applications/antigravity.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    echo "FOUND"
elif [ -f "/usr/share/applications/antigravity.desktop" ]; then
    echo "FOUND (system)"
elif [ -f "/usr/share/applications/google-antigravity.desktop" ]; then
    echo "FOUND (system)"
else
    echo "NOT FOUND"
fi

echo ""

if [[ $INSTALLED -eq 1 ]]; then
    echo "Google Antigravity is installed."
    echo ""
    echo "To launch:"
    echo "  - Run 'antigravity' from terminal"
    echo "  - Or find 'Google Antigravity' in your application menu"
    exit 0
else
    echo "Google Antigravity is NOT installed."
    exit 1
fi
