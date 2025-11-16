# Implementation Plan: Complete Terminal Development Infrastructure

**Branch**: `005-complete-terminal-infrastructure` | **Date**: 2025-11-16 | **Spec**: [spec.md](spec.md)
**Input**: Consolidation of features 001 (repo structure), 002 (terminal productivity), 004 (web development)

---

## Summary

This plan implements a comprehensive terminal development infrastructure that consolidates three related features into a unified, production-ready environment. The implementation provides:

1. **Unified Development Environment** (P1): Single-command installation of Ghostty terminal, ZSH shell, Node.js (latest via fnm), AI tools (Claude Code, Gemini CLI, Copilot), modern Unix tools, and documentation infrastructure.

2. **Modern Web Development Workflow** (P1): Integrated uv (Python), Astro.build (static sites), Tailwind CSS + DaisyUI (UI), with local CI/CD validation ensuring high-performance websites without ongoing costs.

3. **Clear Architecture** (P2): Modular script structure (10+ focused modules) with clean separation between source (`website/src/`) and generated content (`docs/`), enabling easy maintenance and contribution.

4. **Advanced Terminal Productivity** (P2): Performance-optimized shell (sub-50ms startup), rich theming options (Powerlevel10k/Starship), and team collaboration features.

**Technical Approach**:
- Refactor monolithic `start.sh` into 10+ fine-grained, testable modules
- Implement parallel task installation UI with collapsible verbose output (like Claude Code)
- Integrate automated accessibility (axe-core) and security (npm audit) testing in local CI/CD
- Deploy local GitHub Actions runner infrastructure for zero-cost automation
- Enforce latest stable version policy (not LTS) per constitutional requirement
- Maintain constitutional compliance across all 6 core principles

**Success Metrics**:
- Fresh Ubuntu 25.10 system fully configured in <10 minutes (SC-001)
- Shell startup <50ms, Ghostty startup <500ms (SC-010, SC-011)
- Lighthouse scores 95+ all metrics (SC-013, SC-025, SC-047)
- Zero GitHub Actions consumption (constitutional requirement)
- All 10+ modules testable in <10s each (SC-015)

---

## Technical Context

**Language/Version**:
- Bash 5.x+ (system scripts, installation, modular architecture)
- ZSH (interactive shell, Ubuntu 25.10 default)
- Node.js latest stable via fnm (currently v25.2.0+, NOT LTS per constitutional requirement)
- Python latest stable via uv (>=0.9.0)
- TypeScript latest stable (>=5.9) for Astro project

**Primary Dependencies**:
- **Terminal**: Ghostty (from source, Zig 0.14.0), ZSH + Oh My ZSH
- **Node.js Manager**: fnm (Fast Node Manager, <50ms startup vs nvm's ~2000ms)
- **Python Manager**: uv (40x faster than pip, deterministic dependency resolution)
- **Web Stack**: Astro >=5.0, Tailwind CSS >=4.0, DaisyUI (latest), TypeScript >=5.9
- **AI Tools**: @anthropic-ai/claude-code, @google/gemini-cli, @github/copilot (all latest via npm)
- **Unix Tools**: bat, exa, ripgrep, fd, zoxide, fzf (modern CLI replacements)
- **CI/CD**: GitHub CLI, Lighthouse CI, axe-core, shellcheck, bats

**Storage**:
File-based only (no database). Configuration in `~/.config/*/`, logs in `/tmp/ghostty-start-logs/` and `.runners-local/logs/`, backups in timestamped directories, state tracking in JSON files.

**Testing**:
- **Shell Scripts**: shellcheck (static analysis) + bats (unit/integration tests)
- **Web Performance**: Lighthouse CI (95+ all metrics)
- **Accessibility**: axe-core (WCAG 2.1 Level AA, zero violations)
- **Security**: npm audit (zero high/critical vulnerabilities)
- **Contract Validation**: Module interface verification
- **Local GitHub Actions**: Full workflow simulation before cloud deployment

**Target Platform**:
Ubuntu 25.10 (Oracular Oriole) - Latest stable Ubuntu release. Aligns with latest-stable version policy. Ghostty optimizations target latest kernels (6.x+). ZSH default shell (no migration needed).

**Project Type**:
Single project with multi-component architecture. Not a web app (no backend/frontend split), not mobile (no platform-specific structure). Terminal configuration is fundamentally monolithic domain with modular internal structure.

**Performance Goals**:
- Shell startup: <50ms (vs current ~200ms average, SC-010)
- Ghostty terminal startup: <500ms with CGroup optimization (SC-011)
- Documentation site build: Same or better than current (SC-012)
- Lighthouse scores: 95+ all metrics (Performance, Accessibility, Best Practices, SEO) (SC-013, SC-025, SC-047)
- JavaScript bundles: <100KB initial load (SC-014, FR-026)
- Local CI/CD workflow: <2 minutes complete execution (SC-012, constitutional)
- Module tests: <10s per module in isolation (SC-015)

**Constraints**:
- **Constitutional (NON-NEGOTIABLE)**:
  1. Branch preservation: Never delete branches without explicit permission
  2. `.nojekyll` file: ABSOLUTELY CRITICAL for GitHub Pages (docs/.nojekyll)
  3. Local CI/CD first: All validation locally before GitHub deployment
  4. Agent file integrity: AGENTS.md single source of truth (CLAUDE.md, GEMINI.md symlinks)
  5. LLM conversation logging: Complete logs with system state snapshots
  6. Zero-cost operations: No GitHub Actions consumption (MUST be 0)

- **Technical**:
  - Passwordless sudo limited to `/usr/bin/apt` only (security scope)
  - Latest stable versions for ALL technologies (NOT LTS)
  - File-based configuration (no database integration)
  - Directory nesting: Maximum 2 levels from repo root
  - Module size: <250 lines per script

- **Quality**:
  - Accessibility: WCAG 2.1 Level AA compliance (automated testing)
  - Security: Zero high/critical vulnerabilities (npm audit)
  - Performance: Lighthouse 95+ all metrics
  - Testability: Each module testable in <10s

**Scale/Scope**:
- 76 functional requirements (FR-001 to FR-076)
- 62 success criteria (SC-001 to SC-062)
- 10+ modular scripts (refactor from monolithic start.sh)
- 4-5 top-level directories (balanced nesting)
- ~15 major components (Ghostty, ZSH, Node.js, AI tools, Unix tools, web stack, etc.)
- 3 consolidated features (001, 002, 004)
- Fresh system setup: <10 minutes on Ubuntu 25.10

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Branch Preservation & Git Strategy

**Status**: COMPLIANT

**Implementation**:
- All git workflows documented in quickstart.md use branch preservation strategy
- manage.sh CLI never deletes branches
- Installation/update scripts create timestamped branches automatically
- Merge with `--no-ff` to preserve branch history
- No `git branch -d` commands in any scripts

**Rationale**: Configuration history valuable for debugging, regression analysis, and architectural decision archaeology.

### ✅ II. GitHub Pages Infrastructure Protection

**Status**: COMPLIANT

**Implementation**:
- `.nojekyll` file in `docs/` directory (4 protection layers)
  - Layer 1: Astro `public/` directory (automatic copy)
  - Layer 2: Vite plugin automation (astro.config.mjs)
  - Layer 3: Post-build validation scripts
  - Layer 4: Pre-commit git hooks
- Build artifact entity (E4) validates `.nojekyll` presence before deployment
- Quality gate blocks deployment if file missing
- Documented as CRITICAL in all relevant files

**Impact**: Without this file, ALL CSS/JS assets return 404 (Astro outputs to `_astro/`, Jekyll ignores underscore directories).

### ✅ III. Local CI/CD First

**Status**: COMPLIANT

**Implementation**:
- All CI/CD workflows in `.runners-local/workflows/` directory
- `gh-workflow-local.sh all` runs complete validation locally
- Quality gates enforce local execution before git push:
  - shellcheck validation
  - Lighthouse CI (95+ scores)
  - axe-core accessibility (zero violations)
  - npm audit security (zero high/critical)
  - Local GitHub Actions simulation
- Pre-commit hooks trigger local workflows
- manage.sh CLI validates before deployment operations

**Performance**: <2 minutes for complete local workflow (SC-012, constitutional target).

### ✅ IV. Agent File Integrity

**Status**: COMPLIANT

**Implementation**:
- AGENTS.md is regular file (single source of truth)
- CLAUDE.md is symlink → AGENTS.md
- GEMINI.md is symlink → AGENTS.md
- Symlink verification in pre-commit hooks
- Documentation may be COPIED to `website/src/` for Astro site, but AGENTS.md remains intact
- Agent context update script (Phase 1) preserves manual additions between markers

**Verification**: `readlink CLAUDE.md GEMINI.md` must output `AGENTS.md`.

### ✅ V. LLM Conversation Logging

**Status**: COMPLIANT

**Implementation**:
- Conversation logs stored in `documentations/development/conversation_logs/`
- Naming convention: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- System state snapshots in `documentations/development/system_states/`
- CI/CD logs in `documentations/development/ci_cd_logs/`
- Automated reminder in agent instructions
- Pre-commit template prompts for log saving

**Content**: Complete conversation + before/after system states (sensitive data removed).

### ✅ VI. Zero-Cost Operations

**Status**: COMPLIANT

**Implementation**:
- All CI/CD runs locally (`.runners-local/` infrastructure)
- GitHub Actions usage monitoring via `gh api user/settings/billing/actions`
- CI/CD workflow entity (E5) tracks `github_actions_minutes_consumed` (MUST be 0)
- Quality gate fails if any Actions minutes consumed
- Cost monitoring dashboard in `.runners-local/workflows/`
- Performance metrics entity (E6) validates zero-cost compliance

**Monitoring**: `gh api user/settings/billing/actions | jq '.total_minutes_used'` → Must be 0.

---

### Constitutional Compliance Summary

| Principle | Status | Implementation | Validation Method |
|-----------|--------|----------------|-------------------|
| I. Branch Preservation | ✅ COMPLIANT | No branch deletion commands, merge with --no-ff | Code review, git hooks |
| II. GitHub Pages Protection | ✅ COMPLIANT | 4-layer .nojekyll protection, quality gate validation | Build artifact entity check (E4) |
| III. Local CI/CD First | ✅ COMPLIANT | `.runners-local/` workflows, pre-commit hooks | Workflow entity (E5), <2min target |
| IV. Agent File Integrity | ✅ COMPLIANT | AGENTS.md + symlinks, context update script | `readlink` verification, hooks |
| V. LLM Conversation Logging | ✅ COMPLIANT | Storage in documentations/development/, templates | Manual compliance, prompts |
| VI. Zero-Cost Operations | ✅ COMPLIANT | Local CI/CD, GitHub Actions monitoring | Performance entity (E6), billing API |

**Overall Compliance**: ✅ ALL 6 PRINCIPLES MET

**Complexity Violations**: None - no complexity tracking section required.

---

## Project Structure

### Documentation (this feature)

```text
specs/005-complete-terminal-infrastructure/
├── spec.md                     # Feature specification (consolidated from 001, 002, 004)
├── plan.md                     # This file (/speckit.plan command output)
├── research.md                 # Phase 0 output (technical decisions, alternatives)
├── data-model.md               # Phase 1 output (10 entities, validation rules, state transitions)
├── quickstart.md               # Phase 1 output (developer onboarding guide)
├── contracts/                  # Phase 1 output (API interface specifications)
│   ├── cicd-runner-interface.yaml              # Local GitHub Actions runner API
│   ├── installation-display-protocol.yaml      # Parallel task UI contract
│   └── quality-gate-interface.yaml             # Accessibility/security testing API
└── tasks.md                    # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
ghostty-config-files/               # Repository root
│
├── manage.sh                       # Unified management CLI (517 lines, complete)
├── start.sh                        # Wrapper to manage.sh install (backward compatibility)
├── AGENTS.md                       # AI assistant instructions (single source of truth)
├── CLAUDE.md                       # Symlink → AGENTS.md
├── GEMINI.md                       # Symlink → AGENTS.md
├── README.md                       # User documentation
│
├── scripts/                        # Modular installation scripts (10+ modules)
│   ├── common.sh                  # Shared utilities (315 lines, complete)
│   ├── progress.sh                # Installation UI - parallel task display (377 lines, complete)
│   ├── backup_utils.sh            # Backup/restore system (347 lines, complete)
│   ├── install_node.sh            # Node.js via fnm (latest stable, ⚠️ TO IMPLEMENT)
│   ├── install_ghostty.sh         # Ghostty from source (⚠️ TO IMPLEMENT)
│   ├── install_ai_tools.sh        # Claude Code, Gemini CLI, Copilot (⚠️ TO IMPLEMENT)
│   ├── install_unix_tools.sh      # bat, exa, ripgrep, fd, zoxide, fzf (⚠️ TO IMPLEMENT)
│   ├── install_zsh_plugins.sh     # Oh My ZSH plugins (⚠️ TO IMPLEMENT)
│   ├── configure_shell.sh         # ZSH configuration, theme (⚠️ TO IMPLEMENT)
│   ├── setup_context_menu.sh      # Nautilus "Open in Ghostty" integration (⚠️ TO IMPLEMENT)
│   ├── validate_environment.sh    # System validation (⚠️ TO IMPLEMENT)
│   └── update_components.sh       # Component updates (⚠️ TO IMPLEMENT)
│
├── configs/                        # Configuration files
│   ├── ghostty/                   # Ghostty terminal config
│   │   ├── config                 # Main configuration (linux-cgroup=single-instance MANDATORY)
│   │   ├── themes/                # Catppuccin themes (light/dark auto-switching)
│   │   └── dircolors              # XDG-compliant directory colors (world-writable readability)
│   └── ...                        # Other configurations
│
├── website/                        # Astro documentation site (source)
│   ├── src/                       # Editable markdown (committed, version controlled)
│   │   ├── user-guide/            # User documentation
│   │   ├── developer/             # Developer documentation
│   │   └── ai-guidelines/         # AI integration guides
│   ├── astro.config.mjs           # Astro configuration (TypeScript strict mode)
│   ├── tailwind.config.mjs        # Tailwind CSS configuration (v4.0+)
│   ├── package.json               # npm dependencies
│   └── node_modules/              # npm packages (gitignored)
│
├── docs/                           # Astro build output (committed for GitHub Pages)
│   ├── .nojekyll                  # CRITICAL: Disables Jekyll (ABSOLUTELY REQUIRED)
│   ├── index.html                 # Main page
│   ├── _astro/                    # Bundled assets (CSS, JS - requires .nojekyll to load)
│   └── ...                        # Generated pages
│
├── .runners-local/                 # Local CI/CD infrastructure
│   ├── workflows/                 # CI/CD execution scripts (committed)
│   │   ├── gh-workflow-local.sh   # GitHub Actions local simulation (main workflow)
│   │   ├── astro-build-local.sh   # Astro build workflows
│   │   ├── performance-monitor.sh # Performance tracking (<2min workflow, <50ms shell, <500ms Ghostty)
│   │   ├── gh-pages-setup.sh      # GitHub Pages setup (zero-cost validation)
│   │   └── quality-gates.sh       # Accessibility/security/performance gates
│   ├── self-hosted/               # Self-hosted runner management (optional)
│   │   ├── setup-self-hosted-runner.sh  # Runner setup (committed)
│   │   └── config/                # Runner credentials (GITIGNORED)
│   ├── tests/                     # Test infrastructure (committed)
│   │   ├── contract/              # Contract tests (module interfaces)
│   │   ├── unit/                  # Unit tests (each module <10s)
│   │   │   ├── test_common_utils.sh        # Common module tests (547 lines, complete)
│   │   │   └── test_*.sh          # Module-specific tests (⚠️ TO IMPLEMENT)
│   │   ├── integration/           # Integration tests
│   │   ├── validation/            # Validation scripts
│   │   └── fixtures/              # Test fixtures
│   ├── logs/                      # Execution logs (GITIGNORED)
│   │   ├── workflows/             # Workflow execution logs
│   │   ├── builds/                # Build logs
│   │   ├── tests/                 # Test logs
│   │   ├── quality-gates-*.json   # Quality gate results (accessibility, security, performance)
│   │   └── performance-*.json     # Performance metrics (shell startup, Ghostty startup, Lighthouse scores)
│   └── docs/                      # Runner documentation (committed)
│
├── documentations/                 # Centralized documentation hub
│   ├── user/                      # End-user documentation
│   │   ├── installation/          # Installation guides
│   │   ├── configuration/         # Configuration guides
│   │   └── troubleshooting/       # Troubleshooting guides
│   ├── developer/                 # Developer documentation
│   │   ├── architecture/          # Architecture documentation
│   │   ├── contributing/          # Contributing guides
│   │   └── testing/               # Testing guides
│   ├── specifications/            # Active feature specifications
│   │   └── 005-complete-terminal-infrastructure/  # This feature spec (moved from documentations/)
│   └── archive/                   # Historical/obsolete documentation
│
└── .specify/                       # Spec-Kit infrastructure
    ├── templates/                 # Planning templates
    │   ├── plan-template.md       # Implementation plan template
    │   ├── spec-template.md       # Feature specification template
    │   └── tasks-template.md      # Task breakdown template
    ├── scripts/                   # Workflow automation
    │   └── bash/                  # Bash scripts
    │       ├── setup-plan.sh      # Plan setup script
    │       ├── update-agent-context.sh  # Agent context update
    │       └── common.sh          # Common utilities
    └── memory/                    # Constitutional knowledge
        ├── constitution.md        # Core constitutional principles (6 principles)
        ├── git-strategy.md        # Branch preservation, naming, workflow
        ├── github-pages-infrastructure.md  # .nojekyll requirements, protection
        ├── local-cicd.md          # Local-first workflows, zero-cost strategy
        ├── agent-file-integrity.md  # AGENTS.md symlinks, single source of truth
        ├── conversation-logging.md  # LLM logging requirements
        └── zero-cost-operations.md  # GitHub Actions cost monitoring
```

**Structure Decision**:

Selected **single project architecture** with multi-component internal structure for these reasons:

1. **Domain Alignment**: Terminal configuration is fundamentally a monolithic domain. Not a web app (no backend/frontend split needed), not mobile (no platform-specific structure needed).

2. **Modular Internal Organization**: Separation achieved through:
   - `scripts/` directory: 10+ fine-grained modules (each <250 lines, testable in <10s)
   - `manage.sh` unified CLI: Clean entry point for all operations
   - `.runners-local/`: Complete CI/CD infrastructure
   - `website/src/` vs `docs/`: Source vs build output separation

3. **Constitutional Compliance**:
   - 4-5 top-level directories (balanced nesting, not complex)
   - Maximum 2 levels deep from repo root
   - Clear separation reduces cognitive load

4. **Rejected Alternatives**:
   - **Monorepo with workspaces**: Overcomplicated for terminal config (would require package.json for every component)
   - **Separate repositories**: Tight coupling between components (install script needs docs build)
   - **Flat structure**: Already addressed in 001 refactor (root clutter reduced 40%)

**Implementation Status**:
- ✅ **Phase 1-3 Complete (24%)**: Module templates, foundational utilities (common, progress, backup), manage.sh infrastructure
- ⚠️ **Phase 4-7 Pending (76%)**: Modern web stack, modular scripts extraction, AI integration, advanced terminal productivity

---

## Implementation Roadmap

### Phase 0: Completed (Pre-Planning)

**Status**: ✅ COMPLETE

**Deliverables**:
- [x] research.md (9 research areas, all NEEDS CLARIFICATION resolved)
- [x] data-model.md (10 entities with validation rules, state transitions, relationships)
- [x] contracts/ (3 API specifications: CI/CD runner, installation display, quality gates)
- [x] quickstart.md (developer onboarding guide)
- [x] Agent context updated (.specify/scripts/bash/update-agent-context.sh)

**Key Decisions**:
- Latest stable versions policy (not LTS) for all technologies
- DaisyUI for UI (shadcn/ui deferred for future customization needs)
- Parallel task installation UI (like Claude Code)
- Automated accessibility (axe-core) + security (npm audit) testing
- Local GitHub Actions runner infrastructure for zero-cost automation
- fnm for Node.js (40x faster startup than nvm)

---

### Phase 4: Modern Web Stack Integration

**Priority**: P1 (Parallel with Phase 5)

**Objective**: Integrate uv (Python), enhance Astro + Tailwind + DaisyUI, implement quality automation.

**Tasks**:

**T4.1**: Install and Configure uv (Python Package Manager)
- Install uv >=0.9.0 (latest stable)
- Create example automation scripts demonstrating uv usage
- Document uv workflows in developer guides
- Success criteria: uv installed, example scripts functional

**T4.2**: Upgrade Astro to 5.0+ (Latest Stable)
- Update Astro dependencies to >=5.0
- Verify TypeScript strict mode (>=5.9)
- Test existing documentation site builds
- Success criteria: Astro >=5.0, site builds without errors

**T4.3**: Upgrade Tailwind CSS to 4.0+ with DaisyUI
- Update Tailwind to >=4.0 (latest stable)
- Integrate DaisyUI (latest stable) for component library
- Configure dark mode with class-based strategy
- Document design token system
- Success criteria: Tailwind 4+, DaisyUI integrated, dark mode functional

**T4.4**: Implement Automated Accessibility Testing
- Install axe-core CLI for WCAG 2.1 Level AA testing
- Integrate Lighthouse CI for automated accessibility scoring
- Create quality gate script: `.runners-local/workflows/quality-gates.sh`
- Configure blocking gate: Zero violations required for deployment
- Success criteria: SC-045, SC-046, SC-047 (axe-core + Lighthouse >=95)

**T4.5**: Implement Automated Security Scanning
- Integrate npm audit into local CI/CD workflows
- Create dependency vulnerability checking script
- Configure blocking gate: Zero high/critical vulnerabilities
- Document security scanning workflows
- Success criteria: SC-048, SC-049 (zero high/critical vulnerabilities)

**T4.6**: Implement Local GitHub Actions Runner Infrastructure
- Create Docker-based runner environment
- Implement workflow simulation scripts
- Support matrix builds and workflow dependencies
- Document runner setup and usage
- Success criteria: FR-031, FR-032, SC-050, SC-051 (100% workflow fidelity)

**Dependencies**: None (can run in parallel with Phase 5)

**Estimated Effort**: 1 week

**Success Criteria**:
- uv >=0.9.0 installed with example scripts
- Astro >=5.0, Tailwind >=4.0, DaisyUI integrated
- Lighthouse scores 95+ (SC-013, SC-025, SC-047)
- axe-core zero violations (SC-045, SC-046)
- npm audit zero high/critical (SC-048, SC-049)
- Local GitHub Actions runner functional (SC-050, SC-051)

---

### Phase 5: Modular Scripts Extraction

**Priority**: P1 (Foundation for all features)

**Objective**: Refactor monolithic `start.sh` into 10+ focused, testable modules.

**Tasks**:

**T5.1**: Extract Node.js Installation Module (`scripts/install_node.sh`)
- Implement fnm installation (Fast Node Manager)
- Install Node.js latest stable (v25.2.0+, NOT LTS)
- Configure fnm auto-switching (.zshrc integration)
- Support per-project versions via .nvmrc
- Create unit tests (<10s execution)
- Success criteria: FR-060, FR-061, FR-062, FR-063, SC-015

**T5.2**: Extract Ghostty Installation Module (`scripts/install_ghostty.sh`)
- Install build dependencies (Zig 0.14.0, libxkbcommon)
- Clone Ghostty repository, build from source
- Configure `linux-cgroup=single-instance` (MANDATORY)
- Install shell integration (auto-detection)
- Create unit tests (<10s)
- Success criteria: Ghostty installed, <500ms startup (SC-011)

**T5.3**: Extract AI Tools Installation Module (`scripts/install_ai_tools.sh`)
- Install Claude Code (@anthropic-ai/claude-code latest)
- Install Gemini CLI (@google/gemini-cli latest)
- Install GitHub Copilot CLI (@github/copilot latest)
- Configure multi-provider fallbacks
- Create unit tests (<10s)
- Success criteria: FR-040, FR-041, FR-042, FR-043, FR-044, FR-045

**T5.4**: Extract Unix Tools Installation Module (`scripts/install_unix_tools.sh`)
- Install bat, exa, ripgrep, fd, zoxide, fzf
- Configure shell aliases and integrations
- Create unit tests (<10s)
- Success criteria: FR-053, all tools installed and functional

**T5.5**: Extract ZSH Plugins Module (`scripts/install_zsh_plugins.sh`)
- Install Oh My ZSH (latest)
- Configure productivity plugins (git, zsh-autosuggestions, zsh-syntax-highlighting)
- Implement lazy loading for performance
- Create unit tests (<10s)
- Success criteria: Plugins installed, <50ms shell startup contribution

**T5.6**: Extract Shell Configuration Module (`scripts/configure_shell.sh`)
- Configure .zshrc with performance optimizations
- Implement lazy loading, compilation caching, deferred initialization
- Support theme configuration (Powerlevel10k/Starship optional)
- Create unit tests (<10s)
- Success criteria: FR-050, FR-051, FR-052, SC-010 (shell startup <50ms)

**T5.7**: Extract Context Menu Module (`scripts/setup_context_menu.sh`)
- Install Nautilus context menu integration
- Create "Open in Ghostty" action
- Test on Ubuntu 25.10 GNOME
- Create unit tests (<10s)
- Success criteria: Context menu functional

**T5.8**: Extract Validation Module (`scripts/validate_environment.sh`)
- Implement system checks (Ubuntu version, passwordless sudo, disk space, network)
- Validate component installations
- Performance measurement (shell startup, Ghostty startup, Lighthouse scores)
- Create unit tests (<10s)
- Success criteria: Comprehensive validation, clear error messages

**T5.9**: Extract Update Module (`scripts/update_components.sh`)
- Implement smart update detection (detect changes vs reinstall everything)
- Preserve user customizations (FR-074)
- Create automatic backups before updates (FR-075)
- Rollback on failure (FR-076)
- Create unit tests (<10s)
- Success criteria: FR-070 through FR-076, SC-032 (zero data loss)

**T5.10**: Integrate Modules into manage.sh
- Wire all modules into manage.sh install command
- Implement dependency ordering (topological sort)
- Configure parallel task UI (FR-006, FR-007, FR-008)
- Test complete installation workflow
- Success criteria: All modules integrated, <10min fresh install (SC-001)

**Dependencies**: Phase 1-3 foundational utilities already complete

**Estimated Effort**: 2-3 weeks

**Success Criteria**:
- 10+ fine-grained modules created
- Each module <250 lines, testable in <10s (SC-015, SC-030)
- All modules independently testable (SC-030)
- Complete installation in <10 minutes (SC-001)
- Parallel task UI functional (SC-025, SC-026, SC-027, SC-028)

---

### Phase 6: AI Integration Enhancement

**Priority**: P2 (After Phase 5 modules)

**Objective**: Complete AI tool integration with context-aware assistance.

**Tasks**:

**T6.1**: Configure Multi-Provider AI Assistance
- Set up provider fallbacks (OpenAI, Anthropic, Google)
- Configure environment variables (.env template)
- Document API key management
- Success criteria: FR-044 (multi-provider support)

**T6.2**: Implement Context-Aware Command Assistance
- Integrate current directory awareness
- Add Git state detection
- Implement recent command history analysis
- Success criteria: FR-045 (context awareness)

**T6.3**: Configure zsh-codex for Natural Language Translation
- Install and configure zsh-codex
- Set up keybindings
- Create usage examples
- Success criteria: FR-042 (natural language to command)

**T6.4**: Document AI Integration Workflows
- Create user guides for each AI tool
- Document context-aware features
- Provide troubleshooting guides
- Success criteria: Comprehensive AI documentation

**Dependencies**: Phase 5 (AI tools module installed)

**Estimated Effort**: 1 week

**Success Criteria**:
- Multi-provider AI support (FR-044)
- Context-aware assistance (FR-045)
- Command lookup time reduced 30-50% (SC-023)

---

### Phase 7: Advanced Terminal Productivity

**Priority**: P2 (After Phase 5 modules + Phase 6 AI)

**Objective**: Implement advanced theming, performance optimization, and team features.

**Tasks**:

**T7.1**: Implement Advanced Theme Support
- Provide Powerlevel10k and Starship configuration options
- Create instant-rendering optimizations
- Add customizable segments and adaptive behavior
- Success criteria: FR-050, SC-077 (<50ms prompt render)

**T7.2**: Performance Optimization
- Implement compilation caching (.zshrc → bytecode)
- Configure intelligent lazy loading
- Set up deferred initialization
- Create performance profiling tools
- Success criteria: FR-051, FR-052, SC-010 (shell startup <50ms)

**T7.3**: Startup Time Profiling and Monitoring
- Create profiling scripts (zprof integration)
- Generate startup time breakdown reports
- Provide optimization recommendations
- Success criteria: FR-054, detailed profiling available

**T7.4**: Team Configuration Features
- Create shareable configuration templates
- Implement individual customization preservation
- Document team adoption workflows
- Success criteria: FR-055, SC-060, SC-061, SC-062

**Dependencies**: Phase 5 (shell configuration module), Phase 6 (AI tools)

**Estimated Effort**: 1 week

**Success Criteria**:
- Shell startup <50ms (SC-010)
- Prompt rendering <50ms (SC-077)
- Team configuration compliance >90% (SC-060)
- Individual customizations preserved (SC-061)
- New member setup time reduced 70% (SC-062)

---

### Phase 8: Testing and Validation

**Priority**: P1 (Continuous, throughout implementation)

**Objective**: Ensure all components meet quality, performance, and constitutional requirements.

**Tasks**:

**T8.1**: Module Unit Tests
- Create unit tests for each module (10+ modules)
- Each test must complete in <10s (SC-015)
- Use bats framework for consistency
- Success criteria: 100% module coverage, all tests <10s

**T8.2**: Integration Testing
- Test complete installation workflow
- Verify component interactions
- Test update and rollback scenarios
- Success criteria: End-to-end workflows functional

**T8.3**: Performance Testing
- Measure shell startup time (<50ms target)
- Measure Ghostty startup (<500ms target)
- Run Lighthouse CI (95+ scores target)
- Monitor CI/CD performance (<2min target)
- Success criteria: All performance targets met

**T8.4**: Quality Gate Testing
- Run axe-core accessibility tests (zero violations)
- Run npm audit security scans (zero high/critical)
- Verify Lighthouse scores (95+ all metrics)
- Success criteria: All quality gates pass

**T8.5**: Constitutional Compliance Verification
- Verify branch preservation (no delete commands)
- Check .nojekyll file (4 protection layers)
- Validate local CI/CD first (pre-commit hooks)
- Verify agent file integrity (AGENTS.md symlinks)
- Monitor GitHub Actions usage (MUST be 0)
- Success criteria: All 6 constitutional principles compliant

**Dependencies**: Each phase's implementation

**Estimated Effort**: Continuous throughout (1 week focused validation at end)

**Success Criteria**:
- All unit tests pass (<10s each)
- Integration tests pass
- Performance targets met (SC-010 through SC-015)
- Quality gates pass (SC-045 through SC-049)
- Constitutional compliance 100%

---

### Phase 9: Documentation and Deployment

**Priority**: P1 (Final phase)

**Objective**: Complete documentation and deploy to production.

**Tasks**:

**T9.1**: Update User Documentation
- Installation guides (fresh install, updates)
- Configuration guides (Ghostty, ZSH, AI tools)
- Troubleshooting guides (common issues, debugging)
- Success criteria: User documentation complete and tested

**T9.2**: Update Developer Documentation
- Architecture documentation (repository structure, data model)
- Contributing guides (development workflow, testing)
- AI guidelines (agent instructions, conversation logging)
- Success criteria: Developer documentation complete

**T9.3**: Build Documentation Site
- Run Astro build (website/ → docs/)
- Verify .nojekyll file present (CRITICAL)
- Run Lighthouse CI (95+ scores)
- Run axe-core (zero violations)
- Success criteria: Documentation site meets quality gates

**T9.4**: Final Local CI/CD Validation
- Run complete local workflow (./.runners-local/workflows/gh-workflow-local.sh all)
- Verify <2 minute execution
- Check GitHub Actions usage (MUST be 0)
- Success criteria: Local CI/CD passes, zero cloud consumption

**T9.5**: Deploy to GitHub Pages
- Commit docs/ directory
- Push to main branch
- Verify GitHub Pages deployment
- Test site in production (https://username.github.io/repo/)
- Success criteria: Site live, all assets loading, HTTPS working

**Dependencies**: All previous phases complete

**Estimated Effort**: 1 week

**Success Criteria**:
- Documentation comprehensive and accurate
- Documentation site deployed (GitHub Pages)
- Lighthouse 95+ all metrics (SC-013, SC-025, SC-047)
- Zero GitHub Actions consumption (constitutional)

---

## Risks and Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Performance Targets Missed** (<50ms shell, <500ms Ghostty) | Medium | High | Incremental optimization with profiling tools, lazy loading, compilation caching. Baseline early, iterate. |
| **Quality Gate Failures** (Lighthouse <95, axe-core violations) | Low | High | Automated testing in local CI/CD catches issues early. Astro + DaisyUI optimized for accessibility. |
| **Module Dependencies** (circular references, complex ordering) | Low | Medium | Topological sort for dependency ordering. Dependency graph validation in module contract tests. |
| **User Customization Loss** during migration/updates | Medium | High | Automatic backup before changes (FR-075). Hash-based diff detection. User customization preservation logic (FR-074). |
| **GitHub Actions Accidental Consumption** | Low | Medium | CI/CD workflow entity (E5) tracks usage. Quality gate blocks if minutes >0. Monitoring dashboard alerts. |
| **.nojekyll File Deletion** (CRITICAL) | Low | Critical | 4 protection layers (public/, Vite plugin, validation, hooks). Build artifact entity (E4) validates presence. Quality gate blocks deployment if missing. |
| **Installation Failures** on non-25.10 Ubuntu | Medium | Low | Dynamic version detection (not hardcoded). Warnings for unsupported versions. Community testing on multiple versions. |
| **shellcheck/bats Test Maintenance** | Low | Medium | Keep modules small (<250 lines). Independent testability (<10s per module). Automated contract validation. |

---

## Next Steps

### Immediate Actions (Post-Planning)

1. **Generate tasks.md** using `/speckit.tasks` command
   - Break down each phase into concrete, dependency-ordered tasks
   - Assign task IDs (T001-TXXX)
   - Specify deliverables and acceptance criteria
   - Estimate effort per task

2. **Create Implementation Branch**
   ```bash
   DATETIME=$(date +"%Y%m%d-%H%M%S")
   git checkout -b "${DATETIME}-feat-phase-4-5-implementation"
   ```

3. **Begin Phase 4 & 5 in Parallel**
   - Phase 4: Modern web stack integration
   - Phase 5: Modular scripts extraction (foundation)

4. **Set Up Tracking**
   - Create GitHub project board for task tracking
   - Configure performance dashboard (.runners-local/)
   - Set up quality gate monitoring

### Long-Term Roadmap

**Month 1** (Weeks 1-4):
- Weeks 1-2: Phase 4 (Modern web stack) + Phase 5 Tasks 1-5 (Node, Ghostty, AI tools, Unix tools, ZSH plugins)
- Weeks 3-4: Phase 5 Tasks 6-10 (Shell config, context menu, validation, update, integration)

**Month 2** (Weeks 5-8):
- Weeks 5-6: Phase 6 (AI integration enhancement) + Phase 7 (Advanced terminal productivity)
- Weeks 7-8: Phase 8 (Testing and validation) - comprehensive quality assurance

**Month 3** (Weeks 9-12):
- Weeks 9-10: Phase 9 (Documentation and deployment)
- Weeks 11-12: Buffer for refinement, community testing, bug fixes

**Total Estimated Effort**: 4-6 weeks for complete implementation across all phases

---

**Planning Status**: ✅ COMPLETE - All sections filled, constitutional compliance verified, ready for /speckit.tasks

**Implementation Readiness**:
- Phase 1-3: ✅ COMPLETE (24% - foundational infrastructure)
- Phase 4-9: ⚠️ PLANNED (76% - ready for execution)

**Key Success Factors**:
- Modular architecture enables independent development and testing
- Automated quality gates enforce standards continuously
- Performance targets measurable and achievable with profiling
- Constitutional compliance baked into all workflows
- Parallel execution strategy reduces total implementation time
