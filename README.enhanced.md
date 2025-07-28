# 🚀 Enhanced Ghostty Configuration

This repository contains an enhanced Ghostty terminal configuration based on productivity best practices and workflow optimization.

## 📋 Available Configurations

### 1. **Enhanced Configuration** (Recommended)
- **Modular design** with separate config files for easy maintenance
- **Productivity-focused keybindings** using `cmd+s` as leader key
- **Optimized scrolling** for large logs and development work
- **Modern aesthetics** with transparency and blur effects
- **GPU performance optimizations** for smooth operation
- **Developer workflow features** like split management and quick navigation

### 2. **Custom Configuration**
- Your original configuration snippet with improvements
- Vesper theme with 15pt font
- Enhanced cell height (35%) for better readability
- 2x scroll multiplier for faster navigation
- Copy-on-select functionality

### 3. **Default Configuration**
- Simple, minimal setup
- Modular file structure for easy customization

## 🛠️ Configuration Manager

Use the `config-manager.sh` script to easily switch between configurations:

```bash
# Show current config and available options
./config-manager.sh

# Apply enhanced productivity configuration
./config-manager.sh enhanced

# Apply your custom configuration
./config-manager.sh custom

# Restore default configuration
./config-manager.sh default
```

## 🔧 Configuration Files Structure

```
├── config                          # Main configuration file
├── config-manager.sh               # Configuration management script
├── update-config.sh                # Git update script
├── productivity.conf               # Productivity features
├── theme.enhanced.conf             # Enhanced theme settings
├── keybindings.enhanced.conf       # Comprehensive keybindings
├── scroll.enhanced.conf            # Optimized scrolling
├── layout.enhanced.conf            # Window layout settings
└── README.enhanced.md              # This file
```

## ⚡ Key Features from Enhanced Config

### 🎯 Leader Key Workflow
All commands use `cmd+s` as a leader key to avoid conflicts:

**Window & Tab Management:**
- `cmd+s>n` - New window
- `cmd+s>c` - New tab
- `cmd+s>w` - Close tab
- `cmd+s>1-9` - Switch to tab 1-9

**Split/Pane Management:**
- `cmd+s>\` - Split right
- `cmd+s>-` - Split down
- `cmd+s>hjkl` - Navigate splits (vim-style)
- `cmd+s>z` - Toggle pane zoom
- `cmd+s>e` - Equalize all splits

**Search & Navigation:**
- `cmd+s>f` - Search in terminal
- `cmd+s>g` - Go to top
- `cmd+s>shift+g` - Go to bottom

### 🎨 Visual Enhancements
- **Background transparency** with blur effects
- **Optimized color schemes** for long coding sessions
- **Improved font rendering** with adjustable cell height
- **Visual feedback** for unfocused splits

### 🚀 Performance Optimizations
- **Large scrollback buffer** (100,000 lines) for debugging
- **GPU acceleration** settings for smooth rendering
- **Optimized image storage** for terminal graphics
- **Reduced visual overhead** for better performance

## 🔄 Updating Configuration

The repository includes an update script that safely manages git updates:

```bash
./update-config.sh
```

This script will:
- Stash any local changes
- Pull the latest updates from GitHub
- Show you what changed
- Preserve your local modifications

## 💡 Productivity Tips

Based on the article's recommendations:

1. **Use split panes** for multi-tasking:
   - One pane for development server
   - Another for git commands
   - Third for monitoring/logs

2. **Leverage the large scrollback** for debugging:
   - 100,000 lines of history
   - Fast search with `cmd+s>f`
   - Quick navigation to errors

3. **Customize for your workflow**:
   - Modify `productivity.conf` for your specific needs
   - Add custom keybindings in `keybindings.enhanced.conf`
   - Adjust colors in `theme.enhanced.conf`

## 🎛️ Customization

### Adding Custom Keybindings
Edit `keybindings.enhanced.conf` and add:
```
keybind = cmd+s>your_key=your_action
```

### Changing Themes
Edit `theme.enhanced.conf` to change the base theme:
```
theme = "your-preferred-theme"
```

### Modifying Appearance
Edit `productivity.conf` for font size, opacity, and visual settings.

## 🔍 Troubleshooting

**Config not loading?**
- Restart Ghostty completely
- Run `ghostty +reload-config`
- Check for syntax errors with `ghostty +validate-config`

**Keybindings not working?**
- Ensure you're using the leader key (`cmd+s>`)
- Check for conflicts with system shortcuts
- Try the enhanced configuration: `./config-manager.sh enhanced`

**Performance issues?**
- The enhanced config includes GPU optimizations
- Large scrollback might use more memory (adjust `scrollback-limit`)

## 🆘 Getting Help

- **Show all config options**: `ghostty +show-config --default --docs`
- **List available themes**: `ghostty +list-themes`
- **Validate config**: `ghostty +validate-config`
- **Current config**: `./config-manager.sh`

---

*This enhanced configuration is inspired by productivity tips and best practices for terminal workflow optimization.*
