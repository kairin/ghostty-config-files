---
title: "Ghostty Configuration Files - Directory Structure"
description: "This document provides a complete directory structure reference for the Ghostty Configuration Files project. For AI assistant instructions, see [AGENTS.md](../../../AGENTS.md)."
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# Ghostty Configuration Files - Directory Structure

> **Purpose**: Comprehensive directory structure reference for the ghostty-config-files repository.
> **Last Updated**: 2025-11-11
> **Status**: Active Documentation

## Overview

This document provides a complete directory structure reference for the Ghostty Configuration Files project. For AI assistant instructions, see [AGENTS.md](../../../AGENTS.md).

---

## Complete Directory Tree

```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # 🚀 Primary installation & update script
├── manage.sh                   # 🎛️ Unified management interface (Phase 3)
├── AGENTS.md                   # LLM instructions (single source of truth)
├── CLAUDE.md                   # Claude Code integration (symlink to AGENTS.md)
├── GEMINI.md                   # Gemini CLI integration (symlink to AGENTS.md)
├── README.md                   # User documentation & quick start
├── configs/                    # Modular configuration files
│   ├── ghostty/               # Ghostty terminal configuration
│   │   ├── config             # Main config with 2025 optimizations
│   │   ├── theme.conf         # Auto-switching themes (dark/light)
│   │   ├── scroll.conf        # Scrollback settings
│   │   ├── layout.conf        # Font, padding, layout (2025 optimized)
│   │   ├── keybindings.conf   # Productivity keybindings
│   │   └── dircolors          # LS_COLORS configuration (XDG-compliant)
│   └── workspace/             # Development workspace files
│       └── ghostty.code-workspace # VS Code workspace
├── scripts/                   # Modular utility and automation scripts
│   ├── .module-template.sh    # Module template (Phase 1)
│   ├── common.sh              # Common utilities (Phase 2)
│   ├── progress.sh            # Progress reporting (Phase 2)
│   ├── backup_utils.sh        # Backup utilities (Phase 2)
│   ├── install_node.sh        # Node.js installation module (Phase 5 - COMPLETE)
│   ├── check_updates.sh       # Intelligent update detection
│   ├── install_context_menu.sh # Right-click integration
│   ├── install_ghostty_config.sh # Configuration installer
│   ├── update_ghostty.sh      # Ghostty version management
│   ├── fix_config.sh          # Configuration repair tools
│   ├── check_context7_health.sh # Context7 MCP health verification
│   ├── check_github_mcp_health.sh # GitHub MCP health verification
│   └── agent_functions.sh     # AI assistant helper functions
├── documentations/            # Centralized documentation hub (as of 2025-11-09)
│   ├── user/                  # End-user documentation
│   │   ├── installation/      # Installation guides
│   │   ├── configuration/     # Configuration guides
│   │   └── troubleshooting/   # Troubleshooting guides
│   ├── developer/             # Developer documentation
│   │   ├── architecture/      # System architecture (this document)
│   │   └── analysis/          # Technical analysis
│   ├── specifications/        # Active feature specifications
│   │   ├── 001-repo-structure-refactor/  # Spec 001: Repository refactoring
│   │   ├── 002-advanced-terminal-productivity/  # Spec 002
│   │   └── 004-modern-web-development/  # Spec 004
│   └── archive/               # Historical/obsolete documentation
└── .runners-local/              # Zero-cost local infrastructure
    ├── workflows/            # Local CI/CD scripts
    │   ├── gh-workflow-local.sh    # Local GitHub Actions simulation
    │   ├── gh-pages-setup.sh       # GitHub Pages local testing
    │   ├── performance-monitor.sh  # Performance tracking
    │   ├── astro-build-local.sh    # Astro build workflows
    │   └── pre-commit-local.sh     # Pre-commit hooks
    ├── tests/                # Testing infrastructure
    │   ├── unit/             # Unit tests
    │   │   ├── .test-template.sh      # Test template (Phase 1)
    │   │   ├── test_functions.sh      # Test assertions (Phase 1)
    │   │   ├── test_install_node.sh   # install_node.sh tests (Phase 5)
    │   │   └── test_common_utils.sh   # Common utilities tests (Phase 2)
    │   ├── integration/      # Integration tests
    │   ├── contract/         # Contract tests
    │   ├── validation/       # Validation scripts
    │   └── fixtures/         # Test fixtures and data
    ├── self-hosted/          # Self-hosted runner management
    │   ├── setup-self-hosted-runner.sh  # Runner setup
    │   └── config/           # Runner credentials (GITIGNORED)
    └── logs/                 # Local CI/CD logs (GITIGNORED)
        ├── builds/           # Build logs
        ├── tests/            # Test logs
        └── .runners-local/workflows/          # Runner service logs
```

---

## Directory Descriptions

### Root Level

| File/Directory | Purpose | Type |
|---------------|---------|------|
| `start.sh` | Primary installation and update script for one-command setup | Script |
| `manage.sh` | Unified management interface (Phase 3 - future enhancement) | Script |
| `AGENTS.md` | Single source of truth for AI assistant instructions | Documentation |
| `CLAUDE.md` | Claude Code integration (symlink to AGENTS.md) | Symlink |
| `GEMINI.md` | Gemini CLI integration (symlink to AGENTS.md) | Symlink |
| `README.md` | User-facing documentation and quick start guide | Documentation |

### `configs/` - Configuration Files

Modular configuration files organized by component:

#### `configs/ghostty/`
Ghostty terminal emulator configuration with 2025 optimizations:

- **`config`**: Main configuration file with performance optimizations
  - Linux CGroup single-instance mode
  - Shell integration auto-detection
  - Memory management settings
  - Auto theme switching support

- **`theme.conf`**: Theme configuration for light/dark mode support
  - Catppuccin Mocha (dark mode)
  - Catppuccin Latte (light mode)

- **`scroll.conf`**: Scrollback buffer settings
  - Optimized limits for performance
  - Multiplier configurations

- **`layout.conf`**: Font, padding, and layout settings
  - Font family and size (2025 optimized)
  - Window padding configuration
  - Layout preferences

- **`keybindings.conf`**: Productivity keyboard shortcuts
  - Custom key mappings
  - Vim-style navigation support

- **`dircolors`**: LS_COLORS configuration (XDG-compliant)
  - Readable directory colors
  - World-writable directory highlighting
  - Deployed to `~/.config/dircolors`

#### `configs/workspace/`
Development environment configuration:

- **`ghostty.code-workspace`**: VS Code multi-root workspace configuration

### `scripts/` - Utility Scripts

Modular utility and automation scripts following Phase 1-5 development approach:

| Script | Purpose | Phase |
|--------|---------|-------|
| `.module-template.sh` | Template for creating new script modules | Phase 1 |
| `common.sh` | Common utilities and helper functions | Phase 2 |
| `progress.sh` | Progress reporting for long-running operations | Phase 2 |
| `backup_utils.sh` | Backup creation and restoration utilities | Phase 2 |
| `install_node.sh` | Node.js installation via NVM | Phase 5 ✅ |
| `check_updates.sh` | Intelligent update detection and application | Core |
| `install_context_menu.sh` | Right-click "Open in Ghostty" integration | Core |
| `install_ghostty_config.sh` | Configuration deployment and validation | Core |
| `update_ghostty.sh` | Ghostty version management and updates | Core |
| `fix_config.sh` | Configuration repair and recovery tools | Core |
| `check_context7_health.sh` | Context7 MCP server health verification | MCP |
| `check_github_mcp_health.sh` | GitHub MCP server health verification | MCP |
| `agent_functions.sh` | AI assistant helper functions | Core |

### `documentations/` - Centralized Documentation Hub

Comprehensive documentation repository following three-tier structure:

#### `documentations/user/`
End-user documentation organized by topic:

- **`installation/`**: Installation guides for different platforms
- **`configuration/`**: Configuration guides and customization instructions
- **`troubleshooting/`**: Common issues and solutions

#### `documentations/developer/`
Developer-focused technical documentation:

- **`architecture/`**: System architecture documentation (this document)
- **`analysis/`**: Technical analysis and refactoring documentation

#### `documentations/specifications/`
Active feature specifications with planning artifacts:

- **`001-repo-structure-refactor/`**: Spec 001 - Repository refactoring
  - Planning documents
  - Implementation tasks
  - Status tracking

- **`002-advanced-terminal-productivity/`**: Spec 002 - Terminal productivity features
  - Feature specifications
  - Implementation plans

- **`004-modern-web-development/`**: Spec 004 - Modern web development stack
  - Stack component specifications
  - Performance targets
  - Development workflow

#### `documentations/archive/`
Historical and obsolete documentation preserved for reference:

- Deprecated features
- Superseded specifications
- Historical analysis

### `.runners-local/` - Local CI/CD Infrastructure

Zero-cost local CI/CD infrastructure for GitHub Actions simulation:

#### `.runners-local/workflows/`
Local CI/CD scripts with production-ready implementation:

- **`gh-workflow-local.sh`**: Local GitHub Actions simulation
  - Configuration validation
  - Performance testing
  - Workflow status monitoring
  - Billing checks

- **`gh-pages-setup.sh`**: GitHub Pages local testing
  - Critical `.nojekyll` validation
  - Astro build verification
  - Asset directory validation
  - GitHub Pages configuration

- **`performance-monitor.sh`**: Performance tracking
  - Startup time measurement
  - Configuration load time
  - Optimization status tracking
  - System information collection

- **`astro-build-local.sh`**: Astro build workflows
  - Local Astro build execution
  - Build verification and validation
  - Asset optimization

- **`pre-commit-local.sh`**: Pre-commit hooks
  - Code quality checks
  - Configuration validation
  - Documentation synchronization

#### `.runners-local/tests/`
Testing infrastructure:

- **`unit/`**: Unit tests for script modules
  - `.test-template.sh`: Template for creating new tests
  - `test_functions.sh`: Test assertion functions
  - `test_install_node.sh`: install_node.sh unit tests
  - `test_common_utils.sh`: common.sh unit tests

- **`integration/`**: Integration tests for cross-module functionality

- **`contract/`**: Contract tests for API and interface compliance

- **`validation/`**: Validation scripts for configuration and system state

- **`fixtures/`**: Test fixtures and sample data for testing

#### `.runners-local/self-hosted/`
Self-hosted runner management:

- **`setup-self-hosted-runner.sh`**: Runner setup and configuration script
- **`config/`**: Runner credentials and configuration (GITIGNORED)

#### `.runners-local/logs/`
Local CI/CD execution logs (GITIGNORED):

- **`builds/`**: Build logs and artifacts
- **`tests/`**: Test execution results
- **`.runners-local/workflows/`**: Runner service logs and workflow execution

---

## Key Design Patterns

### 1. **Single Source of Truth**
- `AGENTS.md` is the master AI assistant instruction document
- `CLAUDE.md` and `GEMINI.md` symlink to `AGENTS.md`
- No duplicate instructions across AI integration files

### 2. **Modular Configuration**
- Ghostty config split across multiple files (`config`, `theme.conf`, `scroll.conf`, etc.)
- Easy to customize individual aspects without affecting others
- Maintainable and version-control friendly

### 3. **Phased Script Development**
Scripts organized by development phase:
- **Phase 1**: Templates and foundational patterns
- **Phase 2**: Common utilities and shared functions
- **Phase 5**: Feature-specific implementations (Node.js installation)
- **Core**: Essential functionality (updates, installation, configuration)
- **MCP**: Model Context Protocol integrations

### 4. **Three-Tier Documentation**
1. **Tier 1**: Astro build output (`docs/`) → GitHub Pages deployment
2. **Tier 2**: Editable source (`website/src/`) → Human-editable markdown
3. **Tier 3**: Centralized hub (`documentations/`) → Comprehensive repository

### 5. **Zero-Cost CI/CD**
- All CI/CD operations run locally before GitHub deployment
- Comprehensive logging for debugging
- Performance monitoring for optimization tracking
- GitHub Actions usage monitoring to stay within free tier

---

## File Naming Conventions

### Scripts
- Lowercase with underscores: `install_node.sh`, `check_updates.sh`
- Template prefix with dot: `.module-template.sh`
- Health check prefix: `check_*_health.sh`

### Documentation
- Uppercase with underscores: `AGENTS.md`, `README.md`, `DIRECTORY_STRUCTURE.md`
- Specification naming: `001-repo-structure-refactor/` (number-dash-description)

### Configuration
- Lowercase, no extension for main config: `config`
- Lowercase with extension for sub-configs: `theme.conf`, `scroll.conf`

---

## Directory Permissions

### Scripts
- Executable: `755` (rwxr-xr-x)
- Examples: `start.sh`, all scripts in `scripts/` and `.runners-local/workflows/`

### Documentation
- Read-only: `644` (rw-r--r--)
- Examples: `AGENTS.md`, `README.md`, all markdown files

### Configuration
- Read-only: `644` (rw-r--r--)
- Examples: All files in `configs/`

### Logs
- Directory: `755` (rwxr-xr-x)
- Log files: `644` (rw-r--r--)
- Location: `.runners-local/logs/workflows/`

---

## Related Documentation

- **AI Assistant Instructions**: [AGENTS.md](../../../AGENTS.md)
- **User Quick Start**: [README.md](../../../README.md)
- **Context7 MCP Setup**: [context7-mcp.md](../../user/setup/context7-mcp.md)
- **GitHub MCP Setup**: [github-mcp.md](../../user/setup/github-mcp.md)
- **Spec-Kit Guides**: [spec-kit/SPEC_KIT_INDEX.md](../../../spec-kit/guides/SPEC_KIT_INDEX.md)

---

**Version**: 1.0
**Last Updated**: 2025-11-11
**Maintainer**: Ghostty Config Files Project
