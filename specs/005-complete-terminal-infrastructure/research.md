# Research & Technical Decisions
**Feature**: Complete Terminal Development Infrastructure
**Date**: 2025-11-16
**Status**: Consolidated Research (Features 001, 002, 004)

This document captures all technical research and decision rationale for the consolidated terminal infrastructure feature. All "NEEDS CLARIFICATION" items from the plan template have been resolved.

---

## Research Summary

### Critical Research Questions Resolved

1. **Technology Stack Selection** - Latest stable vs LTS versions policy
2. **UI Framework Strategy** - DaisyUI vs shadcn/ui for component library
3. **Installation UX Design** - Parallel task display and verbose output handling
4. **Testing Strategy** - Automated accessibility and security testing integration
5. **CI/CD Architecture** - Local GitHub Actions runner infrastructure
6. **Package Management** - fnm vs nvm, uv requirements, version policy
7. **Performance Optimization** - Shell startup targets and measurement approach
8. **Documentation Architecture** - Source separation and build output management

---

## R1: Language and Runtime Versions

### Decision
- **Primary Language**: Bash 5.x+ (system scripts, installation, CI/CD)
- **Shell Environment**: ZSH (default Ubuntu 25.10 shell)
- **Node.js Runtime**: Latest stable via fnm (currently v25.2.0+)
- **Python Runtime**: Latest stable via uv (>=0.9.0)
- **TypeScript**: Latest stable (>=5.9) for Astro project

### Rationale
**Latest Stable Policy (Constitutional Requirement)**:
- Project constitution mandates latest stable versions (NOT LTS) for all technologies
- Provides access to newest features, performance improvements, and security patches
- fnm enables per-project version management when needed (via .nvmrc)
- Constitutional reference: AGENTS.md "Node.js: Latest version (v25.2.0+) via fnm"

**Bash for System Scripts**:
- Native to all Linux systems, no installation required
- Robust process management and error handling
- Extensive testing tools (shellcheck, bats)
- Strong community patterns for modular script architecture

**ZSH for User Shell**:
- Ubuntu 25.10 default shell (better than bash for interactive use)
- Oh My ZSH ecosystem provides rich plugin architecture
- Performance optimizations available (lazy loading, caching)
- Compatibility with bash scripts via sourcing

### Alternatives Considered

**Node.js Version Policy**:
- **LTS Approach (REJECTED)**: Would use Node.js v22 LTS
  - Rejection reason: Violates constitutional latest-stable policy
  - Trades new features for stability (not project priority)
  - Would still need fnm for per-project overrides

**Version Manager**:
- **nvm (REJECTED)**: Traditional Node version manager
  - Rejection reason: 40x slower startup than fnm (~2000ms vs ~50ms)
  - Impacts shell performance targets (sub-50ms startup)
  - fnm written in Rust, provides native performance

**Python Version Policy**:
- **System Python + pip (REJECTED)**: Use Ubuntu-provided Python 3.x
  - Rejection reason: Doesn't support reproducible environments
  - uv provides deterministic dependency resolution
  - uv 40x faster than pip for installs

### Implementation Notes
- Global Node.js: Latest via fnm (for AI tools, Astro development)
- Project-specific Node.js: Override via .nvmrc when required
- fnm auto-switching: Configured in .zshrc for seamless version management
- uv configuration: Project-local .venv, no global package pollution

### Verification
```bash
# Verify fnm installation and latest Node.js
fnm --version                    # fnm 1.35.0+
node --version                   # v25.2.0+
fnm list                         # Show installed versions

# Verify uv installation
uv --version                     # uv 0.9.0+
uv python list                   # Available Python versions

# Verify shell environment
echo $SHELL                      # /usr/bin/zsh
zsh --version                    # zsh 5.9+
```

---

## R2: Primary Dependencies and Technology Stack

### Decision
**Terminal Infrastructure**:
- **Ghostty**: Latest from source (Zig 0.14.0)
- **ZSH + Oh My ZSH**: Latest with productivity plugins
- **Context Menu**: Nautilus integration for "Open in Ghostty"

**AI Integration**:
- **Claude Code**: @anthropic-ai/claude-code (latest via npm)
- **Gemini CLI**: @google/gemini-cli (latest via npm)
- **zsh-codex**: Natural language to command translation
- **GitHub Copilot CLI**: @github/copilot (via npm)

**Modern Web Development**:
- **uv**: Python package manager (>=0.9.0)
- **Astro.build**: Static site generator (>=5.0)
- **Tailwind CSS**: Utility-first CSS (>=4.0)
- **DaisyUI**: Component library (latest stable)
- **TypeScript**: Type safety (>=5.9)

**Modern Unix Tools**:
- **bat**: Enhanced cat with syntax highlighting
- **exa**: Modern ls replacement
- **ripgrep**: Fast text search
- **fd**: Fast find alternative
- **zoxide**: Intelligent directory navigation
- **fzf**: Fuzzy finder

**Local CI/CD**:
- **GitHub CLI**: Workflow simulation and API access
- **Lighthouse CI**: Performance testing
- **axe-core**: Accessibility testing
- **shellcheck**: Shell script linting
- **bats**: Bash automated testing system

### Rationale

**Ghostty from Source**:
- Latest features and performance optimizations (2025 edition)
- linux-cgroup=single-instance optimization (MANDATORY per constitution)
- Enhanced shell integration with auto-detection
- Snap version often lags behind source releases

**DaisyUI over shadcn/ui**:
- Clarification from 2025-11-16 session: Use Tailwind with DaisyUI
- shadcn/ui reserved for future if deeper customization needed
- DaisyUI provides pre-built accessible components
- Faster initial development with maintained design system

**uv for Python**:
- 40x faster than pip for package installation
- Deterministic dependency resolution (lockfile support)
- Compatible with existing pip workflows
- Project-local environments prevent global pollution

**Astro for Documentation**:
- Static site generation with zero JavaScript by default
- Achieves Lighthouse 95+ scores easily
- TypeScript support built-in
- GitHub Pages deployment via docs/ directory

**Local GitHub Actions Runners**:
- Execute ANY GitHub workflow locally before cloud deployment
- Zero Actions minutes consumption
- Identical environment to cloud runners
- Constitutional requirement: "Zero-Cost Operations"

### Alternatives Considered

**Component Library**:
- **shadcn/ui (DEFERRED)**: Full component customization
  - Rejection reason: Requires deeper Tailwind expertise initially
  - May adopt in future for advanced customization needs
  - DaisyUI sufficient for initial implementation

**Documentation Framework**:
- **Jekyll (REJECTED)**: GitHub Pages default
  - Rejection reason: Ruby dependency, slower builds
  - Requires .nojekyll to disable (Astro requirement anyway)

- **VitePress (REJECTED)**: Vue-based documentation
  - Rejection reason: Vue ecosystem lock-in
  - Astro more flexible (any framework or none)

**Python Package Management**:
- **poetry (REJECTED)**: Popular alternative to uv
  - Rejection reason: Slower than uv, more complex configuration
  - uv provides pip-compatible interface (easier migration)

### Implementation Notes
- All npm packages installed globally via `npm install -g <package>`
- uv manages Python packages in project-local .venv
- Astro project in `website/` directory with source in `website/src/`
- Build output to `docs/` directory for GitHub Pages (committed)
- Local CI/CD runners in `.runners-local/workflows/` directory

### Verification
```bash
# Verify Ghostty installation
ghostty --version                # Ghostty 1.1.4+ (or latest)
ghostty +show-config             # Validate configuration

# Verify AI tools
claude --version                 # Claude Code CLI
gemini --version                 # Gemini CLI
gh copilot --version             # GitHub Copilot CLI

# Verify web stack
uv --version                     # uv 0.9.0+
cd website && npm run build      # Astro build success
lighthouse docs/index.html       # Lighthouse 95+ scores

# Verify modern Unix tools
bat --version                    # bat installed
exa --version                    # exa installed
rg --version                     # ripgrep installed
```

---

## R3: Storage and State Management

### Decision
**File-Based Configuration Only** - No database integration

**Storage Locations**:
- **Configuration**: `~/.config/ghostty/`, `~/.config/dircolors`
- **Logs**: `/tmp/ghostty-start-logs/`, `.runners-local/logs/`
- **Backups**: `~/.config/*/backup-TIMESTAMP/`
- **State Files**: JSON files for migration tracking, system state snapshots
- **Documentation**: `documentations/` (source), `docs/` (build output)
- **Scripts**: `scripts/` (modular), `.runners-local/workflows/` (CI/CD)

### Rationale

**File-Based Approach**:
- Terminal configuration is inherently file-based (config files, dotfiles)
- No need for relational data or complex queries
- Simpler backup and restore (file copy operations)
- Version control friendly (commit configurations directly)
- Constitutional requirement: "File-based configuration and documentation (no database)"

**JSON for State Tracking**:
- Structured data for migration state, system snapshots
- Parseable by both bash scripts (jq) and Node.js tools
- Human-readable for debugging
- Easy to version control and diff

**Temporary Logs in /tmp**:
- Automatic cleanup on reboot
- No disk space accumulation
- Preserved for debugging during session
- Moved to permanent storage if needed

### Alternatives Considered

**SQLite Database**:
- **REJECTED**: Would enable complex state queries
  - Rejection reason: Violates constitutional file-based requirement
  - Adds dependency and complexity
  - Migration state is simple key-value data
  - File-based JSON sufficient for all use cases

**Environment Variables for State**:
- **REJECTED**: Store state in shell environment
  - Rejection reason: Not persistent across sessions
  - Difficult to share state between scripts
  - Hard to debug and inspect

### Implementation Notes
- Backup system creates timestamped directories before modifications
- State files use descriptive naming: `system_state_TIMESTAMP.json`
- Log rotation handled by /tmp auto-cleanup
- Migration state tracked in `~/.config/package-migration/state.json`

### Verification
```bash
# Verify configuration structure
ls -la ~/.config/ghostty/        # Ghostty config directory
ls -la /tmp/ghostty-start-logs/  # Temporary logs
ls -la .runners-local/logs/      # CI/CD logs

# Verify state file structure
jq '.' /tmp/ghostty-start-logs/system_state_*.json  # System state
cat ~/.config/ghostty/config     # Current configuration
```

---

## R4: Testing Strategy and Quality Gates

### Decision
**Multi-Layer Testing Approach**:

**Layer 1: Shell Script Testing**
- **shellcheck**: Static analysis for bash scripts
- **bats**: Bash automated testing system for unit/integration tests
- **Contract validation**: Module interface verification

**Layer 2: Web Performance Testing**
- **Lighthouse CI**: Automated performance, accessibility, SEO, best practices
- **Performance targets**: 95+ all metrics
- **Bundle analysis**: <100KB JavaScript initial load

**Layer 3: Accessibility Testing**
- **axe-core**: Automated WCAG 2.1 Level AA compliance verification
- **Lighthouse accessibility**: Complementary accessibility checks
- **Integration**: Run in local CI/CD before deployment

**Layer 4: Security Testing**
- **npm audit**: Dependency vulnerability scanning
- **shellcheck security**: Shell script security issues
- **Integration**: Run in local CI/CD with zero high/critical vulnerabilities requirement

**Layer 5: Local GitHub Actions Runner**
- **Full workflow simulation**: Execute ALL GitHub Actions workflows locally
- **Matrix builds**: Test multiple configurations
- **Workflow dependencies**: Verify complex automation chains
- **Zero-cost validation**: Ensure workflows work before consuming Actions minutes

### Rationale

**Automated Accessibility Testing**:
- Clarification from 2025-11-16 session: Add axe-core + Lighthouse CI
- WCAG 2.1 Level AA compliance required for professional quality
- Automated testing catches 30-40% of accessibility issues
- Prevents accessibility regressions during development
- Constitutional quality gate: Lighthouse accessibility 95+

**Automated Security Scanning**:
- Clarification from 2025-11-16 session: Add npm audit + dependency checking
- Prevents vulnerable dependencies from reaching production
- Zero high/critical vulnerabilities requirement
- Automated detection of outdated packages with security issues
- Part of local CI/CD quality gates

**Local GitHub Actions Runners**:
- Clarification from 2025-11-16 session: Full local runner infrastructure
- Constitutional requirement: Zero GitHub Actions minutes consumption
- Enables testing complex automation before cloud deployment
- Identical environment to cloud (Docker-based runners)
- Supports ALL workflow features (matrix, dependencies, custom actions)

**Shell Testing with bats**:
- Already used in existing infrastructure (.runners-local/tests/)
- Proven pattern for bash script testing
- Supports test-driven development for modules
- Fast execution (each module <10s test time per SC-015)

**Lighthouse CI for Web**:
- Industry standard for web performance
- Automated scoring prevents performance regressions
- Integrates with local CI/CD workflows
- Success criteria: 95+ all metrics (SC-013, SC-025)

### Alternatives Considered

**Manual Accessibility Testing**:
- **REJECTED**: Manual WCAG compliance verification
  - Rejection reason: Time-consuming, error-prone, not repeatable
  - Automated testing provides consistent baseline
  - Manual testing still valuable for complex interactions (complementary)

**GitHub Actions for All Testing**:
- **REJECTED**: Run all tests in GitHub Actions
  - Rejection reason: Violates constitutional zero-cost requirement
  - Consumes free tier minutes
  - Slower feedback loop than local testing

**Snyk for Security Scanning**:
- **DEFERRED**: Professional security scanning service
  - Deferral reason: npm audit sufficient for initial implementation
  - May adopt for advanced vulnerability database in future
  - Current approach meets constitutional zero-cost requirement

### Implementation Notes

**Local CI/CD Integration**:
```bash
# Pre-commit workflow (runs locally)
./.runners-local/workflows/pre-commit-local.sh
├── shellcheck validation
├── bats unit tests
├── Lighthouse CI (docs site)
├── axe-core accessibility tests
├── npm audit security scan
└── Local GitHub Actions simulation

# Success criteria for commit
- All shellcheck tests pass
- All bats tests pass
- Lighthouse scores 95+ (all metrics)
- axe-core: zero violations
- npm audit: zero high/critical vulnerabilities
- Local workflow simulation: success
```

**Accessibility Testing**:
- axe-core integrated into Astro build process
- Lighthouse accessibility score tracked in performance dashboard
- Violations block deployment (quality gate)

**Security Scanning**:
- npm audit runs on every commit
- Dependency updates trigger re-scan
- High/critical vulnerabilities block merge

**Local GitHub Actions**:
- Docker-based runner infrastructure
- Workflow files from .github/workflows/ executed locally
- Results logged to .runners-local/logs/
- Success required before git push

### Verification
```bash
# Verify testing tools installed
shellcheck --version             # shellcheck 0.8.0+
bats --version                   # bats-core 1.9.0+
lighthouse --version             # Lighthouse 10.0.0+

# Run test suite
./.runners-local/workflows/test-runner.sh all

# Check accessibility
npx @axe-core/cli docs/index.html  # Zero violations

# Security scan
npm audit                        # Zero high/critical

# Local workflow simulation
./.runners-local/workflows/gh-workflow-local.sh all
```

---

## R5: Target Platform and Deployment

### Decision
**Target Platform**: Ubuntu 25.10 (Oracular Oriole) - Latest stable Ubuntu release

**Deployment Strategy**:
- **Local Installation**: `./manage.sh install` (one-command setup)
- **Documentation Site**: GitHub Pages via docs/ directory (zero-cost hosting)
- **CI/CD**: Local-first with optional self-hosted GitHub Actions runners
- **Distribution**: Git repository (no package distribution yet)

### Rationale

**Ubuntu 25.10 Focus**:
- Latest stable Ubuntu release (non-LTS)
- Aligns with latest-stable version policy
- Ghostty optimizations target latest kernels (6.x+)
- Modern systemd features available
- ZSH default shell (no migration needed)

**GitHub Pages for Docs**:
- Zero ongoing hosting costs (constitutional requirement)
- HTTPS enforcement automatic
- Custom domain support available
- Static site generation (Astro) perfect fit
- Critical requirement: docs/.nojekyll file for asset loading

**Local-First CI/CD**:
- Constitutional requirement: zero GitHub Actions consumption
- All validation runs locally before push
- Optional self-hosted runners for team workflows
- Performance target: <2 minutes complete workflow

### Alternatives Considered

**Multi-Distro Support**:
- **DEFERRED**: Ubuntu 20.04 LTS, 22.04 LTS, Debian, Fedora
  - Deferral reason: Complexity increases significantly
  - Different package managers, init systems, shell defaults
  - Future enhancement after Ubuntu 25.10 proven

**Package Distribution**:
- **DEFERRED**: Snap package, apt repository, Flatpak
  - Deferral reason: Repository distribution simpler initially
  - Package maintenance overhead
  - Future enhancement for easier installation

**Commercial Hosting**:
- **REJECTED**: Vercel, Netlify, AWS S3
  - Rejection reason: Violates zero-cost requirement
  - GitHub Pages sufficient for static documentation
  - No dynamic features require compute

### Implementation Notes
- Installation script detects Ubuntu version (dynamic, not hardcoded)
- Warnings for non-25.10 systems (may work but untested)
- GitHub Pages deployment automatic (push to main triggers build)
- docs/.nojekyll file protected by 4 layers (public/, Vite plugin, validation, hooks)

### Verification
```bash
# Verify platform
lsb_release -a                   # Ubuntu 25.10
uname -r                         # Kernel 6.x+

# Verify deployment
gh api repos/:owner/:repo/pages  # GitHub Pages enabled
curl -I https://username.github.io/repo/  # HTTPS works
test -f docs/.nojekyll && echo "CRITICAL FILE PRESENT"  # .nojekyll exists
```

---

## R6: Project Type and Architecture

### Decision
**Project Type**: Single Project with Multi-Component Architecture

**Repository Structure**:
```
ghostty-config-files/
├── manage.sh                    # Unified CLI entry point
├── start.sh                     # Wrapper to manage.sh install
├── scripts/                     # Modular installation scripts (10+ modules)
│   ├── common.sh               # Shared utilities
│   ├── progress.sh             # Installation UI (parallel task display)
│   ├── backup_utils.sh         # Backup/restore system
│   ├── install_node.sh         # Node.js via fnm
│   ├── install_ghostty.sh      # Ghostty from source
│   ├── install_ai_tools.sh     # Claude, Gemini, Copilot CLI
│   └── ...                     # Additional modules (10+ total)
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
├── documentations/              # Centralized documentation
│   ├── user/                   # User guides
│   ├── developer/              # Developer guides
│   ├── specifications/         # Active specs
│   └── archive/                # Historical docs
└── .specify/                    # Spec-Kit infrastructure
    ├── templates/              # Planning templates
    ├── scripts/                # Workflow automation
    └── memory/                 # Constitutional knowledge
```

**Architecture Principles**:
- **Modular Scripts**: Each script handles one specific task (<250 lines)
- **Clear Separation**: Source (website/src/) vs Build (docs/)
- **Constitutional Compliance**: All 6 core principles enforced
- **Testability**: Each module independently testable in <10s

### Rationale

**Single Project Architecture**:
- Not a web app (backend/frontend split unnecessary)
- Not a mobile app (ios/android split unnecessary)
- Terminal configuration is fundamentally monolithic domain
- Modular scripts provide needed separation without project boundaries

**Multi-Component Internal Structure**:
- manage.sh as unified CLI (simpler than multiple entry points)
- Modular scripts in scripts/ directory (maintainability)
- Separate CI/CD infrastructure (.runners-local/)
- Documentation hub (documentations/) + site source (website/src/)

**Installation UI Design**:
- Clarification from 2025-11-16 session: Parallel task UI like Claude Code
- Each task on separate line
- Verbose subtasks collapse into parent task
- Screen remains clean and tidy
- Dynamic status with proper verification (not hardcoded messages)

### Alternatives Considered

**Monorepo with Workspace**:
- **REJECTED**: Multiple packages with npm workspaces
  - Rejection reason: Overcomplicated for terminal config project
  - Would require package.json for every component
  - Dependencies between scripts are simple (function imports)

**Separate Repositories**:
- **REJECTED**: Split into ghostty-config, ghostty-docs, ghostty-tools
  - Rejection reason: Tight coupling between components
  - Installation script needs docs build
  - Docs need config for examples
  - Branch preservation strategy harder to maintain

**Flat Script Structure**:
- **REJECTED**: All scripts in root directory
  - Rejection reason: 001-repo-structure-refactor already addressed this
  - Root directory clutter reduced 40% (22→14 files)
  - scripts/ directory provides clear organization

### Implementation Notes

**Modular Script Contracts**:
- Each module exports specific functions
- Dependencies declared explicitly
- Testable in isolation (<10s per module)
- shellcheck + bats validation

**Installation Progress Display**:
```bash
# Example parallel task UI
✓ Installing Ghostty from source (complete)
✓ Installing Node.js via fnm (complete)
▶ Installing AI tools
  ├── Claude Code (installing...)
  ├── Gemini CLI (pending)
  └── Copilot CLI (pending)
⏳ Building documentation site (pending)
```

**Documentation Separation**:
- website/src/ contains editable markdown (version controlled)
- docs/ contains Astro build output (committed for GitHub Pages)
- Build process: `cd website && npm run build` → outputs to docs/
- Critical: docs/.nojekyll file enables asset loading

### Verification
```bash
# Verify structure
ls -la scripts/                  # 10+ modular scripts
ls -la website/src/              # Source documentation
ls -la docs/                     # Build output
test -f docs/.nojekyll && echo "CRITICAL FILE PRESENT"

# Verify manage.sh
./manage.sh --help               # Show available commands
./manage.sh validate             # Run validation

# Verify module independence
./.runners-local/tests/unit/test_common_utils.sh  # Test common module
```

---

## R7: Performance Goals and Optimization

### Decision

**Shell Performance**:
- **Startup Time**: <50ms (vs current ~200ms average)
- **Strategy**: Lazy loading, compilation caching, deferred initialization
- **Tools**: zprof for profiling, benchmarking scripts

**Terminal Performance**:
- **Ghostty Startup**: <500ms with CGroup single-instance optimization
- **Optimization**: linux-cgroup=single-instance (MANDATORY)
- **Shell Integration**: Auto-detection, enhanced features

**Web Performance**:
- **Lighthouse Scores**: 95+ on all metrics (Performance, Accessibility, Best Practices, SEO)
- **Bundle Size**: <100KB JavaScript initial load
- **Build Time**: Same or better than current (SC-012)

**CI/CD Performance**:
- **Local Workflow**: <2 minutes complete execution
- **Module Tests**: <10s per module in isolation
- **Validation**: <1 minute for pre-commit checks

### Rationale

**Sub-50ms Shell Startup**:
- Success criterion SC-010: "Shell startup time <50ms"
- Requires aggressive optimization (lazy loading, caching)
- fnm chosen over nvm for 40x performance advantage
- Deferred initialization for non-critical plugins

**Ghostty CGroup Optimization**:
- Constitutional requirement: linux-cgroup=single-instance
- Prevents multiple Ghostty instances competing for resources
- Measurable startup improvement on Ubuntu 25.10
- Success criterion SC-011: <500ms terminal startup

**Lighthouse 95+ Scores**:
- Success criteria SC-013, SC-025, SC-045, SC-047
- Industry standard for professional quality
- Astro's zero-JavaScript default helps significantly
- DaisyUI optimized for performance

**Fast Local CI/CD**:
- Constitutional constraint: Developers need rapid feedback
- Success criterion SC-034: Complete migration step in single session
- 2-minute workflow enables quick iteration
- Each module testable in <10s (SC-015)

### Alternatives Considered

**Relaxed Performance Targets**:
- **REJECTED**: <200ms shell startup (current performance)
  - Rejection reason: Not competitive with modern terminal setups
  - User expectation: Instant response
  - Achievable with proper optimization

**Lighthouse 90+ Scores**:
- **REJECTED**: Lower accessibility/performance threshold
  - Rejection reason: 95+ is industry standard for professional quality
  - Achievable with Astro + proper optimization
  - Automated testing enforces threshold

**Slower CI/CD**:
- **REJECTED**: 5-10 minute local workflow
  - Rejection reason: Breaks development flow
  - Developers would skip validation
  - 2-minute target balances thoroughness with speed

### Implementation Notes

**Shell Optimization**:
```zsh
# Lazy loading example
function lazy_load_nvm() {
  unfunction lazy_load_nvm
  # Actually load nvm here
}
alias nvm=lazy_load_nvm

# Compilation caching
zcompile ~/.zshrc                # Compile to bytecode
```

**Ghostty Configuration**:
```
# MANDATORY optimization
linux-cgroup = single-instance

# Shell integration (auto-detect)
shell-integration = detect
shell-integration-features = cursor,sudo,title
```

**Web Optimization**:
- Astro partial hydration (zero JS where possible)
- Tailwind CSS purging (remove unused styles)
- DaisyUI tree-shaking
- Image optimization (webp, lazy loading)

**CI/CD Optimization**:
- Parallel test execution where possible
- Cached dependency resolution
- Incremental builds for documentation

### Verification
```bash
# Measure shell startup
time zsh -i -c exit              # Should be <50ms

# Measure Ghostty startup
time ghostty --print-config      # Should be <500ms

# Check Lighthouse scores
lighthouse docs/index.html --view  # All 95+

# Measure CI/CD performance
time ./.runners-local/workflows/gh-workflow-local.sh all  # <2 minutes
```

---

## R8: Constraints and Requirements

### Decision

**Constitutional Constraints** (NON-NEGOTIABLE):
1. **Branch Preservation**: Never delete branches without explicit permission
2. **GitHub Pages Protection**: docs/.nojekyll file ABSOLUTELY CRITICAL
3. **Local CI/CD First**: All validation locally before GitHub
4. **Agent File Integrity**: AGENTS.md single source of truth (CLAUDE.md, GEMINI.md symlinks)
5. **LLM Conversation Logging**: Complete logs with system state snapshots
6. **Zero-Cost Operations**: No GitHub Actions consumption for routine operations

**Technical Constraints**:
- **Passwordless Sudo**: Limited to /usr/bin/apt only (security scope)
- **Latest Stable Versions**: ALL technologies use latest (not LTS)
- **File-Based Configuration**: No database integration
- **Ubuntu 25.10 Target**: Latest stable Ubuntu release
- **Directory Nesting**: Maximum 2 levels from repo root
- **Module Size**: <250 lines per script module

**Quality Constraints**:
- **Accessibility**: WCAG 2.1 Level AA compliance (automated testing)
- **Security**: Zero high/critical vulnerabilities (npm audit)
- **Performance**: Lighthouse 95+ all metrics
- **Testability**: Each module testable in <10s

### Rationale

**Constitutional Compliance**:
- 6 core principles in .specify/memory/constitution.md
- Non-negotiable per project governance
- Enforced via quality gates and validation
- Violations must be justified in "Complexity Tracking" section

**Passwordless Sudo Requirement**:
- Constitutional requirement for automated installation
- Enables daily updates at 9:00 AM without user interaction
- Security scope limited to /usr/bin/apt (not unrestricted)
- Installation script exits if not configured

**Latest Stable Policy**:
- Constitutional requirement: "Latest stable versions (not LTS)"
- Applies to: Node.js, npm packages, Astro, Tailwind, TypeScript, uv
- Rationale: Access to newest features, better performance
- Per-project overrides via fnm .nvmrc when needed

**Accessibility Requirement**:
- Clarification from 2025-11-16 session: Automated WCAG 2.1 Level AA testing
- axe-core integration in local CI/CD
- Lighthouse accessibility score 95+
- Success criteria SC-045, SC-046, SC-047

**Security Requirement**:
- Clarification from 2025-11-16 session: Automated security scanning
- npm audit integration in local CI/CD
- Zero high/critical vulnerabilities required
- Success criteria SC-048, SC-049

### Alternatives Considered

**LTS Version Policy**:
- **REJECTED**: Use Node.js LTS, Ubuntu LTS, stable Astro
  - Rejection reason: Violates constitutional latest-stable requirement
  - Would miss performance improvements and new features
  - fnm enables per-project LTS if needed

**Unrestricted Sudo**:
- **REJECTED**: Full passwordless sudo (all commands)
  - Rejection reason: Excessive security risk
  - Only apt installation needs sudo
  - Limited scope sufficient for automation

**Manual Accessibility Testing**:
- **REJECTED**: Manual WCAG reviews instead of automated testing
  - Rejection reason: Time-consuming, not repeatable
  - Automated baseline + manual reviews more effective

**Relax .nojekyll Requirement**:
- **REJECTED**: Find alternative to .nojekyll file
  - Rejection reason: NO ALTERNATIVE EXISTS
  - GitHub Pages uses Jekyll by default
  - Astro requires disabling Jekyll (underscore directories)
  - Constitutional protection layers ensure file never removed

### Implementation Notes

**Passwordless Sudo Setup**:
```bash
# Configure sudo (one-time setup)
sudo visudo
# Add: username ALL=(ALL) NOPASSWD: /usr/bin/apt

# Verify
sudo -n apt update  # Should run without password prompt
```

**Constitutional Validation**:
```bash
# Pre-commit checks
├── Branch preservation check (no git branch -d)
├── .nojekyll existence verification
├── Local CI/CD execution proof
├── AGENTS.md symlink verification (readlink CLAUDE.md)
├── Conversation log presence check
└── GitHub Actions usage check (gh api /user/settings/billing/actions)
```

**Version Policy Enforcement**:
```bash
# Verify latest stable versions
node --version                   # v25.2.0+ (not v22 LTS)
npm list -g @anthropic-ai/claude-code  # Latest
uv --version                     # >=0.9.0 (latest stable)
```

### Verification
```bash
# Constitutional compliance
readlink CLAUDE.md GEMINI.md     # Should output: AGENTS.md
test -f docs/.nojekyll && echo "CRITICAL FILE PRESENT"
gh api user/settings/billing/actions | jq '.total_minutes_used'  # Should be 0

# Quality gates
npx @axe-core/cli docs/index.html  # Zero violations
npm audit                        # Zero high/critical
lighthouse docs/index.html       # All 95+

# Performance
time zsh -i -c exit              # <50ms
time ghostty --print-config      # <500ms
```

---

## R9: Scale and Scope

### Decision

**Feature Scope**:
- **76 Functional Requirements** (FR-001 to FR-076)
- **62 Success Criteria** (SC-001 to SC-062)
- **3 Consolidated Features**: 001 (repo structure), 002 (terminal productivity), 004 (web development)
- **4 User Stories**: Unified environment (P1), Web workflow (P1), Architecture (P2), Productivity (P2)

**Code Scope**:
- **10+ Modular Scripts**: Refactor from monolithic start.sh
- **4-5 Top-Level Directories**: Balanced nesting (not complex, not flat)
- **Module Size Limit**: <250 lines per script
- **Test Coverage**: Every module independently testable in <10s

**Documentation Scope**:
- **User Guides**: Installation, configuration, troubleshooting
- **Developer Guides**: Architecture, contributing, AI guidelines
- **Specifications**: Active specs in specifications/, archived in archive/
- **AI Integration**: AGENTS.md (single source), symlinks (CLAUDE.md, GEMINI.md)

**Installation Scope**:
- **Fresh System Setup**: <10 minutes on Ubuntu 25.10
- **Component Count**: ~15 major components (Ghostty, ZSH, Node.js, AI tools, Unix tools, etc.)
- **User Interaction**: Zero manual configuration for standard setup

### Rationale

**Comprehensive Requirements**:
- 76 functional requirements ensure complete feature coverage
- Consolidation from 3 specs prevents scope creep
- Clear success criteria (62) enable measurable validation
- User stories prioritized (P1 for immediate value, P2 for enhancements)

**Modular Script Architecture**:
- Clarification from 001-repo-structure-refactor: Fine-grained modules (10+)
- Each module handles single, specific task
- Success criterion SC-030: "All 10+ fine-grained modules tested independently"
- Maintainability and testability over monolithic simplicity

**Balanced Directory Structure**:
- Clarification from 001-repo-structure-refactor: 4-5 top-level directories
- Not complex (6+ levels deep), not flat (everything in root)
- Current: manage.sh, scripts/, website/, docs/, .runners-local/, documentations/, .specify/
- Success criterion SC-032: "Repository size remains manageable"

**Incremental Migration**:
- Clarification from 001-repo-structure-refactor: Per-component approach
- Success criterion SC-034: "Each increment completes within single development session"
- Already 24% complete (Phases 1-3 from 001 implementation)

### Alternatives Considered

**Minimal Module Count**:
- **REJECTED**: 3-5 large scripts instead of 10+ focused modules
  - Rejection reason: Violates fine-grained granularity decision
  - Harder to test in isolation
  - More difficult to maintain and understand

**Flat Directory Structure**:
- **REJECTED**: All files/scripts in repository root
  - Rejection reason: Already addressed in 001 refactor
  - Root clutter reduced 40% (22→14 files)
  - Clear organization improves navigation

**Complete Rewrite**:
- **REJECTED**: Discard existing implementation, start fresh
  - Rejection reason: 24% already complete and functional
  - Phases 1-3 provide solid foundation
  - Incremental approach safer and faster

### Implementation Notes

**Migration Phases**:
```
Phase 1: Setup & Validation Infrastructure ✅ COMPLETE (24%)
Phase 2: Foundational Utilities ✅ COMPLETE (24%)
Phase 3: manage.sh Infrastructure ✅ COMPLETE (24%)
Phase 4: Modern Web Stack Integration ⚠️ PENDING
Phase 5: Modular Scripts Extraction ⚠️ PENDING (main effort)
Phase 6: AI Integration ⚠️ PENDING
Phase 7: Advanced Terminal Productivity ⚠️ PENDING
```

**Module Breakdown** (estimated):
1. install_ghostty.sh (Ghostty from source)
2. install_node.sh (fnm + Node.js)
3. install_ai_tools.sh (Claude, Gemini, Copilot)
4. install_unix_tools.sh (bat, exa, ripgrep, fd, zoxide, fzf)
5. install_zsh_plugins.sh (Oh My ZSH plugins)
6. configure_shell.sh (ZSH configuration, theme)
7. setup_context_menu.sh (Nautilus integration)
8. validate_environment.sh (System validation)
9. backup_restore.sh (Backup/restore operations)
10. update_components.sh (Component updates)
11. performance_optimize.sh (Performance tuning)
12+ Additional modules as needed

**Documentation Structure**:
```
documentations/
├── user/                        # End-user documentation
│   ├── installation/
│   ├── configuration/
│   └── troubleshooting/
├── developer/                   # Developer documentation
│   ├── architecture/
│   ├── contributing/
│   └── testing/
├── specifications/              # Active feature specs
│   └── 005-complete-terminal-infrastructure/
└── archive/                     # Historical/obsolete docs
```

### Verification
```bash
# Verify module count
ls -1 scripts/install_*.sh | wc -l  # 10+ modules

# Verify directory structure
tree -L 1 -d                     # 4-5 top-level directories

# Verify test coverage
./.runners-local/workflows/test-runner.sh --list  # All modules listed

# Verify module test time
time ./.runners-local/tests/unit/test_common_utils.sh  # <10s
```

---

## Summary of Research Decisions

| Research Area | Decision | Key Rationale |
|---------------|----------|---------------|
| **Language/Runtime** | Bash 5.x+, ZSH, Node.js latest (fnm), uv >=0.9.0 | Latest stable policy (constitutional) |
| **Dependencies** | Ghostty, Astro 5+, Tailwind 4+, DaisyUI, AI tools | Latest stable versions, DaisyUI over shadcn/ui |
| **Storage** | File-based only (no database) | Constitutional requirement, version control friendly |
| **Testing** | shellcheck, bats, Lighthouse CI, axe-core, npm audit | Multi-layer quality gates, automated compliance |
| **Platform** | Ubuntu 25.10 (latest stable) | Aligns with latest-stable policy |
| **Architecture** | Single project, multi-component, 10+ modules | Modular without over-engineering |
| **Performance** | <50ms shell, <500ms Ghostty, 95+ Lighthouse | Industry-leading targets, constitutional goals |
| **Constraints** | 6 constitutional principles + quality gates | Non-negotiable governance requirements |
| **Scope** | 76 FR, 62 SC, 10+ modules, 3 consolidated features | Comprehensive but focused implementation |

---

## Next Steps

This research document resolves ALL "NEEDS CLARIFICATION" items from the plan template. Proceed to:

1. **Phase 1 Design**: Generate data-model.md, contracts/, quickstart.md
2. **Technical Context**: Fill plan.md Technical Context section with above decisions
3. **Constitution Check**: Validate all 6 constitutional principles compliance
4. **Project Structure**: Finalize concrete directory paths (no placeholders)

**Research Status**: ✅ COMPLETE - All clarifications resolved
**Date Completed**: 2025-11-16
**Total Research Items**: 9 major areas (R1-R9) covering all technical unknowns
