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
| 007 | `update_*.sh` | In-place updates (NEW - 2026) |

### Update Scripts (NEW - 2026)

Located in `scripts/007-update/`, these scripts provide non-destructive in-place updates:

| Script | Tool | Purpose |
|--------|------|---------|
| `update_claude_code.sh` | Claude Code | Update via npm |
| `update_fnm.sh` | fnm | Update Node version manager |
| `update_nodejs.sh` | Node.js | Update to latest version |
| `update_python_uv.sh` | Python UV | Update package manager |
| `update_zsh.sh` | ZSH | Update Oh My Zsh + plugins |

**Usage**: Called by TUI installer's Update action or directly via CLI.

## Logging

Tools use two logging approaches:
- **Simple echo**: fastfetch, glow, go, gum, python_uv, vhs, zsh
- **logger.sh**: feh, ghostty, nerdfonts, nodejs (structured logging)

## TUI Dashboard Integration

All tools are accessible through `start.sh` which launches the **Go TUI** (`tui/installer`):
- **Main Dashboard**: ghostty, feh, nerdfonts, nodejs (magenta border)
- **Extras Dashboard**: fastfetch, glow, go, gum, python_uv, vhs, zsh (cyan border)
- **Boot Diagnostics**: System issue detection and fixes

### Go TUI Features (Phase 4)
- **Data-Driven Registry**: Tool definitions in `tui/internal/registry/`
- **Status Caching**: 5-minute TTL reduces script execution overhead
- **Parallel Status Checks**: All 12 tools checked concurrently
- **Real-Time Output**: TailSpinner shows installation progress
- **Crash Recovery**: Checkpoint-based resume from failures

### Source Code
The Go TUI source is in `tui/` directory:
- Registry: `internal/registry/registry.go` (single source of truth)
- UI: `internal/ui/` (Bubbletea model, views, styles)
- Executor: `internal/executor/` (script runner with streaming)

---

**Version**: 1.2
**Last Updated**: 2026-01-17
