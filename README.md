# ghostty-config-files

Ghostty terminal config for a Fish + Nushell + Claude Code workflow on Ubuntu.
Uses tmux inside Ghostty for scripted split layout (claude left, nushell right).

## What's included

- `configs/ghostty/config` — single consolidated Ghostty config (Catppuccin Mocha, 80% opacity, no blur)
- `configs/ghostty/catppuccin-mocha.conf` — Mocha palette reference (not deployed to `~/.config/ghostty/`)
- `configs/tmux/tmux.conf` — minimal tmux config (no status bar, Mocha pane borders, mouse on)
- `scripts/dev.fish` — fish function: run `dev` to launch the split layout automatically
- `scripts/font-picker.fish` — fish function to pick a Nerd Font via zenity with live reload
- `scripts/install.sh` — deploys all configs + installs fish functions
- `scripts/uninstall.sh` — reverses install, restores backup

## Setup

```bash
sudo apt install tmux
git clone https://github.com/kairin/ghostty-config-files.git ~/Apps/ghostty-config-files
cd ~/Apps/ghostty-config-files
./scripts/install.sh
```

Re-run with `--force` to overwrite an existing Ghostty config (a timestamped backup is made).

## Daily workflow

Open Ghostty and type:

```
dev
```

This launches tmux inside Ghostty and automatically creates:

```
┌─────────────────────┬──────────────────┐
│   claude (left)     │   nushell (right)│
│   50%               │   50%            │
└─────────────────────┴──────────────────┘
```

| Action | How |
|--------|-----|
| Launch dev layout | `dev` |
| Navigate splits | mouse click or tmux prefix + arrow |
| Pick a different font | `font-picker` (zenity list) |
| Reload Ghostty config | `ctrl+shift+,` or `pkill -SIGUSR2 ghostty` |
| New Ghostty tab | `ctrl+shift+t` |

## How it works

tmux runs inside Ghostty as a process. Ghostty handles the window/tabs/opacity;
tmux handles the splits and scripted layout. The status bar is hidden (`set -g status off`)
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
