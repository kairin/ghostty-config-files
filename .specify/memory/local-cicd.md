# Local CI/CD Infrastructure

Complete guide to local-first development, zero-cost operations, and GitHub Actions simulation.

## Core Principle

**EVERY configuration change MUST complete local validation BEFORE any GitHub deployment**. This ensures zero GitHub Actions consumption and prevents production failures.

## Pre-Deployment Verification

### Required Steps (MANDATORY)
```bash
# 1. Run local workflow
./.runners-local/workflows/gh-workflow-local.sh local

# 2. Verify build success
./.runners-local/workflows/gh-workflow-local.sh status

# 3. Test configuration
ghostty +show-config && ./scripts/check_updates.sh

# 4. Only then proceed with git workflow
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-config-optimization"
git checkout -b "$BRANCH_NAME"
# ... rest of workflow
```

## Local Workflow Tools

### Primary Tools
- `./.runners-local/workflows/gh-workflow-local.sh` - Local GitHub Actions simulation
- `./.runners-local/workflows/gh-pages-setup.sh` - Zero-cost Pages configuration
- `./.runners-local/workflows/performance-monitor.sh` - Performance tracking
- `./.runners-local/workflows/astro-build-local.sh` - Astro build workflows

### Available Commands
```bash
# Complete workflows
./.runners-local/workflows/gh-workflow-local.sh all       # All stages
./.runners-local/workflows/gh-workflow-local.sh local     # Simulate GitHub Actions
./.runners-local/workflows/gh-workflow-local.sh status    # Check status
./.runners-local/workflows/gh-workflow-local.sh trigger   # Manual trigger
./.runners-local/workflows/gh-workflow-local.sh pages     # Pages simulation

# Individual operations
./.runners-local/workflows/gh-workflow-local.sh validate  # Config validation
./.runners-local/workflows/gh-workflow-local.sh test      # Performance testing
./.runners-local/workflows/gh-workflow-local.sh build     # Build simulation
./.runners-local/workflows/gh-workflow-local.sh deploy    # Deployment simulation

# Monitoring
./.runners-local/workflows/gh-workflow-local.sh billing   # Check GitHub Actions usage
```

## Local CI/CD Pipeline Stages

### Stage 01: Validate Configuration
```bash
# Validates Ghostty configuration
ghostty +show-config

# Validates shell scripts
shellcheck scripts/*.sh

# Validates JSON/YAML
jq '.' config.json
yq '.' config.yaml
```

### Stage 02: Test Performance
```bash
# Runs performance benchmarks
./.runners-local/workflows/performance-monitor.sh --test

# Validates 2025 optimizations
# - CGroup single-instance mode
# - Shell integration detection
# - Memory management
```

### Stage 03: Check Compatibility
```bash
# Cross-system validation
# - Ubuntu 25.10 compatibility
# - Ghostty 1.1.4+ features
# - Node.js latest (v25.2.0+)
```

### Stage 04: Simulate Workflows
```bash
# GitHub Actions local simulation
# Runs without consuming GitHub Actions minutes
./.runners-local/workflows/gh-workflow-local.sh local
```

### Stage 05: Generate Documentation
```bash
# Updates documentation
# Validates documentation sync
./.runners-local/workflows/documentation-sync-checker.sh
```

### Stage 06: Package Release
```bash
# Prepares release artifacts
# Validates package structure
```

### Stage 07: Deploy Pages
```bash
# Local Astro build
./.runners-local/workflows/astro-build-local.sh build

# Validates GitHub Pages requirements
./.runners-local/workflows/gh-pages-setup.sh --verify
```

## Directory Structure

```
.runners-local/                   # Consolidated local CI/CD infrastructure
├── workflows/                    # Workflow execution scripts (committed)
│   ├── gh-workflow-local.sh     # GitHub Actions local simulation
│   ├── astro-build-local.sh     # Astro build workflows
│   ├── performance-monitor.sh   # Performance tracking
│   └── gh-pages-setup.sh        # GitHub Pages setup
├── self-hosted/                  # Self-hosted runner management
│   ├── setup-self-hosted-runner.sh
│   └── config/                   # Runner credentials (GITIGNORED)
├── tests/                        # Complete test infrastructure
│   ├── contract/                # Contract tests
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   ├── validation/              # Validation scripts
│   └── fixtures/                # Test fixtures
├── logs/                         # Execution logs (GITIGNORED)
│   ├── workflows/               # Workflow logs
│   ├── builds/                  # Build logs
│   ├── tests/                   # Test logs
│   └── runners/                 # Runner service logs
└── docs/                         # Runner documentation (committed)
```

## Performance Targets

### Build Performance
- **Complete local workflow**: <2 minutes
- **Configuration validation**: <5 seconds
- **Astro build**: <30 seconds
- **Performance tests**: <10 seconds

### System Performance
- **Startup time**: <500ms (Ghostty CGroup optimization)
- **Memory usage**: <100MB baseline
- **Shell integration**: 100% feature detection
- **Configuration validity**: 100% success rate

## Cost Monitoring

### GitHub Actions Usage
```bash
# Check current usage
gh api user/settings/billing/actions

# Expected output for zero-cost compliance:
# {
#   "total_minutes_used": 0,
#   "included_minutes": 2000,
#   "total_paid_minutes_used": 0
# }

# Monitor workflow runs
gh run list --limit 10 --json status,conclusion,name,createdAt

# Verify zero-cost compliance
./.runners-local/workflows/gh-pages-setup.sh
```

### Cost Breakdown
- **Free tier**: 2,000 minutes/month
- **Target usage**: 0 minutes/month (all local)
- **Emergency usage**: <100 minutes/month (manual GitHub Actions triggers only)

## Logging & Debugging

### Log Locations
```bash
# Ghostty start logs
/tmp/ghostty-start-logs/
├── start-TIMESTAMP.log          # Human-readable main log
├── start-TIMESTAMP.log.json     # Structured JSON log
├── errors.log                   # Critical issues only
├── performance.json             # Performance metrics
└── system_state_TIMESTAMP.json  # System state snapshots

# Local CI/CD logs
./.runners-local/logs/
├── workflow-TIMESTAMP.log       # Local workflow execution
├── gh-pages-TIMESTAMP.log       # GitHub Pages simulation
├── performance-TIMESTAMP.json   # CI performance metrics
└── test-results-TIMESTAMP.json  # Test execution results
```

### Debugging Commands
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

## Integration with Git Workflow

### Complete Workflow
```bash
# 1. Run local CI/CD FIRST
./.runners-local/workflows/gh-workflow-local.sh all

# 2. If validation passes, create branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-description"
git checkout -b "$BRANCH_NAME"

# 3. Make changes and commit
git add .
git commit -m "feat(scope): description"

# 4. Push and merge (preserving branch)
git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
```

### Validation Gates
- Local CI/CD workflows execute successfully
- Configuration validates without errors
- Performance tests pass benchmarks
- Documentation sync verified
- GitHub Actions usage remains zero

## Continuous Integration

### Daily Maintenance
```bash
# Add to crontab for automatic local CI/CD
0 9 * * * cd /home/kkk/Apps/ghostty-config-files && ./.runners-local/workflows/gh-workflow-local.sh all

# Weekly performance monitoring
0 9 * * 0 cd /home/kkk/Apps/ghostty-config-files && ./.runners-local/workflows/performance-monitor.sh --weekly-report
```

### Automated Daily Updates
```bash
# System updates (9:00 AM daily via cron)
update-all                              # Execute all updates
update-logs                             # Latest summary
update-logs-full                        # Complete log
update-logs-errors                      # Errors only

# What gets updated:
# - System packages (apt)
# - Oh My Zsh framework and plugins
# - npm and global packages
# - Claude CLI, Gemini CLI, GitHub Copilot CLI
```

## Rationale

### Why Local-First?

1. **Zero Cost**: Prevents GitHub Actions consumption (2,000 free minutes/month)
2. **Rapid Iteration**: No network latency, immediate feedback
3. **Offline Development**: Works without internet connection
4. **Early Error Detection**: Catches issues before production
5. **Complete Control**: Full visibility into all operations

### Performance Benefits

- **Immediate feedback**: <2 minutes for complete validation
- **No queuing**: GitHub Actions can have queue delays
- **Parallel execution**: Multiple local workflows simultaneously
- **Resource efficiency**: Uses local machine resources

### Quality Benefits

- **Consistent environment**: Same tools, same results
- **Reproducible builds**: Deterministic local execution
- **Complete logging**: Full visibility into all operations
- **Easy debugging**: Direct access to logs and state

---

**Back to**: [constitution.md](constitution.md) | [core-principles.md](core-principles.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
