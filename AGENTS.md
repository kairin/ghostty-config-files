# ghostty-config-files — Agent Instructions

This is a minimal Ghostty terminal config repo. Keep it simple.

## What this repo contains

- `configs/ghostty/config` — single Ghostty config file (no modular split)
- `configs/tmux/tmux.conf` — minimal tmux config (window hint status bar, Mocha pane borders, mouse on)
- `scripts/font-picker.fish` — fish font picker function
- `scripts/dev.fish` — fish function that toggles the `og-tools` tmux session (`claude`, `codex`, `agy`; rooted in `~/Apps/OG-tools`)
- `scripts/install.sh` / `uninstall.sh` — deploy/remove scripts
- `configs/ghostty/catppuccin-mocha.conf` — Mocha palette reference (not deployed)

## Rules

- Do NOT split the Ghostty config back into modular files.
- Keep EXACTLY ONE unquoted `font-family =` line in `configs/ghostty/config`. font-picker.fish replaces it via `sed` on `^font-family`; a second line or a quoted value breaks font selection.
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

shellcheck applies only to the `.sh` scripts; the `.fish` functions (`font-picker.fish`, `dev.fish`) are not shellcheck-compatible.

## User context

- Shell: fish (primary), nushell (secondary). No zsh.
- Terminal: Ghostty 1.3.1 on Ubuntu 26.04.
- tmux dev session `og-tools` (rooted in `~/Apps/OG-tools`): `claude` window has `claude` left and `fish` right; `codex` window runs `codex`; `agy` window runs `agy`.
- `dev` is a toggle: outside tmux it attaches (creating the session first if needed); inside tmux it `detach-client`s so the session keeps running in the background. `dev reset` kills the session and rebuilds it fresh.
- Font picker: `font-picker` fish function (zenity + SIGUSR2 reload).

## tmux integration

- `configs/tmux/tmux.conf` — minimal tmux config for use inside Ghostty
- `scripts/dev.fish` — fish function that toggles the `og-tools` session (rooted in `~/Apps/OG-tools`): `claude` (claude/fish split), `codex`, `agy`. Attach/detach on repeat; `dev reset` rebuilds. Run `dev reset` from outside tmux or a status-bar `run-shell` binding — not from a pane inside the session it is killing.
- tmux is installed via `sudo apt install tmux` (not managed by this repo)
- Status bar is intentionally minimal and shows window-switching hints.
- Pane borders use Catppuccin Mocha surface0 (#313244) and mauve (#cba6f7)
- Do NOT configure tmux splits inside Ghostty native splits — choose one layer only
