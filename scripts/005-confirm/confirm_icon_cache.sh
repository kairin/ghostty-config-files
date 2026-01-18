#!/bin/bash
# Confirm icon cache is valid

ICON_CACHE="/usr/share/icons/hicolor/icon-theme.cache"

if [ -f "$ICON_CACHE" ]; then
    SIZE=$(stat -c%s "$ICON_CACHE" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 1000 ]; then
        echo "Icon cache is valid"
        echo "  Location: $ICON_CACHE"
        echo "  Size: $SIZE bytes"
        echo "  Modified: $(stat -c%y "$ICON_CACHE" 2>/dev/null | cut -d. -f1)"
        exit 0
    else
        echo "ERROR: Icon cache is too small ($SIZE bytes)"
        echo "Run the install action to rebuild the cache"
        exit 1
    fi
else
    echo "ERROR: Icon cache file does not exist"
    echo "  Expected: $ICON_CACHE"
    echo "Run the install action to create the cache"
    exit 1
fi
