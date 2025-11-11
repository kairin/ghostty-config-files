# Ghostty Configuration Files - LLM Instructions (2025 Edition)

> 🔧 **CRITICAL**: This file contains NON-NEGOTIABLE requirements that ALL AI assistants (Claude, Gemini, ChatGPT, etc.) working on this repository MUST follow at ALL times.

## 🎯 Project Overview

**Ghostty Configuration Files** is a comprehensive terminal environment setup featuring Ghostty terminal emulator with 2025 performance optimizations, right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI) and intelligent update management.

**Quick Links:** [README](README.md) • [CLAUDE Integration](CLAUDE.md) • [Gemini Integration](GEMINI.md) • [Context7 Setup](documentations/user/setup/context7-mcp.md) • [GitHub MCP Setup](documentations/user/setup/github-mcp.md) • [Spec-Kit Guides](spec-kit/guides/SPEC_KIT_INDEX.md) • [Performance Optimizations](#performance-optimizations)

## ⚡ NON-NEGOTIABLE REQUIREMENTS

### 🚨 CRITICAL: Ghostty Performance & Optimization (2025)
- **Linux CGroup Single-Instance**: MANDATORY for performance (`linux-cgroup = single-instance`)
- **Enhanced Shell Integration**: Auto-detection with advanced features
- **Memory Management**: Optimized scrollback limits and process controls
- **Auto Theme Switching**: Light/dark mode support with Catppuccin themes
- **Security Features**: Clipboard paste protection enabled

### 🚨 CRITICAL: Package Management & Dependencies
- **Ghostty**: Built from source with Zig 0.14.0 (latest stable)
- **ZSH**: Oh My ZSH with enhanced plugins for productivity
- **Node.js**: Latest LTS via NVM for AI tool integration
- **Dependencies**: Smart detection and minimal installation footprint

### 🚨 CRITICAL: Context7 MCP Integration & Documentation Synchronization

**Purpose**: Up-to-date documentation and best practices for all project technologies.

**Quick Setup:**
```bash
# 1. Configure environment
cp .env.example .env  # Add CONTEXT7_API_KEY=ctx7sk-your-api-key

# 2. Verify configuration
./scripts/check_context7_health.sh

# 3. Restart Claude Code to load MCP servers
exit && claude
```

**Health Check:** `./scripts/check_context7_health.sh`

**Available Tools:**
- `mcp__context7__resolve-library-id` - Find library IDs for documentation queries
- `mcp__context7__get-library-docs` - Retrieve up-to-date library documentation

**Constitutional Compliance:**
- **MANDATORY**: Query Context7 before major configuration changes
- **RECOMMENDED**: Add Context7 validation to local CI/CD workflows
- **BEST PRACTICE**: Document Context7 queries in conversation logs

**Complete Setup Guide:** [Context7 MCP Setup](documentations/user/setup/context7-mcp.md) - Installation, configuration, troubleshooting, examples

### 🚨 CRITICAL: GitHub MCP Integration & Repository Operations

**Purpose**: Direct GitHub API integration for repository operations, issues, PRs, and search.

**Quick Setup:**
```bash
# 1. Verify GitHub CLI authentication
gh auth status

# 2. Run health check
./scripts/check_github_mcp_health.sh

# 3. Restart Claude Code to load MCP servers
exit && claude
```

**Health Check:** `./scripts/check_github_mcp_health.sh`

**Core Capabilities:**
- **Repository Operations**: List, create, manage repositories
- **Issue Management**: Create, update, search issues
- **Pull Request Operations**: Create, review, merge PRs
- **Branch Management**: Create, list, delete branches
- **File Operations**: Read, create, update repository files
- **Search Operations**: Search repos, issues, PRs, code

**Constitutional Compliance:**
- **MANDATORY**: Use GitHub MCP for all repository operations (no manual gh CLI)
- **RECOMMENDED**: GitHub MCP operations follow branch preservation strategy
- **REQUIREMENT**: Respect branch naming conventions (YYYYMMDD-HHMMSS-type-description)

**Security:**
- ✅ Token stored in .env (not committed)
- ✅ Leverages existing gh CLI authentication
- ✅ Token auto-refreshes via gh CLI

**Complete Setup Guide:** [GitHub MCP Setup](documentations/user/setup/github-mcp.md) - Installation, configuration, usage examples, troubleshooting

### 🚨 CRITICAL: Branch Management & Git Strategy

#### Branch Preservation (MANDATORY)
- **NEVER DELETE BRANCHES** without explicit user permission
- **ALL BRANCHES** contain valuable configuration history
- **NO** automatic cleanup with `git branch -d`
- **YES** to automatic merge to main branch, preserving dedicated branch

#### Branch Naming (MANDATORY SCHEMA)
**Format**: `YYYYMMDD-HHMMSS-type-short-description`

Examples:
- `20250919-143000-feat-context-menu-integration`
- `20250919-143515-fix-performance-optimization`
- `20250919-144030-docs-agents-enhancement`

#### GitHub Safety Strategy
```bash
# MANDATORY: Every commit must use this workflow
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-description"
git checkout -b "$BRANCH_NAME"
git add .
git commit -m "Descriptive commit message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
# NEVER: git branch -d "$BRANCH_NAME"
```

### 🚨 CRITICAL: GitHub Pages Infrastructure (MANDATORY)
- **`.nojekyll` File**: ABSOLUTELY CRITICAL for GitHub Pages deployment
- **Location**: `docs/.nojekyll` (empty file, no content needed)
- **Purpose**: Disables Jekyll processing to allow `_astro/` directory assets
- **Impact**: Without this file, ALL CSS/JS assets return 404 errors
- **WARNING**: This file is ESSENTIAL - never remove during cleanup operations
- **Alternative**: No alternative - this file is required for Astro + GitHub Pages

#### Jekyll Cleanup Protection (MANDATORY)
```bash
# BEFORE removing ANY Jekyll-related files, verify this file exists:
ls -la docs/.nojekyll

# If missing, recreate immediately:
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages asset loading"
```

### 🚨 CRITICAL: Local CI/CD Requirements

#### Pre-Deployment Verification (MANDATORY)
**EVERY** configuration change MUST complete these steps locally FIRST:

```bash
# 1. Run local workflow (MANDATORY before GitHub)
./local-infra/runners/gh-workflow-local.sh local

# 2. Verify local build success
./local-infra/runners/gh-workflow-local.sh status

# 3. Test configuration locally
ghostty +show-config && ./scripts/check_updates.sh

# 4. Only then commit using branch strategy
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-config-optimization"
git checkout -b "$BRANCH_NAME"
# ... rest of workflow
```

#### Local Workflow Tools (MANDATORY)
- **`./local-infra/runners/gh-workflow-local.sh`** - Local GitHub Actions simulation
- **`./local-infra/runners/gh-pages-setup.sh`** - Zero-cost Pages configuration
- **Commands**: `local`, `status`, `trigger`, `pages`, `all`
- **Requirement**: Local success BEFORE any GitHub deployment

#### Cost Verification (MANDATORY)
```bash
# Check GitHub Actions usage
gh api user/settings/billing/actions

# Monitor workflow runs
gh run list --limit 10 --json status,conclusion,name,createdAt

# Verify zero-cost compliance
./local-infra/runners/gh-pages-setup.sh
```

#### Logging & Debugging (MANDATORY)
```bash
# Comprehensive logging system
LOG_LOCATIONS="/tmp/ghostty-start-logs/"
├── start-TIMESTAMP.log          # Human-readable main log
├── start-TIMESTAMP.log.json     # Structured JSON log for parsing
├── errors.log                   # Critical issues only
├── performance.json             # Performance metrics
└── system_state_TIMESTAMP.json  # Complete system state snapshots

# Local CI/CD logs
LOCAL_CI_LOGS="./local-infra/logs/"
├── workflow-TIMESTAMP.log       # Local workflow execution
├── gh-pages-TIMESTAMP.log       # GitHub Pages simulation
├── performance-TIMESTAMP.json   # CI performance metrics
└── test-results-TIMESTAMP.json  # Test execution results
```

## 🏗️ System Architecture

### Directory Structure (MANDATORY)

**Essential Structure**:
```
/home/kkk/Apps/ghostty-config-files/
├── start.sh, manage.sh         # Installation & management scripts
├── AGENTS.md                   # AI assistant instructions (single source of truth)
├── CLAUDE.md, GEMINI.md        # AI integration (symlinks to AGENTS.md)
├── README.md                   # User documentation
├── configs/                    # Ghostty config, themes, dircolors, workspace
├── scripts/                    # Utility scripts (installation, updates, health checks)
├── documentations/             # Centralized docs (user/, developer/, specifications/, archive/)
└── local-infra/               # Local CI/CD (runners/, tests/, logs/, config/)
```

**Complete Structure**: See [DIRECTORY_STRUCTURE.md](documentations/developer/architecture/DIRECTORY_STRUCTURE.md) for detailed directory tree with file descriptions, design patterns, and naming conventions.

### Technology Stack (NON-NEGOTIABLE)

**Terminal Environment**:
- **Ghostty**: Latest from source (Zig 0.14.0) with 2025 optimizations
- **ZSH**: Oh My ZSH with productivity plugins
- **Context Menu**: Nautilus integration for "Open in Ghostty"

**AI Integration**:
- **Claude Code**: Latest CLI via npm for code assistance
- **Gemini CLI**: Google's AI assistant with Ptyxis integration
- **Context7 MCP**: Up-to-date documentation server for best practices synchronization
- **Node.js**: Latest LTS via NVM for tool compatibility

**Local CI/CD**:
- **GitHub CLI**: For workflow simulation and API access
- **Local Runners**: Shell-based workflow execution
- **Performance Monitoring**: System state and timing analysis
- **Zero-Cost Strategy**: All CI/CD runs locally before GitHub

**Directory Color Configuration**:
- **XDG Compliance**: Follows XDG Base Directory Specification
- **Location**: `~/.config/dircolors` (not `~/.dircolors` in home directory)
- **Deployment**: Automatic via `start.sh` installation script
- **Shell Integration**: Auto-configured for bash and zsh

### 🎨 Directory Colors & Readability (XDG-Compliant)

The repository includes a carefully configured `dircolors` file that solves common readability issues with directory listings, particularly for world-writable directories.

#### Problem Solved
Default LS_COLORS often render certain directories (like `Desktop`, `Templates`, `.password-store`, `.keras`) with unreadable color combinations:
- **World-writable directories** (`drwxrwxrwx`): Blue text on green background (nearly impossible to read)
- **Standard directories**: Bold blue text (can be difficult to read on some terminal backgrounds)

#### Solution Implementation
**Location**: `configs/ghostty/dircolors` (deployed to `~/.config/dircolors`)

**Key Color Customizations**:
```bash
DIR 01;33                    # Directories: Bold yellow (highly readable)
OTHER_WRITABLE 30;43         # World-writable: Black on yellow (clear contrast)
STICKY_OTHER_WRITABLE 30;42  # Sticky+writable: Black on green
```

**XDG Base Directory Compliance**:
- **Traditional approach** (❌): `~/.dircolors` (clutters home directory)
- **XDG-compliant** (✅): `~/.config/dircolors` (organized, follows standards)
- **Reference**: [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/)

#### Automatic Deployment

The `start.sh` script automatically:
1. Copies `configs/ghostty/dircolors` to `~/.config/dircolors`
2. Adds XDG-compliant dircolors loading to `.bashrc` and `.zshrc`:
   ```bash
   eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"
   ```
3. Preserves existing customizations (idempotent updates)

#### Manual Testing
```bash
# Apply dircolors configuration immediately
eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"

# Test with directory listing
ls -la ~

# Verify world-writable directories are readable
# (Desktop, Templates, etc. should show black on yellow)
```

#### Benefits
- ✅ **XDG Standards Compliance**: Keeps home directory clean
- ✅ **Automatic Deployment**: One-command installation via `start.sh`
- ✅ **Enhanced Readability**: World-writable directories clearly visible
- ✅ **Shell Agnostic**: Works with bash, zsh, and other POSIX shells
- ✅ **Preservation**: User customizations maintained during updates

## 📊 Core Functionality

### Primary Goals
1. **Zero-Configuration Terminal**: One-command setup for Ubuntu fresh installs
2. **2025 Performance Optimizations**: Latest Ghostty features and speed improvements
3. **Context Menu Integration**: Right-click "Open in Ghostty" in file manager
4. **Intelligent Updates**: Smart detection and preservation of user customizations
5. **Local CI/CD**: Complete workflow execution without GitHub Actions costs
6. **AI Tool Integration**: Seamless Claude Code and Gemini CLI setup
7. **Enhanced Readability**: XDG-compliant dircolors for readable directory listings

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

## 🛠️ Development Commands (MANDATORY)

### Environment Setup
```bash
# MANDATORY: One-command fresh Ubuntu setup
cd /home/kkk/Apps/ghostty-config-files
./start.sh

# Initialize local CI/CD infrastructure
./local-infra/runners/gh-workflow-local.sh init

# Setup GitHub CLI integration
gh auth login
gh repo set-default
```

### Local CI/CD Operations
```bash
# Complete local workflow execution
./local-infra/runners/gh-workflow-local.sh all

# Individual workflow stages
./local-infra/runners/gh-workflow-local.sh validate    # Config validation
./local-infra/runners/gh-workflow-local.sh test       # Performance testing
./local-infra/runners/gh-workflow-local.sh build      # Build simulation
./local-infra/runners/gh-workflow-local.sh deploy     # Deployment simulation

# GitHub Actions cost monitoring
./local-infra/runners/gh-workflow-local.sh billing    # Check usage
./local-infra/runners/gh-workflow-local.sh status     # Workflow status
```

### Update Management
```bash
# Smart update detection and application
./scripts/check_updates.sh              # Check and apply necessary updates
./scripts/check_updates.sh --force      # Force all updates
./scripts/check_updates.sh --config-only # Configuration updates only

# Local CI/CD for updates
./local-infra/runners/gh-workflow-local.sh update     # Update workflow
```

### Testing & Validation
```bash
# Configuration validation
ghostty +show-config                    # Validate current configuration
./local-infra/runners/test-runner.sh    # Complete test suite

# Performance monitoring
./local-infra/runners/performance-monitor.sh --baseline # Establish baseline
./local-infra/runners/performance-monitor.sh --compare  # Compare performance

# System testing
./start.sh --verbose                    # Full installation with detailed logs
```

## 🔄 Local CI/CD Implementation

### GitHub CLI Integration

**Script**: `local-infra/runners/gh-workflow-local.sh`

The gh-workflow-local.sh script provides comprehensive local CI/CD capabilities with zero GitHub Actions cost. It includes configuration validation, performance testing, workflow status monitoring, and billing checks.

**Usage**:
```bash
# Run complete local workflow
./local-infra/runners/gh-workflow-local.sh all

# Individual operations
./local-infra/runners/gh-workflow-local.sh local      # Simulate GitHub Actions locally
./local-infra/runners/gh-workflow-local.sh status    # Check workflow status
./local-infra/runners/gh-workflow-local.sh billing   # Monitor Actions usage
./local-infra/runners/gh-workflow-local.sh pages     # Local Pages simulation

# Get help
./local-infra/runners/gh-workflow-local.sh --help
```

**Features**:
- Robust error handling with `set -euo pipefail`
- Structured logging with timestamps and color-coded output
- Performance timing for all operations
- Automatic cleanup with trap handlers
- 2025 Ghostty optimization validation
- GitHub Actions cost monitoring

### Performance Monitoring

**Script**: `local-infra/runners/performance-monitor.sh`

Monitors Ghostty terminal performance, tracks 2025 optimizations, and generates comprehensive performance reports.

**Usage**:
```bash
# Run performance test
./local-infra/runners/performance-monitor.sh --test

# Establish baseline
./local-infra/runners/performance-monitor.sh --baseline

# Generate weekly report
./local-infra/runners/performance-monitor.sh --weekly-report

# Get help
./local-infra/runners/performance-monitor.sh --help
```

**Metrics Collected**:
- Startup time measurement
- Configuration load time
- CGroup single-instance optimization status
- Shell integration detection status
- System information (hostname, kernel, uptime)

**Output**: Performance data saved to `./local-infra/logs/performance-*.json`

### Zero-Cost GitHub Pages Setup

**Script**: `local-infra/runners/gh-pages-setup.sh`

Configures zero-cost GitHub Pages deployment with Astro.build, including critical `.nojekyll` file validation.

**Usage**:
```bash
# Complete setup (verify, build, configure)
./local-infra/runners/gh-pages-setup.sh

# Individual operations
./local-infra/runners/gh-pages-setup.sh --verify      # Verify build and .nojekyll
./local-infra/runners/gh-pages-setup.sh --build       # Run Astro build
./local-infra/runners/gh-pages-setup.sh --configure   # Configure GitHub Pages

# Get help
./local-infra/runners/gh-pages-setup.sh --help
```

**Critical Validations**:
- ✅ `.nojekyll` file existence (REQUIRED for Astro + GitHub Pages)
- ✅ Astro build output verification (`docs/index.html`)
- ✅ Asset directory verification (`docs/_astro/`)
- ✅ GitHub Pages configuration via GitHub CLI
- ✅ Manual setup instructions fallback

**Note**: The `.nojekyll` file is CRITICAL - without it, ALL CSS/JS assets will return 404 errors on GitHub Pages.

## 🚨 LLM Conversation Logging (MANDATORY)

**CRITICAL REQUIREMENT**: All AI assistants working on this repository **MUST** save complete conversation logs and maintain debugging information.

### Requirements
- **Complete Logs**: Save entire conversation from start to finish
- **Exclude Sensitive Data**: Remove API keys, passwords, personal information
- **Storage Location**: `documentations/development/conversation_logs/`
- **Naming Convention**: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- **System State**: Capture before/after system states for debugging
- **CI/CD Logs**: Include local workflow execution logs

### Example Workflow
```bash
# After completing work, save conversation log and system state
mkdir -p documentations/development/conversation_logs/
cp /path/to/conversation.md documentations/development/conversation_logs/CONVERSATION_LOG_20250919_local_cicd_setup.md

# Capture system state and CI/CD logs
cp /tmp/ghostty-start-logs/system_state_*.json documentations/development/system_states/
cp ./local-infra/logs/* documentations/development/ci_cd_logs/

git add documentations/development/
git commit -m "Add conversation log, system state, and CI/CD logs for local infrastructure setup"
```

## ⚠️ ABSOLUTE PROHIBITIONS

### DO NOT
- **NEVER REMOVE `docs/.nojekyll`** - This breaks ALL CSS/JS loading on GitHub Pages
- Delete branches without explicit user permission
- Use GitHub Actions for anything that consumes minutes
- Skip local CI/CD validation before GitHub deployment
- Ignore existing user customizations during updates
- Apply configuration changes without backup
- Commit sensitive data (API keys, passwords, personal information)
- Bypass the intelligent update system for configuration changes
- Remove Jekyll-related files without verifying `.nojekyll` preservation

### DO NOT BYPASS
- Branch preservation requirements
- Local CI/CD execution requirements
- Zero-cost operation constraints
- Configuration validation steps
- User customization preservation
- Logging and debugging requirements

## ✅ MANDATORY ACTIONS

### Before Every Configuration Change
1. **Local CI/CD Execution**: Run `./local-infra/runners/gh-workflow-local.sh all`
2. **Configuration Validation**: Run `ghostty +show-config` to ensure validity
3. **Performance Testing**: Execute `./local-infra/runners/performance-monitor.sh`
4. **Backup Creation**: Automatic timestamped backup of existing configuration
5. **User Preservation**: Extract and preserve user customizations
6. **Documentation**: Update relevant docs if adding features
7. **Conversation Log**: Save complete AI conversation log with system state

### Quality Gates
- Local CI/CD workflows execute successfully
- Configuration validates without errors via `ghostty +show-config`
- All 2025 performance optimizations are present and functional
- User customizations are preserved and functional
- Context menu integration works correctly
- GitHub Actions usage remains within free tier limits
- All logging systems capture complete information

## 🎯 Success Criteria

### Performance Metrics (2025)
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

## 📚 Documentation & Help

### Key Documents
- [README.md](README.md) - User documentation and quick start guide
- [CLAUDE.md](CLAUDE.md) - Claude Code integration details (symlink to this file)
- [GEMINI.md](GEMINI.md) - Gemini CLI integration details (symlink to this file)

### 🚨 CRITICAL: Documentation Structure (CONSTITUTIONAL REQUIREMENT)
- **`docs/`** - **Astro.build output ONLY** → GitHub Pages deployment (committed, DO NOT manually edit)
- **`docs-source/`** - **Astro source files** → Editable markdown documentation (user-guide/, ai-guidelines/, developer/)
- **`documentations/`** - **Centralized documentation hub** (as of 2025-11-09):
  - `user/` - End-user documentation (installation, configuration, troubleshooting)
  - `developer/` - Developer documentation (architecture, analysis)
  - `specifications/` - Active feature specifications with planning artifacts (Spec 001, 002, 004)
  - `archive/` - Historical/obsolete documentation (preserved for reference)

### 🎯 Spec-Kit Development Guides
For modern web development with uv + Astro + GitHub Pages: **[Spec-Kit Index](spec-kit/guides/SPEC_KIT_INDEX.md)** - Complete navigation, commands (/constitution, /specify, /plan, /tasks, /implement), and implementation guides.

## 🌐 Modern Web Development Stack Integration

**Feature 001**: uv + Astro.build + Tailwind CSS + shadcn/ui stack with zero-cost GitHub Pages deployment. **Planning Complete** - Ready for `/tasks` command.

**Complete Specification**: [OVERVIEW.md](documentations/specifications/004-modern-web-development/OVERVIEW.md) - Core stack, performance targets, CI/CD requirements, constitutional compliance, implementation phases.

### Support Commands
```bash
# Get help with installation
./start.sh --help

# Get help with local CI/CD
./local-infra/runners/gh-workflow-local.sh --help

# Get help with updates
./scripts/check_updates.sh --help

# Validate system state
ghostty +show-config
./local-infra/runners/test-runner.sh --validate

# Emergency configuration recovery
cp ~/.config/ghostty/config.backup-* ~/.config/ghostty/config
ghostty +show-config
```

### Debugging & Troubleshooting
```bash
# View comprehensive logs
ls -la /tmp/ghostty-start-logs/
ls -la ./local-infra/logs/

# Analyze system state
jq '.' /tmp/ghostty-start-logs/system_state_*.json

# Check CI/CD performance
jq '.' ./local-infra/logs/performance-*.json

# View errors only
cat /tmp/ghostty-start-logs/errors.log
cat ./local-infra/logs/workflow-errors.log
```

## 🔄 Continuous Integration & Automation

### Daily Maintenance (Recommended)
```bash
# Add to crontab for automatic local CI/CD
# 0 9 * * * cd /home/kkk/Apps/ghostty-config-files && ./local-infra/runners/gh-workflow-local.sh all

# Weekly performance monitoring
# 0 9 * * 0 cd /home/kkk/Apps/ghostty-config-files && ./local-infra/runners/performance-monitor.sh --weekly-report
```

### GitHub CLI Automation
```bash
# Monitor repository activity
gh repo view --json name,description,pushedAt,isPrivate

# Check workflow status without triggering actions
gh run list --limit 10 --json status,conclusion,name,createdAt

# Monitor billing to ensure zero cost
gh api user/settings/billing/actions | jq '{total_minutes_used, included_minutes, total_paid_minutes_used}'
```

---

**CRITICAL**: These requirements are NON-NEGOTIABLE. All AI assistants must follow these guidelines exactly. Failure to comply may result in configuration corruption, performance degradation, user data loss, or unexpected GitHub Actions charges.

**Version**: 2.0-2025-LocalCI
**Last Updated**: 2025-09-19
**Status**: ACTIVE - MANDATORY COMPLIANCE
**Target**: Ubuntu 25.10 (Questing) with Ghostty 1.2.0+ and zero-cost local CI/CD
**Review**: Required before any major configuration changes

## Active Technologies
- ZSH (Ubuntu 25.10 default shell), Node.js LTS (for Astro.build documentation site) (001-repo-structure-refactor)
- File-based configuration and documentation (no database) (001-repo-structure-refactor)
- ZSH (Ubuntu 25.10 default shell) + apt/dpkg (package management), snapd (snap installation), systemd (service management), jq (JSON processing), GitHub CLI (workflow integration) (005-apt-snap-migration)
- File-based logs in `/tmp/ghostty-start-logs/` and `./local-infra/logs/`, backup storage in `~/.config/package-migration/backups/`, JSON state files for migration tracking (005-apt-snap-migration)
- Bash 5.x+ with YAML/Markdown processing (yq/jq), spec archive system (20251111-042534-feat-task-archive-consolidation)

## Recent Changes
- 001-repo-structure-refactor: Added ZSH (Ubuntu 25.10 default shell), Node.js LTS (for Astro.build documentation site)