# ghostty-config-files — Agent Instructions

This is a minimal Ghostty terminal config repo. Keep it simple.

## What this repo contains

- `configs/ghostty/config` — single Ghostty config file (no modular split)
- `scripts/font-picker.fish` — fish font picker function
- `scripts/install.sh` / `uninstall.sh` — deploy/remove scripts
- `configs/ghostty/catppuccin-mocha.conf` — Mocha palette reference (not deployed)

## Rules

- Do NOT split the Ghostty config back into modular files.
- Do NOT add blur (`background-blur`) — it crashes Ghostty on Linux.
- Do NOT set `scrollback-limit` above 50000.
- Do NOT add `config-reload-on-focus-in` — it is not a valid Ghostty 1.3.1 option and fails validation.
- Do NOT create new `.sh` scripts; extend install.sh / uninstall.sh instead.
- NEVER commit directly to main — use a timestamped branch `YYYYMMDD-HHMMSS-description`.
- Keep `CLAUDE.md` and `GEMINI.md` as symlinks to this file. Never overwrite them with regular files.

## Validate before committing

```bash
ghostty +validate-config --config-file=configs/ghostty/config   # must exit 0
shellcheck scripts/install.sh scripts/uninstall.sh
```

## User context

- Shell: fish (primary), nushell (secondary). No zsh.
- Terminal: Ghostty 1.3.1 on Ubuntu 26.04.
- Left split: `claude` (Claude Code). Right split: `fish` → `nu`.
- Font picker: `font-picker` fish function (zenity + SIGUSR2 reload).

## tmux integration

- `configs/tmux/tmux.conf` — minimal tmux config for use inside Ghostty
- `scripts/dev.fish` — fish function that creates the dev layout (claude left, nu right)
- tmux is installed via `sudo apt install tmux` (not managed by this repo)
- Status bar is intentionally OFF (`set -g status off`) — do not re-enable
- Pane borders use Catppuccin Mocha surface0 (#313244) and mauve (#cba6f7)
- Do NOT configure tmux splits inside Ghostty native splits — choose one layer only
