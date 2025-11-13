---
title: "Ci Cd Requirements"
description: "AI assistant guidelines for ci-cd-requirements"
pubDate: 2025-10-27
author: "AI Integration Team"
tags: ["ai", "guidelines"]
targetAudience: "all"
constitutional: true
---


> **Note**: This is a modular extract from [AGENTS.md](../../AGENTS.md) for documentation purposes. AGENTS.md remains the single source of truth.

## Local CI/CD Requirements

### Pre-Deployment Verification (MANDATORY)

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

### Local Workflow Tools (MANDATORY)
- **`./local-infra/runners/gh-workflow-local.sh`** - Local GitHub Actions simulation
- **`./local-infra/runners/gh-pages-setup.sh`** - Zero-cost Pages configuration
- **Commands**: `local`, `status`, `trigger`, `pages`, `all`
- **Requirement**: Local success BEFORE any GitHub deployment

### Cost Verification (MANDATORY)

```bash
# Check GitHub Actions usage
gh api user/settings/billing/actions

# Monitor workflow runs
gh run list --limit 10 --json status,conclusion,name,createdAt

# Verify zero-cost compliance
./local-infra/runners/gh-pages-setup.sh
```

### Logging & Debugging (MANDATORY)

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

## Local CI/CD Implementation

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

## Local CI/CD Workflows

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

## Development Commands (MANDATORY)

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

## Continuous Integration & Automation

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
