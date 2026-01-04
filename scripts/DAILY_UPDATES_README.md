# Daily Updates System

Automated update management for all ghostty-config-files tools.

## Quick Start

```bash
# Check for available updates
update-check

# Apply all updates interactively
update-all

# View latest update summary
update-logs
```

## Shell Aliases

After running `./scripts/configure_zsh.sh` or `./start.sh`, these aliases are available:

| Alias | Description | Script |
|-------|-------------|--------|
| `update-all` | Run all updates interactively | `daily-updates.sh` |
| `update-logs` | Show latest update summary | `show_latest_update_summary()` |
| `update-check` | Check for available updates | `check_updates.sh` |

## Update Workflow

### Interactive Mode (Default)

```bash
./scripts/daily-updates.sh
```

1. Detects available updates for all installed tools
2. Creates backup of configurations
3. Shows update list and prompts for confirmation
4. Applies updates via 004-reinstall scripts
5. Runs CI/CD validation
6. Shows summary with success/failure counts

### Non-Interactive Mode (Cron)

```bash
./scripts/daily-updates.sh --non-interactive
```

Skips confirmation prompts. Ideal for automated daily runs.

### Dry-Run Mode

```bash
./scripts/daily-updates.sh --dry-run
```

Checks for updates without applying them. Shows what would be updated.

## Cron Automation

### Install Daily Updates at 9 AM

```bash
./scripts/daily-updates.sh --install-cron
```

This adds a cron entry:
```
0 9 * * * /path/to/scripts/daily-updates.sh --non-interactive >> .runners-local/logs/cron-updates.log 2>&1
```

### Manual Cron Configuration

```bash
# Edit crontab
crontab -e

# Add custom schedule (example: 6 AM on weekdays)
0 6 * * 1-5 /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh --non-interactive
```

### View Cron Logs

```bash
# View recent cron update logs
tail -f .runners-local/logs/cron-updates.log

# View update summaries
update-logs
```

## Backup & Restore

### Automatic Backups

Before applying updates, the system automatically backs up:
- `~/.config/ghostty/` (Ghostty configuration)
- `~/.zshrc` (ZSH configuration)
- `~/.p10k.zsh` (Powerlevel10k configuration)
- `~/.config/fastfetch/` (Fastfetch configuration)

Backups are stored in `~/.config/ghostty-backups/`.

### Restore from Backup

```bash
# Source logger utilities
source scripts/006-logs/logger.sh

# List available backups
ls ~/.config/ghostty-backups/

# Restore from specific backup
restore_from_backup ~/.config/ghostty-backups/pre-update-20251115-090000
```

### Backup Retention

- Last 5 backups are kept automatically
- Old backups are cleaned up after each update run
- To keep more backups, edit `cleanup_old_backups()` in `logger.sh`

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All updates successful (or dry-run complete) |
| 1 | Some updates failed (non-critical) |
| 2 | Validation failed (rollback recommended) |
| 3 | Already running (lock file exists) |
| 4 | Prerequisites not met |

## Update Log Format

Logs are stored in `.runners-local/logs/update-summary-YYYYMMDD-HHMMSS.log`

### Log Entry Types

```
HEADER|START|timestamp|datetime     # Update session start
UPDATE_START|tool|current|target|ts # Tool update beginning
UPDATE_RESULT|tool|status|msg|ts    # Tool update result
HEADER|END|timestamp|datetime       # Update session end
SUMMARY|total=N|success=N|...       # Final statistics
```

### Viewing Logs

```bash
# Latest summary (via alias)
update-logs

# All update logs
ls -la .runners-local/logs/update-summary-*.log

# Specific log details
cat .runners-local/logs/update-summary-20251115-090000.log
```

## Supported Tools

Updates are applied via reusing existing `scripts/004-reinstall/install_*.sh` scripts:

| Tool | Install Script |
|------|---------------|
| Ghostty | `install_ghostty.sh` |
| Fastfetch | `install_fastfetch.sh` |
| Glow | `install_glow.sh` |
| Go | `install_go.sh` |
| Gum | `install_gum.sh` |
| Node.js | `install_nodejs.sh` |
| Python (uv) | `install_python_uv.sh` |
| VHS | `install_vhs.sh` |
| Nerd Fonts | `install_nerdfonts.sh` |
| Feh | `install_feh.sh` |
| Zsh | `install_zsh.sh` |
| Local AI Tools | `install_ai_tools.sh` |

## Troubleshooting

### Lock File Error

```
ERROR: Another update process is running (PID: XXXX)
```

**Solution**: Wait for the other process to complete, or if it's stale:
```bash
rm /tmp/daily-updates.lock
```

### Validation Failure

```
ERROR: CI/CD validation failed
```

**Solution**: Check the validation output. If critical, restore from backup:
```bash
source scripts/006-logs/logger.sh
restore_from_backup ~/.config/ghostty-backups/pre-update-YYYYMMDD-HHMMSS
```

### No Updates Detected

```
SUCCESS: All tools are up to date
```

This is normal. The system only shows tools with available updates.

### Missing Install Script

```
WARNING: No install script found for ToolName
```

The tool may not have a corresponding install script in `004-reinstall/`.

## Constitutional Compliance

This update system follows the Script Proliferation Prevention principle:

1. **Single orchestrator**: Only `daily-updates.sh` created (justified)
2. **Reuses existing scripts**: Uses `004-reinstall/install_*.sh` (no new update scripts)
3. **Enhances existing utilities**: Backup/logging added to `logger.sh`
4. **No wrapper scripts**: Direct execution, no intermediary layers

## Files Created/Modified

| File | Type | Lines |
|------|------|-------|
| `scripts/daily-updates.sh` | NEW | ~280 |
| `scripts/006-logs/logger.sh` | ENHANCED | +150 |
| `scripts/configure_zsh.sh` | ENHANCED | +17 |
| `scripts/DAILY_UPDATES_README.md` | NEW | ~200 |

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Main project documentation
- [logger.sh](006-logs/logger.sh) - Logging and backup utilities
- [check_updates.sh](check_updates.sh) - Update detection script
