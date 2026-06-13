# config.fish — managed-by: ghostty-config-files
# Interactive shell environment for the Fish-primary workflow.
# Symlinked to ~/.config/fish/config.fish by scripts/install.sh, so `git pull`
# propagates changes. Mirrors the env this repo's machines previously kept in
# ~/.zshrc (Oh My Zsh + powerlevel10k), now ported to fish + starship.
#
# Everything here is guarded with `type -q` so a machine missing a given tool
# still starts a clean shell. No secrets live in this file (see mcp-secrets below).

# --- PATH ---------------------------------------------------------------------
# fish_add_path is idempotent; earlier args take precedence (end up first).
fish_add_path $HOME/.local/bin $HOME/.bun/bin

# --- bun ----------------------------------------------------------------------
set -gx BUN_INSTALL $HOME/.bun
# (bun installs its own fish completions into ~/.config/fish/completions)

# --- fnm (Fast Node Manager) --------------------------------------------------
if type -q fnm
    fnm env --use-on-cd | source
end

# --- Tool completions ---------------------------------------------------------
if type -q uv
    uv generate-shell-completion fish | source
end
if type -q gum
    gum completion fish | source
end
if type -q glow
    glow completion fish | source
end

# --- fzf (Ctrl+R history, Ctrl+T files) — fzf >= 0.48 -------------------------
if type -q fzf
    fzf --fish | source
end

# --- zoxide (replaces the old zsh `z` plugin; provides `z` / `zi`) ------------
if type -q zoxide
    zoxide init fish | source
end

# --- Starship prompt (replaces powerlevel10k; cross-shell) --------------------
if type -q starship
    starship init fish | source
end

# --- MCP secrets --------------------------------------------------------------
# ~/.mcp-secrets is bash syntax (`export KEY=VALUE`) and is synced between
# machines out-of-band. It is NEVER committed to this repo. Fish cannot `source`
# bash export syntax, so parse the export lines and re-export them natively.
if test -f "$HOME/.mcp-secrets"
    for line in (grep -E '^[[:space:]]*export[[:space:]]' "$HOME/.mcp-secrets")
        set -l kv (string replace -r '^[[:space:]]*export[[:space:]]+' '' -- $line)
        set -l parts (string split -m1 '=' -- $kv)
        if test (count $parts) -eq 2
            set -gx $parts[1] (string trim --chars=\"\' -- $parts[2])
        end
    end
end
