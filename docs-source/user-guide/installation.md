---
title: "Installation Guide"
description: "Complete installation guide for Ghostty Configuration Files on Ubuntu 25.10+"
pubDate: 2025-10-27
author: "Ghostty Configuration Files Team"
tags: ["installation", "setup", "quickstart"]
order: 1
---

# Installation Guide

Welcome to the Ghostty Configuration Files installation guide. This guide will walk you through installing and setting up your complete Ghostty terminal environment on Ubuntu 25.10+.

## Quick Start

For a fresh Ubuntu installation, use the one-command setup:

```bash
cd /home/kkk/Apps/ghostty-config-files
./start.sh
```

This will install:
- Ghostty terminal emulator (built from source)
- ZSH with Oh My ZSH
- Node.js LTS (via NVM)
- Context menu integration ("Open in Ghostty")
- AI tools (Claude Code, Gemini CLI)
- All configuration and optimizations

## Prerequisites

### System Requirements
- **OS**: Ubuntu 25.10+ (or compatible Debian-based distribution)
- **Architecture**: x86_64 (amd64)
- **Shell**: ZSH (configured by installation), Bash 5.x+ (for scripts)
- **Disk Space**: ~2GB for full installation
- **Memory**: 2GB+ RAM recommended

### Required Packages
The installation script will automatically install required dependencies:
- Build tools (gcc, make, pkg-config, cmake)
- Zig compiler (0.14.0) for Ghostty compilation
- Git for repository management
- curl/wget for downloads

## Installation Methods

### Method 1: Automated Installation (Recommended)

The simplest method - one command does everything:

```bash
# Clone the repository
git clone https://github.com/your-username/ghostty-config-files.git
cd ghostty-config-files

# Run automated installation
./start.sh
```

**What this does**:
1. Checks for required dependencies
2. Installs Node.js LTS via NVM
3. Installs Zig compiler 0.14.0
4. Builds Ghostty from source
5. Configures ZSH with Oh My ZSH
6. Installs context menu integration
7. Applies all optimizations
8. Sets up AI tools

### Method 2: Using manage.sh (New Unified Interface)

For more control over what gets installed:

```bash
# Install everything
./manage.sh install

# Install with specific components
./manage.sh install --skip-node      # Skip Node.js
./manage.sh install --skip-zig       # Skip Zig
./manage.sh install --skip-ghostty   # Skip Ghostty build
./manage.sh install --skip-zsh       # Skip ZSH setup
./manage.sh install --skip-theme     # Skip theme configuration
./manage.sh install --skip-context-menu  # Skip context menu

# Dry run to see what would be installed
./manage.sh install --dry-run

# Force reinstallation
./manage.sh install --force
```

### Method 3: Manual Component Installation

For advanced users who want full control:

#### Step 1: Install Node.js
```bash
# Using NVM (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm use --lts
```

#### Step 2: Install Zig Compiler
```bash
# Download and install Zig 0.14.0
wget https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz
tar -xf zig-linux-x86_64-0.14.0.tar.xz
sudo mv zig-linux-x86_64-0.14.0 /usr/local/zig-0.14.0
sudo ln -s /usr/local/zig-0.14.0/zig /usr/local/bin/zig
```

#### Step 3: Build Ghostty
```bash
# Clone Ghostty repository
git clone https://github.com/ghostty-org/ghostty.git
cd ghostty

# Build with Zig
zig build -Doptimize=ReleaseFast

# Install binary
sudo cp zig-out/bin/ghostty /usr/local/bin/
```

#### Step 4: Install Configuration
```bash
# Copy Ghostty configuration
mkdir -p ~/.config/ghostty
cp configs/ghostty/config ~/.config/ghostty/
cp configs/ghostty/*.conf ~/.config/ghostty/
```

#### Step 5: Setup ZSH
```bash
# Install ZSH
sudo apt install zsh

# Install Oh My ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set as default shell
chsh -s $(which zsh)
```

#### Step 6: Context Menu Integration
```bash
./scripts/install_context_menu.sh
```

## Post-Installation

### Verify Installation

```bash
# Check Ghostty version
ghostty --version

# Validate configuration
ghostty +show-config

# Check system status
./manage.sh validate
```

### First Launch

1. Open Ghostty terminal
2. Verify theme is applied (Catppuccin)
3. Test context menu: Right-click folder → "Open in Ghostty"
4. Verify shell integration (auto-complete, directory tracking)

### Configure AI Tools (Optional)

#### Claude Code
```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Authenticate
claude auth login
```

#### Gemini CLI
```bash
# Install Gemini CLI
npm install -g @google/generative-ai-cli

# Authenticate with API key
gemini-cli auth
```

## Troubleshooting

### Ghostty Build Fails

**Issue**: Zig compilation errors

**Solution**:
```bash
# Ensure correct Zig version
zig version  # Should be 0.14.0

# Clean and rebuild
cd ghostty
rm -rf zig-cache zig-out
zig build -Doptimize=ReleaseFast
```

### Configuration Not Applied

**Issue**: Ghostty ignores configuration

**Solution**:
```bash
# Validate configuration syntax
ghostty +show-config

# Check file permissions
ls -la ~/.config/ghostty/config

# Reset to defaults
cp configs/ghostty/config ~/.config/ghostty/config
```

### Context Menu Missing

**Issue**: "Open in Ghostty" not appearing

**Solution**:
```bash
# Reinstall context menu
./scripts/install_context_menu.sh

# Restart Nautilus
nautilus -q
```

### ZSH Not Default Shell

**Issue**: Still using bash after installation

**Solution**:
```bash
# Change default shell
chsh -s $(which zsh)

# Log out and log back in
```

## Updating

To update your installation:

```bash
# Check for updates
./manage.sh update --check-only

# Apply all updates
./manage.sh update

# Update specific component
./manage.sh update --component ghostty
./manage.sh update --component zsh
```

Your user customizations will be automatically preserved during updates.

## Uninstallation

To remove Ghostty and related components:

```bash
# Remove Ghostty binary
sudo rm /usr/local/bin/ghostty

# Remove configuration
rm -rf ~/.config/ghostty

# Remove context menu
rm ~/.local/share/nautilus/scripts/"Open in Ghostty"

# Remove ZSH (optional)
sudo apt remove zsh

# Restore bash as default shell
chsh -s /bin/bash
```

## Next Steps

- **[Configuration Guide](configuration.md)** - Customize your Ghostty setup
- **[Usage Guide](usage.md)** - Learn manage.sh commands and workflows
- **[Developer Guide](../developer/architecture.md)** - Contribute to the project

## Getting Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/your-username/ghostty-config-files/issues)
- **Documentation**: Browse `docs-source/` for comprehensive guides
- **Local Validation**: Run `./manage.sh validate` to check system health
