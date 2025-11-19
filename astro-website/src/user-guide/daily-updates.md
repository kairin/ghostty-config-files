---
title: 'Automated Daily Updates'
description: 'Smart system-wide updates at 9:00 AM daily with full logging and passwordless execution'
pubDate: 2025-11-13
author: 'System Documentation'
tags: ['updates', 'automation', 'cron', 'maintenance', 'system']
order: 5
---

# Automated Daily Updates

Keep your system and tools up-to-date automatically with intelligent daily updates.

## Overview

The configuration includes a smart automated update system that runs daily at 9:00 AM. All system packages, development tools, and AI assistants are updated automatically with full logging.

## What Gets Updated

### System Packages (apt)
- GitHub CLI (`gh`)
- All installed system packages
- Automatic cleanup with `autoremove`

### Development Tools
- Oh My Zsh framework
- Oh My Zsh plugins
- npm package manager
- All global npm packages

### AI Tools
- Claude CLI (`@anthropic-ai/claude-code`)
- Gemini CLI (`@google/gemini-cli`)
- GitHub Copilot CLI (`@github/copilot`)

## Features

### Automated Scheduling
- Runs daily at 9:00 AM via cron
- Non-interactive execution
- Background operation (doesn't interrupt work)

### Smart Notifications
- Terminal startup notification (once per day)
- Summary of last update run
- Error notifications if updates fail

### Full Logging
- Complete update output logged
- Timestamped log files
- Error tracking and reporting

### Passwordless Execution
- Requires proper sudoers configuration
- Secure, limited sudo access
- Only for apt package management

## Manual Operations

### Run Updates Now

```bash
# Execute all updates immediately
update-all
```

This runs the complete update sequence:
1. apt update and upgrade
2. Oh My Zsh updates
3. npm updates
4. AI tool updates

### View Update Logs

```bash
# Latest update summary
update-logs

# Complete detailed log
update-logs-full

# Errors only
update-logs-errors

# Browse all log files
ls -la /tmp/daily-updates-logs/
```

### Log File Locations

All logs are stored in `/tmp/daily-updates-logs/`:
- `daily-updates-YYYYMMDD.log` - Complete update output
- `daily-updates-YYYYMMDD-errors.log` - Errors only
- `daily-updates-latest.log` - Symlink to most recent log

## Configuration

### View Current Schedule

```bash
# Check cron configuration
crontab -l
```

Default schedule:
```cron
# Daily updates at 9:00 AM
0 9 * * * /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
```

### Change Schedule

```bash
# Edit crontab
crontab -e
```

Example schedules:
```cron
# Run at 6:00 AM instead
0 6 * * * /path/to/daily-updates.sh

# Run twice daily (9 AM and 9 PM)
0 9,21 * * * /path/to/daily-updates.sh

# Run on weekdays only at 8 AM
0 8 * * 1-5 /path/to/daily-updates.sh
```

### Disable Automated Updates

```bash
# Remove from crontab
crontab -e
# Comment out or delete the daily-updates line
```

## Passwordless Sudo Setup

For fully automated apt updates, configure passwordless sudo for apt only.

### Setup Steps

```bash
# Edit sudoers file (use visudo for safety)
sudo EDITOR=nano visudo

# Add this line (replace 'kkk' with your username):
kkk ALL=(ALL) NOPASSWD: /usr/bin/apt

# Save and exit
```

### Security Notes

- **Limited scope**: Only `/usr/bin/apt` has passwordless sudo
- **Not unrestricted**: Cannot use sudo for other commands
- **Safe configuration**: Uses visudo for syntax validation
- **Recommended**: This is the standard approach for automated package management

### Verify Configuration

```bash
# Test passwordless apt
sudo -n apt update

# Should run without password prompt
# If it asks for password, configuration needs adjustment
```

### Alternative: Interactive Updates

If you prefer manual control:
1. Don't configure passwordless sudo
2. Run updates manually with `update-all`
3. Enter password when prompted
4. Disable automated cron job

## Update Process Details

### Phase 1: System Packages
```bash
sudo apt update          # Update package lists
sudo apt upgrade -y      # Upgrade all packages
sudo apt autoremove -y   # Remove unnecessary packages
```

### Phase 2: Oh My Zsh
```bash
omz update              # Update Oh My Zsh framework
# Updates all installed plugins automatically
```

### Phase 3: npm & Global Packages
```bash
npm install -g npm@latest           # Update npm itself
npm update -g                       # Update all global packages
```

### Phase 4: AI Tools
```bash
npm update -g @anthropic-ai/claude-code  # Claude CLI
npm update -g @google/gemini-cli         # Gemini CLI
npm update -g @github/copilot            # GitHub Copilot
```

## Startup Notifications

### First Terminal of the Day
When you open the first terminal after updates run, you'll see:
```
📦 Daily updates completed successfully at 09:15:32
✅ System packages updated
✅ Oh My Zsh updated
✅ npm packages updated
✅ AI tools updated

View full log: update-logs
```

### Subsequent Terminals
No notification shown (once per day per user).

### Error Notifications
If updates fail:
```
⚠️  Daily updates encountered errors at 09:15:32
❌ Check logs for details: update-logs-errors
```

## Troubleshooting

### Updates Not Running

**Check cron status**:
```bash
# Verify cron service is running
systemctl status cron

# Check crontab entries
crontab -l
```

**Check script permissions**:
```bash
# Script must be executable
chmod +x /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh
```

### Passwordless Sudo Not Working

**Verify sudoers configuration**:
```bash
# Test passwordless apt
sudo -n apt update

# If it asks for password:
sudo visudo
# Verify the NOPASSWD line is present and correct
```

### npm Updates Failing

**Check npm configuration**:
```bash
# Verify npm is properly installed
npm --version

# Check global packages location
npm config get prefix

# Reinstall npm if needed
sudo apt install npm
```

### Logs Not Created

**Check log directory**:
```bash
# Verify directory exists and is writable
ls -la /tmp/daily-updates-logs/

# Create if missing
mkdir -p /tmp/daily-updates-logs
chmod 755 /tmp/daily-updates-logs
```

## Best Practices

### Monitor Logs Regularly
```bash
# Check logs weekly
update-logs

# Review errors monthly
update-logs-errors
```

### Test Updates Before Automation
```bash
# First time: run manually to verify
update-all

# Check for errors
update-logs-errors

# If successful, enable automated cron
```

### Backup Important Configurations
Before enabling automated updates:
```bash
# Backup Ghostty config
cp ~/.config/ghostty/config ~/.config/ghostty/config.backup

# Backup shell configs
cp ~/.zshrc ~/.zshrc.backup
cp ~/.bashrc ~/.bashrc.backup
```

### Review Update History
```bash
# Check all log files
ls -lah /tmp/daily-updates-logs/

# Compare timestamps to verify daily execution
```

## Integration with Guardian Commands

Daily updates integrate with guardian health checks:

```bash
# Check system health including update status
/guardian-health
```

This verifies:
- Last update timestamp
- Update success/failure status
- Available updates
- System package health

## Advanced Configuration

### Custom Update Script

Extend the update system:
```bash
# Create custom update script
cat > ~/.local/bin/custom-updates.sh << 'EOF'
#!/bin/bash
# Add custom updates here
# Example: Update flatpak apps
flatpak update -y

# Example: Update snap packages
sudo snap refresh
EOF

chmod +x ~/.local/bin/custom-updates.sh

# Add to crontab after main updates
crontab -e
# Add: 0 9 * * * ~/.local/bin/custom-updates.sh >> /tmp/custom-updates.log 2>&1
```

### Notification Integration

Add desktop notifications:
```bash
# Install notification tool if needed
sudo apt install libnotify-bin

# Modify update script to send notifications
notify-send "Updates Complete" "Daily system updates finished successfully"
```

## Related Documentation

- [Installation Guide](./installation.md) - Initial setup
- [Configuration Guide](./configuration.md) - Customization options
- [Usage Guide](./usage.md) - Daily operations and commands
- [MCP Integration](./mcp-integration.md) - AI tool updates
