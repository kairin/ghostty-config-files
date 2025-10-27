# Usage Guide

Learn how to use the Ghostty Configuration Files repository and the `manage.sh` unified management interface.

## Table of Contents

- [Quick Reference](#quick-reference)
- [manage.sh Commands](#managesh-commands)
- [Daily Workflows](#daily-workflows)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## Quick Reference

### Most Common Commands

```bash
# Install complete environment
./manage.sh install

# Update all components
./manage.sh update

# Validate system
./manage.sh validate

# Build documentation
./manage.sh docs build

# Get help
./manage.sh --help
./manage.sh <command> --help
```

### Global Options

All commands support these global options:

```bash
--help, -h       # Show help
--version, -v    # Show version
--verbose        # Enable verbose output
--quiet, -q      # Suppress non-essential output
--dry-run        # Show what would be done without executing
```

## manage.sh Commands

### Install Command

Install the complete Ghostty terminal environment.

```bash
# Basic usage
./manage.sh install

# Skip specific components
./manage.sh install --skip-node
./manage.sh install --skip-zig
./manage.sh install --skip-ghostty
./manage.sh install --skip-zsh
./manage.sh install --skip-theme
./manage.sh install --skip-context-menu

# Combine multiple skips
./manage.sh install --skip-node --skip-zig

# Force reinstallation
./manage.sh install --force

# Dry run (preview only)
./manage.sh install --dry-run

# Get help
./manage.sh install --help
```

**Installation Steps**:
1. [1/6] Installing Node.js (LTS via NVM)
2. [2/6] Installing Zig compiler (0.14.0)
3. [3/6] Building Ghostty from source
4. [4/6] Setting up ZSH with Oh My ZSH
5. [5/6] Configuring Catppuccin theme
6. [6/6] Installing context menu integration

### Update Command

Update repository components with user customization preservation.

```bash
# Check for available updates
./manage.sh update --check-only

# Update all components
./manage.sh update

# Update specific component
./manage.sh update --component ghostty
./manage.sh update --component zsh
./manage.sh update --component docs

# Force update even if no changes detected
./manage.sh update --force

# Dry run
./manage.sh update --dry-run
```

**Update Features**:
- Automatic backup before changes
- User customization preservation
- Automatic rollback on failure
- Selective component updates

### Validate Command

Run validation checks on configurations and dependencies.

```bash
# Validate everything
./manage.sh validate

# Validate specific type
./manage.sh validate --type config
./manage.sh validate --type performance
./manage.sh validate --type dependencies

# Validate and auto-fix issues
./manage.sh validate --fix

# Dry run
./manage.sh validate --dry-run
```

**Validation Types**:
- `all` - Run all validation checks (default)
- `config` - Validate Ghostty and ZSH configurations
- `performance` - Check performance metrics
- `dependencies` - Verify all dependencies are installed

### Docs Commands

Manage documentation site (Astro-based).

#### Build Documentation

```bash
# Standard build
./manage.sh docs build

# Clean build (remove old output)
./manage.sh docs build --clean

# Build to custom directory
./manage.sh docs build --output-dir public/

# Dry run
./manage.sh docs build --dry-run
```

#### Development Server

```bash
# Start dev server (default port 4321)
./manage.sh docs dev

# Custom port
./manage.sh docs dev --port 3000

# Expose to network
./manage.sh docs dev --host 0.0.0.0

# Combine options
./manage.sh docs dev --port 3000 --host 0.0.0.0
```

#### Generate Documentation

```bash
# Generate screenshots and API docs
./manage.sh docs generate

# Generate screenshots only
./manage.sh docs generate --screenshots

# Generate API docs only
./manage.sh docs generate --api-docs
```

### Screenshots Commands

Capture and manage documentation screenshots.

#### Capture Screenshots

```bash
# Capture screenshot
./manage.sh screenshots capture <category> <name> "<description>"

# Example: Terminal screenshot
./manage.sh screenshots capture terminal "dark-mode" "Terminal with dark theme enabled"

# Example: Configuration screenshot
./manage.sh screenshots capture config "keybindings" "Custom keybinding configuration"

# Example: UI screenshot
./manage.sh screenshots capture ui "context-menu" "Right-click context menu in Nautilus"
```

**Screenshot Storage**:
```
documentations/screenshots/
├── terminal/
│   ├── dark-mode.png
│   └── dark-mode.png.meta
├── config/
│   ├── keybindings.png
│   └── keybindings.png.meta
└── ui/
    ├── context-menu.png
    └── context-menu.png.meta
```

#### Generate Screenshot Gallery

```bash
# Generate HTML gallery
./manage.sh screenshots generate-gallery

# Custom output file
./manage.sh screenshots generate-gallery --output docs/screenshots.html
```

The gallery is generated at `documentations/screenshots/gallery.html` with:
- Organized by category
- Responsive grid layout
- Dark theme (GitHub style)
- Metadata display

### Help & Version

```bash
# Global help
./manage.sh --help

# Command-specific help
./manage.sh install --help
./manage.sh update --help
./manage.sh validate --help
./manage.sh docs --help
./manage.sh screenshots --help

# Show version
./manage.sh --version
```

## Daily Workflows

### Morning Setup

```bash
# Check for updates
./manage.sh update --check-only

# Apply updates if available
./manage.sh update

# Validate system
./manage.sh validate
```

### Development Session

```bash
# Start documentation dev server
./manage.sh docs dev

# In another terminal, make changes to docs-source/
# Browser auto-reloads at http://localhost:4321

# When done, build for production
./manage.sh docs build --clean
```

### Adding Documentation

```bash
# 1. Edit source files in docs-source/
vim docs-source/user-guide/new-feature.md

# 2. Test locally
./manage.sh docs dev

# 3. Build
./manage.sh docs build

# 4. Commit changes
git add docs-source/ docs/
git commit -m "docs: Add new feature documentation"
```

### Capturing Screenshots

```bash
# 1. Prepare the screen (terminal, config, etc.)

# 2. Capture screenshot
./manage.sh screenshots capture category "name" "Description of screenshot"

# 3. Generate gallery
./manage.sh screenshots generate-gallery

# 4. Commit
git add documentations/screenshots/
git commit -m "docs: Add screenshots for new feature"
```

### Configuration Changes

```bash
# 1. Validate current config
./manage.sh validate --type config

# 2. Make changes to ~/.config/ghostty/config

# 3. Validate again
./manage.sh validate --type config

# 4. Test changes
ghostty # Launch new instance

# 5. If satisfied, update repository config
cp ~/.config/ghostty/config configs/ghostty/config
git add configs/ghostty/config
git commit -m "config: Update Ghostty configuration"
```

## Advanced Usage

### Environment Variables

Control `manage.sh` behavior with environment variables:

```bash
# Enable debug logging
MANAGE_DEBUG=1 ./manage.sh install

# Disable colored output
MANAGE_NO_COLOR=1 ./manage.sh update

# Custom log file
MANAGE_LOG_FILE=/tmp/manage.log ./manage.sh validate

# Custom backup directory
MANAGE_BACKUP_DIR=/backups ./manage.sh update
```

### Combining Options

```bash
# Verbose dry-run of update
./manage.sh update --verbose --dry-run

# Force update with verbose output
./manage.sh update --force --verbose

# Quiet validation with auto-fix
./manage.sh validate --quiet --fix
```

### Scripting with manage.sh

Use `manage.sh` in automated scripts:

```bash
#!/bin/bash

# Automated update script
echo "Checking for updates..."
if ./manage.sh update --check-only --quiet; then
    echo "Updates available, applying..."
    ./manage.sh update --quiet

    echo "Validating system..."
    ./manage.sh validate --quiet

    echo "Rebuilding documentation..."
    ./manage.sh docs build --clean --quiet
fi
```

### Exit Codes

`manage.sh` follows standard exit code conventions:

- `0` - Success
- `1` - General failure
- `2` - Invalid arguments

Use in scripts:

```bash
# Check exit code
if ./manage.sh validate; then
    echo "Validation passed"
else
    echo "Validation failed with exit code: $?"
fi
```

### Parallel Commands

Some commands can be run in parallel:

```bash
# Build docs and generate screenshots simultaneously
./manage.sh docs build --clean &
./manage.sh screenshots generate-gallery &
wait

echo "Both operations complete"
```

## Troubleshooting

### Command Not Found

**Issue**: `./manage.sh: command not found`

**Solution**:
```bash
# Make executable
chmod +x manage.sh

# Or run with bash
bash manage.sh --help
```

### Permission Denied

**Issue**: `Permission denied` errors during installation

**Solution**:
```bash
# Some operations require sudo (Ghostty binary installation)
# The script will prompt when needed

# For backup/config operations, ensure ownership:
sudo chown -R $USER:$USER ~/.config/ghostty
```

### Updates Not Applying

**Issue**: `./manage.sh update` doesn't apply changes

**Solution**:
```bash
# Check for actual changes
./manage.sh update --check-only --verbose

# Force update if needed
./manage.sh update --force

# Check for conflicts
./manage.sh validate --type config
```

### Dry Run Shows Errors

**Issue**: `--dry-run` shows potential errors

**Solution**:
```bash
# Run without dry-run in verbose mode
./manage.sh install --verbose

# Check specific error
./manage.sh validate --type dependencies
```

### Documentation Build Fails

**Issue**: `./manage.sh docs build` fails

**Solution**:
```bash
# Check Node.js installation
node --version

# Reinstall dependencies
cd /home/kkk/Apps/ghostty-config-files
npm install

# Try clean build
./manage.sh docs build --clean --verbose
```

## Tips & Best Practices

### Regular Maintenance

```bash
# Weekly routine
./manage.sh update --check-only
./manage.sh validate
./manage.sh docs build --clean
```

### Before Major Changes

```bash
# Create backup
./manage.sh update --dry-run
cp -r ~/.config/ghostty ~/.config/ghostty.backup-$(date +%Y%m%d)

# Make changes
# ...

# Validate
./manage.sh validate
```

### Performance Optimization

```bash
# Check performance baseline
./manage.sh validate --type performance

# Make configuration changes
# ...

# Compare performance
./manage.sh validate --type performance
```

### Safe Experimentation

```bash
# Use dry-run to preview
./manage.sh install --dry-run --verbose

# Test in stages
./manage.sh install --skip-ghostty  # Test everything except Ghostty
./manage.sh install --skip-node --skip-zig  # Only Ghostty and configs
```

## Next Steps

- **[Configuration Guide](configuration.md)** - Customize your setup
- **[Installation Guide](installation.md)** - Initial setup reference
- **[Developer Guide](../developer/architecture.md)** - Contribute to the project

## Getting Help

If you encounter issues:

1. Check this usage guide
2. Run `./manage.sh <command> --help`
3. Check [troubleshooting section](#troubleshooting)
4. Run `./manage.sh validate` for diagnostics
5. Report issues on GitHub
