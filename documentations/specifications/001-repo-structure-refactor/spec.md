# Feature Specification: Repository Structure Refactoring

**Feature Branch**: `001-repo-structure-refactor`
**Created**: 2025-10-26
**Status**: Draft
**Input**: User description: "Consolidate scripts into manage.sh, restructure documentation to separate source from generated content, and improve modularity by breaking down monolithic files"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Management Interface (Priority: P1)

As a developer working on the Ghostty configuration repository, I want a single, intuitive entry point for all management tasks so that I can efficiently perform operations without hunting through multiple scripts or remembering complex command sequences.

**Why this priority**: This provides immediate value by simplifying the developer experience. A unified interface reduces cognitive load, improves discoverability, and establishes a foundation for future improvements. It delivers measurable productivity gains from day one.

**Independent Test**: Can be fully tested by running `./manage.sh <command>` for each subcommand (install, docs, update, validate) and verifying each operation completes successfully without referencing other scripts.

**Acceptance Scenarios**:

1. **Given** a fresh clone of the repository, **When** I run `./manage.sh --help`, **Then** I see a clear list of all available commands with descriptions
2. **Given** I need to install the terminal environment, **When** I run `./manage.sh install`, **Then** the system performs the complete installation without requiring additional script calls
3. **Given** I want to build documentation, **When** I run `./manage.sh docs build`, **Then** the Astro site builds successfully in the docs-dist directory
4. **Given** I want to validate my changes, **When** I run `./manage.sh validate`, **Then** all validation checks (config, performance, tests) execute and report results

---

### User Story 2 - Clear Documentation Structure (Priority: P2)

As a repository contributor, I want documentation source files clearly separated from generated build artifacts so that I can easily find and edit documentation without confusion about which files are source versus output.

**Why this priority**: This directly addresses maintainability issues that cause confusion and potential data loss. While not as immediately impactful as the unified interface, it prevents ongoing frustration and errors.

**Independent Test**: Can be fully tested by verifying that all source documentation lives in designated source directories, generated content lives only in docs-dist (gitignored), and documentation builds successfully from source.

**Acceptance Scenarios**:

1. **Given** I want to edit documentation, **When** I look in the repository, **Then** I find all source docs in clear source directories (not mixed with generated content)
2. **Given** I build the documentation site, **When** the build completes, **Then** all generated artifacts appear only in the docs-dist directory
3. **Given** I check git status after a doc build, **When** I run `git status`, **Then** the docs-dist directory does not appear (because it's gitignored)
4. **Given** I need to find AI guidelines, **When** I navigate the docs, **Then** I find modular, well-organized files instead of monolithic AGENTS.md
5. **Given** the repository is cloned fresh, **When** I look for build artifacts, **Then** docs-dist does not exist until I explicitly build

---

### User Story 3 - Modular Script Architecture (Priority: P3)

As a maintainer extending repository functionality, I want scripts broken into logical, focused modules so that I can understand, modify, and test individual components without navigating complex monolithic files.

**Why this priority**: This improves long-term maintainability but has less immediate user-facing impact. It's valuable for ongoing development but can be implemented incrementally after the primary interface and documentation improvements.

**Independent Test**: Can be fully tested by verifying that each module handles a single responsibility, can be tested in isolation, and integrates correctly through the manage.sh interface.

**Acceptance Scenarios**:

1. **Given** I need to modify Node.js installation, **When** I look for the code, **Then** I find it in a dedicated scripts/install_node.sh file (not mixed with other dependencies)
2. **Given** I want to test Ghostty building separately, **When** I source scripts/build_ghostty.sh, **Then** the module runs independently with clear inputs and outputs
3. **Given** I'm debugging ZSH theme configuration, **When** I review scripts/configure_theme.sh, **Then** the file contains only theme-specific logic without unrelated ZSH setup concerns
4. **Given** the start.sh monolith has been refactored, **When** I review manage.sh, **Then** it orchestrates modules cleanly without embedded complex logic
5. **Given** I want to add a new management command, **When** I create a new module, **Then** I can integrate it with minimal changes to manage.sh

---

### Edge Cases

- What happens when manage.sh is called with an invalid subcommand? (Should display help and exit with non-zero status)
- How does the system handle partial migrations where some modules are migrated while others remain in start.sh? (manage.sh detects and routes to appropriate implementation, logging which are legacy vs new)
- What happens if docs-dist directory exists but is not gitignored? (Migration script should add to .gitignore)
- How are existing start.sh users transitioned during incremental migration? (Keep start.sh as a wrapper that calls manage.sh, which transparently uses available modules or falls back to legacy code)
- What happens when modular scripts have circular dependencies? (Design should prevent this; validation check included)
- How does incremental migration handle partially migrated documentation sections? (Astro site includes links to both new docs-source/ content and legacy locations until migration complete)
- What happens if a single module migration fails or introduces bugs? (Rollback that specific module while keeping others intact, allowing independent recovery)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a single `manage.sh` entry point for all management operations
- **FR-002**: manage.sh MUST support subcommands: install, docs (generate|build|dev), update, validate
- **FR-002-NOTE**: Screenshot functionality (capture|generate-gallery) has been permanently removed as of 2025-11-09 due to installation hangs and unnecessary complexity
- **FR-003**: manage.sh MUST display contextual help when invoked with --help or invalid arguments
- **FR-004**: System MUST maintain backward compatibility by keeping start.sh as a wrapper to `manage.sh install`
- **FR-005**: All source documentation MUST reside in a single docs-source/ top-level directory with shallow nesting (maximum 2 levels deep from docs-source/, where docs-source/=level 0, docs-source/user-guide/=level 1, docs-source/user-guide/installation.md=level 2)
- **FR-006**: Generated documentation MUST output only to docs-dist directory. The .nojekyll file MUST be created during Astro build process (via public/ directory or build script) and MUST NOT be git tracked (generated artifact only)
- **FR-007**: docs-dist directory MUST be added to .gitignore to prevent accidental commits of build artifacts
- **FR-008**: Monolithic start.sh script MUST be refactored into fine-grained modules (10+ modules) in a flat scripts/ directory (avoiding scripts/modules/ subdirectory to reduce nesting)
- **FR-009**: Each module MUST handle a single, highly specific sub-task (e.g., install_node.sh, install_zig.sh, build_ghostty.sh, setup_zsh.sh, configure_theme.sh as separate files)
- **FR-010**: Modules MUST be sourceable and testable independently of manage.sh orchestration, with each module completing in under 10 seconds when tested in isolation
- **FR-011**: AI guidelines content from AGENTS.md MUST be copied into modular files within docs-source/ai-guidelines/ maintaining shallow nesting. AGENTS.md remains intact as single source of truth with CLAUDE.md and GEMINI.md as symlinks per constitutional requirement (Principle IV: Agent File Integrity)
- **FR-012**: Astro site MUST include both user-facing documentation (installation, usage, configuration) and developer documentation (AI guidelines, architecture, contributing) with clear navigation between sections
- **FR-013**: Migration MUST follow incremental per-component approach: migrate one script module at a time, one doc section at a time, building manage.sh gradually
- **FR-014**: Each migration increment MUST be independently testable and deployable without breaking existing functionality
- **FR-015**: Migration process MUST preserve existing directory structures (spec-kit/, local-infra/, .specify/) unchanged during transition
- **FR-016**: New simplified structure MUST coexist with existing structures without conflicts or namespace collisions
- **FR-017**: System MUST validate module dependencies and prevent circular references
- **FR-018**: All existing script functionality MUST be preserved in new structure
- **FR-019**: During incremental migration, manage.sh MUST support calling both legacy start.sh functions and new modular scripts transparently

### Assumptions

- Repository structure follows nesting limits defined in FR-005 (maximum 2 levels deep) to maintain simplicity for a config project
- Existing workflow structures (spec-kit/, local-infra/, .specify/) remain unchanged and functional during migration
- New simplified structure coexists with existing structures without requiring immediate consolidation
- Incremental migration allows partial completion states where some modules are migrated while others remain in start.sh
- Each migration increment can be validated independently before proceeding to next component. One complete increment is defined as: (1) module created with proper contract compliance, (2) unit test written and passing in <10s, and (3) module integrated into manage.sh with proper error handling
- The docs directory will be renamed or repurposed, not deleted (to preserve GitHub Pages configuration if needed)
- Existing custom modifications to start.sh by users are minimal (script warns about migration)
- Shell environment is bash-compatible for module sourcing
- GitHub Pages deployment can be reconfigured to use docs-dist if needed

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can execute any management task using `./manage.sh <command>` without referencing other scripts
- **SC-002**: New contributors find and edit documentation source files on first attempt without confusion
- **SC-003**: Generated build artifacts (docs-dist) never appear in git status after fresh builds
- **SC-004**: Time to locate and modify specific functionality (e.g., ZSH setup logic) reduces by 50%
- **SC-005**: manage.sh --help output displays all available commands and options in under 2 seconds
- **SC-006**: All existing automation (installation, updates, documentation builds) continues working without regression
- **SC-007**: Each of the 10+ fine-grained modules can be tested independently in under 10 seconds, enabling rapid isolated testing and debugging
- **SC-008**: Repository size (excluding generated docs) remains constant or decreases (no bloat from reorganization)
- **SC-009**: Zero data loss during migration (all existing scripts backed up before modification)
- **SC-010**: Documentation builds complete in same or better time compared to current process
- **SC-011**: Astro site provides clear navigation between user documentation and developer AI guidelines, each accessible within 2 clicks from home page
- **SC-012**: Each incremental migration step (individual module or doc section) can be completed, tested, and validated independently within a single development session

## Clarifications

### Session 2025-10-26

- Q: Overall Structure Complexity - For a "simple config project," what level of organization is most appropriate? → A: Balanced (4-5 top-level directories with shallow nesting: configs/, scripts/, docs-source/, site/) - Clear separation without deep hierarchies
- Q: Astro Site Scope and Purpose - What should the Astro site include? → A: Documentation + AI Guidelines - Include both user-facing docs and developer AI guidelines in the same site
- Q: Handling Existing Complex Structures - How should spec-kit/, local-infra/, .specify/ be handled? → A: Preserve all - Keep existing structures unchanged, only add new simplified structure alongside
- Q: Script Module Granularity - What level of granularity for script modules? → A: Fine-grained (10+ modules) - Highly specific modules for each sub-task (e.g., separate install_node.sh, install_zig.sh, build_ghostty.sh)
- Q: Migration Strategy and Rollout - What migration approach balances safety with progress? → A: Incremental per-component - Migrate one script module at a time, one doc section at a time, building manage.sh gradually

## Current Reality (as of 2025-11-09)

### Completed Changes

1. **Documentation Centralization** ✅
   - Implemented centralized `documentations/` structure with clear categorization:
     - `user/` - Installation guides, troubleshooting
     - `developer/` - Architecture, analysis
     - `specifications/` - All feature specs (moved from `specs/`)
     - `archive/` - Historical documentation
   - Consolidated `spec-kit/001/` → `spec-kit/guides/` (methodology guides)
   - Removed obsolete screenshot-based documentation

2. **Screenshot Functionality Removal** ✅
   - Removed all screenshot capture infrastructure (`.screenshot-tools/`, scripts, tests)
   - Deleted 28 files (2,474 lines) related to screenshots
   - Updated start.sh to remove screenshot code (ENABLE_SCREENSHOTS="false")
   - Rationale: Installation hangs, unnecessary complexity, no user benefit

3. **File Organization** ✅
   - Reduced root directory clutter by 40% (22→14 files)
   - Moved lighthouse performance reports to `documentations/performance/lighthouse-reports/`
   - Created comprehensive documentation: INSTALLATION_BREAKDOWN.md (62 packages), FILE_ORGANIZATION_ANALYSIS.md

### Alignment with Original Spec

**Status**: Spec 001 is **24% complete** with Phase 1-3 Core infrastructure in place:
- ✅ Phase 1: Module templates, validation, testing framework
- ✅ Phase 2: Foundational utilities (common.sh, progress.sh, backup_utils.sh)
- ✅ Phase 3 Core: manage.sh with command stubs
- ⚠️  Phase 3 Commands: Functional stubs implemented but awaiting Phase 5 modules
- ⚠️  Phase 4: Documentation restructure (partially complete via centralization)
- ⚠️  Phase 5: Modular scripts (pending - start.sh still monolithic)

**Next Steps**:
- Update tasks.md to remove screenshot-related tasks (T027-T028)
- Complete Phase 4 documentation restructure (align with centralized structure)
- Begin Phase 5 modular script implementation (break down start.sh)
