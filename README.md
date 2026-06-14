# ghostty-config-files

Ghostty terminal config for a Fish + Nushell + AI coding workflow on Ubuntu.
Uses tmux inside Ghostty for a scripted dev workspace.

## What's included

- `configs/ghostty/config` — single consolidated Ghostty config (Catppuccin Mocha, 80% opacity, no blur)
- `configs/ghostty/catppuccin-mocha.conf` — Mocha palette reference (not deployed to `~/.config/ghostty/`)
- `configs/tmux/tmux.conf` — minimal tmux config (window hint status bar, Mocha pane borders, mouse on)
- `configs/fish/config.fish` — fish interactive env: PATH, fnm, bun, uv/gum/glow completions, fzf, zoxide (`z`), starship, and a `~/.mcp-secrets` parser
- `configs/starship/starship.toml` — Catppuccin Mocha prompt (replaces powerlevel10k)
- `configs/fish/functions/` — tab-title engine: `🌐 <label> 📁 <path> <icon> <cmd>` (host shown only over SSH; `<label>` from machine-local `~/.host-label`, e.g. `DGX`). The per-command emoji is derived from the command's apt `Section` (cached per session, small override list for non-apt tools)
- `scripts/dev.fish` — fish function: `dev` toggles the `og-tools` tmux session (`claude`/`codex`/`agy`, rooted in `~/Apps/OG-tools`)
- `scripts/font-picker.fish` — fish function to pick a Nerd Font via zenity with live reload
- `scripts/install.sh` — deploys all configs, installs fish functions, and sets up the fish shell env (`--no-shell` skips the shell setup)
- `scripts/uninstall.sh` — reverses install, restores backup

## Setup

```bash
sudo apt install tmux
git clone https://github.com/kairin/ghostty-config-files.git ~/Apps/ghostty-config-files
cd ~/Apps/ghostty-config-files
./scripts/install.sh
```

`install.sh` deploys the Ghostty/tmux/fish configs and sets up the fish shell environment:
it installs **fish** + **zoxide** (`sudo apt`) and **starship** (userspace `~/.local/bin`),
symlinks `config.fish`/`starship.toml` into `~/.config`, and offers to `chsh` to fish.
It is idempotent and degrades gracefully without sudo (it warns instead of failing).
Pass `--no-shell` to deploy only the Ghostty/tmux configs. Re-run with `--force` to
overwrite an existing Ghostty config (a timestamped backup is made).

### Shell environment & secrets

`config.fish` is symlinked into `~/.config/fish/`, so `git pull` keeps every machine in sync.
It loads `~/.mcp-secrets` if present — a **machine-local**, bash-syntax (`export KEY=VALUE`)
file synced out-of-band and **never committed** to this repo (fish parses its `export`
lines natively). After install, set fish as your login shell and re-login:

```bash
chsh -s "$(command -v fish)"
```

## Daily workflow

Open Ghostty and type:

```
dev
```

`dev` is a **toggle**:

- First `dev` (in a plain terminal) builds the session and attaches.
- `dev` again while attached **detaches** — the panes keep running in the background and you drop back to the normal terminal.
- `dev` once more **reattaches** to the same session, exactly as you left it.
- `dev reset` tears the session down and rebuilds it fresh (new `claude`/`codex`/`agy`).

It launches tmux inside Ghostty and creates the `og-tools` session (all panes rooted in `~/Apps/OG-tools`):

```
tmux session: og-tools

1:claude
┌────────────────────────────────────────┬────────────────────┐
│ claude                                 │ fish               │
└────────────────────────────────────────┴────────────────────┘

2:codex
┌─────────────────────────────────────────────────────────────┐
│ codex                                                       │
└─────────────────────────────────────────────────────────────┘

3:agy
┌─────────────────────────────────────────────────────────────┐
│ agy                                                         │
└─────────────────────────────────────────────────────────────┘
```

| Action | How |
|--------|-----|
| Launch / reattach dev workspace | `dev` |
| Detach (hide) dev workspace | `dev` again while attached |
| Rebuild dev workspace from scratch | `dev reset` |
| Navigate splits | mouse click or tmux prefix + arrow |
| List tmux windows | tmux prefix + `w` |
| Switch tmux windows | tmux prefix + `1`, `2`, or `3` |
| Pick a different font | `font-picker` (zenity list) |
| Reload Ghostty config | `ctrl+shift+,` or `pkill -SIGUSR2 ghostty` |
| New Ghostty tab | `ctrl+shift+t` |

## How it works

tmux runs inside Ghostty as a process. Ghostty handles the window/tabs/opacity;
tmux handles the splits and scripted layout. The status bar shows window switching hints,
and pane borders use Catppuccin Mocha surface colors so it looks clean.

## Installed Nerd Fonts

Run `font-picker` to see the live list — it reads `fc-list` directly. On this machine the base families are FiraCode, Hack, JetBrainsMono, JetBrainsMonoNL, MesloLGL, MesloLGLDZ, MesloLGM, MesloLGMDZ, MesloLGS, MesloLGSDZ (each also offered as 'Nerd Font Mono' and 'Nerd Font Propo' variants).

## Validate config

```bash
ghostty +validate-config --config-file=configs/ghostty/config
```

Expected: clean exit (0), no errors.

## tmux version

The apt package (`sudo apt install tmux`) provides **3.6a**. The latest GitHub release is **3.6b** (bugfix update). To install 3.6b from source:

```bash
sudo apt install libevent-dev bison build-essential
cd /tmp
wget https://github.com/tmux/tmux/releases/download/3.6b/tmux-3.6b.tar.gz
tar xzf tmux-3.6b.tar.gz && cd tmux-3.6b
./configure --prefix=/usr/local && make -j$(nproc) && sudo make install
tmux -V   # should print: tmux 3.6b
```

Either version works with this config.
