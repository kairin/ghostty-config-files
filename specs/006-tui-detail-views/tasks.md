# Tasks: TUI Detail Views

**Input**: Design documents from `/specs/006-tui-detail-views/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No tests requested in specification - manual TUI testing only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Go TUI project**: `tui/internal/ui/` for UI components, `tui/cmd/installer/` for entry point
- Reference implementation: `tui/internal/ui/nerdfonts.go`

---

## Phase 1: Setup

**Purpose**: Verify environment and understand existing code

- [x] T001 Verify Go 1.23+ installed and TUI compiles: `cd tui && go build ./cmd/installer`
- [x] T002 [P] Read reference implementation `tui/internal/ui/nerdfonts.go` to understand component pattern
- [x] T003 [P] Read current `tui/internal/ui/model.go` to understand View enum and routing
- [x] T004 [P] Read current `tui/internal/ui/extras.go` to understand current table implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core ViewToolDetail component that MUST be complete before ANY user story navigation can work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete (ViewToolDetail must exist)

- [x] T005 Create `tui/internal/ui/tooldetail.go` with ToolDetailModel struct containing: tool, status, cursor, loading, spinner, returnTo, state, cache, repoRoot, width, height fields
- [x] T006 Implement NewToolDetailModel constructor in `tui/internal/ui/tooldetail.go` - accept tool, returnTo view, state, cache, repoRoot params
- [x] T007 Implement Init() method in `tui/internal/ui/tooldetail.go` - return spinner tick and status load command
- [x] T008 Implement Update() method in `tui/internal/ui/tooldetail.go` - handle spinner tick, status loaded, window resize, key messages
- [x] T009 Implement View() method in `tui/internal/ui/tooldetail.go` - render header, status table (5 rows), action menu
- [x] T010 Implement HandleKey() method in `tui/internal/ui/tooldetail.go` - up/down navigation, enter selection, escape back
- [x] T011 Implement helper methods in `tui/internal/ui/tooldetail.go` - IsBackSelected(), GetSelectedAction()
- [x] T012 Add ViewToolDetail constant to View enum in `tui/internal/ui/model.go` (after ViewConfirm)
- [x] T013 Add toolDetail and toolDetailFrom fields to Model struct in `tui/internal/ui/model.go`

**Checkpoint**: ViewToolDetail component exists and can be instantiated - user story routing can now begin

---

## Phase 3: User Story 1 - View Individual Tool Details (Priority: P1) 🎯 MVP

**Goal**: Users can select a tool from any menu and see complete status information on a dedicated detail view

**Independent Test**: Navigate to Ghostty via main menu → verify header visible, status table shows all 5 fields, actions work, Escape returns to dashboard

### Implementation for User Story 1

- [x] T014 [US1] Add ViewToolDetail case to Update() switch in `tui/internal/ui/model.go` - delegate to toolDetail.Update()
- [x] T015 [US1] Add ViewToolDetail case to View() switch in `tui/internal/ui/model.go` - call toolDetail.View()
- [x] T016 [US1] Implement navigation TO ViewToolDetail in `tui/internal/ui/model.go` - create ToolDetailModel with selected tool, set toolDetailFrom
- [x] T017 [US1] Implement navigation FROM ViewToolDetail in `tui/internal/ui/model.go` - on back/escape, restore toolDetailFrom view
- [x] T018 [US1] Wire up Install action in ViewToolDetail - call executor.RunInstall() and return to detail view
- [x] T019 [US1] Wire up Uninstall action in ViewToolDetail - show ViewConfirm, then executor.RunUninstall()
- [x] T020 [US1] Wire up Reinstall action in ViewToolDetail - call appropriate reinstall flow
- [x] T021 [US1] Add refresh (r key) support in ViewToolDetail - reload status via cache

**Checkpoint**: User Story 1 complete - ViewToolDetail fully functional, can navigate to/from it, all actions work

---

## Phase 4: User Story 2 - Simplified Main Dashboard (Priority: P2)

**Goal**: Main dashboard shows only 3 tools in table, with Ghostty/Feh as top menu items

**Independent Test**: Launch TUI → verify table shows 3 tools only, menu shows Ghostty first then Feh, selecting either opens ViewToolDetail

### Implementation for User Story 2

- [x] T022 [US2] Modify renderMainTable() in `tui/internal/ui/model.go` - filter to show only Node.js, AI Tools, Antigravity (3 tools)
- [x] T023 [US2] Add Ghostty menu item at position 0 (top) in main dashboard menu in `tui/internal/ui/model.go`
- [x] T024 [US2] Add Feh menu item at position 1 in main dashboard menu in `tui/internal/ui/model.go`
- [x] T025 [US2] Handle Ghostty menu selection → create ViewToolDetail with ghostty tool, set toolDetailFrom=ViewDashboard
- [x] T026 [US2] Handle Feh menu selection → create ViewToolDetail with feh tool, set toolDetailFrom=ViewDashboard
- [x] T027 [US2] Update menu indices in main dashboard to account for Ghostty/Feh at top (Update All now at 2, etc.)

**Checkpoint**: User Story 2 complete - dashboard shows 3 tools, Ghostty/Feh accessible via menu

---

## Phase 5: User Story 3 - Menu-Based Extras Navigation (Priority: P3)

**Goal**: Extras shows navigation menu instead of table, each tool navigates to ViewToolDetail

**Independent Test**: Navigate to Extras → verify no table, 7 tools in alphabetical order as menu items, selecting any opens ViewToolDetail, Back returns to Extras

### Implementation for User Story 3

- [x] T028 [US3] Remove renderExtrasTable() call from View() in `tui/internal/ui/extras.go`
- [x] T029 [US3] Replace table with navigation menu rendering in `tui/internal/ui/extras.go` - 7 tools + action items
- [x] T030 [US3] Add alphabetically ordered tool menu items in `tui/internal/ui/extras.go`: Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH
- [x] T031 [US3] Keep existing menu items below tools: Install All, Install Claude Config, MCP Servers, Back
- [x] T032 [US3] Handle tool selection in extras → create ViewToolDetail with selected tool, set toolDetailFrom=ViewExtras
- [x] T033 [US3] Update ExtrasModel to track which menu item is a tool vs action for proper navigation handling
- [x] T034 [US3] Verify Escape from tool detail returns to ViewExtras (not dashboard)

**Checkpoint**: User Story 3 complete - Extras is menu-based, all 7 tools navigate to detail views

---

## Phase 6: Polish & Verification

**Purpose**: Final validation and documentation

- [x] T035 Run `cd tui && go build ./cmd/installer` - verify compilation succeeds with no errors
- [x] T036 [P] Manual test: Main dashboard shows exactly 3 tools in table
- [x] T037 [P] Manual test: Ghostty and Feh appear at top of main menu
- [x] T038 [P] Manual test: Selecting Ghostty shows detail view with visible header and all status fields
- [x] T039 [P] Manual test: Escape from ViewToolDetail returns to correct parent (dashboard or extras)
- [x] T040 [P] Manual test: Extras shows menu with 7 alphabetically ordered tools, no table
- [x] T041 [P] Manual test: Each extras tool navigates to its detail view
- [x] T042 Manual test: Install, Uninstall, Refresh (r) all work from detail view
- [x] T043 Run quickstart.md validation checklist
- [x] T044 Update ROADMAP.md Wave 6a tasks to completed status

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (T005-T013)
- **User Story 2 (Phase 4)**: Depends on User Story 1 (needs ViewToolDetail routing)
- **User Story 3 (Phase 5)**: Depends on User Story 1 (needs ViewToolDetail routing)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Requires Foundational (Phase 2) - Core component + routing
- **User Story 2 (P2)**: Requires US1 - Uses ViewToolDetail navigation pattern
- **User Story 3 (P3)**: Requires US1 - Uses ViewToolDetail navigation pattern

**Note**: US2 and US3 can be implemented in parallel after US1 is complete (different files: model.go vs extras.go)

### Within Each User Story

- Implementation in dependency order (model before routing before actions)
- Commit after each logical task group
- Manual test at checkpoint before proceeding

### Parallel Opportunities

- T002, T003, T004 (Phase 1 reading) can run in parallel
- T036-T041 (Phase 6 manual tests) can run in parallel
- After US1 complete, US2 and US3 can run in parallel (different files)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (verify build, read code)
2. Complete Phase 2: Foundational (create tooldetail.go, add ViewToolDetail enum)
3. Complete Phase 3: User Story 1 (routing and actions)
4. **STOP and VALIDATE**: Test ViewToolDetail independently
5. Proceed to US2/US3

### Incremental Delivery

1. Setup + Foundational → ViewToolDetail component ready
2. Add User Story 1 → Detail views work from any context
3. Add User Story 2 → Main dashboard simplified (3 tools + menu items)
4. Add User Story 3 → Extras converted to menu navigation
5. Polish → All tests pass, ROADMAP updated

---

## Notes

- Reference `nerdfonts.go` lines 24-55 for model struct, 56-101 for constructor, 200-235 for View(), 377-440 for HandleKey()
- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- 300-line limit per file per constitution - tooldetail.go estimated ~250 lines
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
