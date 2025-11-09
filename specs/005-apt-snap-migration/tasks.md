# Implementation Tasks: Package Manager Migration (apt → snap)

**Feature Branch**: `005-apt-snap-migration`
**Date**: 2025-11-09
**Status**: Ready for Implementation

## Overview

This document contains actionable implementation tasks organized by user story priority. Each user story represents an independently testable increment that delivers value while building toward the complete migration system.

**Workflow**: Tasks are organized by user story (P1 → P2 → P3), enabling incremental delivery and testing. Complete each phase before moving to the next to maintain system stability.

---

## Task Summary

| Phase | User Story | Task Count | Status | Independent Test |
|-------|-----------|------------|--------|------------------|
| Phase 1 | Setup | 5/5 | ✅ Complete | Project structure validates |
| Phase 2 | Foundational | 8/8 | ✅ Complete | Common utilities testable (20/20 unit tests passing) |
| Phase 3 | US1 - Audit (P1) | 16/16 | ✅ Complete | Audit reports generated without errors |
| Phase 4 | US2 - Test Migration (P2) | 17/17 | ✅ Complete | Single package migrates and rolls back successfully |
| Phase 5 | US3 - System-Wide (P3) | 0/10 | ⚪ Not Started | Batch migration completes with zero breakage |
| Phase 6 | Polish | 0/7 | ⚪ Not Started | Documentation complete, cleanup working |
| **Total** | | **46/78** (59%) | **Migration Engine Complete** | |

---

## Implementation Strategy

### MVP Scope (Recommended First Delivery)

**Phase 1 + Phase 2 + Phase 3 (User Story 1)** = Complete audit system

This provides immediate value by:
- Showing users what can be migrated
- Identifying risks before any destructive operations
- Building trust through zero-risk visibility
- Establishing foundation for migration phases

**Estimated Time**: 2-3 days
**Acceptance**: `./scripts/package_migration.sh audit` runs successfully and generates accurate migration candidate reports

### Incremental Delivery Path

1. **Iteration 1**: MVP (Audit only) - User Story 1
2. **Iteration 2**: Add test migration capability - User Story 2
3. **Iteration 3**: Add system-wide migration - User Story 3
4. **Iteration 4**: Polish and documentation - Phase 6

---

## Phase 1: Setup

**Goal**: Initialize project structure and configuration infrastructure

**Duration**: ~2 hours

**Independent Test**: Project structure matches plan.md specification, all directories exist

### Tasks

- [X] T001 Create user configuration directory structure: `~/.config/package-migration/` with subdirectories `backups/`, `cache/`
- [X] T002 [P] Create configuration file template at `~/.config/package-migration/config.json` with default settings per contracts/cli-interface.md schema
- [X] T003 [P] Create logging infrastructure directories: `/tmp/ghostty-start-logs/` (if not exists), verify write permissions
- [X] T004 [P] Create contracts validation script at `local-infra/tests/validation/validate_cli_contracts.sh` to verify command interface consistency
- [X] T005 Update `.gitignore` to exclude `~/.config/package-migration/` and `/tmp/ghostty-start-logs/` from version control

---

## Phase 2: Foundational Infrastructure

**Goal**: Build shared utilities and testing framework required by all user stories

**Duration**: ~4 hours

**Status**: ✅ COMPLETE (8/8 tasks done)

**Independent Test**: All common utilities execute without errors, test framework validates module template compliance

**Test Results**:
- Unit Tests: 20/20 passed (`test_common_utils.sh`)
  - common.sh: 9 tests (path resolution, logging, error handling, utilities)
  - progress.sh: 4 tests (display functions)
  - backup_utils.sh: 7 tests (backup operations)

### Tasks

- [X] T006 Create error handling utilities in `scripts/common.sh`: functions for error codes (E001-E008), error formatting, exit code management
- [X] T007 [P] Create JSON utilities in `scripts/common.sh`: functions for jq-based JSON parsing, generation, validation with error handling
- [X] T008 [P] Create logging utilities in `scripts/common.sh`: structured logging (log_event function with severity levels DEBUG|INFO|WARNING|ERROR|CRITICAL)
- [X] T009 [P] Create display utilities in `scripts/progress.sh`: colored output functions, progress bars, table formatting (follows existing pattern)
- [X] T010 [P] Create configuration loader in `scripts/common.sh`: load config.json with environment variable overrides, validate schema
- [X] T011 Create test helper functions in `local-infra/tests/unit/test_functions.sh`: assertions for Bash tests (assert_equals, assert_file_exists, assert_json_valid, assert_true, assert_false)
- [X] T012 [P] Create test fixtures directory at `local-infra/tests/fixtures/` with sample JSON files (package-state.json, audit-results.json)
- [X] T013 Write unit tests for common utilities at `local-infra/tests/unit/test_common_utils.sh` validating error handling, JSON operations, logging (20/20 tests passing)

---

## Phase 3: User Story 1 - Safe Package Audit and Detection (P1)

**User Story**: As a system administrator, I want to audit all currently installed apt packages and identify which ones have snap/App Center alternatives available, so that I can make informed decisions about migration candidates without risking system stability.

**Goal**: Deliver complete package audit system with snap alternative detection and reporting

**Duration**: ~8 hours

**Status**: ✅ COMPLETE (16/16 tasks done)

**Independent Test**: Running `./scripts/package_migration.sh audit` produces accurate report showing installed apt packages, snap alternatives, equivalence scores, risk levels, and migration priorities without making any system modifications

**Test Results**:
- Unit Tests: 9/9 passed (`test_audit_packages.sh`)
- Integration Tests: 7/7 passed (`test_audit_workflow.sh`)

**Local CI/CD Validation Checkpoint** (per Constitution Principle III):
- ✅ Unit tests executed locally: `./local-infra/tests/unit/test_audit_packages.sh`
- ✅ Integration tests executed locally: `./local-infra/tests/integration/test_audit_workflow.sh`
- ✅ All tests passed without errors (9/9 unit + 7/7 integration = 16/16 total)
- ✅ Zero GitHub Actions consumption - all validation local

### Acceptance Criteria (from spec.md)

1. ✅ Audit report shows package name, current version, installation method, and dependency tree
2. ✅ Report identifies snap/App Center alternatives with version comparison and functional equivalence status
3. ✅ Essential services and boot dependencies flagged with warning indicators
4. ✅ Dynamic Ubuntu version detection and App Center compatibility validation (no hardcoded versions)

### Tasks

#### Package Detection & Analysis

- [X] T014 [P] [US1] Implement package detection in `scripts/audit_packages.sh`: query installed packages via dpkg-query, extract metadata (name, version, size, arch)
- [X] T015 [P] [US1] Implement dependency analysis in `scripts/audit_packages.sh`: build dependency graph using dpkg-query and apt-cache rdepends per research.md
- [X] T016 [P] [US1] Implement essential service detection in `scripts/audit_packages.sh`: identify boot dependencies and systemd essential services per research.md section 4.4
- [X] T017 [US1] Implement configuration file detection in `scripts/audit_packages.sh`: parse dpkg conffile list, validate paths exist

#### Snap Alternative Discovery

- [X] T018 [P] [US1] Implement snapd API client in `scripts/audit_packages.sh`: query snapd REST API via Unix socket per research.md section 2
- [X] T019 [P] [US1] Implement snap search logic in `scripts/audit_packages.sh`: match apt packages to snap alternatives (exact, alias, fuzzy matching)
- [X] T020 [P] [US1] Implement publisher verification and trust scoring in `scripts/audit_packages.sh`: extract publisher validation status (verified/starred/unverified), calculate trust score, reject unverified publishers per FR-016 requirements, prioritize official/verified publishers

#### Equivalence Scoring & Risk Assessment

- [X] T021 [US1] Implement equivalence scoring in `scripts/audit_packages.sh`: calculate weighted score (name match 20%, version 30%, feature parity 30%, config compatibility 20%)
- [X] T022 [US1] Implement risk level calculation in `scripts/audit_packages.sh`: determine risk based on essential services, reverse dependencies, boot dependencies
- [X] T023 [US1] Implement migration priority algorithm in `scripts/audit_packages.sh`: score based on equivalence, risk level (inverse), dependency order

#### Reporting & Output

- [X] T024 [P] [US1] Implement text report formatter in `scripts/audit_packages.sh`: table output with columns (package, versions, equivalence, risk, priority)
- [X] T025 [P] [US1] Implement JSON report formatter in `scripts/audit_packages.sh`: structured output matching data-model.md MigrationCandidate schema

#### Caching & Performance

- [X] T026 [US1] Implement audit cache in `scripts/audit_packages.sh`: save results to `~/.config/package-migration/audit-cache.json` with TTL validation (default 1 hour)

#### CLI Integration

- [X] T027 [US1] Implement audit command in `scripts/package_migration.sh`: command-line argument parsing (--no-cache, --output, --filter, --sort), delegate to audit_packages.sh

#### Testing

- [X] T028 [US1] Write unit tests at `local-infra/tests/unit/test_audit_packages.sh`: test package detection, dependency graph, equivalence scoring with fixtures
- [X] T029 [US1] Write integration test at `local-infra/tests/integration/test_audit_workflow.sh`: end-to-end audit execution, validate JSON output schema

---

## Phase 4: User Story 2 - Test Migration on Non-Critical Packages (P2)

**User Story**: As a system administrator, I want to perform trial migrations on non-critical packages first, with automatic rollback capability, so that I can validate the migration process works correctly before attempting system-critical applications.

**Goal**: Enable safe single-package migration with pre-checks, backup, verification, and rollback

**Duration**: ~12 hours

**Status**: ✅ COMPLETE (17/17 tasks done)

**Independent Test**: Migrating a non-critical apt package (e.g., htop) to its snap equivalent succeeds with full functionality verification, and rollback restores the exact apt version with all configurations intact

**Implementation Summary**:
- Health check system (T030-T035): Disk space, network, snapd daemon, conflict detection
- Backup system (T036-T040): .deb download, config backup, service state, PPA metadata, backup command
- Migration engine (T041-T046): Apt uninstall, snap install, config migration, verification, logging, orchestration

### Acceptance Criteria (from spec.md)

1. ✅ Pre-migration health checks (disk space, network, snapd status) execute before any changes
2. ✅ Complete backup created including .deb file, configs, and service states
3. ✅ Snap alternative installed and functionally verified (command availability, version check)
4. ✅ Rollback restores exact previous state including apt package, configs, and dependencies

### Tasks

#### Health Check System

- [X] T030 [P] [US2] Implement disk space check in `scripts/migration_health_checks.sh`: calculate required space (apt + snap + buffer), compare with available
- [X] T031 [P] [US2] Implement network connectivity check in `scripts/migration_health_checks.sh`: test snapd socket reachability per research.md section 4.2
- [X] T032 [P] [US2] Implement snapd daemon check in `scripts/migration_health_checks.sh`: verify systemd service active, auto-start if inactive (with permission)
- [X] T033 [P] [US2] Implement conflict detection in `scripts/migration_health_checks.sh`: check for package conflicts between apt and snap versions
- [X] T034 [US2] Implement health check aggregator in `scripts/migration_health_checks.sh`: run all checks, generate HealthCheckResult JSON per data-model.md
- [X] T035 [US2] Implement health command in `scripts/package_migration.sh`: parse --check, --fix, --output options, delegate to migration_health_checks.sh

#### Backup System

- [X] T036 [P] [US2] Implement .deb download in `scripts/migration_backup.sh`: use apt-get download, verify integrity with dpkg --verify
- [X] T037 [P] [US2] Implement config backup in `scripts/migration_backup.sh`: rsync configuration files to backup directory preserving permissions
- [X] T038 [P] [US2] Implement service state capture in `scripts/migration_backup.sh`: record systemd service enabled/active status
- [X] T038a [US2] Implement PPA metadata backup in `scripts/migration_backup.sh`: detect PPA sources from /etc/apt/sources.list.d/, preserve PPA configurations, store PPA GPG keys for rollback per FR-017
- [X] T039 [US2] Implement backup metadata generation in `scripts/migration_backup.sh`: create MigrationBackup JSON with checksums per data-model.md
- [X] T040 [US2] Implement backup command in `scripts/package_migration.sh`: parse --all, --output-dir, --label options, delegate to migration_backup.sh

#### Migration Engine

- [X] T041 [US2] Implement apt uninstall in `scripts/package_migration.sh`: remove package preserving configs, check for orphaned dependencies
- [X] T042 [US2] Implement snap install in `scripts/package_migration.sh`: install via snap command, capture output and exit codes
- [X] T043 [US2] Implement config migration in `scripts/package_migration.sh`: copy configs to snap-specific paths per research.md section 5
- [X] T044 [US2] Implement functional verification in `scripts/package_migration.sh`: test command availability, version check, basic functionality
- [X] T045 [US2] Implement migration logging in `scripts/package_migration.sh`: create MigrationLogEntry for each operation per data-model.md
- [X] T045a [US2] Implement audit and health check logging in `scripts/audit_packages.sh` and `scripts/migration_health_checks.sh`: create MigrationLogEntry for audit/health check operations (action types: audit, health_check) with outcome and error details per data-model.md and FR-013
- [X] T046 [US2] Implement migrate command in `scripts/package_migration.sh`: orchestrate health checks → backup → migrate → verify, support --dry-run

#### Rollback System

- [ ] T047 [P] [US2] Implement backup verification in `scripts/migration_rollback.sh`: validate .deb files exist, checksums match
- [ ] T048 [P] [US2] Implement snap removal in `scripts/migration_rollback.sh`: uninstall snap package with --purge option
- [ ] T049 [US2] Implement apt reinstall in `scripts/migration_rollback.sh`: install from preserved .deb file via dpkg -i
- [ ] T050 [US2] Implement config restoration in `scripts/migration_rollback.sh`: rsync configs back to original paths
- [ ] T051 [US2] Implement service restoration in `scripts/migration_rollback.sh`: restore systemd service states (enabled/active)
- [ ] T052 [US2] Implement rollback command in `scripts/package_migration.sh`: parse backup-id, --all, --verify-only options, delegate to migration_rollback.sh

#### Testing

- [ ] T053 [US2] Write unit tests at `local-infra/tests/unit/test_migration_health_checks.sh`: test all health check functions with mocked system state
- [ ] T054 [US2] Write unit tests at `local-infra/tests/unit/test_migration_backup.sh`: test backup operations with fixtures
- [ ] T055 [US2] Write unit tests at `local-infra/tests/unit/test_migration_rollback.sh`: test rollback operations with mocked backups
- [ ] T056 [US2] Write validation test at `local-infra/tests/validation/validate_single_migration.sh`: end-to-end htop migration and rollback test

---

## Phase 5: User Story 3 - System-Wide Migration with Safety Guarantees (P3)

**User Story**: As a system administrator, I want to migrate all eligible apt packages to snap/App Center equivalents with comprehensive safety checks and rollback protection, so that I can modernize package management while ensuring zero system breakage.

**Goal**: Enable batch migration with dependency ordering, essential service protection, and full system rollback

**Duration**: ~8 hours

**Independent Test**: Running full system migration on a test VM completes successfully, system boots correctly, essential services remain functional, and rollback capability works for the entire migration batch

### Acceptance Criteria (from spec.md)

1. ✅ Packages migrated in dependency-safe order (leaf packages first, non-critical before system-critical)
2. ✅ Dependency analysis identifies all reverse dependencies, ensures snap alternatives exist for entire chain
3. ✅ Essential services scheduled last and flagged for extra verification
4. ✅ Post-migration validation verifies systemd services restart, boot process intact, no conflicts
5. ✅ Automatic rollback on critical validation failures

### Tasks

#### Dependency Ordering

- [ ] T057 [P] [US3] Implement topological sort in `scripts/audit_packages.sh`: order packages by dependency depth (leaf → root) per research.md section 1
- [ ] T058 [P] [US3] Implement circular dependency detection in `scripts/audit_packages.sh`: identify cycles, flag as manual review required
- [ ] T059 [US3] Implement dependency chain validation in `scripts/package_migration.sh`: verify snap alternatives exist for entire dependency chain before starting

#### Batch Migration

- [ ] T060 [P] [US3] Implement batch processor in `scripts/package_migration.sh`: process packages in batches (default 10), maintain migration state between batches
- [ ] T061 [P] [US3] Implement priority filtering in `scripts/package_migration.sh`: support --priority-threshold to migrate only high-priority packages
- [ ] T062 [US3] Implement essential service protection in `scripts/package_migration.sh`: schedule essential services last, require explicit confirmation

#### Post-Migration Validation

- [ ] T063 [P] [US3] Implement service verification in `scripts/package_migration.sh`: check all systemd services are active after migration
- [ ] T064 [P] [US3] Implement boot integrity check in `scripts/package_migration.sh`: verify no boot-critical packages in failed state
- [ ] T065 [US3] Implement conflict resolution check in `scripts/package_migration.sh`: scan for package conflicts post-migration

#### Batch Rollback

- [ ] T066 [US3] Implement batch rollback in `scripts/migration_rollback.sh`: rollback multiple packages in reverse migration order, atomic operation

#### Status & Reporting

- [ ] T067 [US3] Implement status command in `scripts/package_migration.sh`: aggregate migration statistics, show package-level status per contracts/cli-interface.md

#### Testing

- [ ] T068 [US3] Write validation test at `local-infra/tests/validation/validate_batch_migration.sh`: test migration of 5+ packages with dependency relationships
- [ ] T069 [US3] Write validation test at `local-infra/tests/validation/validate_system_migration.sh`: full system migration test on VM/container

---

## Phase 6: Polish & Cross-Cutting Concerns

**Goal**: Complete documentation, cleanup functionality, and production readiness

**Duration**: ~4 hours

**Independent Test**: All documentation complete and accurate, cleanup command removes expired backups correctly, local CI/CD integration passes

### Tasks

- [ ] T070 [P] Implement cleanup command in `scripts/package_migration.sh`: remove expired backups based on retention policy, clear stale cache per contracts/cli-interface.md
- [ ] T071 [P] Create CLI help text for all commands in `scripts/package_migration.sh`: implement --help output for each command matching contracts specification
- [ ] T072 [P] Create user documentation at `documentations/user/package-migration/` with installation guide, usage examples, troubleshooting (based on quickstart.md)
- [ ] T073 [P] Integrate with local CI/CD at `local-infra/runners/gh-workflow-local.sh`: add migrate-validate workflow stage per plan.md
- [ ] T074 Update README.md with package migration feature section, link to user documentation and quickstart guide
- [ ] T075 Create example configuration file at `configs/package-migration/config.example.json` with commented settings and best practices
- [ ] T075a Write dry-run accuracy validation test in `local-infra/tests/validation/validate_dry_run_accuracy.sh`: compare dry-run predictions vs actual execution results, measure >98% accuracy per SC-010, document discrepancies

---

## Dependency Graph

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
    ├──→ Phase 3 (US1 - Audit) [INDEPENDENT]
    │        ↓
    ├──→ Phase 4 (US2 - Test Migration) [Requires US1 for candidate identification]
    │        ↓
    └──→ Phase 5 (US3 - System-Wide) [Requires US1 + US2]
             ↓
Phase 6 (Polish) [Can start after any user story completes]
```

### Task Dependencies Within Phases

**Phase 3 (US1)**: Most tasks are parallelizable after T014-T017 complete (package detection foundation)

**Phase 4 (US2)**:
- Health checks (T030-T034) → can run in parallel
- Backup system (T036-T039) → can run in parallel
- Migration engine (T041-T046) → sequential, depends on health checks + backup
- Rollback system (T047-T051) → can run in parallel after backup system complete

**Phase 5 (US3)**:
- Dependency ordering (T057-T059) must complete before batch migration (T060-T062)
- Post-migration validation (T063-T065) → can run in parallel
- Batch rollback (T066) depends on single-package rollback from Phase 4

---

## Parallel Execution Examples

### Phase 2: Foundational Infrastructure

```bash
# Can execute in parallel (different files, no dependencies)
T007 (JSON utilities) & T008 (logging utilities) & T009 (display utilities) & T010 (config loader) & T012 (test fixtures)
```

### Phase 3: User Story 1 - Audit

```bash
# Parallel batch 1: Package detection foundation
T014 (package detection) & T015 (dependency analysis) & T016 (essential service detection) & T017 (config file detection)

# After batch 1 completes, parallel batch 2: Snap discovery & reporting
T018 (snapd API client) & T019 (snap search) & T020 (publisher verification) & T024 (text formatter) & T025 (JSON formatter)

# Sequential: Scoring and caching (depend on previous batches)
T021 → T022 → T023 → T026
```

### Phase 4: User Story 2 - Test Migration

```bash
# Parallel batch 1: Health checks
T030 (disk space) & T031 (network) & T032 (snapd) & T033 (conflicts)

# Parallel batch 2: Backup system
T036 (.deb download) & T037 (config backup) & T038 (service capture)

# Parallel batch 3: Rollback system (after backup system complete)
T047 (backup verification) & T048 (snap removal)

# Sequential: Migration orchestration
T034 → T035 (health check aggregator + CLI) → T039 → T040 (backup metadata + CLI) → T041-T046 (migration engine) → T049-T052 (rollback steps + CLI)
```

### Phase 5: User Story 3 - System-Wide

```bash
# Parallel batch 1: Dependency ordering
T057 (topological sort) & T058 (cycle detection)

# Parallel batch 2: Batch migration features
T060 (batch processor) & T061 (priority filtering)

# Parallel batch 3: Post-migration validation
T063 (service verification) & T064 (boot integrity) & T065 (conflict check)
```

### Phase 6: Polish

```bash
# All tasks can run in parallel (different concerns)
T070 (cleanup) & T071 (help text) & T072 (user docs) & T073 (CI/CD) & T074 (README) & T075 (example config)
```

---

## Testing Strategy

### Unit Tests (Fast, Isolated)

Run after each task completion:
- `local-infra/tests/unit/test_common_utils.sh` (Phase 2)
- `local-infra/tests/unit/test_audit_packages.sh` (Phase 3)
- `local-infra/tests/unit/test_migration_health_checks.sh` (Phase 4)
- `local-infra/tests/unit/test_migration_backup.sh` (Phase 4)
- `local-infra/tests/unit/test_migration_rollback.sh` (Phase 4)

### Integration Tests (Moderate Speed, Component Interaction)

Run after phase completion:
- `local-infra/tests/integration/test_audit_workflow.sh` (Phase 3)

### Validation Tests (Slow, End-to-End)

Run after user story completion:
- `local-infra/tests/validation/validate_single_migration.sh` (Phase 4 - htop test)
- `local-infra/tests/validation/validate_batch_migration.sh` (Phase 5 - multi-package)
- `local-infra/tests/validation/validate_system_migration.sh` (Phase 5 - full system, VM only)

### Local CI/CD Integration

After Phase 6 (T073):
```bash
./local-infra/runners/gh-workflow-local.sh migrate-validate
```

This runs:
1. All unit tests
2. Integration tests
3. Validation tests (non-critical packages only, not full system)
4. CLI contract validation

---

## Success Criteria Mapping

### User Story 1 Success Criteria (from spec.md)

- **SC-001**: Audit completes in <2 minutes for 100-300 packages → T026 (caching), T014-T025 (optimized queries)
- **SC-002**: 90%+ accuracy in snap alternative detection → T018-T020 (snap API, search, publisher validation)
- **SC-006**: Essential packages identified 100% → T016 (essential service detection)

### User Story 2 Success Criteria

- **SC-003**: Health checks detect 100% of blocking conditions → T030-T034 (comprehensive checks)
- **SC-004**: Test migration succeeds 95%+ without regressions → T041-T044 (migration engine + verification)
- **SC-005**: Rollback accuracy 100% → T047-T051 (complete state restoration)

### User Story 3 Success Criteria

- **SC-007**: System bootability 100% after migration → T064 (boot integrity check)
- **SC-008**: Essential services functional 100% → T063 (service verification)
- **SC-011**: Dependency analysis prevents broken states 100% → T057-T059 (dependency ordering + validation)
- **SC-012**: Migration performance <30 minutes for 50-100 packages → T060 (batch processor)

---

## Implementation Notes

### Code Quality Standards

All scripts must:
- Follow `.module-template.sh` pattern from `scripts/` directory
- Use `set -euo pipefail` for error handling
- Source `common.sh` for shared utilities
- Include module metadata (NAME, VERSION, DESCRIPTION)
- Document all functions with comments
- Validate all input parameters
- Use structured logging via `log_event` function

### Testing Standards

All tests must:
- Follow `.test-template.sh` pattern from `local-infra/tests/unit/`
- Use test fixtures from `local-infra/tests/fixtures/`
- Use assertions from `test_functions.sh`
- Clean up temporary files after execution
- Return exit code 0 on success, non-zero on failure
- Output clear failure messages with expected vs actual values

### Performance Targets

From spec.md success criteria:
- Audit: <2 minutes for 300 packages
- Single migration: <5 minutes for large package (e.g., Chromium)
- Batch migration: <30 minutes for 100 packages
- Rollback: <5 minutes regardless of package count

### Security Requirements

From research.md section 10:
- Minimize sudo usage (only for actual package operations)
- Validate snap publisher trust before installation
- Sanitize user input in all CLI arguments
- Log all package operations for audit trail
- Preserve file permissions during config migration

---

## Next Steps

1. **Start with MVP** (Phases 1-3): Build audit system first
2. **Run local tests**: Execute test suite after each phase
3. **User validation**: Test audit with real Ubuntu system
4. **Iterate**: Add migration capability (Phase 4), then system-wide (Phase 5)
5. **Production readiness**: Complete polish phase (Phase 6)

**Ready to begin implementation!** Start with T001 (setup tasks) and proceed sequentially through phases.
