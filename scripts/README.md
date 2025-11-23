# Scripts Directory

This directory contains utility scripts organized by functionality.

## 📁 Directory Structure

### Core Directories

- **`health/`** - Health checking & system monitoring
  - System health checks
  - MCP server health verification
  - Health dashboards

- **`updates/`** - Update management
  - Daily system updates
  - Ghostty updates
  - Update checkers and logs

- **`config/`** - Configuration & validation
  - ZSH configuration
  - Environment validation
  - Configuration validators

- **`git/`** - Git & version control utilities
  - Smart commit helpers
  - Branch management
  - TODO consolidation

- **`docs/`** - Documentation generation
  - Documentation website generation
  - Dashboard generation
  - AI context extraction

- **`monitoring/`** - Performance & CI/CD monitoring
  - Performance monitoring
  - CI/CD runners
  - Constitutional automation

- **`tasks/`** - Task management & display
  - Task manager
  - Task display UI
  - Progress tracking

- **`system/`** - System maintenance
  - Package removal utilities
  - System verification
  - Passwordless sudo setup

- **`archive/`** - Archival utilities
  - Specification archiving
  - Archive management

- **`lib/`** - Shared libraries (sourced, not executed)
  - Common functions
  - Module templates

- **`examples/`** - Demos & testing
  - Task display demos
  - Script templates

- **`utils/`** - Miscellaneous utilities
  - Project management scripts
  - Utility servers

### Legacy Directories

- **`deprecated/`** - Legacy installer scripts
  - ⚠️ These scripts are deprecated in favor of modular installers in `lib/installers/`
  - Kept for backward compatibility only
  - See `lib/installers/` for current installation scripts

- **`config/`** (pre-existing) - Legacy configuration
- **`examples/`** (pre-existing) - Legacy examples
- **`guides/`** (pre-existing) - Legacy guides

## 🔄 Migration Notes

**Date**: 2025-11-23
**Branch**: `20251123-103223-refactor-scripts-folder-organization`

### What Changed

1. All scripts reorganized into functional directories
2. Deprecated installer scripts moved to `deprecated/`
3. Redundant backup files removed
4. Modular structure improves discoverability

### Backward Compatibility

All scripts maintain their original functionality. Update your paths:

**Old**: `scripts/system_health_check.sh`
**New**: `scripts/health/system_health_check.sh`

### For New Development

- ✅ **DO**: Use modular installers in `lib/installers/`
- ✅ **DO**: Place new scripts in appropriate category folders
- ❌ **DON'T**: Create new scripts in `scripts/` root
- ❌ **DON'T**: Use scripts from `deprecated/` folder

## 📖 Quick Reference

### Health Checks
```bash
./scripts/health/system_health_check.sh
./scripts/health/health_dashboard.sh
```

### Updates
```bash
./scripts/updates/daily-updates.sh
./scripts/updates/check_updates.sh
```

### Configuration
```bash
./scripts/config/configure_zsh.sh
./scripts/config/config_validator.py
```

## 🏗️ Architecture

This reorganization aligns with the project's constitutional principle of **script proliferation prevention**:

- Each category has a clear, single purpose
- Related functionality is grouped together
- Deprecated scripts are clearly marked
- Modular installers live in `lib/installers/` (not here)

See `.claude/instructions-for-agents/principles/script-proliferation.md` for details.
