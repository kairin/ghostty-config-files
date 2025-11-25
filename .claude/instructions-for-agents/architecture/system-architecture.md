---
title: System Architecture Overview
category: architecture
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2025-11-21
---

# 🏗️ System Architecture

[← Back to AGENTS.md](../../../../AGENTS.md)

**Related Sections**:
- [Directory Structure](./directory-structure.md) - File organization details
- [Technology Stack](./technology-stack.md) - Core dependencies
- [Logging System](./logging-system.md) - Dual-mode logging architecture

---

## Project Overview

**Ghostty Configuration Files** is a comprehensive terminal environment setup featuring:
- Ghostty terminal emulator with 2025 performance optimizations
- Right-click context menu integration
- Integrated AI tools (Claude Code, Gemini CLI)
- Intelligent update management
- Zero-cost local CI/CD infrastructure

---

## Directory Structure (MANDATORY)

**Essential Structure** (Restructured 2025-11-20):

```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # Installation orchestrator script
├── AGENTS.md                   # AI instructions (gateway document)
├── CLAUDE.md, GEMINI.md        # Symlinks to AGENTS.md
├── README.md                   # User documentation
│
├── configs/                    # Ghostty config, themes, dircolors, workspace
├── scripts/                    # Utility scripts (manage.sh, daily-updates.sh v2.1, health checks)
├── lib/                        # Modular task libraries with uninstall support
│   ├── installers/ghostty/     # Ghostty .deb installation modules + uninstall.sh
│   ├── installers/gum,glow,vhs/# Charm TUI ecosystem installers
│   ├── ui/vhs-auto-record.sh   # VHS auto-recording library
│   ├── tasks/system_audit.sh   # Pre-installation system audit
│   └── installers/*/           # Other modular installers
│
├── documentation/              # SINGLE documentation folder (consolidated)
│   ├── setup/                  # Setup guides (MCP, new-device, zsh-security)
│   ├── architecture/           # Architecture docs (MODULAR_TASK_ARCHITECTURE.md)
│   ├── developer/              # Developer docs (handoff summaries, guides)
│   ├── user/                   # User guides
│   ├── specifications/         # Feature specifications
│   └── archive/                # Historical documentation
│
├── astro-website/              # Astro.build source (CONSOLIDATED)
│   ├── src/                    # Astro source files & markdown content
│   ├── public/                 # Static assets (.nojekyll, favicon, manifest)
│   ├── astro.config.mjs        # Astro configuration (outDir: '../docs')
│   └── package.json            # Dependencies
│
├── docs/                       # Astro BUILD OUTPUT ONLY (GitHub Pages)
│   └── .nojekyll               # CRITICAL - never delete
│
├── tests/                      # Test infrastructure
├── .runners-local/             # Local CI/CD infrastructure (see below)
└── archive-spec-kit/           # Archived spec-kit materials (.specify/)
```

**Complete Structure**: See [DIRECTORY_STRUCTURE.md](./directory-structure.md) for detailed directory tree with file descriptions, design patterns, and naming conventions.

---

## Technology Stack (NON-NEGOTIABLE)

### Terminal Environment
- **Ghostty v1.2.3+**: Via official .deb package (mkasberg/ghostty-ubuntu) with 2025 optimizations
- **Charm TUI Ecosystem**: gum (tables/spinners), glow (markdown), VHS (recording)
- **ZSH**: Oh My ZSH with productivity plugins
- **Context Menu**: Nautilus integration for "Open in Ghostty"

### AI Integration
- **Claude Code**: Latest CLI via npm for code assistance
- **Gemini CLI**: Google's AI assistant with Ptyxis integration
- **Context7 MCP**: Up-to-date documentation server for best practices synchronization
- **Node.js**: Latest version (v25.2.0+) via fnm for modern JavaScript features and optimal performance
  - Global installations use latest Node.js for cutting-edge features
  - Project-specific versions managed via fnm when required by individual projects

### Local CI/CD
- **GitHub CLI**: For workflow simulation and API access
- **Local Runners**: Shell-based workflow execution
- **Performance Monitoring**: System state and timing analysis
- **Zero-Cost Strategy**: All CI/CD runs locally before GitHub

### Directory Color Configuration
- **XDG Compliance**: Follows XDG Base Directory Specification
- **Location**: `~/.config/dircolors` (not `~/.dircolors` in home directory)
- **Deployment**: Automatic via `start.sh` installation script
- **Shell Integration**: Auto-configured for bash and zsh

---

## Core Functionality

### Primary Goals
1. **Zero-Configuration Terminal**: One-command setup for Ubuntu fresh installs
2. **2025 Performance Optimizations**: Latest Ghostty features and speed improvements
3. **Context Menu Integration**: Right-click "Open in Ghostty" in file manager
4. **Intelligent Updates**: Smart detection and preservation of user customizations
5. **Local CI/CD**: Complete workflow execution without GitHub Actions costs
6. **AI Tool Integration**: Seamless Claude Code and Gemini CLI setup
7. **Enhanced Readability**: XDG-compliant dircolors for readable directory listings
8. **Automated Daily Updates**: System-wide updates with 13-component coverage and modular uninstall → reinstall workflow (v2.1)

### Local CI/CD Workflows

```
Local Development Workflow:
├── Configuration change detection
├── Local testing and validation
├── Performance impact assessment
├── GitHub Actions simulation
├── Documentation update verification
├── Branch creation and safe merging
└── Zero-cost GitHub deployment

CI/CD Pipeline Stages:
├── 01-validate-config        # Ghostty configuration validation
├── 02-test-performance       # 2025 optimization verification
├── 03-check-compatibility    # Cross-system compatibility
├── 04-simulate-workflows     # GitHub Actions local simulation
├── 05-generate-docs          # Documentation update and validation
├── 06-package-release        # Release artifact preparation
└── 07-deploy-pages           # GitHub Pages local build and test
```

---

## Performance Metrics (2025)

### Target Metrics
- **Startup Time**: <500ms for new Ghostty instance (CGroup optimization)
- **Memory Usage**: <100MB baseline with optimized scrollback management
- **Shell Integration**: 100% feature detection and activation
- **Theme Switching**: Instant response to system light/dark mode changes
- **CI/CD Performance**: <2 minutes for complete local workflow execution

### User Experience Metrics
- **One-Command Setup**: Fresh Ubuntu system fully configured in <10 minutes
- **Context Menu**: "Open in Ghostty" available immediately after installation
- **Update Efficiency**: Only necessary components updated, no full reinstalls
- **Customization Preservation**: 100% user setting retention during updates
- **Zero-Cost Operation**: No GitHub Actions minutes consumed for routine operations

### Technical Metrics
- **Configuration Validity**: 100% successful validation rate
- **Update Success**: >99% successful intelligent update application
- **Error Recovery**: Automatic rollback on configuration failures
- **Logging Coverage**: Complete system state capture for all operations
- **CI/CD Success**: >99% local workflow execution success rate

---

## Documentation Structure (CONSTITUTIONAL REQUIREMENT - Restructured 2025-11-20)

- **`docs/`** - **Astro.build output ONLY** → GitHub Pages deployment (committed, DO NOT manually edit)
- **`astro-website/src/`** - **Astro source files** → Editable markdown documentation (user-guide/, ai-guidelines/, developer/)
- **`documentation/`** - **SINGLE documentation folder** (consolidated from docs-setup/, documentations/, specs/):
  - `documentation/setup/` - Setup guides (MCP integration, new-device, zsh-security)
  - `documentation/architecture/` - Architecture docs (MODULAR_TASK_ARCHITECTURE.md, DIRECTORY_STRUCTURE.md)
  - `documentation/developer/` - Developer docs (handoff summaries, conversation logs, guides)
  - `documentation/user/` - User guides
  - `documentation/specifications/` - Feature specifications (001-modern-tui-system/)
  - `documentation/archive/` - Historical documentation
- **`archive-spec-kit/`** - **Archived spec-kit materials** (.specify/ folder, no longer active)

---

## Automated Update System (v2.1)

### Update System Overview

**Script**: `scripts/daily-updates.sh` (Version 3.0)
**Schedule**: Daily at 9:00 AM via cron
**Components**: 12 total update targets
**Logging**: Full logging to `/tmp/daily-updates-logs/`

### 12-Component Update Coverage

| Component | Update Method | Version Detection | Notes |
|-----------|---------------|-------------------|-------|
| 1. GitHub CLI | `apt upgrade gh` | apt package manager | Official repository |
| 2. System Packages | `apt update && apt upgrade` | apt package manager | All system packages |
| 3. Oh My Zsh | `upgrade_oh_my_zsh` | Built-in updater | Framework + plugins |
| 4. fnm | Latest release install | GitHub releases API | Fast Node Manager |
| 5. npm | `npm install -g npm@latest` | npm registry | Global packages included |
| 6. Claude CLI | `npm update -g @anthropic-ai/claude-code` | npm registry | AI assistant CLI |
| 7. Gemini CLI | `npm update -g @google/generative-ai-cli` | npm registry | AI assistant CLI |
| 8. Copilot CLI | `npm update -g @githubnext/github-copilot-cli` | npm registry | AI coding assistant |
| 9. uv | `uv self update` | Built-in updater | Python package installer |
| 10. Spec-Kit CLI | `uv tool upgrade specify-cli` | uv tool manager | Specification-driven development |
| 11. Additional uv Tools | `uv tool upgrade <tool>` | uv tool manager | All installed uv tools |
| 12. Ghostty Terminal | `snap refresh ghostty` | Snap store | Official Snap package auto-updates |

### Snap Package Auto-Updates

**Ghostty Terminal** is managed via Snap, which provides automatic updates:

**Update Detection:**
```bash
# Check for Snap updates
snap refresh --list

# Manual refresh (if needed)
snap refresh ghostty

# Verify installed version
snap list ghostty
```

**Benefits:**
- **Automatic Updates**: Snap handles updates in the background
- **Official Builds**: Direct from Ghostty developers via Snap store
- **Zero Compilation**: Pre-built binaries, instant installation
- **Rollback Support**: `snap revert ghostty` if needed

### Error Handling & Logging

**Graceful Error Handling:**
- Continues updating other components if one fails
- Tracks success/fail/skip/already-latest status for each component
- Exit code tracking distinguishes errors from "not installed" states

**Comprehensive Logging:**
- `update-TIMESTAMP.log` - Full update log with all output
- `errors-TIMESTAMP.log` - Errors only
- `last-update-summary.txt` - Quick summary of last update
- `latest.log` - Symlink to most recent log

**Complete Documentation**: [DAILY_UPDATES_README.md](../../../../scripts/DAILY_UPDATES_README.md)

---

## Modern TUI System Infrastructure

**Active Spec**: Modern TUI Installation System (001) - Phases 1-6 MVP complete with gum.sh module and comprehensive documentation.

**Complete Specification**: [spec.md](../../../../documentation/specifications/001-modern-tui-system/spec.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
