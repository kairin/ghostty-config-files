---
title: "Quick Start: Modern TUI Installation System"
description: "**Last Updated**: 2025-11-18"
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# Quick Start: Modern TUI Installation System

**Last Updated**: 2025-11-18
**Status**: Implementation Ready

## Overview

This guide provides step-by-step instructions for using the new Modern TUI Installation System for Ghostty Configuration Files. The redesigned installation features Docker-like collapsible output, adaptive box drawing, real verification tests, and <10 minute installation times.

## One-Command Installation

### Fresh Ubuntu 25.10 System

```bash
cd /home/kkk/Apps/ghostty-config-files
./start.sh
```

That's it! The installation system will:
- ✅ Automatically detect your terminal capabilities (UTF-8 vs ASCII)
- ✅ Install all dependencies (Ghostty, ZSH, Python/uv, Node.js/fnm, AI tools)
- ✅ Verify each component with real system state checks
- ✅ Show professional Docker-like progress with collapsible output
- ✅ Complete in <10 minutes on fresh systems

### What You'll See

```
╔════════════════════════════════════════════════════════════╗
║  Ghostty Configuration Installation                        ║
╚════════════════════════════════════════════════════════════╝

[●●●●●●●●●●○○○○○○○○○○] 50% (10/20 tasks)

✓ Verify prerequisites                              (2.1s)
✓ Install system dependencies                       (8.3s)
✓ Install Ghostty from source                      (45.7s)
✓ Configure Ghostty themes                          (1.2s)
✓ Install ZSH environment                           (3.8s)
✓ Install uv (Python package manager)               (1.5s)
✓ Install fnm (Fast Node Manager)                   (1.9s)
✓ Install Node.js v25.2.0                           (3.2s)
✓ Install Claude CLI                                (2.8s)
✓ Install Gemini CLI                                (2.6s)
⠋ Configure Nautilus context menu
⏸ Final verification (queued)

Elapsed: 01:15  |  Estimated remaining: ~01:15

[Press 'v' for verbose mode]
```

## Command-Line Options

### Basic Options

```bash
# Show help information
./start.sh --help

# Verbose mode (show all output, no collapsing)
./start.sh --verbose

# Resume interrupted installation
./start.sh --resume

# Skip pre-installation health checks
./start.sh --skip-checks

# Force reinstall all components (ignore idempotency)
./start.sh --force-all
```

### Advanced Options

```bash
# Force ASCII box drawing (for SSH or legacy terminals)
./start.sh --box-style ascii

# Force UTF-8 double-line boxes
./start.sh --box-style utf8-double

# Force UTF-8 light-line boxes
./start.sh --box-style utf8

# Combination: verbose + ASCII for SSH debugging
./start.sh --verbose --box-style ascii
```

## Common Scenarios

### Scenario 1: Fresh Installation on Local Machine

```bash
cd /home/kkk/Apps/ghostty-config-files
./start.sh
```

**Expected**:
- Installation completes in <10 minutes
- UTF-8 box drawing (╔═══╗) renders perfectly
- All 20 tasks complete successfully
- Real verification confirms everything installed

### Scenario 2: Installation via SSH

```bash
ssh user@remote-server
cd /home/kkk/Apps/ghostty-config-files
./start.sh
```

**Expected**:
- System automatically detects SSH and uses ASCII boxes (+---+)
- Installation proceeds normally
- All functionality works (no broken characters)

**Manual Override** (if auto-detection fails):
```bash
./start.sh --box-style ascii
```

### Scenario 3: Interrupted Installation (Power Loss, CTRL+C)

```bash
# First attempt interrupted at 50%
./start.sh
# (interrupted)

# Resume from checkpoint
./start.sh --resume
```

**Expected**:
- System reads installation state from `/tmp/ghostty-start-logs/installation-state.json`
- Shows: "Found 10 completed tasks, resuming from checkpoint"
- Skips completed tasks (shown as `↷ Already installed`)
- Continues from where it stopped

### Scenario 4: Re-running After Successful Installation

```bash
# First installation completed successfully
./start.sh
# ✅ All tasks complete

# Run again (testing idempotency)
./start.sh
```

**Expected**:
- Completes in <30 seconds (constitutional requirement)
- All tasks show `↷ Already installed`
- User customizations preserved (ZSH config, Ghostty themes, etc.)
- No duplicate installations

### Scenario 5: Update Existing Installation

```bash
# System already installed, want to update to latest versions
./start.sh --force-all
```

**Expected**:
- Ignores idempotency, reinstalls all components
- Preserves user customizations (backups created first)
- Updates to latest versions (Node.js, Ghostty, AI tools)
- Verifies all components after update

## Troubleshooting

### Problem: Box drawing shows broken characters (? or □)

**Symptoms**: Instead of clean boxes, you see gibberish characters

**Solution 1**: Force ASCII mode
```bash
export BOX_DRAWING=ascii
./start.sh
```

**Solution 2**: Use command-line flag
```bash
./start.sh --box-style ascii
```

**Root Cause**: Terminal doesn't support UTF-8, or SSH session not forwarding locale

**Permanent Fix** (for SSH):
```bash
# On SSH server, add to ~/.bashrc:
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# On SSH client, add to ~/.ssh/config:
Host *
    SendEnv LANG LC_*
```

---

### Problem: Installation interrupted, can't resume

**Symptoms**: `./start.sh --resume` says "No previous installation found"

**Solution**: Check state file exists
```bash
ls -la /tmp/ghostty-start-logs/installation-state.json
```

**If missing**:
```bash
# State file was cleaned (reboot or manual deletion)
# Re-run full installation (safe due to idempotency)
./start.sh
```

**Root Cause**: `/tmp/` cleaned on reboot, or state file manually deleted

---

### Problem: Verification failed for component

**Symptoms**: Installation stops with "❌ Verification failed: ghostty"

**Solution 1**: Check error log
```bash
cat /tmp/ghostty-start-logs/errors.log
```

**Solution 2**: Check detailed log
```bash
cat /tmp/ghostty-start-logs/start-$(ls -t /tmp/ghostty-start-logs/start-*.log | head -1 | cut -d'-' -f2).log
```

**Solution 3**: Run verification manually
```bash
source lib/verification/unit_tests.sh
verify_ghostty_installed
# Shows detailed error output
```

**Common Causes**:
- Missing system dependencies (install with `sudo apt install <package>`)
- Insufficient disk space (check with `df -h`)
- Permission issues (check file permissions)
- Network issues (check internet connectivity)

---

### Problem: Installation too slow (>10 minutes)

**Symptoms**: Installation exceeds 10 minute constitutional requirement

**Solution**: Check performance log
```bash
cat /tmp/ghostty-start-logs/performance.json
```

**Identify bottleneck**:
```bash
jq '.task_durations | to_entries | sort_by(.value) | reverse | .[0:5]' \
    /tmp/ghostty-start-logs/performance.json
# Shows 5 slowest tasks
```

**Common Causes**:
- Slow network (downloading large packages)
- Low system resources (check with `top`)
- Building from source (Ghostty, Zig compilation)
- Not using parallel execution (bug in implementation)

---

### Problem: fnm startup time >50ms (constitutional violation)

**Symptoms**: Verification shows "fnm startup: 62ms (>50ms ✗)"

**Solution 1**: Check fnm installation method
```bash
which fnm
# Should be: /home/kkk/.local/share/fnm/fnm (not /usr/bin/fnm)
```

**Solution 2**: Reinstall fnm
```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

**Solution 3**: Check filesystem
```bash
# fnm should NOT be on slow network filesystem
df -h ~/.local/share/fnm
```

**Root Cause**: fnm installed incorrectly or on slow filesystem

---

### Problem: User customizations lost after update

**Symptoms**: ZSH config, Ghostty themes, or shell aliases disappeared

**Solution**: Restore from backup
```bash
# Backups stored with timestamps
ls -la ~/.config/ghostty/config.backup-*

# Restore latest backup
cp ~/.config/ghostty/config.backup-$(ls -t ~/.config/ghostty/config.backup-* | head -1) \
   ~/.config/ghostty/config
```

**Prevention**: This shouldn't happen (constitutional requirement to preserve customizations). If it does, it's a BUG - please report.

## Performance Expectations

### Fresh Installation (Ubuntu 25.10)

| Metric | Target | Typical | Notes |
|--------|--------|---------|-------|
| Total Time | <10 minutes | 8-9 minutes | Includes building Ghostty from source |
| System Dependencies | <30 seconds | 20 seconds | apt package installation |
| Ghostty Build | <2 minutes | 60-90 seconds | Zig compilation |
| Package Managers | <10 seconds | 5 seconds | uv + fnm installation (parallel) |
| Node.js Install | <30 seconds | 15 seconds | Via fnm |
| AI Tools | <20 seconds | 12 seconds | Claude + Gemini + Copilot (parallel) |

### Re-Run (Idempotency Check)

| Metric | Target | Typical | Notes |
|--------|--------|---------|-------|
| Total Time | <30 seconds | 15-20 seconds | All tasks skipped |
| Verification | <10 seconds | 5 seconds | Real system checks |
| State Load | <1 second | <1 second | JSON parsing |

### Constitutional Compliance

| Requirement | Target | Validation | Status |
|-------------|--------|------------|--------|
| fnm startup | performance measured and logged | `time fnm env` | ✅ Verified during installation |
| gum startup | performance measured and logged | `time gum --version` | ✅ Verified during installation |
| Total install | <10 min | Logged in performance.json | ✅ Monitored |

## Getting Help

### Logs and Diagnostics

**All logs stored in `/tmp/ghostty-start-logs/`**:
```bash
# View human-readable log
cat /tmp/ghostty-start-logs/start-$(ls -t /tmp/ghostty-start-logs/start-*.log | head -1).log

# View structured JSON log (for parsing)
jq '.' /tmp/ghostty-start-logs/start-$(ls -t /tmp/ghostty-start-logs/start-*.log.json | head -1).log.json

# View errors only
cat /tmp/ghostty-start-logs/errors.log

# View performance metrics
jq '.' /tmp/ghostty-start-logs/performance.json

# View system state (before/after comparison)
jq '.' /tmp/ghostty-start-logs/system_state_*.json
```

### Emergency Rollback

**If installation breaks your system**:
```bash
# Restore from legacy installation script
./start-legacy.sh

# Or manually restore components
git checkout HEAD~1 -- configs/
cp configs/ghostty/config ~/.config/ghostty/config
```

### Reporting Issues

**Include these details**:
1. Error message from `/tmp/ghostty-start-logs/errors.log`
2. Full log from `/tmp/ghostty-start-logs/start-*.log`
3. System info: `uname -a`, `lsb_release -a`
4. Installation command used (with flags)
5. Screenshot of error (if visual issue like box drawing)

## Next Steps

After successful installation:

1. **Verify Installation**: Run `ghostty --version` and `ghostty +show-config`
2. **Launch Ghostty**: Open Ghostty from app menu or run `ghostty`
3. **Test Context Menu**: Right-click folder in Nautilus → "Open in Ghostty"
4. **Configure AI Tools**: Set up API keys for Claude/Gemini if not already configured
5. **Customize**: Edit `~/.config/ghostty/config` for personal preferences

## Additional Resources

- **Full Specification**: [spec.md](./spec.md)
- **Implementation Plan**: [plan.md](./plan.md)
- **Architecture Details**: [data-model.md](./data-model.md)
- **Research Background**: [research.md](./research.md)
- **API Contracts**: [contracts/](./contracts/)

---

**Quick Start Guide Complete** ✅

For advanced usage, troubleshooting, or development information, refer to the specification and plan documents.
