---
title: System Architecture Overview
category: architecture
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-11
---

# 🏗️ System Architecture

[← Back to AGENTS.md](../../../../AGENTS.md)

**Related Sections**:
- [Agent Delegation](./agent-delegation.md) - 5-tier agent hierarchy
- [Agent Registry](./agent-registry.md) - Complete 60-agent reference

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

**Essential Structure** (Updated 2026-01-11):

```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # Installation orchestrator script
├── AGENTS.md                   # AI instructions (gateway document)
├── CLAUDE.md, GEMINI.md        # Symlinks to AGENTS.md
├── README.md                   # User documentation
│
├── configs/                    # Ghostty config, themes, dircolors, workspace
│   └── ghostty/                # Ghostty configuration files & themes
│
├── scripts/                    # Utility scripts organized by function
│   ├── 000-check/              # Pre-installation checks
│   ├── 001-uninstall/          # Uninstallation scripts
│   ├── 002-install-first-time/ # First-time installers (11 tools)
│   ├── 003-verify/             # Verification scripts
│   ├── 004-reinstall/          # Reinstallation scripts (inc. Ghostty build-from-source)
│   ├── 005-confirm/            # Confirmation utilities
│   ├── 006-logs/               # Log management
│   ├── 007-diagnostics/        # Boot diagnostics system
│   ├── daily-updates.sh        # Automated update system (v3.0)
│   ├── ghostty-theme-switcher.sh # Dynamic light/dark theme switching
│   └── check_updates.sh        # Smart update checker
│
├── astro-website/              # Astro.build source (CONSOLIDATED)
│   ├── src/                    # Astro source files & markdown content
│   │   └── developer/          # Developer documentation
│   ├── public/                 # Static assets (.nojekyll, favicon, manifest)
│   ├── astro.config.mjs        # Astro configuration (outDir: '../docs')
│   └── package.json            # Dependencies
│
├── docs/                       # Astro BUILD OUTPUT ONLY (GitHub Pages)
│   └── .nojekyll               # CRITICAL - never delete
│
├── .claude/                    # Claude Code configuration
│   └── instructions-for-agents/ # AI agent instructions & guides
│       ├── requirements/       # Critical requirements
│       ├── architecture/       # System architecture docs
│       ├── guides/             # Setup guides (MCP, troubleshooting)
│       ├── principles/         # Constitutional principles
│       └── tools/              # Tool documentation
│
├── logs/                       # Update logs and manifests
│   └── manifests/              # Update manifests
│
├── tests/                      # Test infrastructure
├── .runners-local/             # Local CI/CD infrastructure
└── .mcp.json                   # MCP server configuration
```

---

## Agent Architecture (5-Tier Hierarchy)

The project uses a 5-tier agent system for intelligent task delegation:

| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| 0 | Sonnet | 5 | Complete workflows (000-*) |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2-3 | Sonnet | 9 | Core/utility operations |
| 4 | Haiku | 50 | Atomic execution tasks |

**Token Optimization**: ~40% reduction by delegating atomic tasks to Haiku tier.

**Complete Documentation**:
- [Agent Delegation Guide](./agent-delegation.md) - When to use which tier
- [Agent Registry](./agent-registry.md) - Complete 65-agent reference

---

## Technology Stack (NON-NEGOTIABLE)

### Terminal Environment
- **Ghostty v1.2.3+**: Via official .deb package (mkasberg/ghostty-ubuntu) with 2025 optimizations
- **Charm TUI Ecosystem**: gum (tables/spinners), glow (markdown), VHS (recording)
- **ZSH**: Oh My ZSH with productivity plugins
- **Context Menu**: Nautilus integration for "Open in Ghostty"

### Modern TUI Installer (Phase 4)
- **Go 1.23+**: Programming language for TUI implementation
- **Bubbletea v1.2.4+**: Elm-architecture TUI framework
- **Lipgloss v1.0.0+**: Terminal styling library
- **Bubbles v0.20.0+**: Reusable TUI components (spinner, viewport)
- **Module**: `github.com/kairin/ghostty-installer`
- **Binary**: `tui/installer` (5.0MB, statically linked)

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

## Documentation Structure (CONSTITUTIONAL REQUIREMENT - Updated 2026-01-11)

- **`docs/`** - **Astro.build output ONLY** → GitHub Pages deployment (committed, DO NOT manually edit)
- **`astro-website/src/`** - **Astro source files** → Editable markdown documentation
  - `astro-website/src/developer/` - Developer documentation (powerlevel10k, etc.)
  - `astro-website/src/user-guide/` - User guides (installation, configuration)
- **`.claude/instructions-for-agents/`** - **AI agent instructions & operational docs**:
  - `requirements/` - Critical requirements (Ghostty, git strategy, CI/CD)
  - `architecture/` - Architecture docs (system architecture, directory structure)
  - `guides/` - Setup guides (MCP integration, troubleshooting)
  - `principles/` - Constitutional principles (script proliferation prevention)
  - `tools/` - Tool implementation reference

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

### Ghostty Installation Methods

**Ghostty Terminal v1.2.3+** supports two installation methods:

**Build from Source** (Default - recommended for latest features):
```bash
# Handled by: scripts/004-reinstall/install_ghostty.sh
# Or via TUI: ./start.sh → Install Tools → Ghostty

# Manual build (if needed)
zig build -Doptimize=ReleaseFast
```

**Snap Package** (Alternative - quick installation):
```bash
# Install via Snap
snap install ghostty --classic

# Check for updates
snap refresh --list

# Manual refresh
snap refresh ghostty

# Verify version
snap list ghostty
```

**Benefits of Build from Source:**
- Latest features and fixes
- Full control over build options
- Better integration with system libraries

**Benefits of Snap:**
- Automatic updates in the background
- Official builds from Ghostty developers
- Zero compilation time
- Rollback support: `snap revert ghostty`

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

## Go TUI Installer Infrastructure (2026)

**Status**: Production-ready Go TUI built with Bubbletea framework, replacing the earlier gum.sh-based prototype.

**Features**:
- Data-driven tool registry with 12 installable tools
- 5-stage installation pipeline with checkpoint recovery
- Real-time output streaming with TailSpinner display
- Nerd Fonts interactive selection with preview
- Nil-pointer safe design patterns throughout

**Source Code**: `tui/` directory (Go/Bubbletea)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
