# Tasks: Repository Structure Refactoring

**Input**: Design documents from `/home/kkk/Apps/ghostty-config-files/documentations/specifications/001-repo-structure-refactor/`
**Prerequisites**: plan.md (✅), spec.md (✅), research.md (✅), data-model.md (✅), contracts/ (✅), quickstart.md (✅)
**Feature Branch**: `001-repo-structure-refactor`

## Execution Flow Summary
```
1. Load plan.md from feature directory
   → ✅ COMPLETE: Bash 5.x+ modules, Astro docs, manage.sh orchestration
2. Load optional design documents:
   → ✅ spec.md: 3 user stories (P1: manage.sh, P2: docs structure, P3: modular scripts)
   → ✅ data-model.md: 5 entities (Bash Module, Documentation Artifact, Management Command, Test Suite, Directory Structure)
   → ✅ contracts/: manage-sh-cli.md, bash-module-interface.md
   → ✅ research.md: Bash testing strategy, .nojekyll preservation, module architecture
   → ✅ quickstart.md: Implementation workflow and troubleshooting
3. Generate tasks by user story:
   → ✅ Setup: Templates, validation tools, testing framework
   → ✅ Foundational: Common utilities, helper functions
   → ✅ US1 (P1): manage.sh CLI with all subcommands
   → ✅ US2 (P2): Documentation restructure (docs-source/ + docs/ committed output)
   → ✅ US3 (P3): Modular scripts (10+ fine-grained modules)
   → ✅ Polish: Integration testing, performance validation, documentation
4. Apply task rules:
   → ✅ Different files = mark [P] for parallel
   → ✅ Same file/dependency = sequential (no [P])
   → ✅ Each user story independently testable
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph by user story
7. Create parallel execution examples
8. Validate task completeness
```

## Format: `- [ ] [ID] [P?] [Story?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[US#]**: User story label (US1=manage.sh, US2=docs, US3=modules)
- All file paths are absolute and follow project structure

## Path Conventions
**Repository Root**: `/home/kkk/Apps/ghostty-config-files/`
- **Scripts**: `scripts/` (modular bash modules)
- **Templates**: `scripts/.module-template.sh`, `local-infra/tests/unit/.test-template.sh`
- **Documentation Source**: `docs-source/` (markdown files to edit)
- **Documentation Build**: `docs/` (Astro output, committed for GitHub Pages)
- **Tests**: `local-infra/tests/unit/`, `local-infra/tests/contract/`
- **Validation**: `scripts/validate_module_*.sh`

---

## Phase 1: Setup & Validation Infrastructure (T001-T012)

**Goal**: Create reusable templates, validation tools, and testing framework to enable rapid module development

**Independent Test**: Validation tools can check any module for contract compliance; test framework can execute standalone unit tests

### Module Templates & Validation Tools (T001-T006)

- [X] T001 [P] Create bash module template in scripts/.module-template.sh with BASH_SOURCE guard, header format, function structure per bash-module-interface contract
- [X] T002 [P] Create unit test template in local-infra/tests/unit/.test-template.sh with mock setup, assertion helpers, cleanup patterns
- [X] T003 Create module contract validation script in scripts/validate_module_contract.sh that checks header completeness, ShellCheck compliance, function documentation
- [X] T004 [P] Create dependency cycle detection script in scripts/validate_module_deps.sh that parses module headers and performs topological sort
- [X] T005 [P] Create test helper functions in local-infra/tests/unit/test_functions.sh for assertions, mocking, PATH overrides
- [X] T006 Integrate validation scripts into local-infra/runners/validate-modules.sh for comprehensive module validation

### .nojekyll Protection System (T007-T010)

- [X] T007 [P] Create public/.nojekyll file for Astro automatic copy to docs/ build output (primary protection layer)
- [X] T008 [P] Create pre-commit git hook in .git/hooks/pre-commit to validate .nojekyll exists in docs/ output before allowing commits
- [X] T009 [P] Verify .gitignore does NOT exclude docs/ directory (build output must be committed for GitHub Pages)
- [X] T010 Verify Vite plugin automation in astro.config.mjs creates .nojekyll (secondary protection layer already implemented)

### Testing Framework Setup (T011-T012)

- [X] T011 Create ShellCheck validation runner in local-infra/tests/validation/run_shellcheck.sh for static analysis of all modules
- [X] T012 [P] Update local-infra/runners/test-runner-local.sh to support unit test discovery and execution with timing validation

---

## Phase 2: Foundational Utilities (T013-T016)

**Goal**: Implement shared utilities needed by all modules

**Independent Test**: Each utility can be sourced and used independently; functions return correct values for various inputs

### Common Utilities (T013-T016)

- [X] T013 [P] Create common utility functions in scripts/common.sh for path resolution, logging, error handling
- [X] T014 [P] Create progress reporting functions in scripts/progress.sh for standardized output (🔄 Starting, ✅ Completed, ❌ Failed)
- [X] T015 [P] Create backup utility functions in scripts/backup_utils.sh for timestamped configuration backups before changes
- [X] T016 [P] Write unit tests for common utilities in local-infra/tests/unit/test_common_utils.sh validating all utility functions

---

## Phase 3: User Story 1 (P1) - Unified Management Interface (T017-T032)

**User Story**: As a developer working on the Ghostty configuration repository, I want a single, intuitive entry point for all management tasks so that I can efficiently perform operations without hunting through multiple scripts.

**Independent Test**: Run `./manage.sh <command>` for each subcommand and verify operation completes without referencing other scripts. Test `./manage.sh --help` displays all commands in <2 seconds.

**Acceptance Criteria**:
- manage.sh --help displays clear command list
- manage.sh install performs complete installation
- manage.sh docs build creates documentation in docs/
- manage.sh validate runs all validation checks

### manage.sh Core Implementation (T017-T020)

- [X] T017 [US1] Create manage.sh skeleton in /home/kkk/Apps/ghostty-config-files/manage.sh with argument parsing, help display, command routing
- [X] T018 [US1] Implement global options in manage.sh (--help, --version, --verbose, --quiet, --dry-run) per manage-sh-cli contract
- [X] T019 [US1] Create environment variable support in manage.sh (MANAGE_DEBUG, MANAGE_NO_COLOR, MANAGE_LOG_FILE, MANAGE_BACKUP_DIR)
- [X] T020 [US1] Implement error handling and cleanup in manage.sh with trap ERR for graceful failure handling

### Install Command (T021-T023)

- [X] T021 [US1] Implement manage.sh install command with options (--skip-node, --skip-zig, --skip-ghostty, --skip-zsh, --skip-theme, --skip-context-menu, --force)
- [X] T022 [US1] Add progress tracking to install command showing step counter (e.g., "[1/6] Installing Node.js...")
- [X] T023 [US1] Implement install command rollback on failure with automatic backup restoration

### Docs Command (T024-T026)

- [X] T024 [P] [US1] Implement manage.sh docs build subcommand calling Astro build with --clean and --output-dir options
- [X] T025 [P] [US1] Implement manage.sh docs dev subcommand starting Astro dev server with --port and --host options
- [X] T026 [P] [US1] Implement manage.sh docs generate subcommand for API documentation generation

### Screenshots Command (T027-T028) ❌ REMOVED

**Status**: ❌ **REMOVED as of 2025-11-09** - Screenshot functionality permanently removed due to installation hangs and unnecessary complexity

- [-] T027 [REMOVED] [US1] Implement manage.sh screenshots capture subcommand accepting category, name, description arguments
- [-] T028 [REMOVED] [US1] Implement manage.sh screenshots generate-gallery subcommand creating HTML gallery from captured images

### Update Command (T029-T030)

- [X] T029 [US1] Implement manage.sh update command with --check-only, --force, --component options for selective updates
- [X] T030 [US1] Add user customization preservation to update command extracting settings before update and reapplying after

### Validate Command (T031-T032)

- [X] T031 [US1] Implement manage.sh validate command with --type (all, config, performance, dependencies) and --fix options
- [X] T032 [US1] Integrate all validation checks into validate command (ghostty config syntax, ZSH config, performance metrics, dependency checking)
- [X] T032.1 [P] [US1] Test edge case: manage.sh called with invalid subcommand displays help and exits with non-zero status per edge case requirement (spec.md:66)

---

## Phase 4: User Story 2 (P2) - Clear Documentation Structure (T033-T046)

**User Story**: As a repository contributor, I want documentation source files clearly separated from generated build artifacts so that I can easily find and edit documentation without confusion.

**Independent Test**: Verify all source docs in docs-source/, generated content only in docs/ (committed for GitHub Pages), documentation builds successfully from source.

**Acceptance Criteria**:
- All editable docs in docs-source/ directory
- Build artifacts only in docs/ (committed for GitHub Pages deployment)
- AI guidelines split into modular files
- Astro site navigates between user and developer docs within 2 clicks

### Documentation Structure Creation (T033-T037)

- [X] T033 [P] [US2] Create docs-source directory structure with user-guide/, ai-guidelines/, developer/ subdirectories
- [X] T034 [P] [US2] Copy AGENTS.md content into modular files in docs-source/ai-guidelines/ (core-principles.md, git-strategy.md, ci-cd-requirements.md, development-commands.md) while maintaining AGENTS.md as single source. Verify CLAUDE.md and GEMINI.md remain as symlinks to AGENTS.md
- [X] T035 [P] [US2] Create user documentation in docs-source/user-guide/ (installation.md, configuration.md, usage.md)
- [X] T036 [P] [US2] Create developer documentation in docs-source/developer/ (architecture.md, contributing.md, testing.md)
- [X] T037 Update README.md to reference docs-source/ for editable documentation and docs/ for committed build output

### Astro Site Configuration (T038-T042)

- [X] T038 [US2] Configure Astro content collections in src/content/config.ts for docs-source/ directory structure
- [X] T039 [P] [US2] Create Astro layout components in src/layouts/ for user docs and developer docs with distinct styling
- [X] T040 [P] [US2] Implement navigation component in src/components/Navigation.astro with clear separation between user and developer sections
- [X] T041 [P] [US2] Configure Astro build output to docs/ in astro.config.mjs. Create .nojekyll file in public/ directory for automatic copy to build output (primary protection layer per FR-006). Verify existing Vite plugin also creates .nojekyll (secondary layer)
- [X] T042 [US2] Create Astro pages in src/pages/ that render content from docs-source/ collections

### Documentation Build Integration (T043-T046)

- [X] T043 [US2] Test documentation build workflow: docs-source/ → Astro → docs/ with .nojekyll verification
- [X] T044 [P] [US2] Verify .nojekyll exists in docs/ after build using all 4 protection layers
- [X] T045 [P] [US2] Test git status shows docs/ committed with .nojekyll file (build output committed for GitHub Pages)
- [X] T046 [US2] Validate Astro site navigation provides access to all sections within 2 clicks from homepage

---

## Phase 5: User Story 3 (P3) - Modular Script Architecture (T047-T068)

**User Story**: As a maintainer extending repository functionality, I want scripts broken into logical, focused modules so that I can understand, modify, and test individual components without navigating complex monolithic files.

**Independent Test**: Each module can be sourced independently, tests in <10 seconds, integrates through manage.sh without breaking existing functionality.

**Acceptance Criteria**:
- Each module handles single sub-task
- Modules sourceable without side effects
- Unit tests for each module complete in <10 seconds
- manage.sh orchestrates modules cleanly
- start.sh wrapper calls manage.sh install

### Core Installation Modules (T047-T050)

- [ ] T047 [P] [US3] Create scripts/install_node.sh module for Node.js installation via NVM with version parameter
- [ ] T048 [P] [US3] Create scripts/install_zig.sh module for Zig compiler installation with version validation
- [ ] T049 [P] [US3] Create scripts/build_ghostty.sh module for Ghostty build from source with optimization flags
- [ ] T050 [P] [US3] Write unit tests in local-infra/tests/unit/test_install_modules.sh for install_node, install_zig, build_ghostty modules

### Configuration Modules (T051-T054)

- [ ] T051 [P] [US3] Create scripts/setup_zsh.sh module for ZSH environment configuration with Oh My ZSH integration
- [ ] T052 [P] [US3] Create scripts/configure_theme.sh module for Catppuccin theme configuration with light/dark mode switching
- [ ] T053 [P] [US3] Create scripts/install_context_menu.sh module for Nautilus "Open in Ghostty" context menu integration
- [ ] T054 [P] [US3] Write unit tests in local-infra/tests/unit/test_config_modules.sh for setup_zsh, configure_theme, install_context_menu modules

### Validation & Maintenance Modules (T055-T058)

- [ ] T055 [P] [US3] Create scripts/validate_config.sh module for Ghostty configuration syntax validation
- [ ] T056 [P] [US3] Create scripts/performance_check.sh module for startup time and memory usage measurement
- [ ] T057 [P] [US3] Create scripts/dependency_check.sh module for system dependency verification (curl, git, make, etc.)
- [ ] T058 [P] [US3] Write unit tests in local-infra/tests/unit/test_validation_modules.sh for validate_config, performance_check, dependency_check modules

### Integration Modules (T059-T062)

- [ ] T059 [P] [US3] Create scripts/backup_config.sh module for timestamped configuration backups before changes
- [ ] T060 [P] [US3] Create scripts/update_components.sh module for intelligent component updates preserving user customizations
- [ ] T061 [P] [US3] Create scripts/generate_docs.sh module for documentation generation
- [ ] T062 [P] [US3] Write unit tests in local-infra/tests/unit/test_integration_modules.sh for backup_config, update_components, generate_docs modules

### Module Integration & Orchestration (T063-T068)

- [ ] T063 [US3] Integrate all modules into manage.sh with proper dependency ordering (install_node → install_zig → build_ghostty)
- [ ] T064 [US3] Implement module sourcing in manage.sh using relative paths from SCRIPTS_DIR
- [ ] T065 [US3] Add module failure handling to manage.sh with specific exit codes per module error type
- [ ] T066 [US3] Create start.sh wrapper calling manage.sh install for backward compatibility
- [ ] T066.1 [P] [US3] Test edge case: partial migration rollback scenario where module migration fails and system recovers using backup per edge case requirement (spec.md:68, spec.md:72)
- [ ] T067 [US3] Test all modules can be sourced independently without side effects using BASH_SOURCE guard
- [ ] T068 [US3] Validate no circular dependencies exist using scripts/validate_module_deps.sh

---

## Phase 6: Integration Testing & Contract Validation (T069-T076)

**Goal**: Ensure all user stories work together and meet contract requirements

**Independent Test**: Full workflow validation, contract compliance, performance targets met

### Contract Testing (T069-T072)

- [ ] T069 [P] Create contract test for manage.sh CLI in local-infra/tests/contract/test_manage_cli.py validating all commands, options, exit codes
- [ ] T070 [P] Create contract test for bash modules in local-infra/tests/contract/test_bash_modules.py validating module interface compliance
- [ ] T071 [P] Create integration test for complete workflow in local-infra/tests/integration/test_complete_workflow.sh (install → docs → validate)
- [ ] T072 [P] Create performance test in local-infra/tests/performance/test_performance_targets.sh validating <2s help, <10s module tests

### End-to-End Validation (T073-T076)

- [ ] T073 Run complete local CI/CD pipeline with ./local-infra/runners/gh-workflow-local.sh all
- [ ] T074 [P] Validate all success criteria from spec.md (SC-001 through SC-012)
- [ ] T075 [P] Test incremental migration rollback by restoring backup and verifying system recovery
- [ ] T076 Execute full installation workflow using manage.sh install --verbose and verify all components installed correctly

---

## Phase 7: Polish & Documentation (T077-T084)

**Goal**: Final polish, comprehensive documentation, and deployment readiness

### Documentation Finalization (T077-T080)

- [ ] T077 [P] Update README.md with complete manage.sh usage examples and migration guide
- [ ] T078 [P] Create MIGRATION.md guide in docs-source/developer/ documenting incremental migration approach
- [ ] T079 [P] Update CLAUDE.md with new structure documentation referencing manage.sh and modular architecture
- [ ] T080 [P] Create troubleshooting guide in docs-source/user-guide/troubleshooting.md for common issues

### Final Validation & Deployment (T081-T084)

- [ ] T081 Run ShellCheck on all modules and validate zero errors
- [ ] T082 [P] Measure and document performance metrics (help <2s, module tests <10s, docs build time)
- [ ] T083 [P] Create conversation log in documentations/development/conversation_logs/ per LLM logging requirements
- [ ] T084 Deploy documentation to GitHub Pages and verify .nojekyll protection working correctly

---

## Dependencies

### Critical Path (Blocking Dependencies)

**Phase 1 (Setup) → Everything**:
- T001-T006 (Templates & Validation) before any module creation
- T007-T010 (.nojekyll Protection) before docs build
- T011-T012 (Testing Framework) before any module tests

**Phase 2 (Foundational) → User Stories**:
- T013-T016 (Common Utilities) before US1, US3

**User Story Independence**:
- US1 (manage.sh) can start after Phase 2
- US2 (docs structure) can start after Phase 1 (parallel with US1)
- US3 (modular scripts) can start after Phase 2 (parallel with US1, US2)

**Integration Dependencies**:
- Phase 6 (Integration) requires US1, US2, US3 complete
- Phase 7 (Polish) requires Phase 6 complete

### Sequential Dependencies Within Phases

**Phase 3 (US1)**:
- T017-T020 (manage.sh core) before T021-T032 (commands)
- T021 (install command) before T023 (rollback)

**Phase 4 (US2)**:
- T033-T037 (docs structure) before T038-T042 (Astro config)
- T038-T042 (Astro config) before T043-T046 (build testing)

**Phase 5 (US3)**:
- T047-T062 (all modules) before T063-T068 (integration)
- T063-T065 (manage.sh integration) before T066-T068 (validation)

---

## Parallel Execution Examples

### Phase 1: Templates & Protection (4-6 parallel tasks)
```bash
# Launch T001, T002, T004, T005, T007, T009 together:
Task: "Create bash module template in scripts/.module-template.sh"
Task: "Create unit test template in local-infra/tests/unit/.test-template.sh"
Task: "Create dependency cycle detection script in scripts/validate_module_deps.sh"
Task: "Create test helper functions in local-infra/tests/unit/test_functions.sh"
Task: "Create public/.nojekyll file for Astro automatic copy"
Task: "Verify .gitignore does NOT exclude docs/ directory (build output must be committed)"
```

### Phase 2: Foundational Utilities (4 parallel tasks)
```bash
# Launch T013, T014, T015, T016 together:
Task: "Create common utility functions in scripts/common.sh"
Task: "Create progress reporting functions in scripts/progress.sh"
Task: "Create backup utility functions in scripts/backup_utils.sh"
Task: "Write unit tests for common utilities in local-infra/tests/unit/test_common_utils.sh"
```

### Phase 3: manage.sh Commands (4 parallel tasks)
```bash
# Launch T024, T025, T026, T029 together (after T017-T020):
Task: "[US1] Implement manage.sh docs build subcommand"
Task: "[US1] Implement manage.sh docs dev subcommand"
Task: "[US1] Implement manage.sh docs generate subcommand"
Task: "[US1] Implement manage.sh update command"

# Note: T027-T028 (screenshot commands) removed as of 2025-11-09
```

### Phase 4: Documentation Structure (4 parallel tasks)
```bash
# Launch T033, T034, T035, T036 together:
Task: "[US2] Create docs-source directory structure"
Task: "[US2] Split CLAUDE.md into modular files in docs-source/ai-guidelines/"
Task: "[US2] Create user documentation in docs-source/user-guide/"
Task: "[US2] Create developer documentation in docs-source/developer/"
```

### Phase 5: Core Installation Modules (4 parallel tasks)
```bash
# Launch T047, T048, T049, T050 together:
Task: "[US3] Create scripts/install_node.sh module"
Task: "[US3] Create scripts/install_zig.sh module"
Task: "[US3] Create scripts/build_ghostty.sh module"
Task: "[US3] Write unit tests in local-infra/tests/unit/test_install_modules.sh"
```

### Phase 5: Configuration Modules (4 parallel tasks)
```bash
# Launch T051, T052, T053, T054 together:
Task: "[US3] Create scripts/setup_zsh.sh module"
Task: "[US3] Create scripts/configure_theme.sh module"
Task: "[US3] Create scripts/install_context_menu.sh module"
Task: "[US3] Write unit tests in local-infra/tests/unit/test_config_modules.sh"
```

### Phase 5: Validation Modules (4 parallel tasks)
```bash
# Launch T055, T056, T057, T058 together:
Task: "[US3] Create scripts/validate_config.sh module"
Task: "[US3] Create scripts/performance_check.sh module"
Task: "[US3] Create scripts/dependency_check.sh module"
Task: "[US3] Write unit tests in local-infra/tests/unit/test_validation_modules.sh"
```

### Phase 6: Contract Testing (4 parallel tasks)
```bash
# Launch T069, T070, T071, T072 together:
Task: "Create contract test for manage.sh CLI in local-infra/tests/contract/test_manage_cli.py"
Task: "Create contract test for bash modules in local-infra/tests/contract/test_bash_modules.py"
Task: "Create integration test for complete workflow in local-infra/tests/integration/test_complete_workflow.sh"
Task: "Create performance test in local-infra/tests/performance/test_performance_targets.sh"
```

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**Recommended MVP**: User Story 1 (P1) Only - Unified Management Interface

**Rationale**:
- Provides immediate value with single entry point (manage.sh)
- Establishes foundation for future modules
- Can be tested and deployed independently
- Delivers measurable productivity gains from day one

**MVP Tasks**: T001-T032 (Setup + Foundational + US1)
- Estimated Duration: 8-12 hours
- Deliverable: Fully functional manage.sh with all commands

### Incremental Delivery Plan

**Phase 1-2 (Foundation)**: T001-T016
- Duration: 3-4 hours
- Deliverable: Templates, validation tools, testing framework

**Phase 3 (MVP - US1)**: T017-T032
- Duration: 6-8 hours
- Deliverable: manage.sh with all subcommands working

**Phase 4 (US2 - Docs)**: T033-T046
- Duration: 4-6 hours
- Deliverable: Separated documentation structure with Astro site

**Phase 5 (US3 - Modules)**: T047-T068
- Duration: 8-10 hours
- Deliverable: 10+ modular scripts with unit tests

**Phase 6-7 (Integration & Polish)**: T069-T084
- Duration: 4-6 hours
- Deliverable: Complete feature with all validations passing

**Total Estimated Duration**: 25-34 hours over 3-5 development sessions

### Parallel Development Opportunities

After Phase 1-2 (Foundation) complete:
- US1, US2, US3 can be developed in parallel (different files, no dependencies)
- Within each user story, parallel tasks marked [P] can run simultaneously
- Maximum parallel capacity: 6-8 tasks at once (limited by distinct files)

---

## Validation Checklist

*GATE: Checked before implementation begins*

- [x] All user stories have complete task coverage (US1: T017-T032, US2: T033-T046, US3: T047-T068)
- [x] Each user story independently testable (acceptance criteria defined)
- [x] Setup phase (T001-T012) provides all needed tools and templates
- [x] Foundational phase (T013-T016) provides common utilities for all stories
- [x] All tasks follow checklist format (checkbox, ID, [P] marker, [Story] label, description with file path)
- [x] Parallel tasks truly independent (different files, no shared dependencies)
- [x] Each task specifies exact file path or component
- [x] No task modifies same file as another [P] task
- [x] Constitutional compliance maintained (local CI/CD, branch preservation, .nojekyll protection)
- [x] Performance targets integrated (<2s help, <10s module tests, docs build maintained)
- [x] All contracts have implementation tasks (manage-sh-cli → T017-T032, bash-module-interface → T047-T068)
- [x] All entities have configuration/implementation tasks (Bash Module → T047-T062, Documentation Artifact → T033-T046, Management Command → T017-T032)

---

## Success Criteria Validation

| Success Criterion | Task Coverage | Validation Method |
|-------------------|---------------|-------------------|
| SC-001: Execute any task via manage.sh | T017-T032 | Run ./manage.sh <command> for each subcommand |
| SC-002: Find docs on first attempt | T033-T046 | Navigate docs-source/ and find target files |
| SC-003: docs/ properly committed with .nojekyll | T007-T010, T043-T046 | Build docs and verify committed output |
| SC-004: 50% faster to locate functionality | T047-T068 | Measure time to find specific module vs current |
| SC-005: Help displays in <2 seconds | T018, T072 | Time ./manage.sh --help execution |
| SC-006: Existing automation continues working | T066, T073-T076 | Run complete installation workflow |
| SC-007: Module tests <10 seconds | T050, T054, T058, T062 | Time each unit test file execution |
| SC-008: Repository size remains manageable | T082 | Measure repo size before/after (with committed docs/) |
| SC-009: Zero data loss during migration | T015, T059, T075 | Verify backups created before changes |
| SC-010: Docs build time maintained/improved | T043, T082 | Measure Astro build time vs baseline |
| SC-011: Docs navigation <2 clicks | T040, T046 | Test navigation from homepage to any section |
| SC-012: Each increment completes in single session | All tasks | Validate each phase can be completed in 2-4 hours |

---

## Notes

- **[P] tasks**: Different files, no dependencies, can run simultaneously
- **[US#] labels**: Map tasks to user stories for independent testing
- **MVP Strategy**: Deliver US1 (manage.sh) first for immediate value, then US2 (docs) and US3 (modules) in parallel
- **Incremental Migration**: Each phase can be tested and deployed independently
- **Constitutional Compliance**: Local CI/CD validation mandatory before GitHub operations
- **Performance Targets**: <2s help, <10s module tests, docs build maintained
- **Branch Preservation**: Follow YYYYMMDD-HHMMSS-type-description naming convention
- **Rollback Safety**: All phases include backup and rollback capabilities

---

## Total Task Summary

**Total Tasks**: 84
- **Setup (Phase 1)**: 12 tasks (T001-T012)
- **Foundational (Phase 2)**: 4 tasks (T013-T016)
- **User Story 1 - manage.sh (Phase 3)**: 16 tasks (T017-T032)
- **User Story 2 - Docs (Phase 4)**: 14 tasks (T033-T046)
- **User Story 3 - Modules (Phase 5)**: 22 tasks (T047-T068)
- **Integration (Phase 6)**: 8 tasks (T069-T076)
- **Polish (Phase 7)**: 8 tasks (T077-T084)

**Parallel Opportunities**: 52 tasks marked [P] (62% parallelizable)
**Estimated Duration**: 25-34 hours (3-5 development sessions)
**MVP Scope**: T001-T032 (32 tasks, 11-15 hours)

**Critical Path**: Setup → Foundational → US1 (MVP) → Integration → Polish
**Recommended Approach**: Complete MVP (US1) first, then US2 and US3 in parallel
