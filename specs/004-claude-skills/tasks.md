# Tasks: Claude Code Workflow Skills

**Input**: Design documents from `/specs/004-claude-skills/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: No automated tests requested - manual verification only.

**Organization**: Tasks are grouped by user story for independent implementation. Each skill can be implemented and tested standalone.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create directory structure for skills

- [x] T001 Create `.claude/commands/` directory if not exists

---

## Phase 2: User Story 1 - Health Check Diagnostics (Priority: P1)

**Goal**: Quick system diagnostics via `/health-check` slash command

**Independent Test**: Run `/health-check` in Claude Code → See structured PASS/FAIL/WARNING report

### Implementation for User Story 1

- [x] T002 [US1] Create skill file `.claude/commands/health-check.md` with YAML frontmatter
- [x] T003 [US1] Add description field: "Quick system diagnostics and environment check"
- [x] T004 [US1] Add handoff to `/deploy-site` in frontmatter
- [x] T005 [US1] Add project detection logic (check for `.runners-local/` or `AGENTS.md`)
- [x] T006 [US1] Add full diagnostics section (ghostty-config-files project)
- [x] T007 [US1] Add basic diagnostics section (other projects fallback)
- [x] T008 [US1] Add structured output format (PASS/FAIL/WARNING per component)
- [x] T009 [US1] Add remediation suggestions for failures

**Checkpoint**: `/health-check` skill fully functional and testable independently

---

## Phase 3: User Story 2 - Site Deployment (Priority: P2)

**Goal**: Astro build and deploy via `/deploy-site` slash command

**Independent Test**: Run `/deploy-site` in Claude Code → See build metrics and deployment confirmation

### Implementation for User Story 2

- [x] T010 [US2] Create skill file `.claude/commands/deploy-site.md` with YAML frontmatter
- [x] T011 [US2] Add description field: "Build and deploy Astro website to GitHub Pages"
- [x] T012 [US2] Add handoff to `/git-sync` in frontmatter
- [x] T013 [US2] Add project detection logic (only works in ghostty-config-files)
- [x] T014 [US2] Add dependency installation step (npm install)
- [x] T015 [US2] Add Astro build step with script reference
- [x] T016 [US2] Add .nojekyll verification/creation step
- [x] T017 [US2] Add bundle size check (<100KB warning)
- [x] T018 [US2] Add build metrics output (file count, size, duration)
- [x] T019 [US2] Add deployment step and URL confirmation

**Checkpoint**: `/deploy-site` skill fully functional and testable independently

---

## Phase 4: User Story 3 - Git Synchronization (Priority: P3)

**Goal**: Safe git operations via `/git-sync` slash command

**Independent Test**: Run `/git-sync` in Claude Code → See sync status and branch validation

### Implementation for User Story 3

- [x] T020 [US3] Create skill file `.claude/commands/git-sync.md` with YAML frontmatter
- [x] T021 [US3] Add description field: "Synchronize repository with remote safely"
- [x] T022 [US3] Add handoff to `/full-workflow` in frontmatter
- [x] T023 [US3] Add pre-flight status check step (git status, branch info)
- [x] T024 [US3] Add fetch and remote analysis step
- [x] T025 [US3] Add divergence detection and user prompt
- [x] T026 [US3] Add pull with rebase step
- [x] T027 [US3] Add push with upstream tracking step
- [x] T028 [US3] Add branch name validation (YYYYMMDD-HHMMSS-type-description)
- [x] T029 [US3] Add constitutional enforcement (NEVER delete branches)
- [x] T030 [US3] Add sync status output (up-to-date/behind/ahead/diverged)

**Checkpoint**: `/git-sync` skill fully functional and testable independently

---

## Phase 5: User Story 4 - Full Development Workflow (Priority: P4)

**Goal**: Complete development cycle via `/full-workflow` slash command

**Independent Test**: Run `/full-workflow` in Claude Code → See all stages execute with comprehensive report

**Note**: This story depends on US1-US3 being complete (orchestrates those skills)

### Implementation for User Story 4

- [x] T031 [US4] Create skill file `.claude/commands/full-workflow.md` with YAML frontmatter
- [x] T032 [US4] Add description field: "Complete development cycle with validation"
- [x] T033 [US4] Add orchestration section (health-check → deploy-site → git-sync)
- [x] T034 [US4] Add uncommitted changes detection and prompt
- [x] T035 [US4] Add local CI/CD validation step (constitutional requirement)
- [x] T036 [US4] Add stage timing and metrics collection
- [x] T037 [US4] Add comprehensive report generation
- [x] T038 [US4] Add constitutional enforcement (local validation before GitHub)
- [x] T039 [US4] Add optional timestamped branch creation

**Checkpoint**: `/full-workflow` skill orchestrates all other skills successfully

---

## Phase 6: Install Script & Polish

**Purpose**: Enable global skill availability and final verification

- [x] T040 Create install script `scripts/install-claude-skills.sh`
- [x] T041 Add directory creation for `~/.claude/commands/` in install script
- [x] T042 Add file copy logic (project → user-level) in install script
- [x] T043 Add deprecated skill removal (`full-git-workflow.md`) in install script
- [x] T044 Add idempotency check in install script
- [x] T045 Run install script and verify files copied to `~/.claude/commands/`
- [x] T046 Test `/health-check` skill in Claude Code
- [x] T047 Test `/deploy-site` skill in Claude Code
- [x] T048 Test `/git-sync` skill in Claude Code
- [x] T049 Test `/full-workflow` skill in Claude Code
- [x] T050 Verify handoff buttons appear after each skill
- [x] T051 Verify hot-reload works (edit skill file → immediate effect)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (US1)**: Depends on Phase 1 - creates first skill
- **Phase 3 (US2)**: Can run parallel with US1 (different files)
- **Phase 4 (US3)**: Can run parallel with US1, US2 (different files)
- **Phase 5 (US4)**: Should complete AFTER US1-US3 (orchestrates them)
- **Phase 6 (Polish)**: Depends on all skills being complete

### User Story Dependencies

- **US1 (Health Check)**: Independent - no dependencies on other skills
- **US2 (Deploy Site)**: Independent - no dependencies on other skills
- **US3 (Git Sync)**: Independent - no dependencies on other skills
- **US4 (Full Workflow)**: References US1-US3 (orchestration skill)

### Parallel Opportunities

**Phase 2-4 can run in parallel**:
- T002-T009 (US1) parallel with T010-T019 (US2) parallel with T020-T030 (US3)
- All create different files in `.claude/commands/`

**Within each user story**:
- All tasks are sequential (same file)

---

## Parallel Example: User Stories 1-3

```text
# Launch all skill file creations in parallel (Phase 2-4):
Task: "Create skill file .claude/commands/health-check.md"
Task: "Create skill file .claude/commands/deploy-site.md"
Task: "Create skill file .claude/commands/git-sync.md"

# Then complete each skill's implementation in parallel
# (each task modifies only its own file)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: User Story 1 (health-check)
3. **STOP and VALIDATE**: Test `/health-check` independently
4. User has working diagnostics tool

### Incremental Delivery

1. Phase 1 (Setup) → Directory ready
2. Phase 2 (US1) → `/health-check` works → Demo
3. Phase 3 (US2) → `/deploy-site` works → Demo
4. Phase 4 (US3) → `/git-sync` works → Demo
5. Phase 5 (US4) → `/full-workflow` orchestrates all → Demo
6. Phase 6 (Polish) → Install script, verification complete

### Recommended Order

Since all skills are independent files:
1. T001 (setup)
2. T002-T030 in parallel (all skill files)
3. T031-T039 (orchestrator skill - after others for testing)
4. T040-T051 (install and verify)

---

## Notes

- All skill files go in `.claude/commands/` (project-level templates)
- Install script copies to `~/.claude/commands/` (user-level)
- Skills wrap existing scripts - DO NOT create new .sh files (constitutional)
- YAML frontmatter format: `description` + `handoffs` array
- Test skills by invoking in Claude Code (e.g., type `/health-check`)
- Hot-reload: Edit skill file → changes take effect without restart (v2.1.0+)
