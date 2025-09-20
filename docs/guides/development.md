# Development Guide

## Getting Started

### Prerequisites
- Ubuntu 22.04+ (recommended)
- Git with GitHub CLI configured
- Node.js (latest LTS via NVM)
- Python 3.12+ with uv
- Zig 0.14.0 (for Ghostty compilation)

### Development Setup
```bash
# Clone and setup
git clone <repository-url>
cd ghostty-config-files

# Run complete setup
./start.sh

# Initialize development environment
./local-infra/runners/gh-workflow-local.sh init
```

## Constitutional Development Workflow

### 1. Pre-Development Validation
```bash
# Ensure system is ready
./local-infra/runners/gh-workflow-local.sh validate

# Check current performance baseline
./local-infra/runners/benchmark-runner.sh --baseline
```

### 2. Constitutional Branch Creation
```bash
# Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${{DATETIME}}-feat-your-feature"
git checkout -b "$BRANCH_NAME"
```

### 3. Development with Continuous Validation
```bash
# During development, run continuous monitoring
./local-infra/runners/performance-monitor.sh --watch

# Validate changes frequently
./local-infra/runners/test-runner-local.sh --quick
```

### 4. Pre-Commit Validation
```bash
# Complete local CI/CD before commit
./local-infra/runners/gh-workflow-local.sh all

# Ensure constitutional compliance
python scripts/constitutional_automation.py --validate
```

### 5. Constitutional Commit
```bash
git add .
git commit -m "Descriptive commit message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 6. Merge with Branch Preservation
```bash
# Push branch
git push -u origin "$BRANCH_NAME"

# Merge to main preserving branch
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main

# NEVER delete branch without explicit permission
# git branch -d "$BRANCH_NAME" # ❌ PROHIBITED
```

## Code Standards

### TypeScript/Astro
- Strict TypeScript mode required
- ESLint and Prettier configuration enforced
- Constitutional component patterns
- Performance-first implementations

### Python
- PEP 8 compliance with constitutional extensions
- Type hints required (Python 3.12+ features)
- Async/await for I/O operations
- Constitutional logging patterns

### Shell Scripts
- Bash strict mode (`set -euo pipefail`)
- Constitutional logging functions
- Performance monitoring integration
- Error handling and rollback procedures

## Testing Requirements

### Local Testing
```bash
# Complete test suite
./local-infra/runners/test-runner-local.sh

# Component-specific testing
npm run test                    # Frontend tests
python -m pytest scripts/      # Python script tests
```

### Performance Testing
```bash
# Performance benchmarks
./local-infra/runners/benchmark-runner.sh --full

# Core Web Vitals monitoring
python scripts/performance_monitor.py --comprehensive
```

### Constitutional Compliance Testing
```bash
# Constitutional validation
python scripts/constitutional_automation.py --test

# Zero GitHub Actions validation
./local-infra/runners/gh-workflow-local.sh billing
```

## Debugging

### Comprehensive Logging
All operations generate detailed logs:
- `local-infra/logs/` - CI/CD and workflow logs
- `/tmp/ghostty-start-logs/` - System installation and update logs
- `docs/development/` - Development and debugging information

### Performance Debugging
```bash
# Analyze performance issues
jq '.' local-infra/logs/performance-*.json

# Monitor system resources
./local-infra/runners/performance-monitor.sh --diagnose
```

### Configuration Debugging
```bash
# Validate Ghostty configuration
ghostty +show-config

# Check configuration diff
./scripts/check_updates.sh --diff
```
