#!/bin/bash
# Check icon cache status
# Output format: STATUS|VERSION|METHOD|LOCATION|NOTES

ICON_CACHE="/usr/share/icons/hicolor/icon-theme.cache"

if [ -f "$ICON_CACHE" ]; then
    SIZE=$(stat -c%s "$ICON_CACHE" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 1000 ]; then
        echo "INSTALLED|Valid|System|$ICON_CACHE|${SIZE} bytes"
    else
        echo "NOT_INSTALLED|Invalid|--|$ICON_CACHE|Cache too small (${SIZE} bytes)"
    fi
else
    echo "NOT_INSTALLED|-|-|$ICON_CACHE|Cache file missing"
fi
