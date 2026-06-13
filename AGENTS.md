# ghostty-config-files — Agent Instructions

This is a minimal Ghostty terminal config repo. Keep it simple.

## What this repo contains

- `configs/ghostty/config` — single Ghostty config file (no modular split)
- `configs/tmux/tmux.conf` — minimal tmux config (window hint status bar, Mocha pane borders, mouse on)
- `configs/fish/config.fish` — fish interactive env (PATH, fnm, bun, uv/gum/glow completions, fzf, zoxide, starship, mcp-secrets shim)
- `configs/starship/starship.toml` — Catppuccin Mocha prompt (replaces the old powerlevel10k zsh prompt)
- `scripts/font-picker.fish` — fish font picker function
- `scripts/dev.fish` — fish function that toggles the `og-tools` tmux session (`claude`, `codex`, `agy`; rooted in `~/Apps/OG-tools`)
- `scripts/install.sh` / `uninstall.sh` — deploy/remove scripts (install.sh also sets up the fish shell env; `--no-shell` skips that)
- `configs/ghostty/catppuccin-mocha.conf` — Mocha palette reference (not deployed)

## Rules

- Do NOT split the Ghostty config back into modular files.
- Keep EXACTLY ONE unquoted `font-family =` line in `configs/ghostty/config`. font-picker.fish replaces it via `sed` on `^font-family`; a second line or a quoted value breaks font selection.
- Do NOT add blur (`background-blur`) — it crashes Ghostty on Linux.
- Do NOT set `scrollback-limit` above 50000.
- Do NOT add `config-reload-on-focus-in` — it is not a valid Ghostty 1.3.1 option and fails validation.
- Do NOT create new `.sh` scripts; extend install.sh / uninstall.sh instead.
- `configs/fish/config.fish` and `configs/starship/starship.toml` are SYMLINKED into `~/.config` by install.sh (like the tmux/fish-function symlinks) so `git pull` propagates updates. Never store secrets in them.
- NEVER put secrets in the repo. `~/.mcp-secrets` is bash-syntax, machine-local, synced out-of-band; config.fish only parses it at startup.
- NEVER commit directly to main — use a timestamped branch `YYYYMMDD-HHMMSS-description`.
- Keep `CLAUDE.md` and `GEMINI.md` as symlinks to this file. Never overwrite them with regular files.

## Validate before committing

```bash
ghostty +validate-config --config-file=configs/ghostty/config   # must exit 0
shellcheck scripts/install.sh scripts/uninstall.sh
```

shellcheck applies only to the `.sh` scripts; the `.fish` files (`config.fish`, `font-picker.fish`, `dev.fish`) are not shellcheck-compatible — sanity-check them with `fish --no-execute configs/fish/config.fish` instead.

## User context

- Shell: fish (primary), nushell (secondary). No zsh. Prompt: starship (Catppuccin Mocha), replacing the old powerlevel10k zsh setup.
- Shell env lives in `configs/fish/config.fish`: PATH (`~/.local/bin`, `~/.bun/bin`), `fnm --use-on-cd`, bun, uv/gum/glow completions, fzf, zoxide (`z`), starship, and a parser for the machine-local bash-syntax `~/.mcp-secrets`.
- `install.sh` installs fish + zoxide (apt) and starship (userspace `~/.local/bin`), then offers `chsh` to fish. Tolerant of no-sudo / non-interactive runs (warns, never hangs).
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

## Codacy gate — cloud CLI (`codacy`)

The `codacy` cloud CLI (binary `codacy`, distinct from the local analyzer
`codacy-cli`) reads `CODACY_API_TOKEN`, which `.envrc.local` exports via direnv —
there is **no `codacy login`**. Always run it through direnv so the token loads:

```bash
direnv exec /home/kkk/Apps/ghostty-config-files codacy pr gh kairin ghostty-config-files <PR#> --diff
```

To unblock a failing Codacy PR gate in one pass: pull the `--diff`-scoped issues,
fix the real ones, add any tests they need, dismiss false positives with a logged
reason (append `--ignore-all-false-positives`), then re-run the scan before merging.
Never run bare `codacy` from `/home/kkk/Apps` (workspace root) — direnv has not
loaded the token there and it fails with `No API token found`.
