# Update Scripts

**Last Updated**: 2026-01-18
**Total Scripts**: 12
**Purpose**: Update installed tools to their latest versions with in-place upgrades

## Overview

Update scripts perform in-place upgrades that preserve existing configurations and data. Each script detects the current installation method and applies the appropriate update strategy.

## Available Update Scripts

| Script | Tool | Update Method |
|--------|------|---------------|
| `update_ai_tools.sh` | AI CLI Tools | npm global update |
| `update_fastfetch.sh` | Fastfetch | apt/source rebuild |
| `update_feh.sh` | Feh | apt upgrade |
| `update_ghostty.sh` | Ghostty | snap refresh or source rebuild |
| `update_glow.sh` | Glow | go install |
| `update_go.sh` | Go | Atomic tarball replacement |
| `update_gum.sh` | Gum | go install |
| `update_nerdfonts.sh` | Nerd Fonts | Installer script |
| `update_nodejs.sh` | Node.js | fnm install + preserve globals |
| `update_python_uv.sh` | Python UV | uv self-upgrade |
| `update_vhs.sh` | VHS | go install |
| `update_zsh.sh` | ZSH | apt + omz update |

## Usage

### Update a Single Tool

```bash
./scripts/007-update/update_<tool>.sh
```

Examples:
```bash
./scripts/007-update/update_ghostty.sh
./scripts/007-update/update_nodejs.sh
./scripts/007-update/update_go.sh
```

### Update All Tools (Batch)

Use the daily-updates orchestrator:

```bash
./scripts/daily-updates.sh
```

Options:
- `--dry-run` - Preview updates without applying
- `--non-interactive` - Cron-compatible mode (no prompts)
- `--skip-validation` - Skip post-update CI/CD checks

### Check for Available Updates

```bash
./scripts/check_updates.sh
```

## Update Strategies

### Ghostty (`update_ghostty.sh`)

Detects installation method and updates accordingly:
- **Snap installation**: `snap refresh ghostty`
- **Source installation**: Rebuilds from git via `install_ghostty.sh`

### Node.js (`update_nodejs.sh`)

Uses fnm for version management:
1. Installs new version alongside existing
2. Switches to new version
3. Preserves all npm global packages

### Go (`update_go.sh`)

Atomic tarball replacement:
1. Fetches latest version from go.dev
2. Downloads architecture-specific tarball
3. Removes old installation
4. Extracts new version
5. Preserves GOPATH and user projects

### AI Tools (`update_ai_tools.sh`)

Updates via npm:
```bash
npm update -g @anthropic-ai/claude-code
npm update -g @google/generative-ai-cli
npm update -g @githubnext/github-copilot-cli
```

## Logging

All update scripts use the shared logging system.

### Log Location

Logs are written to: `~/.local/share/ghostty-updates/logs/`

### View Logs

Use the update-logs alias (if configured):
```bash
update-logs
```

Or manually:
```bash
ls -la ~/.local/share/ghostty-updates/logs/
cat ~/.local/share/ghostty-updates/logs/latest.log
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Permission denied" | Missing sudo | Run with sudo or check file permissions |
| "Command not found" | Tool not in PATH | Source shell config or re-login |
| "Already at latest" | No update available | Normal - script exits successfully |
| "Download failed" | Network issue | Check internet connection and retry |

### Ghostty Update Fails

1. Check installation method: `which ghostty`
2. For snap: `snap list ghostty`
3. For source: Verify `/usr/local/bin/ghostty` exists
4. Check logs in `~/.local/share/ghostty-updates/logs/`

### Node.js Globals Missing After Update

The fnm-based update preserves globals. If packages are missing:
```bash
npm list -g --depth=0
npm install -g <missing-package>
```

### Go Projects Fail After Update

GOPATH is preserved but module cache may need rebuild:
```bash
go clean -modcache
go mod download
```

## Related Documentation

- [Scripts Directory Index](../README.md) - Complete scripts reference
- [Daily Updates Guide](../DAILY_UPDATES_README.md) - Batch update system
- [Logging Guide](../../.claude/instructions-for-agents/guides/LOGGING_GUIDE.md) - Logging system details
