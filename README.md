# Ghostty Configuration with Comprehensive Terminal Tools (2025 Edition)

A complete terminal environment setup featuring Ghostty terminal emulator with **2025 performance optimizations**, right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI) and Ptyxis terminal via Flatpak.

## 🚀 One-Command Installation

```bash
./start.sh
```

This single command installs and configures everything you need:
- **ZSH** - Modern shell with Oh My ZSH and enhanced plugins
- **Ghostty** - Latest version built from source with Zig 0.14.0 + **2025 optimizations**
- **Context Menu** - Right-click "Open in Ghostty" integration for file managers
- **Ptyxis** - Latest version via Flatpak with proper permissions
- **Node.js** - Latest LTS via NVM with npm
- **Claude Code** - Latest AI assistant CLI
- **Gemini CLI** - Google's AI assistant CLI
- **All Dependencies** - Complete development environment

## ✨ Features

### 🚀 2025 Performance Optimizations
- **Linux CGroup Single Instance** - Dramatically faster startup and reduced memory usage
- **Enhanced Shell Integration** - Auto-detection with cursor, sudo, title, and SSH features
- **Memory Management** - Optimized scrollback limits and cgroup process controls
- **Auto Theme Switching** - Light/dark mode support with Catppuccin themes
- **Security Features** - Clipboard paste protection

### 📁 Right-Click Context Menu
- **Nautilus Integration** - Right-click any folder → "Scripts" → "Open in Ghostty"
- **Smart Path Handling** - Works with files, folders, and special characters
- **Automatic Installation** - Fully integrated into the setup process

### Modular Ghostty Configuration
- **`configs/ghostty/theme.conf`** - Theme and appearance settings with 2025 optimizations
- **`configs/ghostty/scroll.conf`** - Scrollback and history settings
- **`configs/ghostty/layout.conf`** - Font, padding, and window layout settings
- **`configs/ghostty/keybindings.conf`** - Optimized keybindings for productivity
- **`configs/ghostty/config`** - Main configuration file with performance optimizations

### Smart Installation Management
- **Intelligent Detection** - Automatically detects existing installations
- **Smart Upgrade Logic** - Chooses optimal update vs reinstall strategy
- **Version Checking** - Monitors for online updates and compatibility
- **Configuration Validation** - Automatic backup, testing, and recovery
- **Cross-platform compatibility** (Ubuntu/Debian focus)
- **Comprehensive logging** - Detailed logs with error recovery

### Safety Features
- **Automatic backup** before any configuration changes
- **Configuration validation** using `ghostty +show-config`
- **Safe recovery** - automatic restoration of last working configuration
- **Comprehensive logging** - detailed logs for troubleshooting

## 📦 Quick Start

1. **Clone this repository:**
   ```bash
   git clone <repository-url> ~/.config/ghostty
   cd ~/.config/ghostty
   ```

2. **Run the installer:**
   ```bash
   ./start.sh
   ```

3. **Follow the prompts** and restart your terminal when complete.

## ⚙️  Installation Options

The `start.sh` script supports various options for customized installation:

```bash
./start.sh --help              # Show all options
./start.sh --skip-deps         # Skip system dependencies
./start.sh --skip-node         # Skip Node.js/NVM installation  
./start.sh --skip-ai           # Skip AI tools (Claude Code, Gemini CLI)
./start.sh --skip-ptyxis       # Skip Ptyxis installation
./start.sh --verbose           # Verbose logging output
```

## 🤖 AI Assistant Setup

### Claude Code
After installation, authenticate with:
```bash
claude-code auth login
```
Get your API key from: https://console.anthropic.com

### Gemini CLI  
Set up your API key:
```bash
export GEMINI_API_KEY="your-api-key-here"
```
Get your API key from: https://makersuite.google.com/app/apikey

### Ptyxis with Gemini Integration
The installation creates a seamless integration where the `gemini` command automatically launches in Ptyxis:
```bash
gemini "your prompt here"  # Automatically runs in Ptyxis terminal with proper working directory
```

## 🔧 Configuration Management

### Reload Ghostty Config
- **Keystroke**: `Cmd+S > R` (or `Ctrl+S > R` on Linux)
- **Command**: `ghostty +show-config` (to validate)

### Intelligent Updates

**Smart Update Checker** (automatically detects what needs updating):
```bash
./scripts/check_updates.sh  # Check and apply only necessary updates
```

**Force Full Update**:
```bash
./start.sh  # Re-run to update all components (handles existing installations intelligently)
```

**Update Options**:
```bash
./scripts/check_updates.sh --force        # Force update even if no changes detected
./scripts/check_updates.sh --config-only  # Only update configuration
./scripts/check_updates.sh --help         # Show all options
```

### Manual Updates
- **Ghostty**: `./scripts/update_ghostty.sh`
- **Configuration**: `./scripts/install_ghostty_config.sh`
- **Dependencies**: `./start.sh --verbose`

## 📋 Project Structure

```
ghostty-config-files/
├── start.sh              # 🚀 Primary installation script
├── README.md             # This file - user documentation  
├── AGENTS.md            # AI agent instructions (single source of truth)
├── CLAUDE.md            # Claude Code setup guide
├── GEMINI.md            # Gemini CLI setup guide
├── configs/             # Configuration files
│   ├── ghostty/         # Ghostty terminal configuration
│   │   ├── config       # Main configuration file
│   │   ├── theme.conf   # Theme settings
│   │   ├── scroll.conf  # Scrollback settings
│   │   ├── layout.conf  # Layout and font settings
│   │   └── keybindings.conf # Keybinding configuration
│   └── workspace/       # Development workspace files
│       └── ghostty.code-workspace # VS Code workspace
└── scripts/             # Additional utility scripts
    ├── install_ghostty_config.sh
    ├── update_ghostty.sh
    ├── fix_config.sh
    └── agent_functions.sh
```

## 🛠️ Troubleshooting

### Check Installation Status
```bash
# Verify Ghostty
ghostty --version
ghostty +show-config

# Verify AI tools
claude-code --version
gemini --version  

# Verify Ptyxis
flatpak list | grep Ptyxis
```

### View Logs
Installation logs are stored in `/tmp/ghostty-start-logs/`:
```bash
# View latest installation log
ls -la /tmp/ghostty-start-logs/
tail -f /tmp/ghostty-start-logs/start-*.log
```

### Common Issues

1. **Configuration Validation Errors**: 
   - Automatic backup restoration will occur
   - Check logs for specific configuration issues
   - Run `ghostty +show-config` manually to debug

2. **Build Failures**:
   - Ensure all dependencies are installed: `./start.sh --verbose`
   - Check Zig version: `zig version` (should be 0.14.0)
   - View build logs in `/tmp/ghostty-start-logs/`

3. **AI Tools Not in PATH**:
   - Restart your terminal or run: `source ~/.bashrc`
   - Check Node.js installation: `node --version`
   - Verify npm global installs: `npm list -g`

## 📚 Additional Resources

- **AI Agent Guidelines**: [AGENTS.md](./AGENTS.md) - Complete instructions for AI assistants
- **Claude Code Setup**: [CLAUDE.md](./CLAUDE.md) - Detailed Claude Code configuration
- **Gemini CLI Setup**: [GEMINI.md](./GEMINI.md) - Detailed Gemini CLI configuration
- **Ghostty Documentation**: https://ghostty.org/docs/config
- **Ptyxis Documentation**: https://gitlab.gnome.org/chergert/ptyxis

## 🔒 Security

- Sudo access is only requested when necessary
- API keys and credentials are never logged
- Configuration backups protect against corruption
- Flatpak sandboxing for Ptyxis provides security isolation

## 🤝 Contributing

For AI assistants working on this project, please refer to [AGENTS.md](./AGENTS.md) for comprehensive guidelines, workflows, and best practices.

## 📄 License

This configuration is provided as-is for educational and personal use. Please respect the licenses of the individual tools and applications.