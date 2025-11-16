# Research Document: Complete Terminal Development Infrastructure

**Feature**: 005-complete-terminal-infrastructure
**Created**: 2025-11-16
**Status**: Planning Phase

This document captures research findings and technical decisions for implementing a unified terminal development infrastructure consolidating specs 001, 002, and 004.

---

## Research Topic: Parallel Task UI Implementation

**Decision**: Implement custom bash-based parallel task display with collapsible verbose output inspired by Claude Code's task presentation.

**Rationale**:
- Professional installation experience requires clean, organized output
- Users need to see current progress while keeping screen clean
- Parallel tasks must display simultaneously without output interleaving
- Completed tasks should collapse to single line while preserving full logs
- Dynamic verification prevents misleading hardcoded success messages

**Alternatives Considered**:
1. GNU Parallel with --line-buffer --keep-order - Good for output management but lacks UI sophistication
2. Simple sequential display - Too slow, doesn't utilize modern hardware
3. Third-party UI frameworks (dialog, whiptail) - Adds dependencies, limited customization
4. Ncurses-based TUI - Too complex, requires additional libraries

**Implementation Approach**:
```bash
# Core Components:
# 1. Task Manager - Tracks parallel task state
# 2. Output Buffer - Captures verbose output per task
# 3. Display Engine - Renders current state to terminal
# 4. Verification System - Dynamic status checks (not hardcoded)

# Task Display Format:
# [✓] Install Node.js via fnm (2.3s)
# [→] Install Ghostty dependencies... (expand for details)
# [ ] Configure ZSH plugins (queued)

# Expanded View (on demand):
# [→] Install Ghostty dependencies...
#     ├─ Checking system requirements... ✓
#     ├─ Installing libgtk-4-dev... ✓
#     ├─ Installing libadwaita-1-dev... (in progress)
#     └─ Verifying installation... (pending)

# Implementation Files:
# - scripts/task_display.sh - Display engine
# - scripts/task_manager.sh - Parallel task orchestration
# - scripts/verification.sh - Dynamic verification methods
```

**References**:
- GNU Parallel documentation: https://www.gnu.org/software/parallel/
- ANSI escape codes for terminal control
- Claude Code's task display as UX reference
- Bash process substitution and file descriptors for output capture

---

## Research Topic: Local GitHub Actions Runners

**Decision**: Use nektos/act (v0.2.82+) for local GitHub Actions execution with Docker-based runners.

**Rationale**:
- Industry standard for local GitHub Actions execution
- Full workflow compatibility including custom actions, matrix builds
- Active development with October 2025 release (v0.2.82)
- Docker-based isolation matches GitHub's cloud environment
- Supports caching and reusable workflows
- Reduces GitHub Actions consumption to zero for development

**Alternatives Considered**:
1. GitHub's official self-hosted runners - Requires constant connectivity, complex setup
2. Custom shell-based workflow interpreter - Insufficient compatibility, high maintenance
3. GitLab CI local execution - Different syntax, migration overhead
4. Manual workflow simulation - Error-prone, incomplete

**Implementation Approach**:
```bash
# Installation:
# 1. Install act via package manager or binary
# 2. Configure Docker for nektos/act images
# 3. Create .actrc for repository-specific settings
# 4. Map secrets and environment variables

# Workflow Execution:
act                              # Run default event (push)
act -l                           # List available workflows
act pull_request                 # Run PR workflows
act -j test                      # Run specific job
act -W .github/workflows/ci.yml  # Run specific workflow

# Integration with manage.sh:
./manage.sh cicd validate       # Run all workflows locally
./manage.sh cicd workflow <name> # Run specific workflow
./manage.sh cicd matrix         # Test matrix builds

# Configuration (.actrc):
-P ubuntu-latest=catthehacker/ubuntu:full-latest
--secret-file .env
--bind
--container-architecture linux/amd64
```

**References**:
- nektos/act GitHub repository: https://github.com/nektos/act
- act documentation: https://nektosact.com/
- GitHub Actions syntax reference
- Docker image compatibility guide
- nektos/gh-act CLI extension for GitHub CLI integration

---

## Research Topic: uv Python Integration

**Decision**: Implement uv >=0.9.0 as exclusive Python dependency manager with full CI/CD integration and example automation scripts.

**Rationale**:
- 80-100x faster than pip (3-4s vs 45s in CI/CD pipelines)
- Native lockfile support (uv.lock) for reproducible builds
- Written in Rust for reliability and performance
- Version 0.9.0 (October 2025) adds Python 3.14 support
- Excellent CI/CD integration with astral-sh/setup-uv action
- Built-in virtual environment management
- Compatible with existing pip workflows (uv pip install)

**Alternatives Considered**:
1. pip + pip-tools - Slower, limited caching, manual lockfile management
2. Poetry - Better than pip but significantly slower than uv
3. Pipenv - Deprecated, poor performance
4. conda - Heavy dependencies, slower, data science focus

**Implementation Approach**:
```bash
# Installation:
curl -LsSf https://astral.sh/uv/install.sh | sh

# Project Initialization:
uv init my-project               # Create new project
uv add requests                  # Add dependency
uv sync                          # Install from lockfile
uv run python script.py          # Run in virtual environment

# CI/CD Integration (.github/workflows/python-ci.yml):
- uses: astral-sh/setup-uv@v1
  with:
    enable-cache: true
    cache-dependency-glob: "uv.lock"

# Example Automation Scripts:
# scripts/examples/python/update_docs.py - Documentation generator
# scripts/examples/python/analyze_configs.py - Config file analyzer
# scripts/examples/python/performance_report.py - Performance metrics

# Features to Demonstrate:
# 1. Fast dependency installation in manage.sh
# 2. Lockfile generation for reproducibility
# 3. Virtual environment management
# 4. CI/CD pipeline integration
# 5. Script automation capabilities
```

**References**:
- uv documentation: https://docs.astral.sh/uv/
- uv GitHub releases: https://github.com/astral-sh/uv/releases
- astral-sh/setup-uv action: https://github.com/astral-sh/setup-uv
- Migration guide from pip/poetry to uv
- Performance benchmarks: https://www.cloudrepo.io/uv

**Key Version 0.9.0 Features**:
- Python 3.14 support (default version)
- Updated Docker images (Alpine 3.22, Debian 13 Trixie)
- Enhanced lockfile stability
- Improved caching mechanisms
- Better parallel dependency resolution

---

## Research Topic: Automated Accessibility Testing

**Decision**: Implement dual-layer automated accessibility testing with axe-core for comprehensive WCAG 2.1 Level AA validation and Lighthouse CI for continuous monitoring.

**Rationale**:
- axe-core finds 57% of WCAG issues automatically (industry-leading coverage)
- Lighthouse CI integrates seamlessly with GitHub Actions and local workflows
- Both tools are industry standards used by Microsoft, Google, and major organizations
- Automated testing in CI/CD prevents accessibility regressions
- Combined approach provides comprehensive coverage (automated + incomplete flagging for manual review)
- Constitutional requirement for WCAG 2.1 Level AA compliance

**Alternatives Considered**:
1. Manual testing only - Time-consuming, inconsistent, regression-prone
2. WAVE or Pa11y - Less comprehensive, fewer integrations
3. Commercial solutions (Deque axe DevTools Pro) - Unnecessary cost for this use case
4. Lighthouse only - Misses axe-core's deeper rule coverage

**Implementation Approach**:
```bash
# Installation:
npm install --save-dev @axe-core/cli @lhci/cli

# Axe-core Integration:
# .runners-local/workflows/accessibility-check.sh
#!/bin/bash
axe http://localhost:4321 \
  --rules wcag2a,wcag2aa,wcag21a,wcag21aa \
  --exit \
  --save accessibility-report.json

# Lighthouse CI Integration:
# lighthouserc.js
module.exports = {
  ci: {
    collect: {
      url: ['http://localhost:4321'],
      startServerCommand: 'npm run preview',
      numberOfRuns: 3
    },
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'categories:accessibility': ['error', {minScore: 0.95}],
        'categories:performance': ['error', {minScore: 0.95}],
        'categories:best-practices': ['error', {minScore: 0.95}],
        'categories:seo': ['error', {minScore: 0.95}]
      }
    },
    upload: {
      target: 'filesystem',
      outputDir: './accessibility-reports'
    }
  }
};

# Local CI/CD Integration:
./manage.sh docs accessibility    # Run accessibility tests
./manage.sh validate accessibility # Validate against standards

# GitHub Actions Integration:
- name: Run Accessibility Tests
  run: |
    npm run build
    npm run preview &
    sleep 5
    npx axe http://localhost:4321 --exit
    npx lhci autorun

# Reporting:
# - JSON reports for programmatic analysis
# - HTML reports for human review
# - CI/CD failure on violations
# - PR comments with violation summaries
```

**References**:
- axe-core repository: https://github.com/dequelabs/axe-core
- axe-core npm package: https://www.npmjs.com/package/axe-core
- Lighthouse CI documentation: https://github.com/GoogleChrome/lighthouse-ci
- WCAG 2.1 guidelines: https://www.w3.org/WAI/WCAG21/quickref/
- Deque Systems best practices: https://www.deque.com/axe/

**Coverage Details**:
- WCAG 2.0 Level A, AA, AAA support
- WCAG 2.1 Level A, AA support
- Section 508 compliance
- EN 301 549 compliance
- Best practices beyond standards
- Incomplete results flagged for manual review

---

## Research Topic: Automated Security Scanning

**Decision**: Implement multi-layer automated security scanning with npm audit for dependency vulnerabilities, GitHub Dependabot alerts, and lockfile integrity validation.

**Rationale**:
- npm audit is built-in, zero-cost, and covers majority of vulnerabilities
- GitHub Dependabot provides continuous monitoring and automated PR updates
- Lockfile validation prevents supply chain attacks
- CI/CD integration blocks vulnerable code before deployment
- Constitutional requirement for security validation

**Alternatives Considered**:
1. Snyk - Commercial, unnecessary cost for open source
2. OWASP Dependency-Check - Java-focused, overkill for Node.js
3. Manual security reviews - Inconsistent, time-consuming
4. GitHub Security Scanning only - Misses local CI/CD validation

**Implementation Approach**:
```bash
# npm audit Integration:
# .runners-local/workflows/security-check.sh
#!/bin/bash
set -euo pipefail

echo "Running npm audit..."
npm audit --audit-level=moderate --json > security-report.json

# Check for high/critical vulnerabilities
HIGH_VULN=$(jq '.metadata.vulnerabilities.high' security-report.json)
CRITICAL_VULN=$(jq '.metadata.vulnerabilities.critical' security-report.json)

if [ "$HIGH_VULN" -gt 0 ] || [ "$CRITICAL_VULN" -gt 0 ]; then
  echo "ERROR: Found high/critical vulnerabilities"
  npm audit
  exit 1
fi

# Lockfile Integrity Validation:
npm ci --dry-run  # Validate package-lock.json integrity

# Dependency Update Detection:
npx npm-check-updates --errorLevel 2  # Check for major updates

# Local CI/CD Integration:
./manage.sh validate security        # Run security checks
./manage.sh security report          # Generate security report
./manage.sh security fix             # Auto-fix vulnerabilities

# GitHub Actions Integration:
- name: Security Audit
  run: |
    npm audit --audit-level=high
    npm ci --dry-run

# Dependabot Configuration (.github/dependabot.yml):
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "maintainer-username"
    labels:
      - "dependencies"
      - "security"

# Reporting:
# - security-report.json: Programmatic vulnerability data
# - security-summary.txt: Human-readable summary
# - CI/CD failure on high/critical vulnerabilities
# - PR comments with security status
```

**References**:
- npm audit documentation: https://docs.npmjs.com/cli/audit
- GitHub Dependabot: https://docs.github.com/en/code-security/dependabot
- npm-check-updates: https://github.com/raineorshine/npm-check-updates
- OWASP Dependency Management: https://owasp.org/www-project-dependency-check/
- Supply chain security best practices

**Security Layers**:
1. **Dependency Scanning**: npm audit for known vulnerabilities
2. **Lockfile Validation**: Prevent tampering with package-lock.json
3. **Continuous Monitoring**: GitHub Dependabot alerts
4. **Automated Updates**: Dependabot PRs for security patches
5. **CI/CD Gates**: Block deployment on high/critical vulnerabilities
6. **Update Tracking**: npm-check-updates for major version monitoring

**Vulnerability Thresholds**:
- **Critical**: Block immediately, zero tolerance
- **High**: Block deployment, require review
- **Moderate**: Warning, track for resolution
- **Low**: Informational, batch with updates

---

## Research Topic: Dynamic Verification

**Decision**: Implement comprehensive dynamic verification system that validates actual system state instead of assuming success based on command exit codes.

**Rationale**:
- Hardcoded success messages mislead users when installations partially fail
- Exit code 0 doesn't guarantee functional installation (e.g., package installed but service failed to start)
- Users need accurate status to troubleshoot issues
- Constitutional requirement for honest, verifiable installation feedback
- Prevents "works on my machine" scenarios

**Alternatives Considered**:
1. Exit code checking only - Insufficient, misses partial failures
2. Hardcoded success messages - Misleading, poor user experience
3. Manual verification prompts - Disruptive, not automated
4. No verification - Unacceptable, leads to broken installations

**Implementation Approach**:
```bash
# Verification Framework (scripts/verification.sh):

# 1. Binary Installation Verification
verify_binary() {
  local binary="$1"
  local min_version="${2:-}"

  # Check binary exists and is executable
  if ! command -v "$binary" &>/dev/null; then
    return 1
  fi

  # Check version if specified
  if [[ -n "$min_version" ]]; then
    local installed_version
    installed_version=$("$binary" --version 2>&1 | head -1 | grep -oP '\d+\.\d+\.\d+')
    if ! version_ge "$installed_version" "$min_version"; then
      return 1
    fi
  fi

  return 0
}

# 2. Configuration File Verification
verify_config() {
  local config_file="$1"
  local validation_command="$2"

  # Check file exists and is readable
  [[ -f "$config_file" && -r "$config_file" ]] || return 1

  # Validate syntax if validation command provided
  if [[ -n "$validation_command" ]]; then
    eval "$validation_command" &>/dev/null || return 1
  fi

  return 0
}

# 3. Service Status Verification
verify_service() {
  local service_name="$1"
  local health_check="${2:-}"

  # Check service is running (for systemd services)
  if systemctl is-active --quiet "$service_name" 2>/dev/null; then
    # Run health check if provided
    if [[ -n "$health_check" ]]; then
      eval "$health_check" &>/dev/null || return 1
    fi
    return 0
  fi

  return 1
}

# 4. Network Connectivity Verification
verify_network() {
  local url="$1"
  local expected_status="${2:-200}"

  local actual_status
  actual_status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

  [[ "$actual_status" == "$expected_status" ]]
}

# 5. Functional Integration Verification
verify_integration() {
  local component="$1"

  case "$component" in
    ghostty)
      # Verify Ghostty can parse config and supports expected features
      ghostty +show-config &>/dev/null && \
      ghostty +show-config | grep -q "linux-cgroup = single-instance"
      ;;
    node)
      # Verify Node.js and npm are functional
      node --version &>/dev/null && \
      npm --version &>/dev/null && \
      node -e "console.log('test')" &>/dev/null
      ;;
    zsh)
      # Verify ZSH configuration loads without errors
      zsh -c 'source ~/.zshrc; echo $ZSH_VERSION' &>/dev/null
      ;;
    astro)
      # Verify Astro can build site
      cd website && \
      npx astro check &>/dev/null && \
      npx astro build --dry-run &>/dev/null
      ;;
  esac
}

# Usage in Installation Scripts:
install_node() {
  # Installation logic...

  # Dynamic verification
  if verify_binary "node" "25.0.0" && \
     verify_binary "npm" "10.0.0" && \
     verify_integration "node"; then
    echo "[✓] Node.js installation verified"
  else
    echo "[✗] Node.js verification failed"
    return 1
  fi
}
```

**References**:
- Bash test operators: `man test`
- Systemd service verification: `man systemctl`
- Version comparison algorithms
- Health check patterns from Docker/Kubernetes
- Smoke testing best practices

**Verification Categories**:
1. **Binary Verification**: Command exists, version adequate, executable
2. **Configuration Verification**: Files exist, syntax valid, semantics correct
3. **Service Verification**: Process running, responding to requests, healthy
4. **Network Verification**: Endpoints reachable, expected responses
5. **Integration Verification**: Components work together, end-to-end functionality

**Benefits**:
- Accurate installation status reporting
- Early detection of partial failures
- Actionable error messages for troubleshooting
- Confidence in automated installations
- Reduced support burden from false positives

---

## Research Topic: Latest Stable Version Tracking

**Decision**: Implement automated version tracking system that maintains cutting-edge dependencies while avoiding unstable pre-releases.

**Rationale**:
- Constitutional requirement: "Latest stable versions (not LTS)"
- Latest stable provides newest features, security patches, and performance improvements
- Avoids LTS stagnation (e.g., Node.js LTS can be 6+ months behind)
- Pre-releases (alpha, beta, rc) too unstable for production
- Automated tracking prevents manual version monitoring overhead

**Alternatives Considered**:
1. LTS versions - Too conservative, misses latest features
2. Bleeding edge (pre-releases) - Too unstable, breaking changes
3. Manual version pinning - High maintenance, gets outdated
4. Automatic updates without validation - Risky, breaks builds

**Implementation Approach**:
```bash
# Version Tracking Configuration (.versions.json):
{
  "technologies": {
    "node": {
      "policy": "latest-stable",
      "minimum": "25.0.0",
      "check_url": "https://nodejs.org/dist/index.json",
      "filter": "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    },
    "astro": {
      "policy": "latest-stable",
      "minimum": "5.0.0",
      "package": "@astrojs/astro",
      "filter": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    },
    "tailwindcss": {
      "policy": "latest-stable",
      "minimum": "4.0.0",
      "package": "tailwindcss",
      "filter": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    },
    "typescript": {
      "policy": "latest-stable",
      "minimum": "5.9.0",
      "package": "typescript",
      "filter": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    },
    "uv": {
      "policy": "latest-stable",
      "minimum": "0.9.0",
      "check_url": "https://api.github.com/repos/astral-sh/uv/releases/latest",
      "filter": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    },
    "daisyui": {
      "policy": "latest-stable",
      "minimum": "5.0.0",
      "package": "daisyui",
      "filter": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    }
  }
}

# Version Checker Script (scripts/check_versions.sh):
#!/bin/bash
set -euo pipefail

check_npm_latest() {
  local package="$1"
  npm view "$package" version 2>/dev/null | grep -P '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1
}

check_github_latest() {
  local repo="$1"
  gh api "repos/$repo/releases/latest" --jq '.tag_name' | sed 's/^v//'
}

check_node_latest() {
  curl -s https://nodejs.org/dist/index.json | \
    jq -r '[.[] | select(.version | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))][0].version' | \
    sed 's/^v//'
}

# Update versions.json with latest
update_versions() {
  local temp_file
  temp_file=$(mktemp)

  jq '.technologies | to_entries[] | {
    name: .key,
    current: .value.minimum,
    latest: (
      if .value.package then
        check_npm_latest(.value.package)
      elif .value.check_url | contains("nodejs.org") then
        check_node_latest()
      elif .value.check_url | contains("github.com") then
        check_github_latest(.value.check_url | sub("https://api.github.com/repos/"; "") | sub("/releases/latest"; ""))
      else
        .value.minimum
      end
    ),
    policy: .value.policy
  }' .versions.json > "$temp_file"

  echo "Version Status:"
  column -t -s $'\t' "$temp_file"
  rm "$temp_file"
}

# CI/CD Integration:
./manage.sh validate versions       # Check for updates
./manage.sh update versions         # Update to latest stable
./manage.sh version report          # Generate version report

# Automation:
# - Weekly automated checks via cron/GitHub Actions
# - PR creation for available updates
# - Automated testing before merge
# - Rollback on test failures
```

**References**:
- npm registry API: https://github.com/npm/registry/blob/master/docs/REGISTRY-API.md
- GitHub Releases API: https://docs.github.com/en/rest/releases
- Node.js distribution index: https://nodejs.org/dist/index.json
- Semantic versioning specification: https://semver.org/
- npm-check-updates tool: https://github.com/raineorshine/npm-check-updates

**Version Policies**:
1. **Latest Stable**: Default policy - newest stable release
2. **Minimum Version**: Constitutional requirement baseline
3. **Pre-release Filter**: Exclude alpha, beta, rc versions
4. **Regression Testing**: Validate updates before deployment
5. **Automated Updates**: Weekly check + PR workflow

**Benefits**:
- Constitutional compliance (latest stable requirement)
- Newest features and security patches
- Automated maintenance reduces manual overhead
- Validated updates prevent breaking changes
- Clear version tracking and audit trail

---

## Summary

This research phase identified optimal technical approaches for:

1. **Parallel Task UI**: Custom bash-based display with collapsible output
2. **Local GitHub Runners**: nektos/act v0.2.82+ for zero-cost CI/CD
3. **Python Tooling**: uv >=0.9.0 for 80-100x faster dependency management
4. **Accessibility**: axe-core + Lighthouse CI for automated WCAG 2.1 AA compliance
5. **Security**: npm audit + Dependabot for vulnerability management
6. **Verification**: Dynamic system state validation vs hardcoded success messages
7. **Version Tracking**: Automated latest stable version monitoring

All decisions align with constitutional requirements for zero-cost operations, latest stable versions, and comprehensive validation.

**Next Steps**:
1. Create data-model.md to define system entities
2. Define contracts for new components (installation display, CI/CD runner, quality gates)
3. Generate implementation plan with phases and dependencies
