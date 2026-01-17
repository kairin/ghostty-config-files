# Tasks: Wave 1 - Scripts Documentation Foundation

**Input**: Design documents from `/specs/002-scripts-documentation/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete)
**Branch**: `002-scripts-documentation`

**Note**: This is documentation-only work. No tests required (manual verification via file existence and link validation).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US5)
- Include exact file paths in descriptions

## Path Reference

| Deliverable | Path |
|-------------|------|
| Scripts master index | `scripts/README.md` |
| MCP consolidated guide | `.claude/instructions-for-agents/guides/mcp-setup.md` |
| Update scripts README | `scripts/007-update/README.md` |
| Diagnostics README | `scripts/007-diagnostics/README.md` |
| AI tools doc fix | `.claude/instructions-for-agents/tools/ai-cli-tools.md` |

---

## Phase 1: Setup

**Purpose**: Preparation and context gathering (minimal for docs-only work)

- [x] T001 Verify branch is `002-scripts-documentation` and working directory is clean
- [x] T002 [P] Enumerate all scripts: `find scripts/ -name "*.sh" -type f | sort > /tmp/scripts-list.txt`
- [x] T003 [P] Read existing MCP guides to identify unique content for consolidation

**Checkpoint**: Ready to create documentation

---

## Phase 2: User Story 1 - Script Discovery via Master Index (Priority: P1) 🎯 MVP

**Goal**: Create `/scripts/README.md` with searchable index of all 114 scripts

**Independent Test**: Search README for "ghostty" → find `check_ghostty.sh`, `update_ghostty.sh`, etc. within 10 seconds

### Implementation for User Story 1

- [x] T004 [US1] Create scripts/README.md with header, overview section, and metadata in scripts/README.md
- [x] T005 [US1] Add stage directory reference table (000-007 purposes and script counts) in scripts/README.md
- [x] T006 [US1] Document 000-check scripts (14 scripts) with descriptions in scripts/README.md
- [x] T007 [US1] Document 001-uninstall scripts (13 scripts) with descriptions in scripts/README.md
- [x] T008 [US1] Document 002-install-first-time scripts (15 scripts) with descriptions in scripts/README.md
- [x] T009 [US1] Document 003-verify scripts (13 scripts) with descriptions in scripts/README.md
- [x] T010 [US1] Document 004-reinstall scripts (13 scripts) with descriptions in scripts/README.md
- [x] T011 [US1] Document 005-confirm scripts (13 scripts) with descriptions in scripts/README.md
- [x] T012 [US1] Document 006-logs scripts with descriptions in scripts/README.md
- [x] T013 [US1] Document 007-update scripts (12 scripts) with descriptions in scripts/README.md
- [x] T014 [US1] Document 007-diagnostics scripts with descriptions in scripts/README.md
- [x] T015 [US1] Document mcp/ directory scripts with descriptions in scripts/README.md
- [x] T016 [US1] Document vhs/ directory scripts with descriptions in scripts/README.md
- [x] T017 [US1] Document root-level scripts (check_updates.sh, daily-updates.sh, etc.) in scripts/README.md
- [x] T018 [US1] Add quick reference section (common operations) in scripts/README.md
- [x] T019 [US1] Verify script count matches `find scripts/ -name "*.sh" | wc -l` (should be 114)

**Checkpoint**: User Story 1 complete - scripts/README.md provides searchable index of all 114 scripts

---

## Phase 3: User Story 2 - MCP Setup from Single Source (Priority: P2)

**Goal**: Consolidate 5 MCP guides into single authoritative source + create redirect stubs

**Independent Test**: Follow mcp-setup.md to configure all 7 MCP servers without needing other guides

### Implementation for User Story 2

- [x] T020 [US2] Copy mcp-new-machine-setup.md to mcp-setup.md in .claude/instructions-for-agents/guides/mcp-setup.md
- [x] T021 [US2] Extract unique Context7 content from context7-mcp.md and merge into mcp-setup.md
- [x] T022 [US2] Extract unique GitHub content from github-mcp.md and merge into mcp-setup.md
- [x] T023 [US2] Extract unique MarkItDown content from markitdown-mcp.md and merge into mcp-setup.md
- [x] T024 [US2] Extract unique Playwright content from playwright-mcp.md and merge into mcp-setup.md
- [x] T025 [US2] Update mcp-setup.md table of contents and internal links
- [x] T026 [P] [US2] Create redirect stub in .claude/instructions-for-agents/guides/context7-mcp.md
- [x] T027 [P] [US2] Create redirect stub in .claude/instructions-for-agents/guides/github-mcp.md
- [x] T028 [P] [US2] Create redirect stub in .claude/instructions-for-agents/guides/markitdown-mcp.md
- [x] T029 [P] [US2] Create redirect stub in .claude/instructions-for-agents/guides/playwright-mcp.md
- [x] T030 [US2] Verify all 7 MCP servers documented in consolidated guide

**Checkpoint**: User Story 2 complete - single MCP guide with redirect stubs

---

## Phase 4: User Story 3 - Update Script Discovery (Priority: P3)

**Goal**: Create `/scripts/007-update/README.md` documenting all 12 update scripts

**Independent Test**: Read README and understand how to update any tool without examining script source code

### Implementation for User Story 3

- [x] T031 [US3] Create scripts/007-update/README.md with header and overview
- [x] T032 [US3] Add table of all 12 update scripts with tool names and update methods in scripts/007-update/README.md
- [x] T033 [US3] Document usage section (manual update command syntax) in scripts/007-update/README.md
- [x] T034 [US3] Document batch update via daily-updates.sh in scripts/007-update/README.md
- [x] T035 [US3] Add logging section (log locations, update-logs alias) in scripts/007-update/README.md
- [x] T036 [US3] Add troubleshooting section (common issues, solutions) in scripts/007-update/README.md
- [x] T037 [US3] Verify all 12 update scripts are documented

**Checkpoint**: User Story 3 complete - 007-update/README.md explains all update scripts

---

## Phase 5: User Story 4 - Boot Diagnostics Understanding (Priority: P4)

**Goal**: Create `/scripts/007-diagnostics/README.md` documenting diagnostic workflow

**Independent Test**: Read README and successfully run boot diagnostics without prior knowledge

### Implementation for User Story 4

- [x] T038 [US4] Create scripts/007-diagnostics/README.md with header and overview
- [x] T039 [US4] Document directory structure (boot_diagnostics.sh, quick_scan.sh, detectors/, lib/) in scripts/007-diagnostics/README.md
- [x] T040 [US4] Document quick_scan.sh usage and output in scripts/007-diagnostics/README.md
- [x] T041 [US4] Document boot_diagnostics.sh usage and output in scripts/007-diagnostics/README.md
- [x] T042 [US4] Document detectors/ subdirectory contents and purpose in scripts/007-diagnostics/README.md
- [x] T043 [US4] Document lib/ subdirectory contents and purpose in scripts/007-diagnostics/README.md
- [x] T044 [US4] Add "what gets checked" section listing all diagnostic checks in scripts/007-diagnostics/README.md

**Checkpoint**: User Story 4 complete - 007-diagnostics/README.md explains diagnostic workflow

---

## Phase 6: User Story 5 - Accurate AI Tools Documentation (Priority: P5)

**Goal**: Fix ai-cli-tools.md to reflect that 4 scripts now exist

**Independent Test**: All script paths in ai-cli-tools.md resolve to existing files

### Implementation for User Story 5

- [x] T045 [US5] Update status from "PLANNED" to "IMPLEMENTED" in .claude/instructions-for-agents/tools/ai-cli-tools.md
- [x] T046 [US5] Update scripts table with correct paths (install, uninstall, confirm, update) in .claude/instructions-for-agents/tools/ai-cli-tools.md
- [x] T047 [US5] Remove or update "Missing Scripts" section in .claude/instructions-for-agents/tools/ai-cli-tools.md
- [x] T048 [US5] Update "Last Updated" date in .claude/instructions-for-agents/tools/ai-cli-tools.md
- [x] T049 [US5] Verify all 4 script paths exist: `ls scripts/004-reinstall/install_ai_tools.sh scripts/001-uninstall/uninstall_ai_tools.sh scripts/005-confirm/confirm_ai_tools.sh scripts/007-update/update_ai_tools.sh`

**Checkpoint**: User Story 5 complete - ai-cli-tools.md accurately reflects current state

---

## Phase 7: Polish & Verification

**Purpose**: Final validation across all deliverables

- [x] T050 Validate all internal links resolve (no broken links)
- [x] T051 Verify documentation follows existing patterns (headers, tables, code blocks, no emojis)
- [x] T052 Run final script count verification: README documents same count as `find scripts/ -name "*.sh" | wc -l`
- [x] T053 Update ROADMAP.md to mark Wave 1 tasks as complete
- [x] T054 Commit all changes with descriptive message

**Checkpoint**: All documentation complete and verified

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ────────────────────────────────────────────────────────────►
                 │
                 ▼
         ┌───────┴───────┬───────────────┬───────────────┬───────────────┐
         ▼               ▼               ▼               ▼               ▼
    Phase 2 (US1)   Phase 3 (US2)   Phase 4 (US3)   Phase 5 (US4)   Phase 6 (US5)
    Scripts README  MCP Consolidate  007-update     007-diagnostics  AI Tools Fix
         │               │               │               │               │
         └───────┬───────┴───────────────┴───────────────┴───────────────┘
                 ▼
           Phase 7 (Polish)
```

### User Story Independence

| Story | Can Start After | Dependencies on Other Stories |
|-------|-----------------|-------------------------------|
| US1 (Scripts README) | Phase 1 | None |
| US2 (MCP Consolidation) | Phase 1 | None |
| US3 (007-update README) | Phase 1 | None |
| US4 (007-diagnostics README) | Phase 1 | None |
| US5 (AI Tools Fix) | Phase 1 | None |

**All user stories are independent and can run in parallel!**

### Parallel Opportunities

**Within User Story 2 (MCP):**
```
T026, T027, T028, T029 can all run in parallel (redirect stubs are independent files)
```

**Across User Stories:**
```
After Phase 1 completes, ALL of the following can run in parallel:
- US1: T004-T019 (scripts/README.md)
- US2: T020-T030 (MCP consolidation)
- US3: T031-T037 (007-update/README.md)
- US4: T038-T044 (007-diagnostics/README.md)
- US5: T045-T049 (ai-cli-tools.md fix)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: User Story 1 (scripts/README.md)
3. **STOP and VALIDATE**: Search for any tool name → find correct script in <30 seconds
4. Commit MVP if time-constrained

### Recommended Execution Order

Since all stories are independent, execute in priority order:

1. **P1 (US1)**: Scripts README - highest value, enables all script discovery
2. **P5 (US5)**: AI Tools Fix - quick win (15 min), fixes inaccurate documentation
3. **P3 (US3)**: 007-update README - frequently used scripts
4. **P4 (US4)**: 007-diagnostics README - smaller scope
5. **P2 (US2)**: MCP Consolidation - most complex, do last

### Parallel Team Strategy (if applicable)

With multiple sessions or agents:

```
Agent A: US1 (Scripts README) - largest task
Agent B: US2 (MCP Consolidation) - complex merge work
Agent C: US3 + US4 + US5 (smaller tasks) - can complete all three
```

---

## Task Summary

| Phase | Story | Task Count | Effort |
|-------|-------|------------|--------|
| Setup | - | 3 | 5 min |
| US1 | Scripts README | 16 | 1 hr |
| US2 | MCP Consolidation | 11 | 2 hr |
| US3 | 007-update README | 7 | 30 min |
| US4 | 007-diagnostics README | 7 | 30 min |
| US5 | AI Tools Fix | 5 | 15 min |
| Polish | - | 5 | 15 min |
| **Total** | | **54 tasks** | **~4.5 hrs** |

---

## Notes

- All tasks create or modify markdown files only (no code changes)
- [P] tasks = different files, can run in parallel
- [USx] label maps task to specific user story for traceability
- Commit after completing each user story phase
- Verification is manual (file existence, link validation, visual review)
