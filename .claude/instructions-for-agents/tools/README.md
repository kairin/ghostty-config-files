# Tool Implementation Reference

> Complete reference for all installable tools managed through the project's 6-step installation framework.

## Quick Reference

| Tool | Description | Method | TUI Location |
|------|-------------|--------|--------------|
| [fastfetch](fastfetch.md) | System info fetcher | APT/PPA + GitHub | Extras |
| [feh](feh.md) | Lightweight image viewer | Source build | Main |
| [ghostty](ghostty.md) | GPU-accelerated terminal | Source build (Zig) | Main |
| [glow](glow.md) | Terminal markdown renderer | Charm repository | Extras |
| [go](go.md) | Go programming language | Official tarball | Extras |
| [gum](gum.md) | TUI component library | Charm repository | Extras |
| [nerdfonts](nerdfonts.md) | Developer fonts (8 families) | GitHub releases | Main |
| [nodejs](nodejs.md) | JavaScript runtime | fnm + Node.js v25 | Main |
| [python-uv](python-uv.md) | Fast Python package manager | Official script | Extras |
| [vhs](vhs.md) | Terminal recording/GIF | Charm repository | Extras |
| [zsh](zsh.md) | Z shell + Oh My Zsh | APT + script | Extras |
| [AI CLI Tools](ai-cli-tools.md) | Claude, Gemini, Copilot | npm (planned) | - |

## Installation Methods

### Source Builds (2)
- **ghostty**: Zig build with desktop integration
- **feh**: Make build from git

### Charm Repository (3)
- **gum**, **glow**, **vhs**: Shared GPG key and apt repository

### Official Scripts (2)
- **python_uv**: Astral's install script
- **nodejs**: fnm (Fast Node Manager)

### APT/PPA (2)
- **fastfetch**: PPA with GitHub fallback
- **zsh**: APT + Oh My Zsh script

### Official Tarball (1)
- **go**: go.dev tarball

### GitHub Releases (1)
- **nerdfonts**: 8 font families as tar.xz

## 6-Step Installation Framework

Each tool follows a standardized script structure:

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_*.sh` | Detect installation status, version, method |
| 001 | `uninstall_*.sh` | Clean removal |
| 002 | `install_deps_*.sh` | Install dependencies |
| 003 | `verify_deps_*.sh` | Verify dependencies |
| 004 | `install_*.sh` | Main installation |
| 005 | `confirm_*.sh` | Verify installation succeeded |

## Logging

Tools use two logging approaches:
- **Simple echo**: fastfetch, glow, go, gum, python_uv, vhs, zsh
- **logger.sh**: feh, ghostty, nerdfonts, nodejs (structured logging)

## TUI Dashboard Integration

All tools are accessible through `start.sh`:
- **Main Menu**: ghostty, feh, nerdfonts, nodejs
- **Extras Menu**: fastfetch, glow, go, gum, python_uv, vhs, zsh

---

**Version**: 1.0
**Last Updated**: 2025-12-13
