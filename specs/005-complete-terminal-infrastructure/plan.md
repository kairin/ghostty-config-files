# Implementation Plan: Complete Terminal Development Infrastructure

**Branch**: `005-complete-terminal-infrastructure` | **Date**: 2025-11-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-complete-terminal-infrastructure/spec.md`

**Note**: This plan consolidates three related features (001, 002, 004) into unified terminal development infrastructure with modern web tooling, AI integration, and local CI/CD.

## Summary

Provide a single-command setup (`./manage.sh install`) for a complete, production-ready terminal environment on Ubuntu 25.10, integrating Ghostty with 2025 optimizations, ZSH + modern Unix tools, AI assistance (Claude Code, Gemini CLI, GitHub Copilot), Astro.build documentation with zero-cost GitHub Pages deployment, and local CI/CD infrastructure. The system uses latest stable versions (not LTS) across all technologies, achieves sub-50ms shell startup, provides parallel task UI for installations, and maintains modular architecture with fine-grained testable modules.

## Technical Context

**Language/Version**:
- Bash 5.x+ (shell scripts with YAML/Markdown processing via yq/jq)
- TypeScript >=5.9 (strict mode for Astro.build)
- Python >=3.11 (via uv >=0.9.0 for package management)
- Node.js latest stable for global installations (currently v25.2.0+ via fnm, with per-project version support via .nvmrc)
- Zig 0.14.0 (for Ghostty compilation from source)

**Primary Dependencies**:
- **Terminal**: Ghostty (latest source), ZSH + Oh My ZSH, Nautilus (context menu integration)
- **Node.js Management**: fnm (Fast Node Manager, <50ms startup impact)
- **AI Tools**: Claude Code (@anthropic-ai/claude-code), Gemini CLI (@google/gemini-cli), GitHub Copilot CLI
- **Modern Unix**: bat, exa, ripgrep, fd, zoxide, fzf
- **Web Stack**: Astro >=5.0, Tailwind CSS >=4.0, DaisyUI (latest), uv >=0.9.0
- **CI/CD**: GitHub CLI (gh), local workflow runners, Lighthouse CI, axe-core, npm audit
- **Optional Theming**: Powerlevel10k or Starship

**Storage**:
- File-based configuration (Ghostty config, ZSH dotfiles, dircolors)
- JSON state files (/tmp/ghostty-start-logs/*.json, .runners-local/logs/*.json)
- Git repository (branch history, conversation logs)
- Astro.build static output (docs/ directory for GitHub Pages)

**Testing**:
- **Shell Scripts**: shellcheck (linting), bats (Bash Automated Testing System)
- **Modules**: Isolated validation (<10s per module), contract validation, dependency checking
- **Web**: Lighthouse CI (performance/accessibility), axe-core (WCAG 2.1 Level AA with manual review process for "incomplete" checks: document check ID, context, manual verification steps, and resolution in accessibility audit log), npm audit (security)
- **Integration**: Local GitHub Actions simulation, complete CI/CD pipeline validation

**Accessibility Testing Protocol**:
- **Automated**: axe-core detects violations (critical/serious/moderate/minor) and incomplete checks requiring manual review
- **Manual Review Process for "Incomplete" Checks**:
  1. Document check ID, element selector, and context in `.runners-local/logs/accessibility/incomplete-checks.md`
  2. Manually verify compliance using browser DevTools and WCAG 2.1 guidelines
  3. Record verification steps, result (pass/fail), and remediation actions
  4. Update incomplete-checks.md with resolution status and date
  5. Re-run axe-core to confirm automated detection after fixes
- **Severity Thresholds**: Critical (blocks deployment), Serious (warning + manual review), Moderate/Minor (logged for future improvement)

**Target Platform**: Ubuntu 25.10 (Questing) with Ghostty 1.1.4+ (1.2.0 upgrade planned)

**Project Type**: Hybrid - Shell-based infrastructure management + Web application (Astro documentation site)

**Performance Goals**:
- Shell startup: <50ms (vs ~200ms average)
- Ghostty startup: <500ms (CGroup single-instance optimization)
- Documentation build: <2 minutes (Astro production build)
- Lighthouse scores: 95+ (Performance, Accessibility, Best Practices, SEO)
- JavaScript bundles: <100KB initial load
- Module tests: <10s each (isolated execution)
- Local CI/CD: <2 minutes (complete workflow)

**Performance Baseline Metrics** (for T127-T134 monitoring):
- **Shell Startup Components**:
  - ZSH initialization: <20ms (core shell loading)
  - Oh My ZSH framework: <15ms (plugin manager overhead)
  - Plugin loading: <10ms total (git, zsh-autosuggestions, zsh-syntax-highlighting, fzf)
  - Theme rendering: <5ms (Powerlevel10k/Starship prompt generation)
  - Total target: <50ms (sum of all components)
- **Memory Footprint**:
  - Ghostty baseline: <100MB (with optimized scrollback)
  - ZSH session: <50MB (including plugins and theme)
  - Node.js tools: <200MB (fnm + npm globals)
- **Compilation Caching**:
  - First run: No cache, measure uncached time
  - Subsequent runs: Cache hit rate >90%, speedup >2x
- **Monitoring Frequency**: Daily performance snapshots, weekly regression analysis

**Constraints**:
- Zero-cost operations (no GitHub Actions consumption)
- Latest stable versions policy (not LTS)
- Passwordless sudo required for apt operations
- GitHub Pages deployment with .nojekyll file MANDATORY
- Branch preservation (never delete without explicit permission)
- Local CI/CD validation before any GitHub deployment
- Memory: <100MB baseline (Ghostty with optimized scrollback)

**Scale/Scope**:
- 18 fine-grained shell modules (single responsibility: install_node, install_ghostty, install_ai_tools, install_modern_tools, configure_zsh, install_uv, install_theme, configure_dircolors, check_updates, daily-updates, backup_utils, validate_modules, common, progress, task_display, task_manager, verification, profile_startup)
- 4 user stories with 76 functional requirements
- 62 success criteria with measurable outcomes
- 3 consolidated feature specs (001, 002, 004)
- Documentation site with 5+ sections (user-guide, ai-guidelines, developer)
- 38 local branches (constitutional preservation), 126 remote branches
- Zero GitHub Actions minutes consumed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Branch Preservation & Git Strategy ✅ PASS
- **Requirement**: Never delete branches without explicit user permission
- **Implementation**: Constitutional branch workflow with timestamped naming (YYYYMMDD-HHMMSS-type-description)
- **Status**: COMPLIANT - Spec 005 uses branch `005-complete-terminal-infrastructure`, all feature branches preserved
- **Verification**: 38 local branches, 126 remote branches maintained per constitutional requirement

### II. GitHub Pages Infrastructure Protection ✅ PASS
- **Requirement**: `.nojekyll` file ABSOLUTELY CRITICAL in docs/ directory
- **Implementation**: FR-011, FR-012 mandate .nojekyll file with multi-layer protection (Astro public/, Vite plugin, post-build validation, pre-commit hooks)
- **Status**: COMPLIANT - Astro configuration ensures .nojekyll deployment, post-build validation scripts verify presence
- **Verification**: docs/.nojekyll checked by local CI/CD before every deployment (SC-044)

### III. Local CI/CD First ✅ PASS
- **Requirement**: ALL configuration changes validate locally before GitHub deployment
- **Implementation**: FR-024, FR-027, FR-031, FR-032 mandate local CI/CD execution with complete workflow simulation
- **Status**: COMPLIANT - Every change runs `.runners-local/workflows/gh-workflow-local.sh local` before GitHub operations
- **Verification**: SC-040, SC-041, SC-050, SC-051 ensure zero GitHub Actions consumption with local validation

### IV. Agent File Integrity ✅ PASS
- **Requirement**: AGENTS.md is single source of truth, CLAUDE.md and GEMINI.md must be symlinks
- **Implementation**: Symlink integrity verification in local CI/CD workflows
- **Status**: COMPLIANT - CLAUDE.md → AGENTS.md symlink recently restored (commit 8561042)
- **Verification**: readlink validation in pre-commit hooks and local workflows

### V. LLM Conversation Logging ✅ PASS
- **Requirement**: Complete conversation logs with system state snapshots
- **Implementation**: documentations/development/conversation_logs/ with CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md naming
- **Status**: COMPLIANT - Infrastructure exists, directory created and tracked
- **Verification**: Conversation logging infrastructure deployed and tested

### VI. Zero-Cost Operations ✅ PASS
- **Requirement**: No GitHub Actions minutes consumed for routine operations
- **Implementation**: FR-024, FR-041 mandate local CI/CD for all validation, SC-041 targets zero Actions consumption
- **Status**: COMPLIANT - All CI/CD workflows execute locally, GitHub Actions used only for Pages deployment (free tier)
- **Verification**: `gh api user/settings/billing/actions` monitoring confirms 0 minutes/month consumption

### Constitutional Compliance Summary

**Overall Status**: ✅ **PASS** - All 6 constitutional principles satisfied

**Key Strengths**:
- Local-first CI/CD strategy eliminates GitHub Actions consumption
- Multi-layer .nojekyll protection prevents deployment failures
- Branch preservation maintains complete configuration history
- Modular architecture supports independent testing and validation

**Risk Areas**: None identified - all constitutional requirements met at specification level

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Shell-based Infrastructure Management
manage.sh                           # Unified CLI entry point (FR-001, FR-002)
start.sh                            # Legacy wrapper → manage.sh install (FR-004)

scripts/                            # Fine-grained modules (FR-013, 10+ modules)
├── install_node.sh                # Node.js via fnm (FR-060, FR-061)
├── install_ghostty.sh             # Ghostty from source with Zig (FR-060)
├── install_ai_tools.sh            # Claude Code, Gemini CLI, Copilot (FR-040-043)
├── install_modern_tools.sh        # bat, exa, ripgrep, fd, zoxide (FR-053)
├── configure_zsh.sh               # Oh My ZSH + plugins (FR-051)
├── configure_dircolors.sh         # XDG-compliant dircolors (FR-055)
├── install_theme.sh               # Powerlevel10k/Starship (FR-050)
├── check_updates.sh               # Smart update detection (FR-074)
├── daily-updates.sh               # Automated daily updates
├── backup_utils.sh                # Backup before changes (FR-075)
├── validate_modules.sh            # Module dependency validation (FR-016)
├── check_context7_health.sh       # Context7 MCP health check
├── check_github_mcp_health.sh     # GitHub MCP health check
├── common.sh                      # Shared utilities (FR-015)
└── progress.sh                    # Parallel task UI (FR-006, FR-007)

configs/                           # Configuration templates
├── ghostty/                       # Ghostty config, themes, dircolors
│   ├── config                     # Main Ghostty configuration
│   ├── themes/                    # Theme files (Catppuccin, etc.)
│   └── dircolors                  # XDG-compliant dircolors
└── workspace/                     # Team configuration templates (FR-055)

# Web Application (Astro Documentation Site)
website/                           # Astro source (FR-010, FR-021)
├── src/                          # Source documentation (FR-010)
│   ├── pages/                    # Markdown pages → HTML
│   ├── components/               # Astro/React components
│   ├── layouts/                  # Page layouts
│   └── styles/                   # Tailwind CSS + DaisyUI (FR-022)
├── public/                       # Static assets + .nojekyll (FR-011)
│   └── .nojekyll                 # CRITICAL for GitHub Pages (FR-012)
├── astro.config.mjs              # Astro configuration (FR-021)
├── tailwind.config.js            # Tailwind CSS >=4.0 (FR-022)
├── tsconfig.json                 # TypeScript >=5.9 strict mode (FR-021)
└── package.json                  # Node.js dependencies

docs/                             # Astro build output → GitHub Pages (FR-011, FR-012)
├── .nojekyll                     # MANDATORY - copied from public/ (FR-012)
├── index.html                    # Generated site
├── _astro/                       # Bundled assets (CSS, JS)
└── [static pages]/               # All documentation pages

# Local CI/CD Infrastructure
.runners-local/                   # Local GitHub Actions simulation (FR-031, FR-032)
├── workflows/                    # Workflow execution scripts
│   ├── gh-workflow-local.sh      # Local workflow runner (FR-027)
│   ├── astro-build-local.sh      # Astro build workflows
│   ├── performance-monitor.sh    # Performance tracking
│   └── gh-pages-setup.sh         # GitHub Pages setup + .nojekyll validation
├── tests/                        # Complete test infrastructure
│   ├── contract/                 # Contract validation (FR-016)
│   ├── unit/                     # Module unit tests (FR-015, <10s each)
│   ├── integration/              # Integration tests (FR-024)
│   └── validation/               # Accessibility (FR-029), security (FR-030)
└── logs/                         # CI/CD execution logs (GITIGNORED)

# Documentation Hub
documentations/                   # Centralized documentation
├── user/                        # End-user documentation
├── developer/                   # Developer guides (architecture, contributing)
├── specifications/              # Feature specs (this is Spec 005)
└── development/                 # Development artifacts
    ├── conversation_logs/       # LLM conversation logs (Constitutional Req V)
    ├── system_states/           # System state snapshots
    └── ci_cd_logs/             # Local CI/CD logs

# Spec-Kit Workflow Infrastructure
.specify/                        # Spec-kit scripts and templates
├── scripts/bash/                # Workflow automation
│   ├── setup-plan.sh           # Planning workflow setup
│   ├── create-new-feature.sh   # Feature creation
│   ├── update-agent-context.sh # Agent context sync
│   └── common.sh               # Shared spec-kit utilities
├── templates/                   # Spec-kit templates
│   ├── plan-template.md        # Implementation plan template
│   └── commands/               # Slash command templates
└── memory/                      # Agent memory (constitution, tech stack, etc.)

# AI Agent Instructions
AGENTS.md                        # Single source of truth (Constitutional Req IV)
CLAUDE.md → AGENTS.md            # Symlink (MANDATORY)
GEMINI.md → AGENTS.md            # Symlink (MANDATORY)

# Environment Configuration
.env                            # API keys (Context7, GitHub MCP) - GITIGNORED
.gitignore                      # Git exclusions
README.md                       # User-facing documentation
```

**Structure Decision**:

This is a **Hybrid Infrastructure + Web Application** project combining:

1. **Shell-based Infrastructure Management**: Root-level scripts (manage.sh, start.sh) orchestrate fine-grained modules in `scripts/` directory. Each module handles a single responsibility (Node.js, Ghostty, AI tools, themes) and is independently testable in <10s (FR-015).

2. **Web Application**: Astro.build documentation site with strict separation:
   - **Source**: `website/src/` (committed, editable markdown)
   - **Output**: `docs/` (committed for GitHub Pages with MANDATORY .nojekyll)
   - **Critical**: `.nojekyll` file in both `website/public/` and `docs/` prevents Jekyll processing

3. **Local CI/CD**: `.runners-local/` provides complete GitHub Actions simulation locally, ensuring zero GitHub Actions consumption while maintaining workflow fidelity.

4. **Documentation Hub**: `documentations/` centralizes all non-web documentation (user guides, developer guides, specifications, conversation logs).

5. **Spec-Kit Integration**: `.specify/` enables specification-driven development with planning workflows, feature creation, and agent context management.

**Key Architectural Decisions**:
- Modular shell scripts over monolithic start.sh (maintainability, testability)
- Source/output separation for documentation (website/src/ vs docs/)
- Local-first CI/CD (zero GitHub Actions cost)
- File-based storage (no database) with JSON state tracking
- Constitutional symlink structure (AGENTS.md ← CLAUDE.md, GEMINI.md)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: No constitutional violations detected. All complexity justified by functional requirements.

**Justifications** (for architectural decisions that add complexity):

| Decision | Why Needed | Simpler Alternative Rejected Because |
|----------|------------|-------------------------------------|
| Hybrid structure (shell + web) | Terminal infrastructure management requires shell scripts; documentation requires modern web tooling | Single technology insufficient: Shell can't generate performant static sites; Web frameworks can't manage system installations |
| 18 fine-grained modules | Independent testability (FR-015: <10s per module), maintainability, single responsibility principle | Monolithic start.sh already proven unmaintainable (current state); Refactoring enables incremental testing and deployment with precise module boundaries |
| Committed docs/ output | GitHub Pages requires committed build output; .nojekyll file MUST be in git history | Using separate gh-pages branch adds complexity and breaks local preview; Docs source/output separation (website/src vs docs/) is clearer |
| Local CI/CD infrastructure | Zero-cost operations (Constitutional Req VI); GitHub Actions free tier exhaustion risk | Cloud-only CI/CD consumes Actions minutes (2,000/month limit); Local validation prevents deployment failures |
| Multiple AI tools | Provider diversity (FR-044: OpenAI, Anthropic, Google); fallback resilience; different use cases (code vs. commands) | Single AI tool insufficient: Claude Code (code), Gemini CLI (commands), Copilot (suggestions) serve different workflows |

All complexity adds value through:
- **Testability**: Modular architecture enables <10s independent tests
- **Maintainability**: Single-responsibility modules reduce cognitive load
- **Cost-efficiency**: Zero GitHub Actions consumption via local CI/CD
- **Resilience**: Multi-provider AI fallbacks prevent single-point-of-failure
- **Performance**: Latest stable versions policy (not LTS) ensures cutting-edge features

---

## Post-Design Constitution Re-Evaluation

*Required after Phase 1 completion to verify design decisions don't introduce violations*

### Design Artifacts Generated
- ✅ research.md (23 KB, comprehensive technical decisions)
- ✅ data-model.md (32 KB, 10 entities with validation rules)
- ✅ contracts/ (3 OpenAPI 3.0.3 specs, 57 KB total)
- ✅ quickstart.md (11 KB, <5 minute onboarding guide)

### Constitutional Re-Check Results

#### I. Branch Preservation & Git Strategy ✅ MAINTAINED
**Design Impact**: No changes. Constitutional branch workflow remains enforced.
**Validation**: Branch `005-complete-terminal-infrastructure` follows `###-feature-name` pattern.

#### II. GitHub Pages Infrastructure Protection ✅ STRENGTHENED
**Design Impact**: IMPROVED - Multi-layer .nojekyll protection added:
1. Astro `public/.nojekyll` (source)
2. Vite plugin automation (build-time copy)
3. Post-build validation scripts (verification)
4. Pre-commit hooks (git-level enforcement)

**Rationale**: Constitutional requirement critical, so added redundant protection layers.

#### III. Local CI/CD First ✅ MAINTAINED
**Design Impact**: EXPANDED - Added comprehensive test infrastructure:
- Contract validation (FR-016)
- Accessibility testing (FR-029: axe-core, Lighthouse CI)
- Security scanning (FR-030: npm audit)
- Performance monitoring

**Validation**: All changes validate locally before GitHub deployment.

#### IV. Agent File Integrity ✅ MAINTAINED
**Design Impact**: No changes. AGENTS.md symlink structure preserved.
**Validation**: Agent context updated via `update-agent-context.sh claude`.

#### V. LLM Conversation Logging ✅ MAINTAINED
**Design Impact**: Infrastructure exists and ready for use.
**Note**: This conversation will be logged to `documentations/development/conversation_logs/`.

#### VI. Zero-Cost Operations ✅ STRENGTHENED
**Design Impact**: IMPROVED - Local CI/CD infrastructure formalized:
- `.runners-local/workflows/` with complete GitHub Actions simulation
- Performance monitoring and reporting
- Cost tracking via `gh api user/settings/billing/actions`

**Validation**: Zero GitHub Actions consumption target maintained.

### Final Compliance Status

**Overall**: ✅ **PASS** - All 6 constitutional principles maintained or strengthened

**Key Improvements**:
1. Multi-layer .nojekyll protection (Constitutional Req II)
2. Formalized local CI/CD infrastructure (Constitutional Req III, VI)
3. Comprehensive quality gates (accessibility, security, performance)

**No Violations Introduced**: Design decisions align with constitutional requirements. Complexity justified by functional requirements and constitutional compliance.

---

## Planning Phase Complete

**Phase 0 (Research)**: ✅ Complete
- research.md with all technical decisions documented
- All "NEEDS CLARIFICATION" items resolved

**Phase 1 (Design)**: ✅ Complete
- data-model.md with 10 entities and validation rules
- contracts/ with 3 OpenAPI 3.0.3 specifications
- quickstart.md with <5 minute onboarding guide
- Agent context updated (CLAUDE.md via update-agent-context.sh)

**Constitutional Compliance**: ✅ Verified
- All 6 principles maintained or strengthened
- No violations introduced by design decisions

**Next Steps**:
1. Execute `/speckit.tasks` to generate implementation tasks from this plan
2. Use parallel agent execution (4 agents, one per user story)
3. Estimated time: ~10 minutes (vs ~28 minutes sequential) = 64% faster

**Branch**: `005-complete-terminal-infrastructure`
**Date Completed**: 2025-11-16
**Ready for Implementation**: Yes
