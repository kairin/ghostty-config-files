#!/usr/bin/env bash
# uninstall.sh - remove deployed configs/links and restore backups.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DST_GHOSTTY="$HOME/.config/ghostty/config"
DST_TMUX="$HOME/.config/tmux/tmux.conf"
DST_FONT_PICKER="$HOME/.config/fish/functions/font-picker.fish"
DST_DEV="$HOME/.config/fish/functions/dev.fish"

# Ghostty config: detect via managed-by marker or stale symlink
if [ -f "$DST_GHOSTTY" ] && grep -q 'managed-by: ghostty-config-files' "$DST_GHOSTTY" 2>/dev/null; then
    LATEST_BAK=$(ls -t "${DST_GHOSTTY}.bak."* 2>/dev/null | head -1 || true)
    rm -f "$DST_GHOSTTY"
    if [ -n "$LATEST_BAK" ]; then
        mv "$LATEST_BAK" "$DST_GHOSTTY"
        echo "Restored backup: $LATEST_BAK -> $DST_GHOSTTY"
    else
        echo "Removed $DST_GHOSTTY (no backup to restore)."
    fi
    rm -f "${DST_GHOSTTY}.bak."* 2>/dev/null || true
elif [ -L "$DST_GHOSTTY" ] && [[ "$(readlink "$DST_GHOSTTY")" == "$REPO_ROOT"* ]]; then
    rm -f "$DST_GHOSTTY"
    echo "Removed symlink $DST_GHOSTTY"
else
    echo "Ghostty config is not managed by this repo - skipping."
fi

# tmux config symlink
if [ -L "$DST_TMUX" ] && [[ "$(readlink "$DST_TMUX")" == "$REPO_ROOT"* ]]; then
    rm -f "$DST_TMUX"
    echo "Removed tmux config symlink $DST_TMUX"
else
    echo "tmux config is not managed by this repo - skipping."
fi

# Fish function symlinks
for dst in "$DST_FONT_PICKER" "$DST_DEV"; do
    if [ -L "$dst" ] && [[ "$(readlink "$dst")" == "$REPO_ROOT"* ]]; then
        rm -f "$dst"
        echo "Removed $(basename "$dst") symlink $dst"
    else
        echo "$(basename "$dst") is not managed by this repo - skipping."
    fi
done
