---
title: "Development Commands"
description: "AI assistant guidelines for development-commands"
pubDate: 2025-10-27
author: "AI Integration Team"
tags: ["ai", "guidelines"]
targetAudience: "all"
constitutional: true
---


> **Note**: This is a modular extract from [AGENTS.md](../../AGENTS.md) for documentation purposes. AGENTS.md remains the single source of truth.

## System Architecture

### Directory Structure (MANDATORY)
```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # 🚀 Primary installation & update script
├── AGENTS.md                   # LLM instructions (single source of truth)
├── CLAUDE.md                   # Claude Code integration (symlink to AGENTS.md)
├── GEMINI.md                   # Gemini CLI integration (symlink to AGENTS.md)
├── README.md                   # User documentation & quick start
├── configs/                    # Modular configuration files
│   ├── ghostty/               # Ghostty terminal configuration
│   └── workspace/             # Development workspace files
├── scripts/                   # Utility and automation scripts
├── .runners-local/              # Zero-cost local infrastructure
│   ├── .runners-local/workflows/              # Local CI/CD scripts
│   ├── logs/                 # Local CI/CD logs
│   └── config/               # CI/CD configuration files
└── website/src/              # Documentation source files
    ├── user-guide/           # User documentation
    ├── ai-guidelines/        # AI assistant guidelines
    └── developer/            # Developer documentation
```

### Technology Stack (NON-NEGOTIABLE)

**Terminal Environment**:
- **Ghostty**: Latest from source (Zig 0.14.0) with 2025 optimizations
- **ZSH**: Oh My ZSH with productivity plugins
- **Context Menu**: Nautilus integration for "Open in Ghostty"

**AI Integration**:
- **Claude Code**: Latest CLI via npm for code assistance
- **Gemini CLI**: Google's AI assistant with Ptyxis integration
- **Node.js**: Latest LTS via NVM for tool compatibility

**Local CI/CD**:
- **GitHub CLI**: For workflow simulation and API access
- **Local Runners**: Shell-based workflow execution
- **Performance Monitoring**: System state and timing analysis
- **Zero-Cost Strategy**: All CI/CD runs locally before GitHub

## Core Functionality

### Primary Goals
1. **Zero-Configuration Terminal**: One-command setup for Ubuntu fresh installs
2. **2025 Performance Optimizations**: Latest Ghostty features and speed improvements
3. **Context Menu Integration**: Right-click "Open in Ghostty" in file manager
4. **Intelligent Updates**: Smart detection and preservation of user customizations
5. **Local CI/CD**: Complete workflow execution without GitHub Actions costs
6. **AI Tool Integration**: Seamless Claude Code and Gemini CLI setup

## Quick Start Commands

### Installation
```bash
# MANDATORY: One-command fresh Ubuntu setup
cd /home/kkk/Apps/ghostty-config-files
./start.sh

# Initialize local CI/CD infrastructure
./.runners-local/.runners-local/workflows/gh-workflow-local.sh init

# Setup GitHub CLI integration
gh auth login
gh repo set-default
```

### Management Commands (via manage.sh)
```bash
# Install complete Ghostty environment
./manage.sh install

# Install with specific components
./manage.sh install --skip-node --skip-zig

# Documentation operations
./manage.sh docs build              # Build documentation site
./manage.sh docs build --clean       # Clean build
./manage.sh docs dev                 # Start dev server
./manage.sh docs dev --port 3000     # Custom port
./manage.sh docs generate            # Generate screenshots and API docs

# Screenshot management
./manage.sh screenshots capture terminal "dark-mode" "Terminal with dark theme"
./manage.sh screenshots generate-gallery

# Update system
./manage.sh update                   # Update all components
./manage.sh update --check-only      # Check for updates only
./manage.sh update --component ghostty  # Update specific component

# Validation
./manage.sh validate                 # Run all checks
./manage.sh validate --type config   # Validate configuration only
./manage.sh validate --fix           # Auto-fix issues

# Global options
./manage.sh <command> --help         # Show command help
./manage.sh <command> --dry-run      # Show what would be done
./manage.sh <command> --verbose      # Verbose output
```

### Local CI/CD Operations
```bash
# Complete local workflow execution
./.runners-local/.runners-local/workflows/gh-workflow-local.sh all

# Individual workflow stages
./.runners-local/.runners-local/workflows/gh-workflow-local.sh validate    # Config validation
./.runners-local/.runners-local/workflows/gh-workflow-local.sh test       # Performance testing
./.runners-local/.runners-local/workflows/gh-workflow-local.sh build      # Build simulation
./.runners-local/.runners-local/workflows/gh-workflow-local.sh deploy     # Deployment simulation

# GitHub Actions cost monitoring
./.runners-local/.runners-local/workflows/gh-workflow-local.sh billing    # Check usage
./.runners-local/.runners-local/workflows/gh-workflow-local.sh status     # Workflow status
```

### Update Management
```bash
# Smart update detection and application
./scripts/check_updates.sh              # Check and apply necessary updates
./scripts/check_updates.sh --force      # Force all updates
./scripts/check_updates.sh --config-only # Configuration updates only

# Local CI/CD for updates
./.runners-local/.runners-local/workflows/gh-workflow-local.sh update     # Update workflow
```

### Testing & Validation
```bash
# Configuration validation
ghostty +show-config                    # Validate current configuration
./.runners-local/.runners-local/workflows/test-runner.sh    # Complete test suite

# Performance monitoring
./.runners-local/.runners-local/workflows/performance-monitor.sh --baseline # Establish baseline
./.runners-local/.runners-local/workflows/performance-monitor.sh --compare  # Compare performance

# System testing
./start.sh --verbose                    # Full installation with detailed logs
```

## Debugging & Troubleshooting

### View Logs
```bash
# View comprehensive logs
ls -la /tmp/ghostty-start-logs/
ls -la ./.runners-local/logs/

# Analyze system state
jq '.' /tmp/ghostty-start-logs/system_state_*.json

# Check CI/CD performance
jq '.' ./.runners-local/logs/performance-*.json

# View errors only
cat /tmp/ghostty-start-logs/errors.log
cat ./.runners-local/logs/workflow-errors.log
```

### Emergency Recovery
```bash
# Emergency configuration recovery
cp ~/.config/ghostty/config.backup-* ~/.config/ghostty/config
ghostty +show-config
```

### Get Help
```bash
# Get help with installation
./start.sh --help

# Get help with local CI/CD
./.runners-local/.runners-local/workflows/gh-workflow-local.sh --help

# Get help with updates
./scripts/check_updates.sh --help

# Validate system state
ghostty +show-config
./.runners-local/.runners-local/workflows/test-runner.sh --validate
```

## Documentation Structure

### 🚨 CRITICAL: Documentation Directory Rules

- **`docs/`** - **Astro.build output ONLY** → GitHub Pages deployment (DO NOT manually edit)
- **`website/src/`** - **All editable documentation** → installation guides, screenshots, manuals, specs

### Documentation Locations
- **User Guide**: `website/src/user-guide/` - Installation, configuration, usage
- **Developer Docs**: `website/src/developer/` - Architecture, contributing, testing
- **AI Guidelines**: `website/src/ai-guidelines/` - This file and related guides
- **Spec-Kit**: `spec-kit/` - Modern web development stack guides

## Spec-Kit Development Guides

For implementing modern web development stacks with local CI/CD:
- **[Spec-Kit Index](../../spec-kit/guides/SPEC_KIT_INDEX.md)** - Complete navigation and overview
- **[Comprehensive Guide](../../spec-kit/guides/SPEC_KIT_GUIDE.md)** - Original detailed implementation

**Individual Command Guides**:
1. [Constitution](../../spec-kit/guides/1-spec-kit-constitution.md) - Establish project principles
2. [Specify](../../spec-kit/guides/2-spec-kit-specify.md) - Create technical specifications
3. [Plan](../../spec-kit/guides/3-spec-kit-plan.md) - Create implementation plans
4. [Tasks](../../spec-kit/guides/4-spec-kit-tasks.md) - Generate actionable tasks
5. [Implement](../../spec-kit/guides/5-spec-kit-implement.md) - Execute implementation

**Key Features**: uv-first Python management, Astro.build static sites, Tailwind CSS + shadcn/ui, mandatory local CI/CD, zero-cost GitHub Pages deployment.

## Modern Web Development Stack Integration

### Feature 001: Modern Web Development Stack
**Implementation Status**: Planning Phase Complete
**Location**: `specs/001-modern-web-development/`
**Branch**: `001-modern-web-development`

**Core Stack Components**:
- **uv (≥0.4.0)**: Exclusive Python dependency management
- **Astro.build (≥4.0)**: Static site generation with TypeScript
- **Tailwind CSS (≥3.4)**: Utility-first CSS framework
- **shadcn/ui**: Copy-paste component library
- **Local CI/CD Infrastructure**: Zero GitHub Actions consumption

**Performance Targets**:
- Lighthouse scores 95+ across all metrics
- Core Web Vitals: FCP <1.5s, LCP <2.5s, CLS <0.1
- JavaScript bundle size <100KB for initial load
- Build time <30 seconds locally with hot reload <1 second

**Local CI/CD Requirements**:
```bash
# Modern web stack local workflow
./.runners-local/.runners-local/workflows/astro-build-local.sh       # Astro build simulation
./.runners-local/.runners-local/workflows/performance-monitor.sh     # Core Web Vitals monitoring
./.runners-local/.runners-local/workflows/gh-workflow-local.sh all   # Complete validation
```

**Development Workflow Integration**:
```bash
# Spec-kit workflow commands
/.specify/scripts/bash/create-new-feature.sh    # Feature specification
# Available commands: /constitution, /specify, /plan, /tasks, /implement
```

## Common Patterns

### Dry Run Pattern
All manage.sh commands support `--dry-run` to preview actions:
```bash
./manage.sh install --dry-run
./manage.sh update --dry-run
./manage.sh docs build --clean --dry-run
```

### Verbose Logging Pattern
Enable detailed logging for debugging:
```bash
MANAGE_DEBUG=1 ./manage.sh install
./manage.sh install --verbose
```

### Backup Pattern
Commands automatically create backups before changes:
```bash
# Backups stored in:
~/.config/ghostty/backups/
# Or custom location:
MANAGE_BACKUP_DIR=/path/to/backups ./manage.sh update
```

### Testing Pattern
Test locally before deployment:
```bash
# 1. Validate
./manage.sh validate

# 2. Run local CI/CD
./.runners-local/.runners-local/workflows/gh-workflow-local.sh all

# 3. Only then deploy
git push
```
