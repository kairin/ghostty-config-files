# Ghostty Configuration with Comprehensive Terminal Tools (2025 Edition)

A complete terminal environment setup featuring Ghostty terminal emulator with **2025 performance optimizations**, right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI) and modern web development stack with Astro.build.

## 🏗️ Project Status

**Implementation Progress: 24 of 58 tasks completed (41%)**

### ✅ Completed Features
- ✅ Modern web development stack (Astro.build + Tailwind CSS + shadcn/ui)
- ✅ Local CI/CD infrastructure with zero GitHub Actions consumption
- ✅ Constitutional compliance framework with TDD methodology
- ✅ Performance validation framework (Lighthouse 95+ targets)
- ✅ Context menu integration ("Open in Ghostty")
- ✅ AI tool integration (Claude Code + Gemini CLI)
- ✅ Complete test suite (35 properly failing tests)
- ✅ Comprehensive logging and debugging systems

### 🚧 System Installation Status
Based on recent verification (2025-01-20):

**✅ Currently Working:**
- **Ghostty**: v1.2.0 (installed via Snap, not source build)
- **Context Menu**: Functional "Open in Ghostty" integration
- **Ptyxis**: v47.5 (installed via APT, not Flatpak)
- **Node.js**: v22.13.1 via NVM (working)
- **Claude Code CLI**: v0.12.2 (working)
- **Gemini CLI**: v0.1.13 (working)
- **Complete development environment**: Python, TypeScript, testing frameworks

**❌ Installation Gaps:**
- **ZSH + Oh My ZSH**: Not installed (system using bash)
- **Zig 0.14.0**: Not installed (Ghostty via Snap instead of source)
- **Flatpak**: Not installed (Ptyxis via APT instead)

### 📋 Current Development Phase
**Phase 3.5**: Local CI/CD Runner Implementation (5 remaining tasks)
- Next phases include core development, monitoring, documentation, and deployment automation

## 🚀 One-Command Installation

```bash
./start.sh
```

This command manages installation and configuration:
- **Modern Web Stack** - Astro.build + Tailwind CSS + shadcn/ui with TypeScript
- **Local CI/CD** - Zero GitHub Actions consumption with local runners
- **Context Menu** - Right-click "Open in Ghostty" integration (✅ working)
- **AI Tools** - Claude Code + Gemini CLI integration (✅ working)
- **Node.js** - Latest LTS via NVM (✅ working)
- **Development Environment** - Python via uv, TypeScript, testing frameworks (✅ working)

**Note**: Some documented installations (ZSH, Zig, Flatpak) are currently gaps in the system but core functionality works via alternative methods (Ghostty via Snap, Ptyxis via APT).

## ✨ Features

### 🚀 Modern Web Development Stack
- **Astro.build v5.13.9** - High-performance static site generation with TypeScript strict mode
- **Tailwind CSS v3.4.17** - Constitutional design system with CSS variables and dark mode
- **shadcn/ui Integration** - Component-driven architecture with accessibility plugins
- **Performance Targets** - Lighthouse 95+ scores, JavaScript <100KB, build time <30s
- **Local CI/CD** - Zero GitHub Actions consumption with comprehensive local runners

### 📁 Right-Click Context Menu
- **Nautilus Integration** - Right-click any folder → "Scripts" → "Open in Ghostty"
- **Smart Path Handling** - Works with files, folders, and special characters
- **Automatic Installation** - Fully integrated into the setup process

### Modern Development Infrastructure
- **`astro.config.mjs`** - Astro configuration with GitHub Pages deployment and TypeScript strict mode
- **`tailwind.config.mjs`** - Constitutional design system with dark mode and performance optimizations
- **`pyproject.toml`** - uv-first Python management with ruff, black, mypy strict tooling
- **`tsconfig.json`** - TypeScript strict mode with path mapping and performance optimizations
- **`local-infra/runners/`** - Local CI/CD infrastructure eliminating GitHub Actions consumption

### Constitutional Compliance Framework
- **Test-Driven Development** - 35 properly failing tests across contract, integration, and performance
- **uv-First Python Management** - Strict tooling with ruff, black, mypy compliance
- **Performance Validation** - Lighthouse 95+ scores, bundle size limits, build time targets
- **Zero GitHub Actions Consumption** - Complete local CI/CD infrastructure
- **Branch Preservation Strategy** - Timestamped branches with constitutional merging
- **Comprehensive logging** - Detailed logs with system state capture and debugging

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

## 🤖 AI Assistant Setup (✅ Working)

### Claude Code (v0.12.2)
Already authenticated and working:
```bash
claude --version  # v0.12.2
```
Working with development environment integration.

### Gemini CLI (v0.1.13)
Already configured and working:
```bash
gemini --version  # v0.1.13
```

### Ptyxis Integration (v47.5 via APT)
The `gemini` command works with Ptyxis terminal integration:
```bash
gemini "your prompt here"  # Runs with proper working directory context
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
# Verify Ghostty (Snap installation)
snap list | grep ghostty
ghostty --version  # v1.2.0

# Verify AI tools (working)
claude --version   # v0.12.2
gemini --version   # v0.1.13

# Verify Ptyxis (APT installation)
apt list --installed | grep ptyxis
ptyxis --version   # v47.5

# Verify development environment
uv --version       # v0.8.15
node --version     # v22.13.1
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

2. **Development Environment Issues**:
   - Ensure all dependencies are installed: `./start.sh --verbose`
   - Check uv installation: `uv --version` (should be ≥0.8.15)
   - Run local CI/CD validation: `./local-infra/runners/astro-build-local.sh`

3. **AI Tools Not in PATH**:
   - Restart your terminal or run: `source ~/.bashrc`
   - Check Node.js installation: `node --version`
   - Verify npm global installs: `npm list -g`

## 📚 Additional Resources

- **AI Agent Guidelines**: [AGENTS.md](./AGENTS.md) - Complete instructions for AI assistants
- **Development Progress**: [CHANGELOG.md](./CHANGELOG.md) - Comprehensive implementation tracking
- **Spec-Kit Methodology**: [spec-kit/SPEC_KIT_GUIDE.md](./spec-kit/SPEC_KIT_GUIDE.md) - Constitutional development approach
- **Claude Code Setup**: [CLAUDE.md](./CLAUDE.md) - Detailed Claude Code configuration
- **Gemini CLI Setup**: [GEMINI.md](./GEMINI.md) - Detailed Gemini CLI configuration
- **Astro Documentation**: https://docs.astro.build - Modern web development stack
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