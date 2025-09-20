# Deployment Guide

## Constitutional Deployment Strategy

All deployments follow the Constitutional Framework ensuring zero GitHub Actions consumption and local validation.

### Pre-Deployment Checklist
- [ ] Local CI/CD passes (`./local-infra/runners/gh-workflow-local.sh all`)
- [ ] Configuration validates (`ghostty +show-config`)
- [ ] Performance targets met (Lighthouse 95+, <100KB JS, <2.5s LCP)
- [ ] Zero GitHub Actions consumption confirmed
- [ ] User customizations preserved
- [ ] Documentation updated
- [ ] Constitutional branch naming used

### Deployment Workflow

#### 1. Local Validation
```bash
# Complete local CI/CD workflow
./local-infra/runners/gh-workflow-local.sh all

# Validate constitutional compliance
python scripts/constitutional_automation.py --validate

# Performance benchmarking
./local-infra/runners/benchmark-runner.sh --full
```

#### 2. GitHub Pages Deployment (Zero-Cost)
```bash
# Local GitHub Pages simulation
./local-infra/runners/gh-pages-setup.sh

# Verify zero GitHub Actions consumption
gh api user/settings/billing/actions | jq '.total_paid_minutes_used'
```

#### 3. Configuration Deployment
```bash
# Deploy configuration changes
./scripts/check_updates.sh --apply

# Validate deployment
ghostty +show-config
```

### Rollback Procedures

#### Automatic Rollback
The system automatically rolls back on:
- Configuration validation failures
- Performance regression below constitutional targets
- User customization overwrites
- GitHub Actions minute consumption

#### Manual Rollback
```bash
# Restore from backup
cp ~/.config/ghostty/config.backup-* ~/.config/ghostty/config

# Verify restoration
ghostty +show-config

# Re-run validation
./local-infra/runners/test-runner-local.sh
```

### Production Monitoring

#### Continuous Monitoring
```bash
# Setup continuous monitoring (add to crontab)
# 0 */6 * * * cd /path/to/project && ./local-infra/runners/performance-monitor.sh --continuous

# Daily constitutional validation
# 0 9 * * * cd /path/to/project && python scripts/constitutional_automation.py --validate
```

#### Performance Monitoring
```bash
# Monitor Core Web Vitals
python scripts/performance_monitor.py --production

# System performance monitoring
./local-infra/runners/benchmark-runner.sh --monitor
```

### Emergency Procedures

#### Configuration Recovery
```bash
# Emergency configuration reset
./scripts/fix_config.sh --emergency

# Restore from known-good backup
./scripts/fix_config.sh --restore-backup
```

#### Performance Recovery
```bash
# Performance issue diagnosis
./local-infra/runners/benchmark-runner.sh --diagnose

# Apply performance optimizations
./scripts/check_updates.sh --performance-only
```

### Deployment Environments

#### Development
- Local CI/CD validation required
- Continuous performance monitoring
- Constitutional compliance checking

#### Staging
- Complete local workflow execution
- Performance benchmarking against targets
- User acceptance testing

#### Production
- Zero GitHub Actions consumption validated
- All constitutional targets met
- Emergency rollback procedures tested
