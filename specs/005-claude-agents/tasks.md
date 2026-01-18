# Tasks: Claude Agents User-Level Consolidation

**Input**: Design documents from `/specs/005-claude-agents/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: Manual verification only (per plan.md) - no automated tests requested

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Project root**: Repository root for `.claude/` directories
- **Scripts**: `scripts/` directory
- **User-level**: `~/.claude/` directories

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure for agent migration

- [x] T001 Create `.claude/agent-sources/` directory for agent source files
- [x] T002 Verify `.claude/skill-sources/` exists with 4 skill files

**Checkpoint**: Directory structure ready for agent migration

---

## Phase 2: Migration (Blocking Prerequisites)

**Purpose**: Move agent files from project-level to source directory

**⚠️ CRITICAL**: No install script work can begin until this phase is complete

- [x] T003 Move all 65 agent files from `.claude/agents/` to `.claude/agent-sources/` using `git mv`
- [x] T004 Verify all 65 files moved successfully (count files in `.claude/agent-sources/`)
- [x] T005 Verify `.claude/agents/` directory is empty after migration

**Checkpoint**: All 65 agents migrated to source directory - install script can now be created

---

## Phase 3: User Story 1 - Fresh System Setup (Priority: P1) 🎯 MVP

**Goal**: Enable fresh system installation of all 65 agents to user-level

**Independent Test**: Clone repo on fresh system, run install script, verify 65 agents in `~/.claude/agents/`

### Implementation for User Story 1

- [x] T006 [US1] Create `scripts/install-claude-config.sh` with header and color definitions
- [x] T007 [US1] Add source path variables for skills (`.claude/skill-sources/`) and agents (`.claude/agent-sources/`)
- [x] T008 [US1] Add target path variables for user-level skills (`~/.claude/commands/`) and agents (`~/.claude/agents/`)
- [x] T009 [US1] Implement agent directory creation logic (`mkdir -p ~/.claude/agents/`)
- [x] T010 [US1] Implement agent file copy loop from source to user-level
- [x] T011 [US1] Add agent installation counter and success messages
- [x] T012 [US1] Add final summary showing skills and agents installed counts

**Checkpoint**: Fresh installation works - US1 complete and independently testable

---

## Phase 4: User Story 2 - Update Agents Across Computers (Priority: P1)

**Goal**: Enable idempotent updates when agent definitions change

**Independent Test**: Modify an agent file, run install script, verify updated file at user-level

### Implementation for User Story 2

- [x] T013 [US2] Ensure agent copy overwrites existing files (idempotent behavior)
- [x] T014 [US2] Add skip message for agents not found in source (graceful handling)
- [x] T015 [US2] Verify script completes successfully on repeated runs with no changes

**Checkpoint**: Idempotent updates work - US2 complete and independently testable

---

## Phase 5: User Story 3 - Combined Skills and Agents Installation (Priority: P2)

**Goal**: Single command installs both skills (4) and agents (65)

**Independent Test**: Run install script, verify both `~/.claude/commands/` (4 files) and `~/.claude/agents/` (65 files)

### Implementation for User Story 3

- [x] T016 [US3] Add skills array with 4 skill filenames (001-health-check.md, etc.)
- [x] T017 [US3] Add agents array with pattern matching for all 65 agent files
- [x] T018 [US3] Implement skills installation loop (copy from skill-sources to commands)
- [x] T019 [US3] Add skills installation counter and messages
- [x] T020 [US3] Update summary to show both skills and agents counts

**Checkpoint**: Combined installation works - US3 complete and independently testable

---

## Phase 6: User Story 4 - Clean Up Deprecated Configuration (Priority: P3)

**Goal**: Automatically remove deprecated skill/agent files during installation

**Independent Test**: Create deprecated file at user-level, run install script, verify it's removed

### Implementation for User Story 4

- [x] T021 [US4] Add deprecated skills array (non-prefixed versions: health-check.md, etc.)
- [x] T022 [US4] Implement deprecated skills removal loop
- [x] T023 [US4] Add removal messages for deprecated files

**Checkpoint**: Deprecated cleanup works - US4 complete and independently testable

---

## Phase 7: Cleanup & Documentation

**Purpose**: Remove old script, update documentation

- [x] T024 [P] Remove deprecated `scripts/install-claude-skills.sh` (superseded by combined script)
- [x] T025 [P] Update ROADMAP.md to mark agents consolidation complete
- [x] T026 [P] Update relevant documentation references to use new install script name

---

## Phase 8: Verification

**Purpose**: End-to-end validation of complete feature

- [x] T027 Run `./scripts/install-claude-config.sh` and verify output
- [x] T028 Verify `~/.claude/commands/` contains 4 skill files
- [x] T029 Verify `~/.claude/agents/` contains 65 agent files
- [x] T030 Verify `.claude/agents/` directory is empty (no project-level agents)
- [x] T031 Test agent availability in Claude Code (manual check)
- [x] T032 Commit all changes with constitutional commit message

**Checkpoint**: Feature complete - all user stories verified

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Migration (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Migration phase completion
  - User stories are mostly sequential (US1 creates script, others extend it)
  - US3 and US4 can be worked on together once US1/US2 are done
- **Cleanup (Phase 7)**: Depends on all user stories being complete
- **Verification (Phase 8)**: Depends on Cleanup

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Migration - Creates base install script
- **User Story 2 (P1)**: Depends on US1 - Extends install script with idempotent behavior
- **User Story 3 (P2)**: Depends on US1/US2 - Adds skills installation to script
- **User Story 4 (P3)**: Depends on US3 - Adds deprecated file cleanup

### Within Each User Story

- Script creation/extension is sequential within each story
- All tasks within a story build on previous tasks
- Story complete before moving to next priority

### Parallel Opportunities

- T024, T025, T026 in Cleanup phase can run in parallel
- T028, T029, T030 verification tasks can run in parallel

---

## Parallel Example: Cleanup Phase

```bash
# These can run in parallel (different files):
Task T024: Remove scripts/install-claude-skills.sh
Task T025: Update ROADMAP.md
Task T026: Update documentation references
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Migration (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (fresh install capability)
4. Complete Phase 4: User Story 2 (idempotent updates)
5. **STOP and VALIDATE**: Test fresh install and updates work
6. This is a functional MVP - agents can be installed!

### Incremental Delivery

1. Complete Setup + Migration → Infrastructure ready
2. Add US1 + US2 → Core install works (MVP!)
3. Add US3 → Combined skills+agents in one command
4. Add US4 → Cleanup of deprecated files
5. Complete Cleanup + Verification → Feature fully done

---

## Notes

- All agent file operations use `git mv` to preserve history
- Install script must be idempotent (safe to run multiple times)
- Script follows same pattern as existing `install-claude-skills.sh`
- 65 agents = 5 Tier 0 + 1 Tier 1 + 5 Tier 2 + 4 Tier 3 + 50 Tier 4
- Skills are already in `.claude/skill-sources/` (migrated in previous work)
- Commit after each phase or logical group of tasks
