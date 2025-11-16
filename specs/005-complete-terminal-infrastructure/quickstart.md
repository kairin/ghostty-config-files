# Quickstart: Complete Terminal Development Infrastructure
**Feature**: 005-complete-terminal-infrastructure
**Date**: 2025-11-16
**For**: Developers implementing or extending the terminal infrastructure

This guide gets you from zero to productive in <5 minutes. Read [plan.md](plan.md) for architecture details, [data-model.md](data-model.md) for entities, and [research.md](research.md) for technical decisions.

---

## Prerequisites (5 minutes)

### 1. System Requirements
```bash
# Ubuntu 25.10 (Oracular Oriole) - REQUIRED
lsb_release -a  # Verify Ubuntu 25.10

# Passwordless sudo for apt (MANDATORY for automation)
sudo visudo
# Add: your_username ALL=(ALL) NOPASSWD: /usr/bin/apt

# Verify passwordless sudo
sudo -n apt update  # Should run without password prompt
```

### 2. Essential Tools
```bash
# Git, GitHub CLI, jq (JSON processing)
sudo apt update
sudo apt install -y git gh jq

# Authenticate GitHub CLI
gh auth login
gh repo set-default
```

### 3. Clone Repository
```bash
cd ~/Apps  # Or your preferred location
git clone https://github.com/username/ghostty-config-files.git
cd ghostty-config-files

# Verify structure
ls -la  # Should see manage.sh, scripts/, website/, docs/, .runners-local/
```

---

## Quick Install (One Command)

### Fresh System Setup
```bash
#  Single command install (zero configuration required)
./manage.sh install

# What this does:
# 1. Installs Ghostty from source (Zig 0.14.0)
# 2. Installs Node.js latest via fnm (v25.2.0+)
# 3. Installs AI tools (Claude Code, Gemini CLI, Copilot)
# 4. Installs modern Unix tools (bat, exa, ripgrep, fd, zoxide, fzf)
# 5. Configures ZSH + Oh My ZSH
# 6. Sets up context menu ("Open in Ghostty")
# 7. Builds documentation site (Astro)
# 8. Configures local CI/CD infrastructure

# Installation display (parallel task UI):
# ╔══════════════════════════════════════════════════════════╗
# ║ Installing Complete Terminal Infrastructure (47%)       ║
# ╠══════════════════════════════════════════════════════════╣
# ║ ✓ Installing Ghostty from source (complete)             ║
# ║ ✓ Installing Node.js via fnm (complete)                 ║
# ║ ▶ Installing AI tools (2/3 complete)                    ║
# ║   ├── ✓ Claude Code (verified)                          ║
# ║   ├── ▶ Gemini CLI (installing v1.2.0...)               ║
# ║   └── ⏳ Copilot CLI (pending)                           ║
# ║ ⏳ Building documentation site (pending)                 ║
# ╠══════════════════════════════════════════════════════════╣
# ║ Step 3/5 • Estimated: 2 minutes remaining               ║
# ╚══════════════════════════════════════════════════════════╝
```

**Success Criteria**: Complete in <10 minutes (SC-001), zero configuration (SC-003)

---

## Development Workflow

### 1. Branch Creation
```bash
# ALWAYS create timestamped feature branch (constitutional requirement)
DATETIME=$(date +"%Y%m%d-%H%M%S")
FEATURE="your-feature-description"
BRANCH_NAME="${DATETIME}-feat-${FEATURE}"

git checkout -b "$BRANCH_NAME"
```

### 2. Make Changes
```bash
# Example: Modify Ghostty configuration
nano configs/ghostty/config

# Example: Update installation script
nano scripts/install_ghostty.sh

# Example: Edit documentation
nano website/src/user-guide/installation.md
```

### 3. Local CI/CD Validation (MANDATORY)
```bash
# Run complete local workflow (MUST pass before commit)
./.runners-local/workflows/gh-workflow-local.sh all

# Individual validations:
./.runners-local/workflows/gh-workflow-local.sh validate    # Config validation
./.runners-local/workflows/gh-workflow-local.sh test       # Performance testing
./.runners-local/workflows/gh-workflow-local.sh build      # Build simulation
./.runners-local/workflows/gh-workflow-local.sh deploy     # Deployment simulation

# Quality gates:
# ✓ shellcheck: Zero errors in shell scripts
# ✓ Lighthouse: 95+ all metrics (Performance, Accessibility, Best Practices, SEO)
# ✓ axe-core: Zero WCAG 2.1 Level AA violations
# ✓ npm audit: Zero high/critical vulnerabilities
# ✓ Bundle size: JavaScript <100KB

# Performance target: <2 minutes complete workflow (SC-012, constitutional)
```

### 4. Commit with Constitutional Compliance
```bash
# Add changes
git add .

# Commit with proper format
git commit -m "feat: Your descriptive commit message

Detailed explanation of what changed and why.

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push feature branch
git push -u origin "$BRANCH_NAME"
```

### 5. Merge to Main (Branch Preservation)
```bash
# Switch to main
git checkout main

# Merge with no-fast-forward (preserve branch history)
git merge "$BRANCH_NAME" --no-ff

# Push to remote
git push origin main

# CRITICAL: NEVER delete branch (constitutional requirement)
# git branch -d "$BRANCH_NAME"  ← DO NOT DO THIS

# Branch preservation reason: Valuable configuration history for debugging
```

---

## Key Commands

### Installation Management
```bash
./manage.sh install              # Fresh installation
./manage.sh install --dry-run    # Preview without executing
./manage.sh install --verbose    # Detailed output
./manage.sh validate             # Validate current environment
./manage.sh update               # Update components
```

### Documentation Site
```bash
./manage.sh docs build           # Build Astro site → docs/
./manage.sh docs dev             # Live development server (HMR)
./manage.sh docs preview         # Preview production build
./manage.sh docs clean           # Clean build outputs

# Manual Astro operations (website/ directory):
cd website
npm install                      # Install dependencies
npm run build                    # Build to docs/
npm run dev                      # Development server
```

### Local CI/CD
```bash
./.runners-local/workflows/gh-workflow-local.sh all       # Complete workflow
./.runners-local/workflows/gh-workflow-local.sh status    # Check status
./.runners-local/workflows/gh-workflow-local.sh billing   # Monitor Actions usage (MUST be 0)

./.runners-local/workflows/performance-monitor.sh --test  # Performance test
./.runners-local/workflows/astro-build-local.sh build    # Astro build workflow
```

### Quality Gates
```bash
# Run individual quality gates:
shellcheck scripts/*.sh                           # Shell script linting
lighthouse docs/index.html --view                 # Performance audit
npx @axe-core/cli docs/index.html                 # Accessibility testing
npm audit                                         # Security scanning

# Verify compliance:
# - Lighthouse all scores >= 95 (SC-013, SC-025, SC-047)
# - axe-core zero violations (SC-045, SC-046)
# - npm audit zero high/critical (SC-048, SC-049)
```

### Performance Profiling
```bash
# Measure shell startup
time zsh -i -c exit              # Target: <50ms (SC-010)

# Measure Ghostty startup
time ghostty --print-config      # Target: <500ms (SC-011)

# Validate Ghostty config
ghostty +show-config             # Must exit 0 (no errors)

# Performance dashboard
./.runners-local/workflows/performance-dashboard.sh view
```

---

## Common Tasks

### Add New Installation Module
```bash
# 1. Create module from template
cp .module-template.sh scripts/install_your_module.sh

# 2. Implement installation logic
nano scripts/install_your_module.sh

# 3. Add module contract
# - Function exports
# - Dependencies declared
# - Verification method

# 4. Create unit test
cp .test-template.sh .runners-local/tests/unit/test_your_module.sh

# 5. Test module in isolation (<10s requirement, SC-015)
time ./.runners-local/tests/unit/test_your_module.sh

# 6. Integrate into manage.sh
nano manage.sh  # Add to install command

# 7. Run validation
./.runners-local/workflows/validate-modules.sh ./scripts
```

### Update Documentation
```bash
# 1. Edit source files (website/src/)
nano website/src/user-guide/your-page.md

# 2. Build documentation
cd website && npm run build

# 3. Verify build output
test -f docs/index.html && echo "Build successful"
test -f docs/.nojekyll && echo "CRITICAL FILE PRESENT"  # MUST exist

# 4. Run quality gates
lighthouse docs/index.html --view                  # Scores >= 95
npx @axe-core/cli docs/index.html                  # Zero violations

# 5. Commit (docs/ directory is committed for GitHub Pages)
git add website/src/ docs/
git commit -m "docs: Update user guide"
```

### Test Installation Display UI
```bash
# Run installation with parallel task UI
./manage.sh install --verbose

# Verify UI requirements:
# ✓ Each task on separate line (FR-006, SC-025)
# ✓ Verbose subtasks collapse when complete (FR-006, SC-027)
# ✓ Screen remains clean (FR-008, SC-027)
# ✓ Dynamic verification (not hardcoded) (FR-007, SC-026)
# ✓ Current step always visible (SC-028)
```

### Troubleshooting

#### Installation Fails
```bash
# Check system requirements
lsb_release -a                   # Ubuntu 25.10?
sudo -n apt update               # Passwordless sudo configured?
df -h                            # Sufficient disk space?

# Check logs
ls -la /tmp/ghostty-start-logs/
cat /tmp/ghostty-start-logs/errors.log
jq '.' /tmp/ghostty-start-logs/system_state_*.json

# Rollback if needed
./manage.sh rollback             # Restore previous state
```

#### CI/CD Fails Locally
```bash
# Check quality gate failures
cat ./.runners-local/logs/workflow-errors.log

# Common issues:
# - Lighthouse score < 95: Check bundle sizes, optimize assets
# - axe-core violations: Fix accessibility issues
# - npm audit high/critical: Update vulnerable dependencies
# - shellcheck errors: Fix shell script issues

# Re-run specific gates
shellcheck scripts/*.sh
lighthouse docs/index.html
npx @axe-core/cli docs/index.html
npm audit
```

#### GitHub Actions Consuming Minutes
```bash
# Check usage (MUST be 0 for constitutional compliance)
gh api user/settings/billing/actions | jq '.total_minutes_used'

# If non-zero:
# 1. Identify triggered workflows
gh run list --limit 10 --json status,conclusion,name,createdAt

# 2. Cancel running workflows
gh run cancel <run-id>

# 3. Ensure local CI/CD runs first
./.runners-local/workflows/gh-workflow-local.sh all
```

#### .nojekyll File Missing (CRITICAL)
```bash
# Verify file exists
test -f docs/.nojekyll && echo "PRESENT" || echo "MISSING (CRITICAL)"

# If missing, recreate immediately
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages asset loading"

# Without this file, ALL CSS/JS assets return 404 on GitHub Pages
# This is a constitutional requirement with 4 protection layers
```

---

## Testing

### Run All Tests
```bash
# Complete test suite
./.runners-local/workflows/test-runner.sh all

# Unit tests only
./.runners-local/tests/unit/run_all_tests.sh

# Integration tests
./.runners-local/tests/integration/run_all_tests.sh

# Contract validation
./.runners-local/workflows/validate-modules.sh ./scripts
```

### Test Individual Module
```bash
# Test specific module (<10s requirement, SC-015)
time ./.runners-local/tests/unit/test_common_utils.sh

# Should output:
# Running tests for common_utils...
# ✓ Test 1: Function exports
# ✓ Test 2: Dependency checks
# ...
# All tests passed!
# real    0m3.245s  # Must be <10s
```

---

## Performance Targets

### Shell Performance
- **Startup Time**: <50ms (SC-010)
- **Measurement**: `time zsh -i -c exit`
- **Optimization**: Lazy loading, compilation caching, deferred initialization

### Terminal Performance
- **Ghostty Startup**: <500ms (SC-011)
- **Measurement**: `time ghostty --print-config`
- **Optimization**: linux-cgroup=single-instance (MANDATORY)

### Web Performance
- **Lighthouse Scores**: 95+ all metrics (SC-013, SC-025, SC-047)
- **Measurement**: `lighthouse docs/index.html`
- **Bundle Size**: <100KB JavaScript (SC-014, FR-026)

### CI/CD Performance
- **Complete Workflow**: <2 minutes (SC-012, constitutional)
- **Measurement**: `time ./.runners-local/workflows/gh-workflow-local.sh all`
- **Module Tests**: <10s per module (SC-015)

---

## Architecture Overview

### Repository Structure
```
ghostty-config-files/
├── manage.sh                    # Unified CLI entry point
├── scripts/                     # Modular installation scripts (10+ modules)
│   ├── common.sh               # Shared utilities
│   ├── progress.sh             # Installation UI (parallel task display)
│   ├── install_node.sh         # Node.js via fnm
│   ├── install_ghostty.sh      # Ghostty from source
│   └── ...                     # Additional modules
├── website/                     # Astro documentation site
│   ├── src/                    # Editable markdown (committed)
│   └── astro.config.mjs        # Astro configuration
├── docs/                        # Build output (committed for GitHub Pages)
│   ├── .nojekyll               # CRITICAL: Disables Jekyll
│   └── ...                     # Generated HTML, CSS, JS
├── .runners-local/              # Local CI/CD infrastructure
│   ├── workflows/              # CI/CD scripts
│   ├── tests/                  # Test suites
│   └── logs/                   # Execution logs (gitignored)
└── .specify/                    # Spec-Kit infrastructure
    ├── templates/              # Planning templates
    └── memory/                 # Constitutional knowledge
```

### Technology Stack
- **Languages**: Bash 5.x+, TypeScript 5.9+, ZSH
- **Terminal**: Ghostty (from source, Zig 0.14.0), ZSH + Oh My ZSH
- **Node.js**: Latest via fnm (v25.2.0+, not LTS per constitutional requirement)
- **Python**: uv >=0.9.0 (latest stable)
- **Web**: Astro >=5.0, Tailwind CSS >=4.0, DaisyUI (latest)
- **AI Tools**: Claude Code, Gemini CLI, GitHub Copilot CLI
- **Unix Tools**: bat, exa, ripgrep, fd, zoxide, fzf
- **CI/CD**: GitHub CLI, Lighthouse CI, axe-core, shellcheck, bats

### Constitutional Requirements
1. **Branch Preservation**: Never delete branches (valuable history)
2. **GitHub Pages Protection**: docs/.nojekyll ABSOLUTELY CRITICAL
3. **Local CI/CD First**: All validation locally before GitHub
4. **Agent File Integrity**: AGENTS.md single source of truth (symlinks: CLAUDE.md, GEMINI.md)
5. **LLM Conversation Logging**: Complete logs with system state
6. **Zero-Cost Operations**: No GitHub Actions consumption (MUST be 0)

---

## Next Steps

1. **First Time Setup**: Run `./manage.sh install` and verify all components
2. **Read Documentation**: [plan.md](plan.md) for architecture, [research.md](research.md) for decisions
3. **Explore Contracts**: [contracts/](contracts/) for API specifications
4. **Run Local CI/CD**: `./.runners-local/workflows/gh-workflow-local.sh all`
5. **Make Changes**: Follow development workflow above
6. **Contribute**: See [CONTRIBUTING.md](../../documentations/developer/contributing.md)

---

**Questions?** Check [README.md](../../README.md) or [documentations/](../../documentations/)

**Issues?** Create GitHub issue or check logs in `/tmp/ghostty-start-logs/`

**Performance?** Run `./.runners-local/workflows/performance-monitor.sh --test`
