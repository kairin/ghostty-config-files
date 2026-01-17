# Tasks: Wave 0 Foundation Fixes

**Input**: Design documents from `/specs/001-foundation-fixes/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete), data-model.md (complete)

**Tests**: Not requested - documentation-only feature with manual verification.

**Organization**: Tasks grouped by user story for independent implementation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All paths are absolute from repository root

---

## Phase 1: Setup (No Tasks Required)

**Purpose**: Project initialization

This is a documentation-only feature. No project setup, dependencies, or build configuration required.

**Checkpoint**: Ready to proceed directly to user stories.

---

## Phase 2: Foundational (No Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before user stories

No foundational blocking tasks - all user stories are independent and can proceed in parallel.

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - LICENSE File Creation (Priority: P1)

**Goal**: Create MIT LICENSE file at repository root for legal clarity

**Independent Test**: Verify LICENSE file exists at `/LICENSE` with valid MIT license content and GitHub detects it correctly.

### Implementation for User Story 1

- [x] T001 [US1] Create LICENSE file at /LICENSE with MIT license text
- [x] T002 [US1] Add copyright year 2026 and copyright holder name to LICENSE
- [x] T003 [US1] Verify LICENSE file content matches standard MIT format

**Checkpoint**: LICENSE file exists and GitHub should detect "MIT" license.

---

## Phase 4: User Story 2 - Broken Link Resolution (Priority: P1)

**Goal**: Fix broken link `../guides/local-cicd-guide.md` in local-cicd-operations.md

**Independent Test**: Follow all links in `local-cicd-operations.md` and verify each resolves to an existing file.

### Implementation for User Story 2

- [x] T004 [US2] Create /.claude/instructions-for-agents/guides/local-cicd-guide.md
- [x] T005 [US2] Add local CI/CD quick reference content (see quickstart.md template)
- [x] T006 [US2] Add troubleshooting section to local-cicd-guide.md
- [x] T007 [US2] Add cross-reference links to local-cicd-operations.md and git-strategy.md
- [x] T008 [US2] Verify broken link in /.claude/instructions-for-agents/requirements/local-cicd-operations.md now resolves

**Checkpoint**: All links in local-cicd-operations.md resolve to existing files.

---

## Phase 5: User Story 3 - Agent Tier Definition Unification (Priority: P2)

**Goal**: Unify tier definitions to consistent 5-tier structure across 4 documentation files

**Independent Test**: Compare tier tables in all 4 files and verify they show identical structure (Tier 0-4 with counts 5,1,5,4,50).

### Implementation for User Story 3

- [x] T009 [US3] Verify canonical tier table in /.claude/instructions-for-agents/architecture/agent-registry.md
- [x] T010 [P] [US3] Update tier table in /AGENTS.md to match canonical 5-tier structure
- [x] T011 [P] [US3] Update tier table in /.claude/instructions-for-agents/architecture/agent-delegation.md
- [x] T012 [P] [US3] Update tier table in /.claude/instructions-for-agents/architecture/system-architecture.md

> **Note**: If file uses combined "2-3" tier format, preserve it with count 9 (5+4 combined).

- [x] T013 [US3] Cross-verify all 4 files show identical tier counts: 5, 1, 5, 4, 50

**Checkpoint**: All architecture docs show consistent 5-tier structure.

---

## Phase 6: Polish & Verification

**Purpose**: Final verification and ROADMAP update

- [x] T014 Verify LICENSE detected by GitHub and README badge resolves (manual check after push)
- [x] T015 [P] Run link validation on all documentation in /.claude/instructions-for-agents/
- [x] T016 [P] Verify all tier references consistent across repository
- [x] T017 Update /ROADMAP.md to mark Wave 0 tasks complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Skipped - no setup needed
- **Foundational (Phase 2)**: Skipped - no blocking prerequisites
- **User Stories (Phase 3-5)**: All independent - can proceed in parallel
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies - LICENSE file is standalone
- **User Story 2 (P1)**: No dependencies - new guide file is standalone
- **User Story 3 (P2)**: No dependencies - tier updates are independent edits

### Within Each User Story

- US1: Single file creation, sequential tasks
- US2: File creation → content → verification
- US3: Verify source → parallel updates → cross-verify

### Parallel Opportunities

**All 3 User Stories can run in parallel** since they touch different files:

```text
US1: LICENSE (standalone)
US2: .claude/instructions-for-agents/guides/local-cicd-guide.md (new file)
US3: AGENTS.md, agent-delegation.md, system-architecture.md (separate files)
```

Within US3, tasks T010, T011, T012 can run in parallel (different files).

---

## Parallel Example: User Story 3

```bash
# Launch all tier updates together (different files, no conflicts):
Task: "Update tier table in /AGENTS.md"
Task: "Update tier table in /.claude/instructions-for-agents/architecture/agent-delegation.md"
Task: "Update tier table in /.claude/instructions-for-agents/architecture/system-architecture.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001-T003 (LICENSE file)
2. **STOP and VALIDATE**: Verify LICENSE exists and contains MIT text
3. Commit with message referencing US1

### Incremental Delivery

1. US1 → Commit → LICENSE visible on GitHub
2. US2 → Commit → Broken link fixed
3. US3 → Commit → Tier consistency achieved
4. Polish → Final commit → Wave 0 complete

### Recommended Single-Developer Flow

Since all stories are small and independent:

1. Complete US1 (T001-T003) - ~5 min
2. Complete US2 (T004-T008) - ~15 min
3. Complete US3 (T009-T013) - ~15 min
4. Complete Polish (T014-T017) - ~5 min
5. Single commit with all changes - follows spec SC-004 (<40 min total)

---

## Canonical Tier Table Reference

For US3 tasks, use this exact table format:

```markdown
| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| 0 | Sonnet | 5 | Complete workflows (000-*) |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 5 | Core operations |
| 3 | Sonnet | 4 | Utility operations |
| 4 | Haiku | 50 | Atomic execution |
```

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- All 3 user stories are independently completable
- No tests required (manual verification per spec)
- Commit after each story or as single batch
- Total: 17 tasks across 3 user stories + polish phase
