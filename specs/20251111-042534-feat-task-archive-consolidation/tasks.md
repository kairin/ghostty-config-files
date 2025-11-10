# Tasks: Task Archive and Consolidation System

**Input**: Design documents from `/home/kkk/Apps/ghostty-config-files/specs/20251111-042534-feat-task-archive-consolidation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-interface.md, quickstart.md

**Tests**: Not explicitly requested - focus on implementation and validation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each archival capability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Scripts**: `scripts/` at repository root
- **Archives**: `documentations/archive/specifications/`
- **Outputs**: `IMPLEMENTATION_CHECKLIST.md`, `PROJECT_STATUS_DASHBOARD.md` at repository root
- **Tests**: Validation through actual usage, not unit tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and baseline validation

- [x] T001 Create archive directory structure at `documentations/archive/specifications/`
- [x] T002 Verify bash version >= 5.0 and core dependencies (grep, awk, sed, git)
- [x] T003 [P] Check for optional dependencies (yq for YAML validation, jq for JSON processing)
- [x] T004 [P] Create common utility functions in `scripts/archive_common.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core parsing and validation infrastructure that ALL scripts depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Implement specification discovery in `scripts/archive_common.sh` (scan both `specs/` and `documentations/specifications/`)
- [x] T006 [P] Implement task parsing functions in `scripts/archive_common.sh` (extract task IDs, completion status, phase info)
- [x] T007 [P] Implement file path extraction from task descriptions in `scripts/archive_common.sh`
- [x] T008 Implement completion percentage calculation in `scripts/archive_common.sh`
- [x] T009 [P] Create YAML template loader in `scripts/archive_common.sh` (based on 004-modern-web-development.yaml schema)
- [x] T010 [P] Implement file existence validation in `scripts/archive_common.sh`
- [x] T011 Implement progress indicator functions in `scripts/archive_common.sh` (emoji-based: 🔍 ✅ ❌ ⚠️ 📦 📋 📊 💾)

**Checkpoint**: Foundation ready - script implementation can now begin in parallel

---

## Phase 3: User Story 1 - Archive Completed Specifications (Priority: P1) 🎯 MVP

**Goal**: Generate concise YAML archives for 100% complete specifications with >90% size reduction, validate file existence, and move originals to archive location

**Independent Test**: Run `./scripts/archive_spec.sh 004` and verify YAML archive created with 93% size reduction

### Implementation for User Story 1

- [x] T012 [US1] Create `scripts/archive_spec.sh` skeleton with CLI argument parsing (--all, --force, --dry-run, --validate-only, --output-dir, --keep-original, --help, --version)
- [x] T013 [US1] Implement help and version display in `scripts/archive_spec.sh`
- [x] T014 [P] [US1] Implement specification scanning logic in `scripts/archive_spec.sh` (identify 100% complete specs)
- [x] T015 [P] [US1] Implement single spec validation mode in `scripts/archive_spec.sh` (--validate-only flag)
- [x] T016 [US1] Implement file existence validation for completed tasks in `scripts/archive_spec.sh` (exit code 2 on missing files)
- [x] T017 [US1] Implement YAML generation from spec.md in `scripts/archive_spec.sh` (feature_id, title, status, completion_date, summary)
- [x] T018 [US1] Implement YAML generation from plan.md in `scripts/archive_spec.sh` (requirements, implementation, architecture)
- [x] T019 [US1] Implement YAML generation from tasks.md in `scripts/archive_spec.sh` (tasks section with total/completed/key_tasks)
- [x] T020 [US1] Implement outcomes and lessons_learned extraction in `scripts/archive_spec.sh`
- [x] T021 [US1] Implement space savings calculation in `scripts/archive_spec.sh` (compare original vs archive line counts)
- [x] T022 [US1] Implement original directory move operation in `scripts/archive_spec.sh` (move to `[spec-id]-original/`)
- [x] T023 [US1] Implement dry-run mode in `scripts/archive_spec.sh` (show actions without execution)
- [x] T024 [US1] Implement force re-archive mode in `scripts/archive_spec.sh` (--force flag to overwrite existing)
- [x] T025 [US1] Add YAML validation with yq if available in `scripts/archive_spec.sh`
- [x] T026 [US1] Implement exit codes (0=success, 1=error, 2=validation-error, 3=exists, 4=not-found, 5=incomplete) in `scripts/archive_spec.sh`
- [x] T027 [US1] Add comprehensive error messages to stderr in `scripts/archive_spec.sh`

**Checkpoint**: At this point, User Story 1 should archive completed specs with validation and >90% size reduction

---

## Phase 4: User Story 2 - Consolidate Outstanding Todos (Priority: P2)

**Goal**: Extract all incomplete tasks from active specifications into a unified, prioritized implementation checklist

**Independent Test**: Run `./scripts/consolidate_todos.sh` and verify `IMPLEMENTATION_CHECKLIST.md` contains all incomplete tasks grouped by spec

### Implementation for User Story 2

- [x] T028 [US2] Create `scripts/consolidate_todos.sh` skeleton with CLI argument parsing (--output, --sort-by, --filter-spec, --filter-priority, --show-dependencies, --estimate-effort, --dry-run, --help, --version)
- [x] T029 [US2] Implement help and version display in `scripts/consolidate_todos.sh`
- [x] T030 [P] [US2] Implement specification scanning for active specs in `scripts/consolidate_todos.sh`
- [x] T031 [P] [US2] Implement incomplete task extraction in `scripts/consolidate_todos.sh` (parse `- [ ]` markers)
- [x] T032 [US2] Implement task metadata extraction in `scripts/consolidate_todos.sh` (ID, priority, phase, description, effort)
- [x] T033 [P] [US2] Implement specification-based grouping in `scripts/consolidate_todos.sh`
- [x] T034 [P] [US2] Implement priority-based sorting in `scripts/consolidate_todos.sh` (P1, P2, P3, P4)
- [x] T035 [P] [US2] Implement effort estimation aggregation in `scripts/consolidate_todos.sh`
- [x] T036 [US2] Implement dependency detection from task descriptions in `scripts/consolidate_todos.sh`
- [x] T037 [US2] Implement circular dependency detection in `scripts/consolidate_todos.sh` (exit code 6 warning)
- [x] T038 [US2] Generate summary section in `scripts/consolidate_todos.sh` (total tasks, specs scanned, estimated effort)
- [x] T039 [US2] Generate per-specification task sections in `scripts/consolidate_todos.sh`
- [x] T040 [US2] Implement dependency graph visualization in `scripts/consolidate_todos.sh` (text-based hierarchical lists)
- [x] T041 [US2] Implement filter by spec functionality in `scripts/consolidate_todos.sh` (--filter-spec flag)
- [x] T042 [US2] Implement filter by priority functionality in `scripts/consolidate_todos.sh` (--filter-priority flag)
- [x] T043 [US2] Implement multiple sort modes in `scripts/consolidate_todos.sh` (spec, priority, effort, phase)
- [x] T044 [US2] Write markdown output to `IMPLEMENTATION_CHECKLIST.md` in `scripts/consolidate_todos.sh`
- [x] T045 [US2] Implement dry-run mode in `scripts/consolidate_todos.sh`
- [x] T046 [US2] Implement exit codes (0=success, 1=error, 4=no-tasks, 6=circular-deps) in `scripts/consolidate_todos.sh`

**Checkpoint**: At this point, User Story 2 should consolidate all incomplete tasks into unified checklist

---

## Phase 5: User Story 3 - Generate Status Dashboard (Priority: P3)

**Goal**: Generate comprehensive status dashboard showing completion metrics, remaining work estimates, and archive statistics

**Independent Test**: Run `./scripts/generate_dashboard.sh` and verify `PROJECT_STATUS_DASHBOARD.md` shows accurate completion percentages and metrics

### Implementation for User Story 3

- [x] T047 [US3] Create `scripts/generate_dashboard.sh` skeleton with CLI argument parsing (--output, --include-archived, --show-details, --format, --dry-run, --help, --version)
- [x] T048 [US3] Implement help and version display in `scripts/generate_dashboard.sh`
- [x] T049 [P] [US3] Implement specification scanning for all specs in `scripts/generate_dashboard.sh` (active + archived)
- [x] T050 [P] [US3] Implement completion percentage calculation per spec in `scripts/generate_dashboard.sh`
- [x] T051 [US3] Implement overall completion percentage calculation in `scripts/generate_dashboard.sh` (weighted average)
- [x] T052 [P] [US3] Implement status classification in `scripts/generate_dashboard.sh` (completed, in-progress, questionable, abandoned)
- [x] T053 [P] [US3] Implement remaining effort estimation in `scripts/generate_dashboard.sh`
- [x] T054 [US3] Implement archive statistics calculation in `scripts/generate_dashboard.sh` (count, space savings)
- [x] T055 [US3] Generate summary metrics section in `scripts/generate_dashboard.sh` (total specs, overall completion, remaining work)
- [x] T056 [US3] Generate status distribution section in `scripts/generate_dashboard.sh` (emoji indicators: ✅ 🔄 ⚠️ ❌)
- [x] T057 [US3] Generate specification details table in `scripts/generate_dashboard.sh` (ID, title, status, progress, remaining, effort)
- [x] T058 [US3] Generate archive statistics section in `scripts/generate_dashboard.sh`
- [x] T059 [US3] Implement per-phase breakdown in `scripts/generate_dashboard.sh` (--show-details flag)
- [x] T060 [US3] Generate notes section with recommendations in `scripts/generate_dashboard.sh`
- [x] T061 [P] [US3] Implement JSON output format in `scripts/generate_dashboard.sh` (--format json)
- [x] T062 [P] [US3] Implement CSV output format in `scripts/generate_dashboard.sh` (--format csv)
- [x] T063 [US3] Write markdown output to `PROJECT_STATUS_DASHBOARD.md` in `scripts/generate_dashboard.sh`
- [x] T064 [US3] Implement dry-run mode in `scripts/generate_dashboard.sh`
- [x] T065 [US3] Implement exit codes (0=success, 1=error, 4=no-specs) in `scripts/generate_dashboard.sh`

**Checkpoint**: All user stories should now be independently functional - archiving, consolidation, and dashboard generation

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple scripts and overall system quality

- [x] T066 [P] Add color output support in all scripts (detect terminal with `tput colors`)
- [x] T067 [P] Implement atomic file writes in all scripts (write to temp, then move)
- [x] T068 [P] Add file permission validation before writes in all scripts
- [x] T069 Implement constitutional compliance verification in `scripts/archive_spec.sh` (check .nojekyll preservation, branch preservation)
- [x] T070 [P] Make all scripts executable with `chmod +x scripts/archive_*.sh scripts/consolidate_*.sh scripts/generate_*.sh`
- [x] T071 Add logging to stderr for operations, stdout for results in all scripts
- [x] T072 Update `AGENTS.md` to document new archive consolidation system
- [x] T073 [P] Create quickstart validation workflow (run all scenarios from quickstart.md)
- [x] T074 Test archive generation for all 4 existing specs (004, 005, 001, 002)
- [x] T075 Test consolidation with actual repository data
- [x] T076 Test dashboard generation with actual repository data
- [x] T077 [P] Performance optimization for large repositories (parallel processing)
- [x] T078 [P] Add progress indicators for long operations (specification scanning, file validation)
- [x] T079 Document usage examples in `README.md` or documentation site
- [x] T080 Commit all scripts and generated outputs to repository

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1 → US2 → US3)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independently testable, no US1 dependency
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independently testable, benefits from US1 archives but not required

### Within Each User Story

- **US1 (Archive)**: CLI parsing → validation → YAML generation → file operations → error handling
- **US2 (Consolidate)**: CLI parsing → scanning → extraction → grouping/sorting → markdown generation
- **US3 (Dashboard)**: CLI parsing → scanning → metrics calculation → status classification → output formatting

### Parallel Opportunities

- **Phase 1**: T003 (optional deps check) and T004 (common utils) can run in parallel
- **Phase 2**: T006 (task parsing), T007 (file path extraction), T009 (YAML template), T010 (validation), T011 (progress indicators) can run in parallel after T005
- **User Stories**: US1, US2, and US3 can all start in parallel after Phase 2 completion
- **Within US1**: T014-T015 (scanning/validation), T017-T020 (YAML generation sections), T025 (yq validation) can run in parallel
- **Within US2**: T030-T031 (scanning/extraction), T033-T035 (grouping/sorting/effort), T041-T042 (filters) can run in parallel
- **Within US3**: T049-T050 (scanning/percentages), T052-T053 (status/effort), T061-T062 (output formats) can run in parallel
- **Phase 6**: T066-T068 (cross-cutting improvements), T070 (permissions), T073-T076 (testing), T077-T078 (performance) can run in parallel

---

## Parallel Example: User Story 1 (Archive)

```bash
# Launch YAML generation tasks together (different sections):
Task: "Implement YAML generation from spec.md in scripts/archive_spec.sh"
Task: "Implement YAML generation from plan.md in scripts/archive_spec.sh"
Task: "Implement YAML generation from tasks.md in scripts/archive_spec.sh"
Task: "Implement outcomes and lessons_learned extraction in scripts/archive_spec.sh"

# These tasks touch different parts of the YAML output and can be developed independently
```

---

## Parallel Example: User Story 2 (Consolidate)

```bash
# Launch grouping and sorting implementations together:
Task: "Implement specification-based grouping in scripts/consolidate_todos.sh"
Task: "Implement priority-based sorting in scripts/consolidate_todos.sh"
Task: "Implement effort estimation aggregation in scripts/consolidate_todos.sh"

# These tasks process the same data but generate different views
```

---

## Parallel Example: User Story 3 (Dashboard)

```bash
# Launch output format implementations together:
Task: "Implement JSON output format in scripts/generate_dashboard.sh"
Task: "Implement CSV output format in scripts/generate_dashboard.sh"

# These tasks format the same data differently and can be developed in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T011) - CRITICAL - blocks all stories
3. Complete Phase 3: User Story 1 (T012-T027)
4. **STOP and VALIDATE**: Test archiving spec 004 independently
5. Verify >90% size reduction achieved
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test archiving spec 004 → Deploy/Demo (MVP! ✅)
3. Add User Story 2 → Test checklist generation → Deploy/Demo (Consolidation ✅)
4. Add User Story 3 → Test dashboard generation → Deploy/Demo (Full system ✅)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T011)
2. Once Foundational is done:
   - Developer A: User Story 1 (Archive - T012-T027)
   - Developer B: User Story 2 (Consolidate - T028-T046)
   - Developer C: User Story 3 (Dashboard - T047-T065)
3. Stories complete and integrate independently
4. Polish phase (T066-T080) can be distributed across team

---

## Success Metrics

**From spec.md success criteria:**

- **SC-001**: Developers can identify next task from checklist within 30 seconds → Validate with `./scripts/consolidate_todos.sh` (US2)
- **SC-002**: Archiving achieves >90% file size reduction → Validate with `./scripts/archive_spec.sh 004` (US1)
- **SC-003**: Assess status in <2 minutes using dashboard → Validate with `./scripts/generate_dashboard.sh` (US3)
- **SC-004**: Generate checklist in <10 seconds for 5 specs → Performance test consolidate_todos.sh (US2)
- **SC-005**: Archive generation takes <30 seconds per spec → Performance test archive_spec.sh (US1)
- **SC-006**: Zero file existence errors for validated archives → Test with --validate-only flag (US1)
- **SC-007**: Dashboard updates in <10 seconds → Performance test generate_dashboard.sh (US3)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability (US1, US2, US3)
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Focus on bash scripting best practices: error handling, input validation, idempotency
- Use existing YAML archive (004-modern-web-development.yaml) as reference schema
- Leverage common utilities from archive_common.sh to avoid duplication
- Test with actual repository data (4 existing specs: 004, 005, 001, 002)
