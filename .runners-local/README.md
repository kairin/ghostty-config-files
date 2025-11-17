# Local CI/CD Infrastructure

## Overview

Consolidated local infrastructure for continuous integration, deployment testing, and self-hosted runner management without consuming GitHub Actions minutes.

## Directory Structure

- **workflows/** - Workflow execution scripts (committed)
  - `gh-workflow-local.sh` - Local GitHub Actions simulation
  - `gh-pages-setup.sh` - GitHub Pages local testing (active)
  - `astro-build-local.sh` - Astro build workflow
  - `performance-monitor.sh` - Performance tracking
  - `pre-commit-local.sh` - Pre-commit validation
  - `documentation-sync-checker.sh` - Documentation synchronization
  - `benchmark-runner.sh` - Constitutional performance benchmarking
  - `performance-dashboard.sh` - Performance metrics dashboard
  - `validate-modules.sh` - Module contract and dependency validation
  - ~~`astro-pages-setup.sh.DISABLED`~~ - Archived (replaced by `gh-pages-setup.sh`)
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
  - `.runners-local/workflows/` - Runner service logs
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

- [CI/CD Requirements](../website/src/ai-guidelines/ci-cd-requirements.md)
- [Development Commands](../website/src/ai-guidelines/development-commands.md)
- [Testing Guide](../website/src/developer/testing.md)
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

## Workflow Scripts Documentation

### 1. astro-build-local.sh

**Purpose**: Enhanced Astro build runner with self-hosted integration for constitutional compliance and zero-cost local CI/CD.

**Key Features**:
- Complete Astro build workflow with environment detection
- Node.js 25+ validation with Astro 18+ compatibility
- TypeScript validation and GitHub Pages configuration
- Constitutional compliance checks (bundle size <100KB)
- Performance metrics tracking with JSON reporting
- Supports both local development and GitHub Actions runners

**Usage**:
```bash
# Complete build workflow (default)
./.runners-local/workflows/astro-build-local.sh build

# Install dependencies only
./.runners-local/workflows/astro-build-local.sh deps

# TypeScript validation only
./.runners-local/workflows/astro-build-local.sh check

# Astro build only
./.runners-local/workflows/astro-build-local.sh astro

# Validate GitHub Pages deployment
./.runners-local/workflows/astro-build-local.sh validate

# Generate build report
./.runners-local/workflows/astro-build-local.sh report

# Clean build output
./.runners-local/workflows/astro-build-local.sh clean

# Show help
./.runners-local/workflows/astro-build-local.sh help
```

**Environment Variables**:
- `NODE_ENV` - Build environment (default: production)
- `ASTRO_TELEMETRY_DISABLED` - Disable telemetry (default: 1)
- `RUNNER_TYPE` - Set by environment detection (local/github-actions)

**Expected Output**:
- Build performance logs: `.runners-local/logs/astro-build-*.log`
- Performance metrics: `.runners-local/logs/astro-performance-*.json`
- Build reports: `.runners-local/logs/astro-build-report-*.json`
- Build output: `docs/` directory

**Prerequisites**:
- Node.js 25+ (project target) or 18+ (Astro minimum)
- npm package manager
- package.json and astro.config.mjs
- Valid Astro project structure

**Constitutional Compliance**:
- JavaScript bundle <100KB validation
- GitHub Pages configuration verification
- TypeScript strict mode enforcement
- Performance timing and optimization

---

### 2. pre-commit-local.sh

**Purpose**: Local CI/CD pre-commit validation implementing zero GitHub Actions consumption with comprehensive file, commit, and constitutional compliance checks.

**Key Features**:
- Constitutional compliance validation (zero GitHub Actions, uv-First Python)
- File change validation (Python, TypeScript, Astro, JSON, YAML, Markdown)
- Commit message validation (conventional commits, length checks)
- Performance impact assessment (dependencies, configs, components)
- GitHub CLI integration for repository status checks
- Sensitive data pattern detection
- JSON validation reports with constitutional compliance status

**Usage**:
```bash
# Full validation (default)
./.runners-local/workflows/pre-commit-local.sh

# File validation only
./.runners-local/workflows/pre-commit-local.sh --type files

# Commit message validation only
./.runners-local/workflows/pre-commit-local.sh --type commit "feat: add feature"

# Performance impact only
./.runners-local/workflows/pre-commit-local.sh --type performance

# With commit message
./.runners-local/workflows/pre-commit-local.sh "fix: resolve bug"

# Show help
./.runners-local/workflows/pre-commit-local.sh --help

# Show version
./.runners-local/workflows/pre-commit-local.sh --version
```

**Validation Types**:
- `full` - All validation checks (default)
- `files` - File changes only
- `commit` - Commit message only
- `performance` - Performance impact only

**Expected Output**:
- Human-readable logs: `.runners-local/logs/workflows/pre-commit-*.log`
- JSON reports: `.runners-local/logs/workflows/pre-commit-validation-*.json`
- GitHub status: `.runners-local/logs/workflows/github-status-*.json`

**Constitutional Requirements**:
- Zero GitHub Actions consumption
- uv-First Python management
- Strict type checking compliance
- File change validation
- Performance impact assessment

**File Validations**:
- Python: Syntax check, uv validation
- TypeScript/JavaScript: tsconfig compilation
- Astro: Component syntax validation
- JSON: Syntax validation with jq
- YAML: Syntax validation with Python
- Markdown: Structure validation

---

### 3. documentation-sync-checker.sh

**Purpose**: Validates consistency across the three-tier documentation system (docs/, website/src/, documentations/) with comprehensive synchronization checks.

**Key Features**:
- Tier 1 (docs/) build output validation (.nojekyll, index.html, _astro/)
- Tier 2 (website/src/) source structure verification
- Tier 3 (documentations/) hub structure validation
- Astro outDir configuration verification
- AGENTS.md symlinks validation (CLAUDE.md, GEMINI.md)
- User guide synchronization between tiers
- Configuration drift detection
- Local CI/CD integration checks

**Usage**:
```bash
# Run complete documentation synchronization check
./.runners-local/workflows/documentation-sync-checker.sh
```

**Expected Output**:
- Console output with color-coded status
- Detailed logs: `.runners-local/logs/doc-sync-*.log`
- JSON reports: `.runners-local/logs/doc-sync-report-*.json`
- Summary report with pass/fail/warning counts

**Validation Checks**:
1. Tier 1 build output structure
2. Tier 2 source structure
3. Tier 3 documentation hub
4. Astro outDir configuration
5. AGENTS.md symlinks
6. User guide synchronization
7. Documentation strategy guide
8. Context7 MCP documentation
9. Configuration drift detection
10. Local CI/CD integration

**Critical Files Validated**:
- `docs/.nojekyll` (CRITICAL for GitHub Pages)
- `docs/index.html` (Astro build output)
- `website/src/astro.config.mjs` (Astro configuration)
- `CLAUDE.md` → `AGENTS.md` (symlink)
- `GEMINI.md` → `AGENTS.md` (symlink)

**Exit Codes**:
- 0 - All checks passed
- 1 - One or more checks failed

---

### 4. benchmark-runner.sh

**Purpose**: Constitutional Performance Benchmarking System with comprehensive performance measurement and constitutional target validation.

**Key Features**:
- Build performance benchmarking (time, success rate)
- Bundle size analysis (JavaScript, CSS)
- Memory usage monitoring
- Development server performance testing
- Lighthouse performance audits (Performance, Accessibility, Best Practices, SEO)
- Core Web Vitals measurement (FCP, LCP, CLS, FID)
- Python scripts performance testing
- File system performance benchmarking
- Baseline comparison and tracking
- Constitutional compliance validation

**Usage**:
```bash
# Run complete benchmark suite (default)
./.runners-local/workflows/benchmark-runner.sh all

# Build performance only
./.runners-local/workflows/benchmark-runner.sh build

# Lighthouse audit only
./.runners-local/workflows/benchmark-runner.sh lighthouse

# Python scripts performance
./.runners-local/workflows/benchmark-runner.sh scripts

# System performance (memory, filesystem)
./.runners-local/workflows/benchmark-runner.sh system

# Development server performance
./.runners-local/workflows/benchmark-runner.sh server

# Update baseline with current results
./.runners-local/workflows/benchmark-runner.sh all --update-baseline

# Show help
./.runners-local/workflows/benchmark-runner.sh --help
```

**Constitutional Targets**:
- Lighthouse Performance: ≥95
- Lighthouse Accessibility: ≥95
- Lighthouse Best Practices: ≥95
- Lighthouse SEO: ≥95
- Build Time: ≤30 seconds
- JavaScript Bundle: ≤100KB
- CSS Bundle: ≤50KB
- First Contentful Paint: ≤1500ms
- Largest Contentful Paint: ≤2500ms
- Cumulative Layout Shift: ≤0.1
- Memory Usage: ≤512MB

**Expected Output**:
- Console output: Color-coded performance metrics
- Benchmark logs: `.update_cache/benchmark_logs/benchmark_*.log`
- JSON results: `.update_cache/benchmark_logs/benchmark_results_*.json`
- Baseline file: `.update_cache/benchmark_logs/baseline_benchmark.json`

**Prerequisites**:
- Node.js and npm (for build benchmarks)
- Lighthouse CLI (for Lighthouse audits): `npm install -g lighthouse`
- Python 3 (for Python script benchmarks)
- bc command (for calculations)
- jq command (for JSON processing)

**Exit Codes**:
- 0 - All constitutional targets met
- 1 - One or more constitutional violations

---

### 5. performance-dashboard.sh

**Purpose**: Performance Benchmarking Dashboard that tracks Lighthouse scores, build metrics, and CI/CD performance over time with HTML visualization.

**Key Features**:
- Lighthouse metrics collection (Performance, Accessibility, Best Practices, SEO)
- Build performance tracking (duration, bundle sizes)
- CI/CD workflow performance monitoring
- Metrics database with JSON storage
- Interactive HTML dashboard with Chart.js
- Constitutional targets tracking
- Trend analysis and visualization
- Core Web Vitals monitoring

**Usage**:
```bash
# Run complete benchmark suite
./.runners-local/workflows/performance-dashboard.sh benchmark

# Collect Lighthouse metrics only
./.runners-local/workflows/performance-dashboard.sh lighthouse

# Collect build metrics only
./.runners-local/workflows/performance-dashboard.sh build

# Collect CI/CD metrics only
./.runners-local/workflows/performance-dashboard.sh cicd

# Generate dashboard from existing data
./.runners-local/workflows/performance-dashboard.sh dashboard

# Open dashboard in browser
./.runners-local/workflows/performance-dashboard.sh view

# Show help
./.runners-local/workflows/performance-dashboard.sh help
```

**Expected Output**:
- Metrics database: `documentations/performance/metrics-database.json`
- Lighthouse reports: `documentations/performance/lighthouse-reports/lighthouse-*.json`
- HTML dashboard: `documentations/performance/dashboard.html`
- Execution logs: `.runners-local/logs/preview-*.log`, `build-*.log`, `cicd-*.log`

**Dashboard Features**:
- Real-time metric cards (8 key metrics)
- Lighthouse scores trend chart
- Build performance trend chart
- Bundle size trend chart
- Constitutional targets visualization
- Last updated timestamp
- Responsive design with Chart.js

**Prerequisites**:
- Lighthouse CLI: `npm install -g lighthouse`
- npm and Node.js (for Astro build)
- jq command (for JSON processing)
- Astro project with build output in `docs/`

**Constitutional Targets**:
- Lighthouse scores: 95+ for all categories
- Build time: <30 seconds
- JavaScript bundle: <100KB
- CI/CD workflow: <120 seconds

**Dashboard Access**:
- Local file: `file://<repo>/documentations/performance/dashboard.html`
- Auto-opens in browser with `view` command
- Works offline with cached data

---

### 6. validate-modules.sh

**Purpose**: Comprehensive module validation runner for contract compliance and dependency validation with detailed reporting.

**Key Features**:
- Contract validation for all modules
- Dependency validation with circular dependency detection
- Header completeness verification
- BASH_SOURCE guard checking
- Function documentation validation
- Private function naming conventions
- ShellCheck compliance
- Topological sort dependency analysis

**Usage**:
```bash
# Quick validation
./.runners-local/workflows/validate-modules.sh ./scripts

# Detailed validation with full output
./.runners-local/workflows/validate-modules.sh --detailed ./scripts

# Show help
./.runners-local/workflows/validate-modules.sh --help
```

**Validation Checks**:

**Contract Validation**:
1. Header completeness
2. BASH_SOURCE guard presence
3. Required sections (Purpose, Dependencies, Exit Codes)
4. Function documentation
5. Private function naming (_function_name)
6. ShellCheck compliance

**Dependency Validation**:
1. Circular dependency detection
2. Topological sort validation
3. Dependency graph analysis
4. Module loading order

**Expected Output**:
- Console output: Color-coded validation results
- Summary report with pass/fail counts
- Detailed validation output (with --detailed flag)

**Exit Codes**:
- 0 - All validations passed
- 1 - One or more validations failed
- 2 - Usage error or invalid arguments

**Prerequisites**:
- `validate_module_contract.sh` script in `scripts/`
- `validate_module_deps.sh` script in `scripts/`
- Bash modules following project conventions

**Example Output**:
```
════════════════════════════════════════════════════════
🔍 Module Validation Suite
════════════════════════════════════════════════════════
  Directory: ./scripts
  Mode: Quick

════════════════════════════════════════════════════════
📋 Step 1: Contract Validation
════════════════════════════════════════════════════════

Validating: module1.sh
  ✓ Contract validation passed

  Total modules: 5
  Passed: 5
  Failed: 0
  ✅ Contract validation PASSED

════════════════════════════════════════════════════════
🔗 Step 2: Dependency Validation
════════════════════════════════════════════════════════

✅ Dependency validation PASSED
  No circular dependencies detected

════════════════════════════════════════════════════════
📊 Validation Summary
════════════════════════════════════════════════════════

  Contract Validation:   ✅ PASS
  Dependency Validation: ✅ PASS

╔════════════════════════════════════════╗
║                                        ║
║    ✅  ALL VALIDATIONS PASSED  ✅     ║
║                                        ║
╚════════════════════════════════════════╝
```

---

**Last Updated**: 2025-11-15
**Status**: Active
**Maintainer**: See AGENTS.md for AI assistant instructions
