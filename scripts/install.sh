#!/usr/bin/env bash
# install.sh - deploy Ghostty + tmux configs and fish functions for this repo.
# Idempotent and safe to re-run. Copies the Ghostty config (so the font-picker's
# in-place sed edits never mutate tracked repo files); symlinks fish functions
# so `git pull` propagates updates automatically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC_GHOSTTY="$REPO_ROOT/configs/ghostty/config"
SRC_TMUX="$REPO_ROOT/configs/tmux/tmux.conf"
SRC_FONT_PICKER="$REPO_ROOT/scripts/font-picker.fish"
SRC_DEV="$REPO_ROOT/scripts/dev.fish"

GHOSTTY_DST="$HOME/.config/ghostty"
TMUX_DST="$HOME/.config/tmux"
FISH_FUNCS="$HOME/.config/fish/functions"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$GHOSTTY_DST" "$TMUX_DST" "$FISH_FUNCS"

# --- Ghostty config: COPY (never symlink; font-picker sed would clobber it) ---
deploy_ghostty() {
    local dst="$GHOSTTY_DST/config"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] || [ "$FORCE" -eq 1 ]; then
            cp -p "$dst" "$dst.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
            rm -f "$dst"
            cp "$SRC_GHOSTTY" "$dst"
            echo "Replaced Ghostty config (backup saved)."
        else
            echo "Ghostty config already present (kept your font choice). Use --force to overwrite."
        fi
    else
        cp "$SRC_GHOSTTY" "$dst"
        echo "Installed Ghostty config -> $dst"
    fi
}
deploy_ghostty

# --- tmux config: SYMLINK (never mutated, propagation is safe) ---
ln -sfn "$SRC_TMUX" "$TMUX_DST/tmux.conf"
echo "Linked tmux config -> $TMUX_DST/tmux.conf"

# --- Fish functions: SYMLINK ---
ln -sfn "$SRC_FONT_PICKER" "$FISH_FUNCS/font-picker.fish"
echo "Linked font-picker -> $FISH_FUNCS/font-picker.fish"
ln -sfn "$SRC_DEV" "$FISH_FUNCS/dev.fish"
echo "Linked dev -> $FISH_FUNCS/dev.fish"

# --- Check tmux is installed ---
if ! command -v tmux >/dev/null 2>&1; then
    echo ""
    echo "WARNING: tmux not installed. Install it with:"
    echo "  sudo apt install tmux"
fi

# --- Validate the deployed Ghostty config ---
if command -v ghostty >/dev/null 2>&1; then
    if ghostty +validate-config --config-file="$GHOSTTY_DST/config" >/dev/null 2>&1; then
        echo "Ghostty config validates clean."
    else
        echo "WARNING: ghostty +validate-config reported errors:"
        ghostty +validate-config --config-file="$GHOSTTY_DST/config" || true
    fi
fi

cat <<'MSG'

Next steps:
  1. Install tmux if not present:  sudo apt install tmux
  2. Open Ghostty and run:  dev
     -> splits into claude (left) and nushell (right) automatically.
  3. Run `font-picker` to change the Ghostty font (zenity list + live reload).
  4. Reload Ghostty config: ctrl+shift+,  (or: pkill -SIGUSR2 ghostty)
MSG
