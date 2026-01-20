# Tasks: TUI Dashboard Consistency

**Input**: Design documents from `/specs/008-tui-dashboard-consistency/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec - tests omitted per Task Generation Rules.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **TUI Application**: `tui/internal/ui/` for UI components
- **Registry**: `tui/internal/registry/` for tool definitions
- **Commands**: `tui/cmd/installer/` for entry point

---

## Phase 1: Setup

**Purpose**: Project initialization and ViewState foundation

- [X] T001 Verify current build compiles with `cd tui && go build ./cmd/installer`
- [X] T002 Add ViewBatchPreview constant to View enum in tui/internal/ui/model.go
- [X] T003 [P] Add batchPreview field (*BatchPreviewModel) to Model struct in tui/internal/ui/model.go

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core BatchPreviewModel component that ALL user stories depend on

**⚠️ CRITICAL**: User Stories 2 and 4 cannot begin until this phase is complete

- [X] T004 Create tui/internal/ui/batchpreview.go with BatchPreviewModel struct
- [X] T005 Implement NewBatchPreviewModel constructor for tools in tui/internal/ui/batchpreview.go
- [X] T006 Implement NewBatchPreviewModelForFonts constructor in tui/internal/ui/batchpreview.go
- [X] T007 Implement Init() method returning nil in tui/internal/ui/batchpreview.go
- [X] T008 Implement Update() method with keyboard navigation in tui/internal/ui/batchpreview.go
- [X] T009 Implement View() method with item list and buttons in tui/internal/ui/batchpreview.go
- [X] T010 Implement helper methods (IsConfirmed, IsCancelled, GetTools, GetFonts, GetReturnView) in tui/internal/ui/batchpreview.go
- [X] T011 Add ViewBatchPreview case to View() switch in tui/internal/ui/model.go
- [X] T012 Add ViewBatchPreview handling in Update() for key messages in tui/internal/ui/model.go
- [X] T013 Verify batchpreview.go compiles with `cd tui && go build ./cmd/installer`

**Checkpoint**: BatchPreviewModel component ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Consistent Tool Navigation (Priority: P1) 🎯 MVP

**Goal**: All tools (table and menu) navigate through ViewToolDetail before showing actions

**Independent Test**: Select nodejs from the table and verify it shows ViewToolDetail before actions. Compare to selecting Ghostty from menu.

### Implementation for User Story 1

- [X] T014 [US1] Locate handleEnter() function table tool handling in tui/internal/ui/model.go (~line 1033)
- [X] T015 [US1] Replace ViewAppMenu navigation with ViewToolDetail for table tools in tui/internal/ui/model.go
- [X] T016 [US1] Ensure ToolDetailModel receives correct returnView (ViewDashboard) in tui/internal/ui/model.go
- [ ] T017 [US1] Verify nodejs table selection shows ViewToolDetail by running TUI manually
- [ ] T018 [US1] Verify ai_tools table selection shows ViewToolDetail by running TUI manually
- [ ] T019 [US1] Verify antigravity table selection shows ViewToolDetail by running TUI manually
- [ ] T020 [US1] Verify ESC from ViewToolDetail returns to Dashboard

**Checkpoint**: User Story 1 complete - all table tools now use ViewToolDetail like menu tools

---

## Phase 4: User Story 2 - Batch Operation Preview (Priority: P2)

**Goal**: "Update All" and "Install All" show preview screens before execution

**Independent Test**: Select "Update All" and verify a preview screen shows which tools will be updated before starting.

### Implementation for User Story 2

- [X] T021 [US2] Locate startBatchUpdate call in handleEnter() in tui/internal/ui/model.go (~line 1054)
- [X] T022 [US2] Create helper function getToolsNeedingUpdates() returning []*registry.Tool in tui/internal/ui/model.go
- [X] T023 [US2] Replace immediate startBatchUpdate with BatchPreviewModel creation in tui/internal/ui/model.go
- [X] T024 [US2] Add status map copy for preview display in tui/internal/ui/model.go
- [X] T025 [US2] Handle BatchPreview confirmation to start batch update in tui/internal/ui/model.go
- [X] T026 [US2] Locate Extras Install All handling in tui/internal/ui/model.go (~line 455)
- [X] T027 [US2] Replace immediate batch start with BatchPreviewModel for Extras Install All in tui/internal/ui/model.go
- [ ] T028 [US2] Verify "Update All" shows preview by running TUI manually
- [ ] T029 [US2] Verify "Install All" (Extras) shows preview by running TUI manually
- [ ] T030 [US2] Verify Cancel returns to origin view in both cases

**Checkpoint**: User Story 2 complete - batch operations show preview before execution

---

## Phase 5: User Story 3 - Claude Config In-TUI Progress (Priority: P1)

**Goal**: "Install Claude Config" shows progress within TUI instead of exiting to terminal

**Independent Test**: Select "Install Claude Config" from Extras and verify progress is shown in a TUI view.

### Implementation for User Story 3

- [X] T031 [US3] Locate IsClaudeConfigSelected handling in extras section of tui/internal/ui/model.go
- [X] T032 [US3] Create pseudo-tool struct for Claude Config inline in tui/internal/ui/model.go
- [X] T033 [US3] Remove tea.ExecProcess call for Claude Config in tui/internal/ui/model.go
- [X] T034 [US3] Create InstallerModel with pseudo-tool for Claude Config in tui/internal/ui/model.go
- [X] T035 [US3] Set currentView to ViewInstaller and emit start message in tui/internal/ui/model.go
- [ ] T036 [US3] Verify "Install Claude Config" shows ViewInstaller by running TUI manually
- [ ] T037 [US3] Verify installation progress displays in TUI
- [ ] T038 [US3] Verify ESC returns to Extras after completion

**Checkpoint**: User Story 3 complete - Claude Config installation stays within TUI

---

## Phase 6: User Story 4 - Nerd Fonts Install All Preview (Priority: P2)

**Goal**: "Install All" in Nerd Fonts shows preview of fonts to be installed

**Independent Test**: From Nerd Fonts with some fonts missing, select "Install All" and verify preview is shown.

### Implementation for User Story 4

- [X] T039 [US4] Locate IsInstallAllSelected handling in nerdfonts section of tui/internal/ui/model.go
- [X] T040 [US4] Extract missing fonts from NerdFontsModel state in tui/internal/ui/model.go
- [X] T041 [US4] Create BatchPreviewModelForFonts with missing fonts list in tui/internal/ui/model.go
- [X] T042 [US4] Handle confirmation to start nerdfonts batch install in tui/internal/ui/model.go
- [ ] T043 [US4] Verify "Install All" (Nerd Fonts) shows preview by running TUI manually
- [ ] T044 [US4] Verify preview lists only missing fonts, not all fonts
- [ ] T045 [US4] Verify Cancel returns to ViewNerdFonts

**Checkpoint**: User Story 4 complete - Nerd Fonts batch install shows preview

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup and verification

- [ ] T046 Remove unused ViewAppMenu code from tui/internal/ui/model.go (after all stories verified)
- [X] T047 [P] Search for remaining tea.ExecProcess usage to ensure only sudo operations remain
- [X] T048 Run `cd tui && go build ./cmd/installer` to verify final build
- [ ] T049 Manual verification of all 26 menu items per research.md inventory
- [ ] T050 [P] Update quickstart.md verification steps if needed in specs/008-tui-dashboard-consistency/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS User Stories 2 and 4
- **User Story 1 (Phase 3)**: Can start after Setup (no BatchPreview needed)
- **User Story 2 (Phase 4)**: Depends on Foundational (uses BatchPreviewModel)
- **User Story 3 (Phase 5)**: Can start after Setup (no BatchPreview needed)
- **User Story 4 (Phase 6)**: Depends on Foundational (uses BatchPreviewModelForFonts)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

```
Setup (Phase 1)
    │
    ├──────────────────────────────────┐
    │                                  │
    ▼                                  ▼
Foundational (Phase 2)          US1 (Phase 3) - P1
    │                                  │
    ├─────────────┐                    │
    │             │                    │
    ▼             ▼                    │
US2 (Phase 4)  US4 (Phase 6)           │
    │             │                    │
    └─────────────┴────────────────────┘
                  │
                  ▼
           US3 (Phase 5) - P1
                  │
                  ▼
           Polish (Phase 7)
```

### Parallel Opportunities

**After Setup:**
- US1 and US3 can start immediately (both P1, independent)
- Foundational (Phase 2) can run in parallel with US1/US3

**After Foundational:**
- US2 and US4 can run in parallel (both P2, independent)

### Within Each Phase

- Tasks marked [P] within a phase can run in parallel
- Sequential tasks depend on prior task completion

---

## Parallel Example: Setup + User Story 1 + User Story 3

```bash
# These can run in parallel after T001 completes:

# Thread 1: Foundational work
Task: "T004 Create tui/internal/ui/batchpreview.go..."
Task: "T005 Implement NewBatchPreviewModel..."
# ...continues through T013

# Thread 2: User Story 1 (table tools)
Task: "T014 [US1] Locate handleEnter() function..."
Task: "T015 [US1] Replace ViewAppMenu navigation..."
# ...continues through T020

# Thread 3: User Story 3 (Claude Config)
Task: "T031 [US3] Locate IsClaudeConfigSelected..."
Task: "T032 [US3] Create pseudo-tool struct..."
# ...continues through T038
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 3)

1. Complete Phase 1: Setup
2. Start Phase 3: User Story 1 (table tool navigation) - HIGH IMPACT
3. Start Phase 5: User Story 3 (Claude Config in TUI) - HIGH IMPACT
4. **STOP and VALIDATE**: Test both independently
5. These are both P1 priority and can be delivered immediately

### Incremental Delivery

1. Setup + US1 + US3 → Test → Deploy (MVP - 77% → 92% consistency)
2. Add Foundational + US2 + US4 → Test → Deploy (100% consistency)
3. Polish → Final cleanup and verification

### Single Developer Strategy

1. Setup (30 min)
2. User Story 1 (1 hour) - biggest user impact
3. User Story 3 (1 hour) - stops TUI exits
4. Foundational (1.5 hours)
5. User Story 2 (1 hour)
6. User Story 4 (45 min)
7. Polish (30 min)

**Total: ~6 hours**

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All file paths are relative to repository root
