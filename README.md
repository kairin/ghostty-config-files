# Ghostty Configuration Files

> ## ARCHIVED
>
> This repository has been **archived**. All content has been migrated to [000-dotfiles](https://github.com/kairin/000-dotfiles).
>
> **Reason**: Ghostty 1.3.0 exhibited multiple stability issues (rendering artifacts, crashes, input lag). Migrated to a general development environment setup without terminal-specific dependencies.
>
> **New Repository**: https://github.com/kairin/000-dotfiles

---

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-25.10+-E95420?logo=ubuntu)](https://ubuntu.com/)
[![Ghostty](https://img.shields.io/badge/Ghostty-v1.2.3+-purple)](https://ghostty.org/)

A comprehensive terminal environment setup featuring Ghostty terminal emulator with performance optimizations, AI tools integration, and automated system maintenance.

## Quick Start

```bash
git clone https://github.com/kairin/ghostty-config-files.git
cd ghostty-config-files
./start.sh
```

## Features

- **Modern Go TUI** - Bubbletea-powered dashboard with parallel status checks and crash recovery
- **Ghostty Terminal v1.2.3+** - Build-from-source (default) or Snap installation with CGroup optimization
- **Dynamic Theme Switching** - Automatic light/dark mode with Catppuccin themes
- **Boot Diagnostics** - Automated detection and one-click fixes for system boot issues
- **AI Integration** - Claude Code, Gemini CLI with fnm Node.js management, Context7 & GitHub MCP
- **Charm TUI** - gum, glow, vhs for beautiful terminal interfaces
- **ZSH + Oh My ZSH** - Modern shell with PowerLevel10k support
- **Automated Updates** - Daily updates at 9 AM with comprehensive logging
- **Context Menu** - "Open in Ghostty" right-click integration
- **Local CI/CD** - Zero-cost local workflow execution before GitHub deployment
- **Astro Website** - Documentation site deployed to GitHub Pages

## Prerequisites

- Ubuntu 25.10 (Questing) or compatible Linux distribution
- Git installed
- Passwordless sudo for apt: `sudo visudo` → add `username ALL=(ALL) NOPASSWD: /usr/bin/apt`

## Terminal Compatibility

The TUI dashboard uses **Nerd Font icons** for visual elements. Any terminal emulator with Nerd Font support will work:

| Terminal | Nerd Font Setup |
|----------|-----------------|
| **Ghostty** | Configured automatically by this project |
| **Ptyxis** (GNOME 49+) | Settings → Font → Select any Nerd Font (e.g., JetBrainsMonoNL NF) |
| **GNOME Terminal** | Preferences → Profiles → Custom font → Select Nerd Font |
| **Kitty/Alacritty** | Configure in respective config files |

**Without Nerd Fonts**: The dashboard will show missing glyphs (□) but functionality remains intact.

**Recommended fonts**: JetBrainsMono Nerd Font, FiraCode Nerd Font, or any font from [nerdfonts.com](https://www.nerdfonts.com/).

## Boot Diagnostics

Automated system health checker that detects and fixes common boot issues:

```bash
# Access via main menu
./start.sh  # Select "Boot Diagnostics"

# Or run directly
./scripts/007-diagnostics/quick_scan.sh count    # Quick issue count
./scripts/007-diagnostics/boot_diagnostics.sh   # Full TUI interface
```

**Detects**: Orphaned services, unsupported snaps, network wait issues, failed services, cosmetic warnings.

## Commands

### Installation & Updates

```bash
./start.sh              # Main TUI - install, configure, update
update-all              # Run all updates interactively
update-check            # Check for available updates
update-logs             # View latest update summary
```

### Automated Daily Updates

Install cron job for daily updates at 9:00 AM:

```bash
./scripts/daily-updates.sh --install-cron
```

Or run updates manually with options:

```bash
./scripts/daily-updates.sh                 # Interactive mode
./scripts/daily-updates.sh --dry-run       # Check only, no changes
./scripts/daily-updates.sh --non-interactive  # For cron/automation
```

See [Daily Updates README](scripts/DAILY_UPDATES_README.md) for full documentation.

### Website Development

```bash
cd astro-website
npm run dev             # Start dev server (localhost:4321)
npm run build           # Build to docs/ for GitHub Pages
npm run check           # TypeScript validation
npm run preview         # Preview production build
```

### System Cleanup

```bash
sudo ./scripts/remove_libreoffice.sh  # Remove LibreOffice (~700-800 MB freed)
```

## Documentation

### For Users
- [Daily Updates](scripts/DAILY_UPDATES_README.md) - Automated update system
- [Icon Troubleshooting](.claude/instructions-for-agents/guides/troubleshooting-icons.md) - Missing icons, GTK resolution, Ubuntu 25.10 fixes

### For Developers
- [System Architecture](.claude/instructions-for-agents/architecture/system-architecture.md) - Complete architecture overview
- [PowerLevel10k Integration](astro-website/src/developer/powerlevel10k/README.md) - ZSH prompt theme
- [Context7 MCP Setup](.claude/instructions-for-agents/guides/context7-mcp.md) - AI documentation server
- [GitHub MCP Setup](.claude/instructions-for-agents/guides/github-mcp.md) - GitHub integration
- [Contributing Guide](.github/CONTRIBUTING.md) - Development workflow

### Live Documentation
- [GitHub Pages Site](https://kairin.github.io/ghostty-config-files/)

## Project Structure

```
ghostty-config-files/
├── start.sh                    # Main entry point (Go TUI launcher)
├── configs/ghostty/            # Ghostty configuration & themes
├── scripts/
│   ├── 002-install-first-time/ # Tool installers (11 tools)
│   ├── 004-reinstall/          # Reinstall scripts (inc. Ghostty build-from-source)
│   ├── 007-diagnostics/        # Boot diagnostics system
│   ├── daily-updates.sh        # Automated updates
│   └── ghostty-theme-switcher.sh # Dynamic theme switching
├── .claude/instructions-for-agents/ # AI agent instructions
├── astro-website/src/          # Documentation source (editable)
└── docs/                       # Built site (GitHub Pages)
```

## Development

```bash
# Run TypeScript checks
cd astro-website && npm run check

# Build documentation
npm run build

# Local CI/CD validation
./.runners-local/workflows/gh-workflow-local.sh all
```

## Contributing

Contributions welcome! See [Contributing Guide](.github/CONTRIBUTING.md) for:
- Git workflow and branch preservation policy
- Development commands and testing procedures
- Code style guidelines

## License

MIT License - see [LICENSE](LICENSE) for details.
