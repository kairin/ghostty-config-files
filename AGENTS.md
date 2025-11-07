# Ghostty Configuration Files - LLM Instructions (2025 Edition)

> 🔧 **CRITICAL**: This file contains NON-NEGOTIABLE requirements that ALL AI assistants (Claude, Gemini, ChatGPT, etc.) working on this repository MUST follow at ALL times.

## 🎯 Project Overview

**Ghostty Configuration Files** is a comprehensive terminal environment setup featuring Ghostty terminal emulator with 2025 performance optimizations, right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI) and intelligent update management.

**Quick Links:** [README](README.md) • [CLAUDE Integration](CLAUDE.md) • [Gemini Integration](GEMINI.md) • [Spec-Kit Guides](spec-kit/SPEC_KIT_INDEX.md) • [Performance Optimizations](#performance-optimizations)

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
```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # 🚀 Primary installation & update script
├── AGENTS.md                   # This file - LLM instructions (single source of truth)
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
├── scripts/                   # Utility and automation scripts
│   ├── check_updates.sh       # Intelligent update detection
│   ├── install_context_menu.sh # Right-click integration
│   ├── install_ghostty_config.sh # Configuration installer
│   ├── update_ghostty.sh      # Ghostty version management
│   ├── fix_config.sh          # Configuration repair tools
│   └── agent_functions.sh     # AI assistant helper functions
└── local-infra/              # Zero-cost local infrastructure
    ├── runners/              # Local CI/CD scripts
    │   ├── gh-workflow-local.sh    # Local GitHub Actions simulation
    │   ├── gh-pages-setup.sh       # GitHub Pages local testing
    │   ├── test-runner.sh          # Local test execution
    │   └── performance-monitor.sh   # Performance tracking
    ├── logs/                 # Local CI/CD logs
    └── config/               # CI/CD configuration files
        ├── workflows/        # Local workflow definitions
        └── test-suites/      # Test configuration
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
```bash
# File: local-infra/runners/gh-workflow-local.sh
#!/bin/bash

# GitHub CLI-based local workflow simulation
case "$1" in
    "local")
        # Simulate GitHub Actions locally
        echo "🚀 Running local GitHub Actions simulation..."

        # Configuration validation
        ghostty +show-config || exit 1

        # Performance testing
        ./local-infra/runners/performance-monitor.sh --test

        # Build simulation
        ./start.sh --verbose --dry-run
        ;;

    "status")
        # Check workflow status using gh CLI
        gh run list --limit 5 --json status,conclusion,name,createdAt
        ;;

    "billing")
        # Monitor GitHub Actions usage
        gh api user/settings/billing/actions | jq '.total_minutes_used, .included_minutes'
        ;;

    "pages")
        # Local GitHub Pages simulation
        ./local-infra/runners/gh-pages-setup.sh
        ;;

    "all")
        # Complete local workflow
        $0 local && $0 status && $0 billing
        ;;
esac
```

### Performance Monitoring
```bash
# File: local-infra/runners/performance-monitor.sh
#!/bin/bash

monitor_ghostty_performance() {
    echo "📊 Monitoring Ghostty performance..."

    # Startup time measurement
    startup_time=$(time (ghostty --version) 2>&1 | grep real | awk '{print $2}')

    # Memory usage measurement
    memory_usage=$(ps aux | grep ghostty | awk '{sum+=$6} END {print sum/1024}')

    # Configuration load time
    config_time=$(time (ghostty +show-config) 2>&1 | grep real | awk '{print $2}')

    # Store results in JSON
    cat > "./local-infra/logs/performance-$(date +%s).json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "startup_time": "$startup_time",
    "memory_usage_mb": "$memory_usage",
    "config_load_time": "$config_time",
    "optimizations": {
        "cgroup_single_instance": $(grep -q "linux-cgroup.*single-instance" ~/.config/ghostty/config && echo "true" || echo "false"),
        "shell_integration_detect": $(grep -q "shell-integration.*detect" ~/.config/ghostty/config && echo "true" || echo "false")
    }
}
EOF
}
```

### Zero-Cost GitHub Pages Setup
```bash
# File: local-infra/runners/gh-pages-setup.sh
#!/bin/bash

setup_github_pages() {
    echo "📄 Setting up zero-cost GitHub Pages with Astro..."

    # Ensure Astro build output directory exists
    if [ ! -d "docs/" ]; then
        echo "❌ docs/ directory not found. Run Astro build first:"
        echo "   npx astro build"
        return 1
    fi

    # Configure GitHub Pages to serve from docs/ folder
    if command -v gh >/dev/null 2>&1; then
        echo "🔧 Configuring GitHub Pages deployment..."
        gh api repos/:owner/:repo --method PATCH \
            --field source[branch]=main \
            --field source[path]="/docs"
        echo "✅ GitHub Pages configured to serve from docs/ folder"
    else
        echo "ℹ️ GitHub CLI not available, configure Pages manually:"
        echo "   Settings → Pages → Source: Deploy from a branch → main → /docs"
    fi

    # Verify Astro build output
    if [ -f "docs/index.html" ]; then
        echo "✅ Astro build output verified in docs/"
    else
        echo "❌ No index.html found in docs/. Run: npx astro build"
        return 1
    fi
}
```

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
- **`docs/`** - **Astro.build output ONLY** → GitHub Pages deployment (DO NOT manually edit)
- **`documentations/`** - **All other documentation** → installation guides, screenshots, manuals, specs

### 🎯 Spec-Kit Development Guides
For implementing modern web development stacks with local CI/CD:
- **[Spec-Kit Index](spec-kit/SPEC_KIT_INDEX.md)** - Complete navigation and overview for uv + Astro + GitHub Pages stack
- **[Comprehensive Guide](spec-kit/SPEC_KIT_GUIDE.md)** - Original detailed implementation document
- **Individual Command Guides**:
  - [1. Constitution](spec-kit/1-spec-kit-constitution.md) - Establish project principles
  - [2. Specify](spec-kit/2-spec-kit-specify.md) - Create technical specifications
  - [3. Plan](spec-kit/3-spec-kit-plan.md) - Create implementation plans
  - [4. Tasks](spec-kit/4-spec-kit-tasks.md) - Generate actionable tasks
  - [5. Implement](spec-kit/5-spec-kit-implement.md) - Execute implementation

**Key Features**: uv-first Python management, Astro.build static sites, Tailwind CSS + shadcn/ui, mandatory local CI/CD, zero-cost GitHub Pages deployment.

## 🌐 Modern Web Development Stack Integration

### Feature 001: Modern Web Development Stack
**Implementation Status**: Planning Phase Complete, Ready for Tasks Generation
**Location**: `specs/001-modern-web-development/`
**Branch**: `001-modern-web-development`

**Core Stack Components**:
- **uv (≥0.4.0)**: Exclusive Python dependency management with virtual environment integration
- **Astro.build (≥4.0)**: Static site generation with TypeScript strict mode and islands architecture
- **Tailwind CSS (≥3.4)**: Utility-first CSS framework with design system optimization
- **shadcn/ui**: Copy-paste component library with Radix UI primitives and accessibility compliance
- **Local CI/CD Infrastructure**: Zero GitHub Actions consumption with complete workflow simulation

**Performance Targets**:
- Lighthouse scores 95+ across all metrics (Performance, Accessibility, Best Practices, SEO)
- Core Web Vitals: FCP <1.5s, LCP <2.5s, CLS <0.1
- JavaScript bundle size <100KB for initial load
- Build time <30 seconds locally with hot reload <1 second

**Local CI/CD Requirements**:
```bash
# Modern web stack local workflow
./local-infra/runners/astro-build-local.sh       # Astro build simulation
./local-infra/runners/performance-monitor.sh     # Core Web Vitals monitoring
./local-infra/runners/gh-workflow-local.sh all   # Complete validation
```

**Constitutional Compliance**:
- ✅ uv-First Python Management: Exclusive use of uv for all Python operations
- ✅ Static Site Generation Excellence: Astro.build with performance optimization
- ✅ Local CI/CD First: Mandatory local validation before GitHub deployment
- ✅ Component-Driven UI: shadcn/ui with accessibility requirements
- ✅ Zero-Cost Deployment: GitHub Pages with branch preservation

**Development Workflow Integration**:
```bash
# Spec-kit workflow commands for modern web development
/.specify/scripts/bash/create-new-feature.sh    # Feature specification
# Available commands: /constitution, /specify, /plan, /tasks, /implement

# Project structure follows constitutional requirements
project-root/
├── .venv/                  # uv managed Python environment
├── src/                    # Astro source files
├── components/             # shadcn/ui components
├── local-infra/            # Local CI/CD infrastructure
└── [config files]          # Constitutional configuration files
```

**Next Steps**: Execute `/tasks` command to generate implementation tasks following Phase 2 planning approach.

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
**Target**: Ubuntu 25.04+ with Ghostty 1.2.0+ and zero-cost local CI/CD
**Review**: Required before any major configuration changes

## Active Technologies
- Bash 5.x+ (Ubuntu 25.04 default shell), Node.js LTS (for Astro.build documentation site) (001-repo-structure-refactor)
- File-based configuration and documentation (no database) (001-repo-structure-refactor)

## Recent Changes
- 001-repo-structure-refactor: Added Bash 5.x+ (Ubuntu 25.04 default shell), Node.js LTS (for Astro.build documentation site)