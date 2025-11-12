# Local CI/CD Infrastructure

## Overview

Consolidated local infrastructure for continuous integration, deployment testing, and self-hosted runner management without consuming GitHub Actions minutes.

## Directory Structure

- **workflows/** - Workflow execution scripts (committed)
  - `gh-workflow-local.sh` - Local GitHub Actions simulation
  - `gh-pages-setup.sh` - GitHub Pages local testing
  - `astro-build-local.sh` - Astro build workflow
  - `performance-monitor.sh` - Performance tracking
- **self-hosted/** - Self-hosted runner management (committed scripts, gitignored config)
  - `setup-self-hosted-runner.sh` - Runner setup
  - `config/` - Machine-specific runner credentials (gitignored)
- **tests/** - Testing infrastructure (committed)
  - `contract/` - Contract test suites
  - `unit/` - Unit test suites
  - `integration/` - Integration tests
  - `validation/` - Validation scripts
  - `fixtures/` - Test fixtures
- **logs/** - CI/CD execution logs (gitignored)
  - `workflows/` - Workflow execution logs
  - `builds/` - Build logs
  - `tests/` - Test execution logs
  - `runners/` - Runner service logs
- **docs/** - Runner documentation (committed)

## Quick Start

```bash
# Run complete local workflow
./.runners-local/workflows/gh-workflow-local.sh all

# Simulate specific stages
./.runners-local/workflows/gh-workflow-local.sh validate
./.runners-local/workflows/gh-workflow-local.sh test
./.runners-local/workflows/gh-workflow-local.sh build

# Monitor GitHub Actions usage
./.runners-local/workflows/gh-workflow-local.sh billing
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
./.runners-local/workflows/gh-workflow-local.sh validate

# Run tests
./.runners-local/workflows/gh-workflow-local.sh test

# Build and verify
./.runners-local/workflows/gh-workflow-local.sh build
```

### Performance Monitoring

```bash
# Establish baseline
./.runners-local/workflows/performance-monitor.sh --baseline

# Compare against baseline
./.runners-local/workflows/performance-monitor.sh --compare
```

### GitHub Pages Deployment

```bash
# Local Pages simulation
./.runners-local/workflows/gh-pages-setup.sh

# Verify deployment readiness
./.runners-local/workflows/gh-pages-setup.sh --verify
```

### Self-Hosted Runner Management

```bash
# Setup self-hosted runner
./.runners-local/self-hosted/setup-self-hosted-runner.sh setup

# Check runner status
./.runners-local/self-hosted/setup-self-hosted-runner.sh status

# Troubleshoot runner issues
./.runners-local/self-hosted/troubleshoot-runner.sh
```

---

**Last Updated**: 2025-11-11
**Status**: Active
**Maintainer**: See AGENTS.md for AI assistant instructions
