---
title: Installation Guide
description: Complete guide to installing the Ghostty Configuration Files project
---

# Installation Guide

This guide walks you through installing the Ghostty Configuration Files project on a fresh Ubuntu system.

## Prerequisites

### System Requirements

- **Operating System**: Ubuntu 25.10 (Questing) or compatible Linux distribution
- **Git**: Must be installed
- **Internet**: Required for downloading packages

### Passwordless Sudo (Recommended)

For automated installation, configure passwordless sudo for apt:

```bash
# Open sudoers file
sudo visudo

# Add this line (replace 'username' with your actual username)
username ALL=(ALL) NOPASSWD: /usr/bin/apt
```

**Why?** This enables:
- Automated daily updates
- Non-interactive installation
- Seamless tool installation

**Alternative**: Run with interactive password prompts (not recommended for automation).

## Quick Start

```bash
# Clone the repository
git clone https://github.com/kairin/ghostty-config-files.git

# Enter the directory
cd ghostty-config-files

# Run the installer
./start.sh
```

## TUI Installer

The installer provides a modern terminal user interface (TUI) with:

- **Parallel status checks** - See tool status in real-time
- **Crash recovery** - Resume from where you left off
- **Boot diagnostics** - Detect and fix system issues
- **Selective installation** - Install only what you need

### Navigation

| Key | Action |
|-----|--------|
| `↑/↓` or `j/k` | Navigate menu items |
| `Enter` | Select/confirm |
| `Space` | Toggle selection |
| `q` | Quit |
| `?` | Help |

## What Gets Installed

The TUI offers installation of 11+ tools:

| Tool | Description | Time |
|------|-------------|------|
| **Ghostty** | Modern terminal emulator | 2-5 min |
| **ZSH + Oh My ZSH** | Modern shell with plugins | 1-2 min |
| **Go** | Programming language (for TUI) | 1 min |
| **Node.js** | JavaScript runtime (via fnm) | 1 min |
| **NerdFonts** | Icon fonts for terminal | 1-2 min |
| **gum** | TUI form components | <1 min |
| **glow** | Markdown viewer | <1 min |
| **vhs** | Terminal recorder | <1 min |
| **feh** | Image viewer | 1-2 min |
| **fastfetch** | System info display | <1 min |
| **Python + uv** | Python with fast package manager | 1-2 min |
| **AI Tools** | Claude Code, Gemini CLI | 1-2 min |

## Post-Installation

### Verify Installation

```bash
# Check Ghostty configuration
ghostty +show-config

# Launch the TUI again to verify status
./start.sh
```

### Configure Daily Updates

Install the cron job for automatic updates:

```bash
./scripts/daily-updates.sh --install-cron
```

This schedules updates to run daily at 9:00 AM.

### Set Default Shell

If you installed ZSH:

```bash
# Set ZSH as default shell
chsh -s $(which zsh)

# Log out and back in, or start a new terminal
```

## Ghostty Installation Methods

The project supports two methods for installing Ghostty:

### Build from Source (Default)

- Compiles the latest stable release
- Requires Zig compiler (auto-installed)
- Takes 2-5 minutes
- Best for latest features

### Snap Package (Alternative)

- Pre-built official package
- Takes 30-60 seconds
- Automatic updates via Snap store

To use Snap instead:

```bash
# Skip the TUI and install via Snap directly
snap install ghostty --classic
```

## Troubleshooting

### Installation Fails

1. Check the log files:
   ```bash
   ls -lt scripts/006-logs/ | head -10
   cat scripts/006-logs/<latest-file>.log
   ```

2. Verify internet connectivity

3. Ensure sudo is configured correctly:
   ```bash
   sudo -n apt update  # Should not prompt for password
   ```

### Icons Missing

If you see boxes (□) instead of icons:

1. Ensure NerdFonts are installed
2. Configure your terminal to use a Nerd Font
3. See: [Icon Troubleshooting](/.claude/instructions-for-agents/guides/troubleshooting-icons.md)

### Ghostty Build Fails

If build-from-source fails:

1. Check the log: `scripts/006-logs/*ghostty*.log`
2. Ensure system packages are updated: `sudo apt update && sudo apt upgrade`
3. Try the Snap alternative: `snap install ghostty --classic`

## Next Steps

- [Configuration Guide](./configuration.md) - Customize your setup
- [Boot Diagnostics](../../README.md#boot-diagnostics) - Fix system issues
- [Daily Updates](../../scripts/DAILY_UPDATES_README.md) - Automated updates
