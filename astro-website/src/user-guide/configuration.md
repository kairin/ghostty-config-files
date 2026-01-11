---
title: Configuration Guide
description: Guide to customizing your Ghostty terminal and development environment
---

# Configuration Guide

This guide covers customizing your Ghostty terminal and the broader development environment.

## Ghostty Configuration

### Configuration Location

Ghostty configuration is stored in:

```
~/.config/ghostty/config
```

The project installs a pre-configured setup from `configs/ghostty/`.

### Key Configuration Options

#### Performance Settings

```ini
# CGroup optimization for single-instance performance
linux-cgroup = single-instance

# Unlimited scrollback with memory protection
scrollback-limit = 999999999
```

#### Theme Settings

The project includes Catppuccin themes:

```ini
# Dark theme (default)
theme = catppuccin-mocha

# Light theme
theme = catppuccin-latte
```

#### Font Configuration

```ini
# Font family (Nerd Font recommended)
font-family = JetBrainsMono Nerd Font

# Font size
font-size = 12

# Font features
font-feature = calt
font-feature = liga
```

#### Shell Integration

```ini
# Enable shell integration features
shell-integration = detect-and-report
shell-integration-features = cursor,sudo,title
```

#### Clipboard Settings

```ini
# Clipboard paste protection
clipboard-paste-protection = true
clipboard-read = allow
clipboard-write = allow
```

### Validate Configuration

Always validate after making changes:

```bash
ghostty +show-config
```

## Dynamic Theme Switching

The project includes automatic light/dark theme switching:

### Manual Control

```bash
# Apply current system theme
./scripts/ghostty-theme-switcher.sh apply

# Force dark theme
./scripts/ghostty-theme-switcher.sh dark

# Force light theme
./scripts/ghostty-theme-switcher.sh light

# Show current status
./scripts/ghostty-theme-switcher.sh status
```

### Automatic Monitoring

The theme switcher can monitor GNOME/GTK color scheme changes:

```bash
# Start monitoring (runs in foreground)
./scripts/ghostty-theme-switcher.sh monitor
```

### Systemd Service (Optional)

For automatic background monitoring, create a systemd user service:

```bash
# The service file should be created at:
# ~/.config/systemd/user/ghostty-theme-switcher.service

# Enable and start
systemctl --user enable ghostty-theme-switcher.service
systemctl --user start ghostty-theme-switcher.service
```

## ZSH Configuration

### Oh My ZSH

The project installs Oh My ZSH with useful plugins. Configuration is in:

```
~/.zshrc
```

### Recommended Plugins

The installer configures these plugins:

- `git` - Git aliases and functions
- `zsh-autosuggestions` - Fish-like suggestions
- `zsh-syntax-highlighting` - Command highlighting
- `z` - Directory jumping

### PowerLevel10k (Optional)

For an enhanced prompt, see:
- [PowerLevel10k Integration](../developer/powerlevel10k/README.md)

## AI Tools Configuration

### Claude Code

After installation, configure:

```bash
# Login to Claude
claude login
```

### Gemini CLI

After installation, configure:

```bash
# Login to Gemini
gemini login
```

### MCP Servers

MCP server configuration is in `.mcp.json`:

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    },
    "github": {
      "command": "bash",
      "args": ["-c", "GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github"]
    }
  }
}
```

See:
- [Context7 MCP Setup](/.claude/instructions-for-agents/guides/context7-mcp.md)
- [GitHub MCP Setup](/.claude/instructions-for-agents/guides/github-mcp.md)

## Update Configuration

### Daily Updates

Configure automated daily updates:

```bash
# Install cron job (runs at 9 AM)
./scripts/daily-updates.sh --install-cron

# Run updates manually
./scripts/daily-updates.sh

# Dry run (check only)
./scripts/daily-updates.sh --dry-run
```

### Shell Aliases

After installation, these aliases are available:

| Alias | Command | Description |
|-------|---------|-------------|
| `update-all` | `./scripts/daily-updates.sh` | Run all updates |
| `update-check` | Check for updates | Quick update check |
| `update-logs` | View logs | Show update summary |

## Context Menu Integration

The project adds "Open in Ghostty" to the Nautilus right-click menu.

### Verify Installation

Right-click on any folder in Nautilus - you should see "Open in Ghostty".

### Troubleshooting

If the context menu is missing:

```bash
# Reinstall the desktop action
cp configs/ghostty/ghostty-open.desktop ~/.local/share/nautilus/scripts/
nautilus -q  # Restart Nautilus
```

## Directory Colors

The project installs XDG-compliant dircolors for better directory listing readability.

### Configuration Location

```
~/.config/dircolors
```

### Apply Changes

If you modify dircolors:

```bash
# Reload dircolors
eval "$(dircolors ~/.config/dircolors)"
```

## Customization Tips

### Adding Custom Keybindings

Add to your Ghostty config:

```ini
# Example: Open new tab
keybind = ctrl+t=new_tab

# Example: Close tab
keybind = ctrl+w=close_surface
```

### Custom Fonts

1. Download a Nerd Font from [nerdfonts.com](https://www.nerdfonts.com/)
2. Install to `~/.local/share/fonts/`
3. Update font-family in Ghostty config
4. Run `fc-cache -fv` to refresh font cache

### Theme Creation

Create custom themes by copying an existing theme:

```bash
cp configs/ghostty/catppuccin-mocha.conf configs/ghostty/my-theme.conf
# Edit my-theme.conf with your colors
```

## Related Documentation

- [Installation Guide](./installation.md)
- [Daily Updates README](../../scripts/DAILY_UPDATES_README.md)
- [PowerLevel10k Integration](../developer/powerlevel10k/README.md)
