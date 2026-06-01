#!/usr/bin/env bash
# install.sh - deploy Ghostty config + fish font-picker for this repo.
# Idempotent and safe to re-run. Copies the config (so the font-picker's
# in-place sed edits never mutate tracked repo files); symlinks only the
# never-mutated fish function so `git pull` propagates function updates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC_CONFIG="$REPO_ROOT/configs/ghostty/config"
SRC_FUNC="$REPO_ROOT/scripts/font-picker.fish"

GHOSTTY_DST="$HOME/.config/ghostty"
FISH_FUNCS="$HOME/.config/fish/functions"
DST_CONFIG="$GHOSTTY_DST/config"
DST_FUNC="$FISH_FUNCS/font-picker.fish"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$GHOSTTY_DST" "$FISH_FUNCS"

# --- Ghostty config: COPY (never symlink; font-picker sed would clobber it) ---
deploy_config() {
    if [ -e "$DST_CONFIG" ] || [ -L "$DST_CONFIG" ]; then
        if [ -L "$DST_CONFIG" ] || [ "$FORCE" -eq 1 ]; then
            cp -p "$DST_CONFIG" "$DST_CONFIG.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
            rm -f "$DST_CONFIG"
            cp "$SRC_CONFIG" "$DST_CONFIG"
            echo "Replaced existing config (backup saved)."
        else
            echo "Config already present at $DST_CONFIG (kept your font choice)."
            echo "Re-run with --force to overwrite (a backup will be made)."
        fi
    else
        cp "$SRC_CONFIG" "$DST_CONFIG"
        echo "Installed config -> $DST_CONFIG"
    fi
}
deploy_config

# --- Fish font-picker function: SYMLINK (immutable, so propagation is fine) ---
ln -sfn "$SRC_FUNC" "$DST_FUNC"
echo "Linked font-picker -> $DST_FUNC"

# --- Validate the deployed config ---
if command -v ghostty >/dev/null 2>&1; then
    if ghostty +validate-config --config-file="$DST_CONFIG" >/dev/null 2>&1; then
        echo "Config validates clean."
    else
        echo "WARNING: ghostty +validate-config reported errors:"
        ghostty +validate-config --config-file="$DST_CONFIG" || true
    fi
fi

cat <<'EOF'

Next steps:
  1. Open (or restart) Ghostty.
  2. Left pane: run `claude`.
  3. Press ctrl+alt+d to open a right split; run `fish` then `nu` there.
  4. Run `font-picker` to change the font (zenity list + live reload).
  5. Reload config manually anytime: ctrl+shift+,  (or: pkill -SIGUSR2 ghostty)
EOF
