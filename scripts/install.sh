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
SRC_FISH_FUNCS_DIR="$REPO_ROOT/configs/fish/functions"
SRC_FISH_CONFIG="$REPO_ROOT/configs/fish/config.fish"
SRC_STARSHIP="$REPO_ROOT/configs/starship/starship.toml"

GHOSTTY_DST="$HOME/.config/ghostty"
TMUX_DST="$HOME/.config/tmux"
FISH_DIR="$HOME/.config/fish"
FISH_FUNCS="$FISH_DIR/functions"
FISH_CONFIG_DST="$FISH_DIR/config.fish"
STARSHIP_DST="$HOME/.config/starship.toml"

FORCE=0
SETUP_SHELL=1
for arg in "$@"; do
    case "$arg" in
        --force)    FORCE=1 ;;
        --no-shell) SETUP_SHELL=0 ;;  # skip fish/starship/shell-env setup
        *) echo "Unknown option: $arg (use --force and/or --no-shell)"; exit 2 ;;
    esac
done

# Non-interactive if stdin is not a TTY (CI, piped, background agents): never
# block on a prompt and never trigger an interactive sudo password request.
NONINTERACTIVE=0
[ -t 0 ] || NONINTERACTIVE=1

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

# Tab-title engine: fish_title + apt-Section emoji resolver (__app_icon,
# __app_section_icon). Symlinked so `git pull` propagates updates.
for fn in fish_title __app_icon __app_section_icon; do
    ln -sfn "$SRC_FISH_FUNCS_DIR/$fn.fish" "$FISH_FUNCS/$fn.fish"
    echo "Linked $fn -> $FISH_FUNCS/$fn.fish"
done

# Friendly per-machine label for the SSH tab title (e.g. "DGX"). Seed it with the
# short hostname if absent; edit ~/.host-label to taste. Never tracked by the repo.
if [ ! -e "$HOME/.host-label" ] && [ ! -L "$HOME/.host-label" ]; then
    _hl="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo localhost)"
    if printf '%s\n' "$_hl" > "$HOME/.host-label" 2>/dev/null; then
        echo "Seeded ~/.host-label -> $_hl (edit to taste)"
    else
        echo "NOTE: could not seed ~/.host-label - create it manually if desired."
    fi
fi

# --- Fish shell environment (fish + starship + zoxide, config, default shell) -
# Honors the repo's "fish primary, no zsh" standard. Idempotent. Tolerant of
# missing sudo / non-interactive runs (warns instead of failing or hanging).
setup_shell() {
    # 1. System packages via apt (need sudo). Warn-don't-fail if unavailable.
    local missing=()
    command -v fish   >/dev/null 2>&1 || missing+=("fish")
    command -v zoxide >/dev/null 2>&1 || missing+=("zoxide")
    if [ "${#missing[@]}" -gt 0 ]; then
        if [ "$NONINTERACTIVE" -eq 0 ] || sudo -n true 2>/dev/null; then
            echo "Installing via apt: ${missing[*]}"
            sudo apt-get update -qq || true
            sudo apt-get install -y "${missing[@]}" \
                || echo "WARNING: apt install failed - run: sudo apt install ${missing[*]}"
        else
            echo "WARNING: missing ${missing[*]} - run: sudo apt install ${missing[*]}"
        fi
    fi

    # 2. Starship prompt (userspace install -> ~/.local/bin, no sudo).
    if ! command -v starship >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/starship" ]; then
        if command -v curl >/dev/null 2>&1; then
            echo "Installing starship -> $HOME/.local/bin"
            mkdir -p "$HOME/.local/bin"
            curl -sS https://starship.rs/install.sh \
                | sh -s -- --yes --bin-dir "$HOME/.local/bin" \
                || echo "WARNING: starship install failed - see https://starship.rs"
        else
            echo "WARNING: curl not found - install starship manually: https://starship.rs"
        fi
    fi

    # 3. Symlink shell configs so 'git pull' propagates updates.
    ln -sfn "$SRC_FISH_CONFIG" "$FISH_CONFIG_DST"
    echo "Linked fish config -> $FISH_CONFIG_DST"
    ln -sfn "$SRC_STARSHIP" "$STARSHIP_DST"
    echo "Linked starship config -> $STARSHIP_DST"

    # 4. Make fish a valid login shell and offer to set it as default.
    local fish_bin
    fish_bin="$(command -v fish || true)"
    if [ -z "$fish_bin" ]; then
        echo "NOTE: fish not installed yet - install it, then re-run to set the default shell."
        return
    fi
    if ! grep -qxF "$fish_bin" /etc/shells 2>/dev/null; then
        echo "$fish_bin" | sudo tee -a /etc/shells >/dev/null 2>&1 \
            && echo "Added $fish_bin to /etc/shells" \
            || echo "NOTE: add $fish_bin to /etc/shells (needs sudo) before chsh."
    fi
    if [ "${SHELL:-}" != "$fish_bin" ]; then
        if [ "$NONINTERACTIVE" -eq 0 ]; then
            read -rp "Set fish as your default login shell now? [y/N] " ans
            case "$ans" in
                [Yy]*) chsh -s "$fish_bin" \
                        && echo "Default shell set to fish (log out/in to apply)." \
                        || echo "chsh failed - run it yourself: chsh -s $fish_bin" ;;
                *) echo "Skipped. To switch later:  chsh -s $fish_bin" ;;
            esac
        else
            echo "To make fish your default shell:  chsh -s $fish_bin"
        fi
    fi
}
if [ "$SETUP_SHELL" -eq 1 ]; then
    setup_shell
else
    echo "Skipped fish/starship/shell-env setup (--no-shell)."
fi

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
  2. If fish was just installed, set it as your default shell:  chsh -s $(command -v fish)
     then log out/in. Start a new fish shell to load config.fish (starship prompt,
     fnm/bun/uv/gum/glow completions, zoxide `z`, and ~/.mcp-secrets if present).
  3. Open Ghostty and run:  dev
     -> toggles the og-tools tmux session: claude (claude/fish), codex, agy.
        Run `dev` again to detach, `dev` to reattach, `dev reset` to rebuild.
  4. Run `font-picker` to change the Ghostty font (zenity list + live reload).
  5. Reload Ghostty config: ctrl+shift+,  (or: pkill -SIGUSR2 ghostty)
MSG
