# Feature Specification: Complete Terminal Development Infrastructure

**Feature Branch**: `005-complete-terminal-infrastructure`
**Created**: 2025-11-16
**Status**: Consolidated Draft
**Consolidated From**:
- 001-repo-structure-refactor (24% complete)
- 002-advanced-terminal-productivity (planning complete)
- 004-modern-web-development (planning complete)

**Input**: Consolidation of three related features into unified terminal development infrastructure:
1. Repository structure refactoring with manage.sh CLI and modular architecture
2. AI-powered terminal productivity with modern Unix tools and advanced theming
3. Modern web development stack with uv + Astro + Tailwind + shadcn/ui + GitHub Pages

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Development Environment (Priority: P1)

As a developer setting up a new development machine, I want a single command to install a complete, production-ready terminal environment with modern tools, AI assistance, and documentation infrastructure so that I can be productive immediately without manual configuration.

**Why this priority**: Delivers immediate value by providing zero-configuration setup. Combines the best of all three features into one cohesive experience that gets developers productive on day one.

**Independent Test**: Can be fully tested by running `./manage.sh install` on a fresh Ubuntu system and verifying all components (Ghostty, ZSH, Node.js, AI tools, modern Unix tools, documentation site) are installed and functional.

**Acceptance Scenarios**:

1. **Given** a fresh Ubuntu 25.10 installation, **When** I run `./manage.sh install`, **Then** I get a complete terminal environment with Ghostty, ZSH + Oh My Zsh, Node.js (latest via fnm), Claude Code, Gemini CLI, modern Unix tools (bat, exa, ripgrep, fd, zoxide), and local documentation site
2. **Given** I need AI assistance, **When** I use natural language commands with zsh-codex or GitHub Copilot CLI, **Then** I get accurate command suggestions with context awareness
3. **Given** I want to customize my setup, **When** I edit configuration files, **Then** the system preserves my customizations during updates
4. **Given** I need to validate my environment, **When** I run `./manage.sh validate`, **Then** all components are checked (Ghostty config, performance metrics, dependencies) and I get a comprehensive report

---

### User Story 2 - Modern Web Development Workflow (Priority: P1)

As a web developer building documentation sites and web projects, I want integrated modern web tooling (uv for Python, Astro for static sites, Tailwind CSS + shadcn/ui for UI) with local CI/CD validation so that I can build high-performance websites without ongoing costs while maintaining code quality.

**Why this priority**: Directly addresses the need for cost-effective, high-performance web development. Combines Python automation, modern frontend tooling, and zero-cost deployment into one workflow.

**Independent Test**: Can be fully tested by running `./manage.sh docs build`, verifying Lighthouse scores, checking bundle sizes, and validating GitHub Pages deployment without consuming GitHub Actions minutes.

**Acceptance Scenarios**:

1. **Given** I need to build documentation, **When** I run `./manage.sh docs build`, **Then** the Astro site builds with 95+ Lighthouse scores, sub-100KB bundles, and full accessibility compliance
2. **Given** I make code changes, **When** I commit, **Then** local CI/CD validates build quality, performance, and security before any GitHub operations
3. **Given** I want live development, **When** I run `./manage.sh docs dev`, **Then** I get hot module replacement with instant feedback
4. **Given** I need to deploy, **When** I push to GitHub, **Then** the site deploys to GitHub Pages with zero Actions consumption and HTTPS enforcement

---

### User Story 3 - Clear Architecture and Maintainability (Priority: P2)

As a repository maintainer extending functionality, I want a modular, well-documented architecture with clear separation between source and generated content so that I can understand, modify, and test components without navigating complex monolithic files.

**Why this priority**: Improves long-term maintainability and reduces cognitive load. Makes the repository approachable for contributors and ensures sustainable development.

**Independent Test**: Can be fully tested by verifying module independence, documentation clarity, and ability to modify individual components without affecting others.

**Acceptance Scenarios**:

1. **Given** I need to modify Node.js installation, **When** I look for the code, **Then** I find it in `scripts/install_node.sh` with clear contract, tests, and documentation
2. **Given** I want to add a new management command, **When** I create a new module, **Then** I can integrate it with minimal changes to manage.sh
3. **Given** I need to edit documentation, **When** I navigate the repository, **Then** I find all source docs in `website/src/` (committed) separate from build output in `docs/` (committed for GitHub Pages)
4. **Given** I want to understand the system, **When** I read the documentation, **Then** I have access to both user guides (installation, usage) and developer guides (architecture, AI guidelines, contributing)

---

### User Story 4 - Advanced Terminal Productivity (Priority: P2)

As a power user requiring maximum terminal efficiency, I want advanced theming (Powerlevel10k/Starship), performance optimizations (sub-50ms startup), and team collaboration features so that I have a professional terminal environment with rich information display and fast response times.

**Why this priority**: Enhances daily productivity for advanced users. Provides professional-grade terminal experience with measurable performance improvements.

**Independent Test**: Can be fully tested by measuring shell startup time, verifying theme rendering, and validating team configuration sharing.

**Acceptance Scenarios**:

1. **Given** I start a new shell, **When** the prompt loads, **Then** it renders in <50ms with rich Git status, directory information, and context awareness
2. **Given** I want a professional theme, **When** I configure Powerlevel10k or Starship, **Then** I get instant rendering with customizable segments and adaptive behavior
3. **Given** I work in a team, **When** I share configuration templates, **Then** team members can adopt standards while preserving individual customizations
4. **Given** I need performance analysis, **When** I run performance profiling, **Then** I get detailed startup time breakdowns and optimization recommendations

---

### Edge Cases

**Repository Structure**:
- What happens when manage.sh is called with an invalid subcommand? (Display help and exit with non-zero status)
- How does the system handle partial migrations where some modules are migrated while others remain in start.sh? (manage.sh detects and routes appropriately, logging legacy vs new)
- What happens if docs/.nojekyll file is accidentally removed? (Build process recreates it via public/ directory copy)

**Web Development**:
- What happens when local CI/CD validation fails? (Commit blocked with clear error messages)
- How does the system handle dependency updates? (Automated detection with local validation before deployment)
- What if GitHub Actions are accidentally triggered? (Monitoring alerts and usage tracking)

**Terminal Productivity**:
- What happens when AI services are unavailable? (Local fallbacks for command assistance)
- How does the system handle theme conflicts with existing configurations? (Backup and restore system, non-destructive installation)
- What if startup time exceeds performance targets? (Automatic detection and profiling recommendations)

**Team Collaboration**:
- How are existing start.sh customizations preserved during migration? (Extract and backup before migration, warning system)
- What happens when team configurations conflict with individual preferences? (Individual overrides preserved, team standards as defaults)
- How does the system handle different Node.js versions across projects? (fnm provides per-project version management via .nvmrc)

## Requirements *(mandatory)*

### Functional Requirements - Unified Management Interface

- **FR-001**: System MUST provide a single `manage.sh` entry point for all management operations (install, docs, update, validate)
- **FR-002**: manage.sh MUST support subcommands with contextual help and comprehensive error handling
- **FR-003**: manage.sh MUST display help when invoked with --help or invalid arguments
- **FR-004**: System MUST maintain backward compatibility by keeping start.sh as a wrapper to `manage.sh install`
- **FR-005**: Each management operation MUST support dry-run mode for validation before execution
- **FR-006**: Installation display MUST use parallel task UI with collapsible verbose output - each task on separate line, subtasks collapse into parent, screen remains clean
- **FR-007**: All installation steps MUST show dynamic status (not hardcoded messages) with proper verification methods
- **FR-008**: Task display MUST clearly show current step while keeping completed tasks visible in collapsed one-line format

### Functional Requirements - Repository Structure

- **FR-010**: All source documentation MUST reside in `website/src/` with clear separation from build output
- **FR-011**: Generated documentation MUST output to `docs/` directory for GitHub Pages deployment with mandatory .nojekyll file
- **FR-012**: docs/ directory MUST be committed with Astro build output including critical .nojekyll file to disable Jekyll processing
- **FR-013**: Monolithic start.sh script MUST be refactored into fine-grained modules (10+ modules) in scripts/ directory
- **FR-014**: Each module MUST handle a single, highly specific sub-task with independent testability
- **FR-015**: Modules MUST be sourceable and testable independently, completing in under 10 seconds when tested in isolation
- **FR-016**: System MUST validate module dependencies and prevent circular references

### Functional Requirements - Modern Web Development

- **FR-020**: System MUST provide Python dependency management exclusively through uv (>=0.9.0, latest stable) with installation validation
- **FR-021**: System MUST generate static sites using Astro.build (>=5.0, latest stable) with TypeScript strict mode (>=5.9)
- **FR-022**: System MUST provide UI components through DaisyUI (latest stable) with Tailwind CSS (>=4.0, latest stable) and full accessibility (shadcn/ui reserved for future consideration if deeper customization needed)
- **FR-023**: System MUST deploy to GitHub Pages with zero ongoing hosting costs
- **FR-024**: System MUST execute all CI/CD workflows locally before any GitHub operations
- **FR-025**: System MUST achieve Lighthouse scores of 95+ across all metrics (Performance, Accessibility, Best Practices, SEO)
- **FR-026**: System MUST maintain JavaScript bundle sizes under 100KB for initial load
- **FR-027**: System MUST provide local build simulation mirroring exact GitHub Actions environment
- **FR-028**: System MUST support dark mode with class-based strategy and consistent design tokens
- **FR-029**: System MUST implement automated accessibility testing (axe-core, Lighthouse CI) in local CI/CD for WCAG 2.1 Level AA compliance verification
- **FR-030**: System MUST implement automated security scanning (npm audit, dependency vulnerability checking) in local CI/CD workflows
- **FR-031**: System MUST provide local GitHub Actions runner infrastructure to execute ANY GitHub automation locally before cloud deployment
- **FR-032**: Local CI/CD MUST support all GitHub Actions workflows including custom actions, matrix builds, and workflow dependencies

### Functional Requirements - AI Integration

- **FR-040**: System MUST install and configure Claude Code (@anthropic-ai/claude-code) via npm
- **FR-041**: System MUST install and configure Gemini CLI (@google/gemini-cli) via npm
- **FR-042**: System MUST support zsh-codex for natural language to command translation
- **FR-043**: System MUST integrate GitHub Copilot CLI with existing gh setup
- **FR-044**: AI tools MUST support multiple providers (OpenAI, Anthropic, Google) with fallbacks
- **FR-045**: AI assistance MUST understand current directory, Git state, and recent command context

### Functional Requirements - Terminal Productivity

- **FR-050**: System MUST support advanced theme installation (Powerlevel10k and/or Starship)
- **FR-051**: System MUST achieve sub-50ms shell startup times through performance optimization
- **FR-052**: System MUST provide intelligent caching (compilation caching, lazy loading, deferred initialization)
- **FR-053**: System MUST install modern Unix tools (bat, exa, ripgrep, fd, zoxide, fzf)
- **FR-054**: System MUST provide startup time profiling and performance monitoring
- **FR-055**: System MUST support team configuration templates with individual customization preservation

### Functional Requirements - Node.js Management

- **FR-060**: System MUST install Node.js using fnm (Fast Node Manager) for <50ms startup impact
- **FR-061**: Global Node.js installations MUST use latest stable version (not LTS) per constitutional requirement
- **FR-062**: System MUST support per-project Node.js versions via .nvmrc or package.json engines field
- **FR-063**: fnm MUST be configured for automatic version switching on directory change
- **FR-064**: ALL technologies MUST use latest stable versions (not LTS) - applies to Astro, Tailwind, TypeScript, uv, npm packages

### Functional Requirements - Migration and Updates

- **FR-070**: Migration MUST follow incremental per-component approach (one module at a time)
- **FR-071**: Each migration increment MUST be independently testable and deployable
- **FR-072**: System MUST preserve existing directory structures (spec-kit/, .runners-local/, .specify/) during transition
- **FR-073**: All existing script functionality MUST be preserved in new structure
- **FR-074**: Update system MUST detect and preserve user customizations
- **FR-075**: System MUST provide automatic backup before configuration changes
- **FR-076**: Failed operations MUST trigger automatic rollback to previous working state

### Assumptions

- Repository follows nesting limits (maximum 2 levels deep) for maintainability
- Existing workflow structures (spec-kit/, .runners-local/, .specify/) remain functional during migration
- Incremental migration allows partial completion states
- Each migration increment can be validated independently
- docs/ directory exists as committed GitHub Pages deployment with critical .nojekyll file
- Shell environment is bash-compatible for module sourcing
- Passwordless sudo configured for apt package installation
- GitHub CLI authenticated for repository operations
- Latest stable versions policy: All technologies use latest stable (not LTS) per constitutional requirement

## Success Criteria *(mandatory)*

### Measurable Outcomes - Installation and Setup

- **SC-001**: Fresh Ubuntu 25.10 system fully configured in <10 minutes via `./manage.sh install`
- **SC-002**: All components install successfully on first attempt with clear progress reporting
- **SC-003**: Zero manual configuration required for standard setup
- **SC-004**: Installation creates automatic backups before any modifications

### Measurable Outcomes - Performance

- **SC-010**: Shell startup time <50ms (vs current ~200ms average)
- **SC-011**: Ghostty terminal startup <500ms with CGroup optimization
- **SC-012**: Documentation site build completes in same or better time vs current process
- **SC-013**: Astro site achieves Lighthouse scores 95+ across all metrics
- **SC-014**: JavaScript bundle sizes remain under 100KB for initial load
- **SC-015**: Each module tests independently in under 10 seconds

### Measurable Outcomes - User Experience

- **SC-020**: Developers execute any management task using `./manage.sh <command>` without referencing other scripts
- **SC-021**: New contributors find and edit documentation on first attempt
- **SC-022**: Time to locate and modify specific functionality reduced by 50%
- **SC-023**: AI command assistance reduces command lookup time by 30-50%
- **SC-024**: manage.sh --help displays all commands in under 2 seconds
- **SC-025**: Installation display shows parallel tasks on separate lines with collapsible verbose output
- **SC-026**: Each installation step uses dynamic verification (not hardcoded success messages)
- **SC-027**: Screen remains clean during installation - completed tasks collapse to single line
- **SC-028**: User can always see current step and overall progress without scrolling

### Measurable Outcomes - Architecture

- **SC-030**: All 10+ fine-grained modules tested independently in <10s each
- **SC-031**: Documentation clearly separated: source in website/src/, output in docs/
- **SC-032**: Zero data loss during migration (all scripts backed up)
- **SC-033**: Repository size remains manageable with committed docs/ output
- **SC-034**: Each incremental migration step completes within single development session

### Measurable Outcomes - Web Development

- **SC-040**: Local CI/CD validates all changes before GitHub operations
- **SC-041**: Zero GitHub Actions minutes consumed for routine development
- **SC-042**: Documentation site navigation accessible within 2 clicks from home
- **SC-043**: Hot module replacement provides instant feedback during development
- **SC-044**: GitHub Pages deployment succeeds with HTTPS enforcement
- **SC-045**: Automated accessibility testing runs in local CI/CD and reports WCAG 2.1 Level AA compliance status
- **SC-046**: All accessibility violations detected by axe-core are reported before deployment
- **SC-047**: Lighthouse accessibility score maintains 95+ throughout development
- **SC-048**: Automated security scanning detects vulnerable dependencies before deployment
- **SC-049**: npm audit reports zero high/critical vulnerabilities in production dependencies
- **SC-050**: Local GitHub Actions runner executes ALL workflows locally with 100% fidelity to cloud environment
- **SC-051**: Any GitHub automation can be tested and validated locally before cloud deployment

### Measurable Outcomes - Team Collaboration

- **SC-060**: Team configuration compliance >90% across members
- **SC-061**: Individual customizations preserved during team standard updates
- **SC-062**: Configuration sharing reduces new member setup time by 70%

## Clarifications

### Session 2025-11-16

- Q: Component library strategy - Should we use shadcn/ui (spec requirement) or DaisyUI (current implementation)? → A: Use Tailwind with DaisyUI; shadcn/ui reserved for future if needed
- Q: Python tooling scope - Implement uv now or document as future-ready? → A: Implement uv >=0.9.0 now with example automation scripts
- Q: Installation display requirements - How should parallel task installation be presented to users? → A: Parallel task UI like Claude Code - each task separate line, verbose subtasks collapse into parent, dynamic status with verification, keep screen clean and clear
- Q: Version requirements strategy - Use LTS or latest stable versions? → A: ALL technologies must use latest stable versions (not LTS) - Astro >=5.0, Tailwind >=4.0, TypeScript >=5.9, uv >=0.9.0, applies to all npm packages
- Q: Accessibility testing approach - Manual testing or automated in CI/CD? → A: Add automated accessibility testing (axe-core, Lighthouse CI) to local CI/CD workflows for continuous WCAG 2.1 Level AA compliance verification
- Q: Security scanning and local GitHub runners - Automate security or manual reviews? → A: Add automated security scanning (npm audit, dependency checking) AND full local GitHub Actions runner infrastructure to execute ANY GitHub automation locally before cloud deployment

### Original Clarifications from 001-repo-structure-refactor

**Session 2025-10-26**:
- Q: Overall Structure Complexity - For a "simple config project," what level of organization is most appropriate? → A: Balanced (4-5 top-level directories with shallow nesting)
- Q: Astro Site Scope and Purpose - What should the Astro site include? → A: Documentation + AI Guidelines
- Q: Handling Existing Complex Structures - How should spec-kit/, .runners-local/, .specify/ be handled? → A: Preserve all unchanged
- Q: Script Module Granularity - What level of granularity for script modules? → A: Fine-grained (10+ modules)
- Q: Migration Strategy and Rollout - What migration approach balances safety with progress? → A: Incremental per-component

### Consolidation Clarifications

**Session 2025-11-16**:
- Q: How do we handle three overlapping features? → A: Consolidate into single unified feature with clear component boundaries
- Q: What happens to existing 001 implementation (24% complete)? → A: Preserve and continue - all completed work (Phases 1-3) carries forward
- Q: Should we maintain all three original specs? → A: Yes, preserve for reference but make 005 the active specification
- Q: How do we prioritize components across three feature sets? → A: Terminal environment (P1), Web development (P1), Advanced productivity (P2), Modular architecture (P2)

## Current Reality (as of 2025-11-16)

### Completed from 001-repo-structure-refactor (24% Complete)

**Phase 1 - Setup & Validation Infrastructure** ✅ COMPLETE
- Module templates (.module-template.sh, .test-template.sh)
- Validation scripts (validate_module_contract.sh, validate_module_deps.sh)
- Testing framework (test_functions.sh, run_shellcheck.sh)
- .nojekyll protection system (4 layers)

**Phase 2 - Foundational Utilities** ✅ COMPLETE
- scripts/common.sh (315 lines, 15+ utility functions)
- scripts/progress.sh (377 lines, rich progress reporting)
- scripts/backup_utils.sh (347 lines, backup/restore system)
- .runners-local/tests/unit/test_common_utils.sh (547 lines, 20+ test cases)

**Phase 3 Core - manage.sh Infrastructure** ✅ COMPLETE
- manage.sh (517 lines, unified management interface)
- Full argument parsing and command routing
- Global options (--help, --version, --verbose, --quiet, --dry-run)
- Comprehensive error handling and cleanup

**Phase 3 Commands** ⚠️ FUNCTIONAL STUBS
- Install command: Interface complete, awaiting modules
- Docs commands: Stubs ready for Astro integration
- Update commands: Stubs ready for component modules
- Validate commands: Stubs ready for validation modules
- Screenshot commands: ❌ REMOVED (installation hangs, unnecessary complexity)

**Documentation Centralization** ✅ COMPLETE
- documentations/ hub structure with user/, developer/, specifications/, archive/
- website/src/ contains editable markdown (committed)
- docs/ contains Astro build output (committed for GitHub Pages)
- Critical docs/.nojekyll file committed for asset loading

**File Organization** ✅ COMPLETE
- Root directory clutter reduced 40% (22→14 files)
- Performance reports moved to documentations/performance/
- Comprehensive documentation created

### From 002-advanced-terminal-productivity

**Planning** ✅ COMPLETE
- Full specification with AI integration, theming, performance optimization, team features
- Component structure defined
- Implementation phases outlined

**Implementation** ⚠️ NOT STARTED
- AI integration pending
- Advanced theming pending
- Performance optimization pending
- Team features pending

### From 004-modern-web-development

**Planning** ✅ COMPLETE
- Full specification with uv, Astro, Tailwind, shadcn/ui, GitHub Pages
- Local CI/CD requirements defined
- Performance targets established

**Implementation** ⚠️ PARTIAL
- Astro already in use for documentation site
- docs/ deployment to GitHub Pages functional
- uv, Tailwind, shadcn/ui not yet integrated
- Local CI/CD infrastructure exists but needs web-specific workflows

### Implementation Status Summary

**Total Progress**: 24% (from 001 implementation)

**Completed Infrastructure**:
- ✅ Module system and templates
- ✅ Foundational utilities (common, progress, backup)
- ✅ manage.sh unified interface
- ✅ Documentation structure (website/src/ + docs/)
- ✅ Testing framework and validation

**Ready for Implementation**:
- ⚠️ Phase 5: Modular scripts (10+ modules from start.sh)
- ⚠️ Phase 4: Complete Astro integration with modern web stack
- ⚠️ AI integration (Claude Code, Gemini CLI, zsh-codex, Copilot CLI)
- ⚠️ Advanced theming (Powerlevel10k/Starship)
- ⚠️ Performance optimization (sub-50ms startup)
- ⚠️ Team collaboration features

## Implementation Dependencies

### Critical Path
1. **Phase 5 - Modular Scripts** (Foundation)
   - Extract start.sh into 10+ focused modules
   - Implement module contracts and tests
   - Integrate modules into manage.sh commands
   - Enables: All other features depend on clean module architecture

2. **Modern Web Stack Integration** (Parallel to Phase 5)
   - Install uv for Python dependency management
   - Integrate Tailwind CSS + shadcn/ui into Astro
   - Enhance local CI/CD for web-specific validations
   - Enables: Professional documentation site and developer tooling

3. **AI Integration** (After Modules)
   - Install Claude Code, Gemini CLI, zsh-codex, GitHub Copilot CLI
   - Configure multi-provider AI assistance
   - Set up context-aware command assistance
   - Depends on: Module system for clean installation scripts

4. **Advanced Terminal Productivity** (After Modules + AI)
   - Install Powerlevel10k or Starship themes
   - Implement performance optimizations (lazy loading, caching)
   - Add modern Unix tools (bat, exa, ripgrep, fd, zoxide)
   - Configure team collaboration features
   - Depends on: Module system and AI integration complete

### Parallel Workstreams

**Can run in parallel**:
- Phase 5 modular scripts + Modern web stack integration
- Documentation site enhancements + AI integration
- Performance optimization + Team collaboration features

**Must run sequentially**:
- Foundational modules → AI integration → Advanced theming
- Basic Astro → Tailwind/shadcn/ui → Component library

## Out of Scope

### Explicitly Excluded
- Screenshot capture functionality (removed from 001 due to installation hangs)
- Database integration (file-based configuration only)
- Windows/macOS support (Ubuntu 25.10 focus)
- Docker/container integration (future enhancement)
- Custom AI model training (uses existing providers)
- Warp Terminal integration (future consideration)
- Remote development optimization (future enhancement)

### Future Enhancements (Not in This Feature)
- Container development environments
- Remote development configurations
- Custom AI models trained on team patterns
- Multi-OS support (Windows, macOS)
- GUI configuration tools
- Browser extension integration

---

**Status**: Consolidated Draft - Ready for Clarification
**Next Command**: `/speckit.clarify` to validate consolidation and identify any gaps
**Priority**: P1 - Foundation for all terminal development workflows
**Estimated Effort**: 4-6 weeks for complete implementation across all components
