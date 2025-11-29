# Daily Updates System

Automated daily updates for your development environment.

## 📋 What Gets Updated (13 Components)

**Version 2.1** - Enhanced with modular uninstall → reinstall workflow for major applications

1. **GitHub CLI (gh)** - Latest version from official repository
2. **System Packages** - All apt packages (`apt update && apt upgrade`)
3. **Oh My Zsh** - Zsh framework and plugins
4. **fnm (Fast Node Manager)** - Latest version with shell integration updates
5. **npm** - npm itself and all globally installed packages
6. **Claude CLI** - Anthropic's AI assistant CLI
7. **Gemini CLI** - Google's AI assistant CLI
8. **Copilot CLI** - GitHub's AI coding assistant
9. **uv** - Python package installer and tool manager
10. **Spec-Kit CLI** - Specification-driven development tool (via uv)
11. **Additional uv Tools** - All tools installed via `uv tool install`
12. **Zig Compiler** - Complete uninstall → reinstall when updates detected
13. **Ghostty Terminal** - Complete uninstall → reinstall when updates detected

## 🕐 Schedule

The updates run automatically every day at **9:00 AM** via cron.

**Crontab Entry:**
```
0 9 * * * /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
```

## 📊 Viewing Update Logs

Every terminal session shows the latest update summary. You can also use these commands:

### Quick Commands

```bash
# View latest update summary
update-logs

# View full update log with all details
update-logs-full

# View only errors
update-logs-errors

# List all available logs
/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh --list

# View specific date (YYYYMMDD format)
/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh --date 20251112
```

### Log Files Location

All logs are stored in `/tmp/daily-updates-logs/`:

- `update-TIMESTAMP.log` - Full update log with all output
- `errors-TIMESTAMP.log` - Errors only
- `last-update-summary.txt` - Quick summary of last update
- `latest.log` - Symlink to most recent log
- `cron-output.log` - Cron execution output

## 🔧 Manual Updates

Run updates manually anytime:

```bash
update-all
```

Or directly:

```bash
/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
```

## 📝 Update Log Format

Each log includes:

- Timestamp for every operation
- Success/failure status with ✅/❌ indicators
- Version information before and after updates
- Package counts and details
- Error messages (if any)
- Execution duration
- Summary of all updates

### Example Summary Output

```
=============================================================================
Daily Update Summary - 2025-11-12 09:00:45
=============================================================================
Duration: 245s

Log Files:
- Full log: /tmp/daily-updates-logs/update-20251112-090000.log
- Error log: /tmp/daily-updates-logs/errors-20251112-090000.log
- Latest: /tmp/daily-updates-logs/latest.log

Updates Completed:
✅ GitHub CLI (gh) - Updated
✅ System Packages - Updated
✅ Oh My Zsh - Updated
✅ npm & Global Packages - Updated
✅ Claude CLI - Updated
⚠️  Gemini CLI - Failed or Skipped
⚠️  Copilot CLI - Failed or Skipped

==============================================================================
```

## 🚨 Error Handling

The update script:

- **Continues on errors** - If one update fails, others still run
- **Logs all errors** - Check `errors-TIMESTAMP.log` for details
- **Preserves output** - Full stdout/stderr captured
- **Non-destructive** - Uses standard package manager update commands

## ⚙️ Customization

### Change Update Time

Edit the crontab:

```bash
crontab -e
```

Change the time (current: `0 9 * * *` = 9:00 AM daily):

```
# Run at 6:00 AM instead
0 6 * * * /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh

# Run at 9:00 PM instead
0 21 * * * /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh

# Run twice a day (9 AM and 9 PM)
0 9,21 * * * /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
```

### Disable Automatic Updates

Remove the crontab entry:

```bash
crontab -r
```

Or comment it out:

```bash
crontab -e
# Add # at the beginning of the line
```

### Modify What Gets Updated

Edit the script:

```bash
nano /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
```

Comment out sections you don't want:

```bash
# update_github_cli || overall_success=false  # Disabled
update_system_packages || overall_success=false
# update_oh_my_zsh || overall_success=false  # Disabled
update_npm_packages || overall_success=false
```

## 🧪 Testing

Test the update system without waiting for cron:

```bash
# Run updates now
/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh

# Then check the logs
update-logs
```

## 🚀 Version 2.1 Features

### Modular Uninstall → Reinstall Workflow

For major applications (Ghostty, Zig), the update system now performs complete uninstall → reinstall:

**Benefits:**
- **Clean State**: Removes all old files before installing new version
- **No Conflicts**: Prevents version conflicts or partial updates
- **Verified Installation**: Fresh installation ensures proper configuration
- **Comprehensive Logging**: All steps logged for troubleshooting

**Uninstall Scripts:**
- `lib/installers/ghostty/uninstall.sh` - Removes Ghostty binary, source, config symlinks
- `lib/installers/zig/uninstall.sh` - Removes Zig compiler, symlinks, PATH entries

### Intelligent Version Detection

**Zig Compiler:**
- Queries `https://ziglang.org/download/index.json` for latest version
- Compares with local `zig version` output
- Triggers uninstall → reinstall only when update available

**Ghostty Terminal:**
- Fetches latest commits from `origin/main` in Ghostty repository
- Compares local and remote commit hashes
- Triggers uninstall → reinstall only when new commits available

### Graceful Error Handling

- **Continues on Failure**: If one component fails, others still update
- **Exit Code Tracking**: Distinguishes between errors and "not installed" states
- **Comprehensive Logging**: All stdout/stderr captured to log files
- **Update Summary**: Clear status for each component (success, fail, skip, already latest)

## 📱 Terminal Startup Notification

When you open a new terminal, you'll see the latest update summary **once per day**. This prevents spam while keeping you informed.

To suppress this notification, remove the section from `~/.zshrc`:

```bash
# Comment out or remove the "Display last update summary" section
```

## 🔍 Troubleshooting

### Updates not running

1. Check crontab is installed:
   ```bash
   crontab -l
   ```

2. Check cron service is running:
   ```bash
   systemctl status cron
   ```

3. Check cron logs:
   ```bash
   grep CRON /var/log/syslog | tail -20
   ```

### Updates failing

1. View error log:
   ```bash
   update-logs-errors
   ```

2. Run manually to see live output:
   ```bash
   /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
   ```

3. Check specific component:
   ```bash
   # Test GitHub CLI update
   sudo apt update && sudo apt upgrade gh

   # Test npm updates
   npm update -g
   ```

### Logs not showing

1. Check log directory exists:
   ```bash
   ls -la /tmp/daily-updates-logs/
   ```

2. Check script has run:
   ```bash
   ls -lt /tmp/daily-updates-logs/
   ```

3. Run script manually to generate logs:
   ```bash
   update-all
   ```

## 📚 Additional Resources

- **GitHub CLI Documentation**: https://cli.github.com/manual/
- **Oh My Zsh Updates**: https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ
- **npm Documentation**: https://docs.npmjs.com/cli/commands/npm-update

## 🔐 Security Notes

- Script runs with your user permissions
- `sudo` is only used for apt package updates
- You may be prompted for your password during updates
- All updates use official package managers and repositories
- No external scripts or untrusted sources

## 📄 Files Created

- `/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh` - Main update script
- `/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh` - Log viewer utility
- `/home/kkk/.zshrc` - Updated with aliases and notification
- Crontab entry - Scheduled daily execution

## 🎯 Quick Reference

```bash
# Manual update
update-all

# View summary
update-logs

# View full log
update-logs-full

# View errors
update-logs-errors

# Edit schedule
crontab -e

# Disable auto-updates
crontab -r

# Re-enable auto-updates
crontab /tmp/daily-updates-crontab.txt
```

---

## 📦 Uninstall Scripts Reference

### Ghostty Uninstall (`lib/installers/ghostty/uninstall.sh`)

**What it removes:**
- Ghostty binary from `~/Apps/zig-out/bin/ghostty`
- Ghostty source directory from `~/Apps/ghostty/`
- Config symlink at `~/.config/ghostty/config`
- Desktop application entry
- PATH entries in shell configs

**Exit codes:**
- `0` - Successfully uninstalled
- `2` - Not installed (clean state)

### Zig Uninstall (`lib/installers/zig/uninstall.sh`)

**What it removes:**
- Zig installation directory from `~/Apps/zig/`
- Zig symlink from `~/Apps/zig-out/bin/zig`
- PATH entries from shell configs

**Exit codes:**
- `0` - Successfully uninstalled
- `2` - Not installed (clean state)

---

**Last Updated**: 2025-11-22
**Version**: 2.1
**Maintainer**: ghostty-config-files automation
