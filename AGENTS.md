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
│   │   └── keybindings.conf   # Productivity keybindings
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

## 📊 Core Functionality

### Primary Goals
1. **Zero-Configuration Terminal**: One-command setup for Ubuntu fresh installs
2. **2025 Performance Optimizations**: Latest Ghostty features and speed improvements
3. **Context Menu Integration**: Right-click "Open in Ghostty" in file manager
4. **Intelligent Updates**: Smart detection and preservation of user customizations
5. **Local CI/CD**: Complete workflow execution without GitHub Actions costs
6. **AI Tool Integration**: Seamless Claude Code and Gemini CLI setup

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
    echo "📄 Setting up zero-cost GitHub Pages..."

    # Create documentation directory
    mkdir -p docs/

    # Copy README as index
    cp README.md docs/index.md

    # Create simple GitHub Pages config
    cat > docs/_config.yml << EOF
title: Ghostty Configuration Files
description: Comprehensive terminal environment setup with 2025 optimizations
theme: jekyll-theme-minimal
plugins:
  - jekyll-relative-links
relative_links:
  enabled: true
  collections: true
EOF

    # Test local Jekyll build (if available)
    if command -v jekyll >/dev/null 2>&1; then
        cd docs && jekyll build --destination _site_test
        echo "✅ Local Jekyll build successful"
    else
        echo "ℹ️ Jekyll not available, skipping local build test"
    fi
}
```

## 🚨 LLM Conversation Logging (MANDATORY)

**CRITICAL REQUIREMENT**: All AI assistants working on this repository **MUST** save complete conversation logs and maintain debugging information.

### Requirements
- **Complete Logs**: Save entire conversation from start to finish
- **Exclude Sensitive Data**: Remove API keys, passwords, personal information
- **Storage Location**: `docs/development/conversation_logs/`
- **Naming Convention**: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- **System State**: Capture before/after system states for debugging
- **CI/CD Logs**: Include local workflow execution logs

### Example Workflow
```bash
# After completing work, save conversation log and system state
mkdir -p docs/development/conversation_logs/
cp /path/to/conversation.md docs/development/conversation_logs/CONVERSATION_LOG_20250919_local_cicd_setup.md

# Capture system state and CI/CD logs
cp /tmp/ghostty-start-logs/system_state_*.json docs/development/system_states/
cp ./local-infra/logs/* docs/development/ci_cd_logs/

git add docs/development/
git commit -m "Add conversation log, system state, and CI/CD logs for local infrastructure setup"
```

## ⚠️ ABSOLUTE PROHIBITIONS

### DO NOT
- Delete branches without explicit user permission
- Use GitHub Actions for anything that consumes minutes
- Skip local CI/CD validation before GitHub deployment
- Ignore existing user customizations during updates
- Apply configuration changes without backup
- Commit sensitive data (API keys, passwords, personal information)
- Bypass the intelligent update system for configuration changes

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