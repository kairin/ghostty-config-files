# Scripts Directory Index

**Last Updated**: 2026-01-18
**Total Scripts**: 114
**Purpose**: Comprehensive tool installation, management, and maintenance for the Ghostty Configuration Files project

## Overview

This directory contains shell scripts organized into numbered stage directories following the installation pipeline pattern. Each stage handles a specific phase of tool lifecycle management.

### Directory Structure

| Stage | Directory | Purpose | Scripts |
|-------|-----------|---------|---------|
| 000 | `000-check` | Tool presence detection | 14 |
| 001 | `001-uninstall` | Clean removal of tools | 13 |
| 002 | `002-install-first-time` | Fresh installation with dependencies | 15 |
| 003 | `003-verify` | Dependency verification | 13 |
| 004 | `004-reinstall` | Reinstallation (upgrade/repair) | 14 |
| 005 | `005-confirm` | Post-install confirmation | 15 |
| 006 | `006-logs` | Logging utilities | 2 |
| 007 | `007-diagnostics` | System health checks | 9 |
| 007 | `007-update` | Tool updates | 12 |
| - | `mcp` | MCP server scripts | 1 |
| - | `vhs` | VHS recording scripts | 1 |
| - | Root | Utility scripts | 5 |

### Script Naming Convention

Scripts follow the pattern: `<action>_<tool>.sh`

Examples:
- `check_ghostty.sh` - Check if Ghostty is installed
- `update_nodejs.sh` - Update Node.js to latest version
- `uninstall_zsh.sh` - Uninstall ZSH and related components

---

## 000-check - Detection Scripts

Detect whether tools are installed and their installation method.

| Script | Purpose |
|--------|---------|
| `check_ai_tools.sh` | Detect AI CLI tools (Claude Code, Gemini CLI, Copilot CLI) |
| `check_antigravity.sh` | Detect Antigravity font installation |
| `check_fastfetch.sh` | Detect fastfetch system information tool |
| `check_feh.sh` | Detect feh image viewer |
| `check_ghostty.sh` | Detect Ghostty terminal (snap vs source) |
| `check_glow.sh` | Detect glow markdown renderer |
| `check_go.sh` | Detect Go programming language |
| `check_gum.sh` | Detect gum TUI component library |
| `check_nerdfonts.sh` | Detect Nerd Fonts installation |
| `check_nodejs.sh` | Detect Node.js via fnm |
| `check_python_uv.sh` | Detect Python UV package manager |
| `check_vhs.sh` | Detect VHS terminal recorder |
| `check_zsh.sh` | Detect ZSH and Oh My ZSH |
| `verify_manifest.sh` | Verify tool manifest against installed tools |

---

## 001-uninstall - Removal Scripts

Cleanly remove tools and their configurations.

| Script | Purpose |
|--------|---------|
| `uninstall_ai_tools.sh` | Remove AI CLI tools |
| `uninstall_antigravity.sh` | Remove Antigravity font |
| `uninstall_fastfetch.sh` | Remove fastfetch |
| `uninstall_feh.sh` | Remove feh image viewer |
| `uninstall_ghostty.sh` | Remove Ghostty terminal |
| `uninstall_glow.sh` | Remove glow |
| `uninstall_go.sh` | Remove Go |
| `uninstall_gum.sh` | Remove gum |
| `uninstall_nerdfonts.sh` | Remove Nerd Fonts |
| `uninstall_nodejs.sh` | Remove Node.js and fnm |
| `uninstall_python_uv.sh` | Remove Python UV |
| `uninstall_vhs.sh` | Remove VHS |
| `uninstall_zsh.sh` | Remove ZSH and Oh My ZSH |

---

## 002-install-first-time - Fresh Installation Scripts

Install tools for the first time including all dependencies.

| Script | Purpose |
|--------|---------|
| `install_deps_ai_tools.sh` | Install AI CLI tools dependencies |
| `install_deps_antigravity.sh` | Install Antigravity font dependencies |
| `install_deps_fastfetch.sh` | Install fastfetch dependencies |
| `install_deps_feh.sh` | Install feh dependencies |
| `install_deps_ghostty.sh` | Install Ghostty dependencies |
| `install_deps_glow.sh` | Install glow dependencies |
| `install_deps_go.sh` | Install Go dependencies |
| `install_deps_gum.sh` | Install gum dependencies |
| `install_deps_nerdfonts.sh` | Install Nerd Fonts dependencies |
| `install_deps_nodejs.sh` | Install Node.js/fnm dependencies |
| `install_deps_python_uv.sh` | Install Python UV dependencies |
| `install_deps_vhs.sh` | Install VHS dependencies |
| `install_deps_zsh.sh` | Install ZSH dependencies |
| `install_ghostty_config.sh` | Install Ghostty configuration files |
| `setup_mcp_config.sh` | Setup MCP server configuration |

---

## 003-verify - Dependency Verification Scripts

Verify that all dependencies are correctly installed.

| Script | Purpose |
|--------|---------|
| `verify_deps_ai_tools.sh` | Verify AI CLI tools dependencies |
| `verify_deps_antigravity.sh` | Verify Antigravity font dependencies |
| `verify_deps_fastfetch.sh` | Verify fastfetch dependencies |
| `verify_deps_feh.sh` | Verify feh dependencies |
| `verify_deps_ghostty.sh` | Verify Ghostty dependencies |
| `verify_deps_glow.sh` | Verify glow dependencies |
| `verify_deps_go.sh` | Verify Go dependencies |
| `verify_deps_gum.sh` | Verify gum dependencies |
| `verify_deps_nerdfonts.sh` | Verify Nerd Fonts dependencies |
| `verify_deps_nodejs.sh` | Verify Node.js/fnm dependencies |
| `verify_deps_python_uv.sh` | Verify Python UV dependencies |
| `verify_deps_vhs.sh` | Verify VHS dependencies |
| `verify_deps_zsh.sh` | Verify ZSH dependencies |

---

## 004-reinstall - Reinstallation Scripts

Reinstall or upgrade existing tool installations.

| Script | Purpose |
|--------|---------|
| `install_ai_tools.sh` | Reinstall AI CLI tools |
| `install_antigravity.sh` | Reinstall Antigravity font |
| `install_fastfetch.sh` | Reinstall fastfetch |
| `install_feh.sh` | Reinstall feh |
| `install_ghostty.sh` | Reinstall Ghostty |
| `install_glow.sh` | Reinstall glow |
| `install_go.sh` | Reinstall Go |
| `install_gum.sh` | Reinstall gum |
| `install_nerdfonts.sh` | Reinstall Nerd Fonts |
| `install_nodejs.sh` | Reinstall Node.js via fnm |
| `install_python_uv.sh` | Reinstall Python UV |
| `install_vhs.sh` | Reinstall VHS |
| `install_zsh.sh` | Reinstall ZSH |
| `reinstall_powerlevel10k.sh` | Reinstall PowerLevel10k theme |

---

## 005-confirm - Post-Install Confirmation Scripts

Confirm successful installation and display version information.

| Script | Purpose |
|--------|---------|
| `confirm_ai_tools.sh` | Confirm AI CLI tools installation |
| `confirm_antigravity.sh` | Confirm Antigravity font installation |
| `confirm_fastfetch.sh` | Confirm fastfetch installation |
| `confirm_feh.sh` | Confirm feh installation |
| `confirm_ghostty.sh` | Confirm Ghostty installation |
| `confirm_glow.sh` | Confirm glow installation |
| `confirm_go.sh` | Confirm Go installation |
| `confirm_gum.sh` | Confirm gum installation |
| `confirm_nerdfonts.sh` | Confirm Nerd Fonts installation |
| `confirm_nodejs.sh` | Confirm Node.js installation |
| `confirm_ohmyzsh.sh` | Confirm Oh My ZSH installation |
| `confirm_powerlevel10k.sh` | Confirm PowerLevel10k installation |
| `confirm_python_uv.sh` | Confirm Python UV installation |
| `confirm_vhs.sh` | Confirm VHS installation |
| `confirm_zsh.sh` | Confirm ZSH installation |

---

## 006-logs - Logging Utilities

Centralized logging for all scripts.

| Script | Purpose |
|--------|---------|
| `logger.sh` | Shared logging functions (source this in other scripts) |
| `view_logs.sh` | View and manage log files |

**Usage**: Source the logger in other scripts:
```bash
source "$SCRIPT_DIR/../006-logs/logger.sh"
log "INFO" "Starting installation..."
```

---

## 007-diagnostics - System Health Checks

Boot diagnostics and system health monitoring. See [007-diagnostics/README.md](007-diagnostics/README.md) for details.

| Script | Purpose |
|--------|---------|
| `boot_diagnostics.sh` | Full system diagnostic scan |
| `quick_scan.sh` | Fast health check |

### Detectors Subdirectory

| Script | Purpose |
|--------|---------|
| `detectors/detect_cosmetic_warnings.sh` | Detect cosmetic warning issues |
| `detectors/detect_failed_services.sh` | Detect failed systemd services |
| `detectors/detect_network_wait_issues.sh` | Detect network wait timeouts |
| `detectors/detect_orphaned_services.sh` | Detect orphaned services |
| `detectors/detect_unsupported_snaps.sh` | Detect unsupported snap packages |

### Library Subdirectory

| Script | Purpose |
|--------|---------|
| `lib/fix_executor.sh` | Execute fixes for detected issues |
| `lib/issue_registry.sh` | Registry of known issues and fixes |

---

## 007-update - Update Scripts

Update installed tools to their latest versions. See [007-update/README.md](007-update/README.md) for details.

| Script | Purpose |
|--------|---------|
| `update_ai_tools.sh` | Update AI CLI tools via npm |
| `update_fastfetch.sh` | Update fastfetch |
| `update_feh.sh` | Update feh |
| `update_ghostty.sh` | Update Ghostty (snap refresh or source rebuild) |
| `update_glow.sh` | Update glow |
| `update_go.sh` | Update Go |
| `update_gum.sh` | Update gum |
| `update_nerdfonts.sh` | Update Nerd Fonts |
| `update_nodejs.sh` | Update Node.js via fnm |
| `update_python_uv.sh` | Update Python UV |
| `update_vhs.sh` | Update VHS |
| `update_zsh.sh` | Update ZSH and plugins |

---

## mcp - MCP Server Scripts

Model Context Protocol server management.

| Script | Purpose |
|--------|---------|
| `setup_mcp_servers.sh` | Setup and configure MCP servers |

---

## vhs - VHS Recording Scripts

Terminal recording with VHS.

| Script | Purpose |
|--------|---------|
| `record_demo.sh` | Record terminal demos |

---

## Root-Level Scripts

Utility scripts at the scripts directory root.

| Script | Purpose |
|--------|---------|
| `check_updates.sh` | Check for available updates across all tools |
| `configure_zsh.sh` | Configure ZSH with Oh My ZSH and plugins |
| `daily-updates.sh` | Run daily update routine (cron-compatible) |
| `ghostty-theme-switcher.sh` | Switch Ghostty theme based on system preference |
| `install_apt_hook.sh` | Install APT hook for update notifications |

---

## Quick Reference

### Common Operations

| Task | Command |
|------|---------|
| Check if tool installed | `./scripts/000-check/check_<tool>.sh` |
| Install a tool | `./scripts/004-reinstall/install_<tool>.sh` |
| Uninstall a tool | `./scripts/001-uninstall/uninstall_<tool>.sh` |
| Update a tool | `./scripts/007-update/update_<tool>.sh` |
| Update all tools | `./scripts/daily-updates.sh` |
| Run diagnostics | `./scripts/007-diagnostics/boot_diagnostics.sh` |
| Quick health check | `./scripts/007-diagnostics/quick_scan.sh` |

### Supported Tools

| Tool | Check | Install | Uninstall | Update |
|------|-------|---------|-----------|--------|
| AI Tools | ✓ | ✓ | ✓ | ✓ |
| Fastfetch | ✓ | ✓ | ✓ | ✓ |
| Feh | ✓ | ✓ | ✓ | ✓ |
| Ghostty | ✓ | ✓ | ✓ | ✓ |
| Glow | ✓ | ✓ | ✓ | ✓ |
| Go | ✓ | ✓ | ✓ | ✓ |
| Gum | ✓ | ✓ | ✓ | ✓ |
| Nerd Fonts | ✓ | ✓ | ✓ | ✓ |
| Node.js | ✓ | ✓ | ✓ | ✓ |
| Python UV | ✓ | ✓ | ✓ | ✓ |
| VHS | ✓ | ✓ | ✓ | ✓ |
| ZSH | ✓ | ✓ | ✓ | ✓ |

---

## Related Documentation

- [007-update/README.md](007-update/README.md) - Update scripts documentation
- [007-diagnostics/README.md](007-diagnostics/README.md) - Boot diagnostics documentation
- [DAILY_UPDATES_README.md](DAILY_UPDATES_README.md) - Daily updates system documentation
