---
title: Logging System Guide
category: guides
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-11
---

# Logging System Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

The project uses a comprehensive logging system to track installations, updates, and system operations. Logs are essential for troubleshooting and audit purposes.

## Log Locations

### Installation Logs

**Location**: `scripts/006-logs/`

**Format**: `YYYYMMDD-HHMMSS-operation.log`

**Examples**:
- `20260111-061122-install_deps_go.log` - Go installation
- `20260111-062301-install_nerdfonts.log` - NerdFonts installation
- `20260111-063332-check_ghostty.log` - Ghostty status check

**Operations logged**:
- `install_deps_*` - Dependency installation
- `check_*` - Status checks
- `verify_*` - Verification operations
- `confirm_*` - Confirmation steps
- `generate_manifest` - Manifest generation

### Update Manifests

**Location**: `logs/manifests/`

Contains JSON manifests of installed tool versions for update tracking.

### Daily Update Logs

**Location**: `/tmp/daily-updates-logs/` (temporary)

**Files**:
- `update-TIMESTAMP.log` - Full update log with all output
- `errors-TIMESTAMP.log` - Errors only
- `last-update-summary.txt` - Quick summary of last update
- `latest.log` - Symlink to most recent log

## Log Format

### Standard Log Entry

```
[TIMESTAMP] [LEVEL] message
```

**Levels**:
- `INFO` - General information
- `WARN` - Warning conditions
- `ERROR` - Error conditions
- `DEBUG` - Debug information (verbose mode only)

### Installation Log Structure

```
=== Operation Started: install_deps_ghostty ===
Timestamp: 2026-01-11 06:11:22
[INFO] Checking dependencies...
[INFO] Installing Zig compiler...
[INFO] Cloning Ghostty repository...
[INFO] Building Ghostty (this may take 2-5 minutes)...
[INFO] Installation complete
=== Operation Completed: SUCCESS ===
Duration: 3m 42s
```

## Viewing Logs

### Recent Installation Logs

```bash
# List recent logs
ls -lt scripts/006-logs/ | head -20

# View specific log
cat scripts/006-logs/20260111-061122-install_deps_go.log

# Follow logs in real-time during installation
tail -f scripts/006-logs/*.log
```

### Daily Update Logs

```bash
# View last update summary
cat /tmp/daily-updates-logs/last-update-summary.txt

# View full update log
cat /tmp/daily-updates-logs/latest.log

# View errors only
cat /tmp/daily-updates-logs/errors-*.log
```

### Using Shell Aliases

After installation, these aliases are available:

```bash
update-logs    # View latest update summary
```

## Log Retention

- **Installation logs**: Kept in `scripts/006-logs/` indefinitely (git-tracked)
- **Daily update logs**: Kept in `/tmp/` (cleared on reboot)
- **Manifests**: Kept in `logs/manifests/` indefinitely (git-tracked)

## Troubleshooting with Logs

### Installation Failed

1. Check the specific log file:
   ```bash
   ls -lt scripts/006-logs/ | head -5
   cat scripts/006-logs/<latest-file>.log
   ```

2. Look for ERROR lines:
   ```bash
   grep -i error scripts/006-logs/<log-file>.log
   ```

### Update Failed

1. Check the error log:
   ```bash
   cat /tmp/daily-updates-logs/errors-*.log
   ```

2. Check the full log for context:
   ```bash
   cat /tmp/daily-updates-logs/latest.log | grep -A5 -B5 "ERROR"
   ```

### Version Mismatch

Check the manifest for recorded versions:

```bash
cat logs/manifests/*.json
```

## Best Practices

1. **Check logs after installation**: Always verify successful completion
2. **Keep installation logs**: Don't delete logs from `scripts/006-logs/`
3. **Review update logs weekly**: Monitor for recurring issues
4. **Include logs in bug reports**: Always attach relevant logs when reporting issues

## Related Documentation

- [Daily Updates README](../../../../scripts/DAILY_UPDATES_README.md)
- [System Architecture](../architecture/system-architecture.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
