#!/usr/bin/env bash
# uninstall.sh - remove deployed configs/links and restore backups.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DST_CONFIG="$HOME/.config/ghostty/config"
DST_FUNC="$HOME/.config/fish/functions/font-picker.fish"

if [ -f "$DST_CONFIG" ] && grep -q 'managed-by: ghostty-config-files' "$DST_CONFIG" 2>/dev/null; then
    LATEST_BAK=$(ls -t "${DST_CONFIG}.bak."* 2>/dev/null | head -1 || true)
    rm -f "$DST_CONFIG"
    if [ -n "$LATEST_BAK" ]; then
        mv "$LATEST_BAK" "$DST_CONFIG"
        echo "Restored backup: $LATEST_BAK -> $DST_CONFIG"
    else
        echo "Removed $DST_CONFIG (no backup to restore)."
    fi
elif [ -L "$DST_CONFIG" ] && [[ "$(readlink "$DST_CONFIG")" == "$REPO_ROOT"* ]]; then
    rm -f "$DST_CONFIG"
    echo "Removed symlink $DST_CONFIG"
else
    echo "Config at $DST_CONFIG is not managed by this repo - skipping."
fi

if [ -L "$DST_FUNC" ] && [[ "$(readlink "$DST_FUNC")" == "$REPO_ROOT"* ]]; then
    rm -f "$DST_FUNC"
    echo "Removed font-picker symlink $DST_FUNC"
else
    echo "font-picker at $DST_FUNC is not managed by this repo - skipping."
fi
