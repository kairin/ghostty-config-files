# ghostty-config-files

Ghostty terminal config for a Fish + Nushell + Claude Code workflow on Ubuntu.

## What's included

- `configs/ghostty/config` — single consolidated Ghostty config (Catppuccin Mocha, 80% opacity, no blur)
- `configs/ghostty/catppuccin-mocha.conf` — Mocha palette reference (not deployed to `~/.config/ghostty/`)
- `scripts/font-picker.fish` — fish function to pick a Nerd Font via zenity with live reload
- `scripts/install.sh` — deploys config + installs the fish function
- `scripts/uninstall.sh` — reverses install, restores backup

## Setup

```bash
git clone https://github.com/kairin/ghostty-config-files.git ~/Apps/ghostty-config-files
cd ~/Apps/ghostty-config-files
./scripts/install.sh
```

Re-run with `--force` to overwrite an existing config (a timestamped backup is made).

## Daily workflow

| Action | How |
|--------|-----|
| Open Claude Code (left pane) | `claude` |
| Open right split | `ctrl+alt+d` |
| Launch nushell in right pane | `fish` → `nu` |
| Navigate between splits | `ctrl+alt+left` / `ctrl+alt+right` |
| Pick a different font | `font-picker` (zenity list) |
| Reload config | `ctrl+shift+,` or `pkill -SIGUSR2 ghostty` |
| New tab | `ctrl+shift+t` |

## Installed Nerd Fonts

FiraCode · Hack · JetBrainsMono · JetBrainsMonoNL · MesloLGL · MesloLGM · MesloLGS

## Validate config

```bash
ghostty +validate-config --config-file=configs/ghostty/config
```

Expected: clean exit (0), no errors.
