# Local CI/CD Infrastructure

## Overview

Zero-cost local infrastructure for continuous integration and deployment testing without consuming GitHub Actions minutes.

## Directory Structure

- **runners/** - Local CI/CD execution scripts
  - `gh-workflow-local.sh` - Local GitHub Actions simulation
  - `gh-pages-setup.sh` - GitHub Pages local testing
  - `test-runner.sh` - Local test execution
  - `performance-monitor.sh` - Performance tracking
- **tests/** - Testing infrastructure
  - `unit/` - Unit test suites
  - `validation/` - Validation scripts
- **logs/** - CI/CD execution logs
- **config/** - CI/CD configuration files

## Quick Start

```bash
# Run complete local workflow
./local-infra/runners/gh-workflow-local.sh all

# Simulate specific stages
./local-infra/runners/gh-workflow-local.sh validate
./local-infra/runners/gh-workflow-local.sh test
./local-infra/runners/gh-workflow-local.sh build

# Monitor GitHub Actions usage
./local-infra/runners/gh-workflow-local.sh billing
```

## Benefits

- ✅ Zero GitHub Actions cost
- ✅ Faster feedback loop
- ✅ Complete workflow simulation
- ✅ Performance monitoring
- ✅ Offline development capability

## Documentation

- [CI/CD Requirements](../docs-source/ai-guidelines/ci-cd-requirements.md)
- [Development Commands](../docs-source/ai-guidelines/development-commands.md)
- [Testing Guide](../docs-source/developer/testing.md)
- [AGENTS.md](../AGENTS.md) - AI assistant integration

## Usage Examples

### Basic Workflow Execution

```bash
# Validate configuration
./local-infra/runners/gh-workflow-local.sh validate

# Run tests
./local-infra/runners/gh-workflow-local.sh test

# Build and verify
./local-infra/runners/gh-workflow-local.sh build
```

### Performance Monitoring

```bash
# Establish baseline
./local-infra/runners/performance-monitor.sh --baseline

# Compare against baseline
./local-infra/runners/performance-monitor.sh --compare
```

### GitHub Pages Deployment

```bash
# Local Pages simulation
./local-infra/runners/gh-pages-setup.sh

# Verify deployment readiness
./local-infra/runners/gh-pages-setup.sh --verify
```

---

**Last Updated**: 2025-11-11
**Status**: Active
**Maintainer**: See AGENTS.md for AI assistant instructions
