# Tasks: SpecKit Project Updater

**Input**: Design documents from `/specs/009-speckit-project-updater/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: Unit tests for speckit package (config, scanner, patcher) recommended.

**Organization**: Tasks are grouped by component/phase to enable incremental delivery and clear dependencies.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, etc.)
- Include exact file paths in descriptions

## Path Conventions

- **TUI Application**: `tui/internal/ui/` for UI components
- **SpecKit Package**: `tui/internal/speckit/` for core logic
- **Config**: `tui/internal/config/` for config path utilities

---

## Phase 1: Setup & Package Structure

**Purpose**: Create package structure and add ViewState definitions

- [X] T001 Verify current build compiles with `cd tui && go build ./cmd/installer`
- [X] T002 Create directory `tui/internal/speckit/`
- [X] T003 Add ViewSpecKitUpdater constant to View enum in tui/internal/ui/model.go
- [X] T004 [P] Add ViewSpecKitProjectDetail constant to View enum in tui/internal/ui/model.go
- [X] T005 [P] Add speckitUpdater field (*SpecKitUpdaterModel) to Model struct in tui/internal/ui/model.go
- [X] T006 [P] Add speckitDetail field (*SpecKitDetailModel) to Model struct in tui/internal/ui/model.go

**Checkpoint**: Package structure ready, ViewStates defined ✅

---

## Phase 2: Core Types & Config Persistence

**Purpose**: Define data structures and implement config persistence (enables all user stories)

**⚠️ CRITICAL**: User Stories 1-7 depend on this phase for config loading/saving

### Types (tui/internal/speckit/types.go)

- [X] T007 Create tui/internal/speckit/types.go with package declaration
- [X] T008 Define ProjectStatus type (string enum: pending, up-to-date, needs-update, error)
- [X] T009 Define FileDifference struct (File, LineStart, LineEnd, CanonicalContent, ProjectContent)
- [X] T010 Define TrackedProject struct (Path, LastScanned, Status, Differences, LastBackup)
- [X] T011 Define ProjectConfig struct (Version, Projects)

### Config Persistence (tui/internal/speckit/config.go)

- [X] T012 Create tui/internal/speckit/config.go with package declaration
- [X] T013 Implement getConfigPath() returning ~/.config/ghostty-installer/speckit-projects.json
- [X] T014 Implement LoadConfig() (JSON load, returns *ProjectConfig, creates empty if missing)
- [X] T015 Implement SaveConfig(*ProjectConfig) (JSON save with indentation)
- [X] T016 Implement AddProject(path string) (validates .specify/ exists, adds to config)
- [X] T017 Implement RemoveProject(path string) (removes from config by path)
- [X] T018 Implement UpdateProjectStatus(path, status, diffs, backup) (updates existing project)

**Checkpoint**: Config can be loaded, saved, and modified ✅

---

## Phase 3: Scanner Implementation

**Purpose**: File comparison logic (enables User Stories 2, 3)

### Scanner (tui/internal/speckit/scanner.go)

- [X] T019 Create tui/internal/speckit/scanner.go with package declaration
- [X] T020 Implement getCanonicalFilePaths(repoRoot string) returning list of canonical bash scripts
- [X] T021 Implement readFileLines(path string) returning []string and error
- [X] T022 Implement compareFiles(canonicalPath, projectPath string) returning []FileDifference
- [X] T023 Implement ScanProject(projectPath, repoRoot string) returning ([]FileDifference, error)
- [X] T024 Implement generateUnifiedDiff(canonical, project []string, filename string) returning string
- [X] T025 Verify scanner compiles with `cd tui && go build ./cmd/installer`

**Checkpoint**: Can scan a project and identify differing lines ✅

---

## Phase 4: Patcher Implementation

**Purpose**: Backup and patch logic (enables User Stories 4, 7)

### Patcher (tui/internal/speckit/patcher.go)

- [X] T026 Create tui/internal/speckit/patcher.go with package declaration
- [X] T027 Implement createBackupDir(projectPath string) returning backup path with timestamp
- [X] T028 Implement copyFile(src, dst string) for backup operations
- [X] T029 Implement CreateBackup(projectPath string, files []string) returning backupPath, error
- [X] T030 Implement ApplyPatch(projectPath, repoRoot string, diffs []FileDifference) returning error
- [X] T031 Implement RestoreFromBackup(projectPath, backupPath string) returning error
- [X] T032 Implement GetLatestBackup(projectPath string) returning backupPath, error
- [X] T033 Verify patcher compiles with `cd tui && go build ./cmd/installer`

**Checkpoint**: Can backup, patch, and rollback files ✅

---

## Phase 5: User Story 1 - Add Project Directory (Priority: P1) 🎯 MVP

**Goal**: Users can add project directories to the SpecKit Updater

**Independent Test**: Navigate to SpecKit Updater → Add Project → Enter path → Verify project appears in list.

### SpecKitUpdaterModel (tui/internal/ui/speckitupdater.go)

- [X] T034 [US1] Create tui/internal/ui/speckitupdater.go with package declaration
- [X] T035 [US1] Define SpecKitUpdaterModel struct (projects, cursor, loading, state, config, repoRoot)
- [X] T036 [US1] Define menu items (Add Project, Update All, Refresh, Back)
- [X] T037 [US1] Implement NewSpecKitUpdaterModel constructor
- [X] T038 [US1] Implement Init() returning config load command
- [X] T039 [US1] Implement Update() with keyboard navigation (arrow keys, enter, esc)
- [X] T040 [US1] Implement handleAddProject() showing text input modal
- [X] T041 [US1] Implement handleProjectSelect() navigating to ViewSpecKitProjectDetail
- [X] T042 [US1] Implement View() rendering project list with status icons
- [X] T043 [US1] Add styles for speckit views in tui/internal/ui/styles.go

### Model Integration

- [X] T044 [US1] Add ViewSpecKitUpdater case to View() switch in tui/internal/ui/model.go
- [X] T045 [US1] Add ViewSpecKitUpdater handling in Update() for key messages in tui/internal/ui/model.go
- [X] T046 [US1] Add specKitConfigLoadedMsg handler in Update() in tui/internal/ui/model.go
- [X] T047 [US1] Add "SpecKit Updater" menu item to ExtrasModel in tui/internal/ui/extras.go
- [X] T048 [US1] Handle navigation from Extras to ViewSpecKitUpdater in tui/internal/ui/model.go

### Verification

- [X] T049 [US1] Verify add project with valid path works by running TUI manually
- [X] T050 [US1] Verify add project with invalid path shows error
- [X] T051 [US1] Verify project list persists after TUI restart

**Checkpoint**: User Story 1 complete - can add and list projects ✅

---

## Phase 6: User Story 2 - Scan Project for Differences (Priority: P1) 🎯 MVP

**Goal**: Users can scan projects and see differing files

**Independent Test**: Add a project → Select "Scan" → View list of differing files.

### SpecKitDetailModel (tui/internal/ui/speckitdetail.go)

- [X] T052 [US2] Create tui/internal/ui/speckitdetail.go with package declaration
- [X] T053 [US2] Define SpecKitDetailModel struct (project, scanning, diffs, cursor, repoRoot)
- [X] T054 [US2] Define menu items (Scan, Preview, Apply, Rollback, Remove, Back)
- [X] T055 [US2] Implement NewSpecKitDetailModel constructor
- [X] T056 [US2] Implement Init() returning nil command
- [X] T057 [US2] Implement Update() with keyboard navigation
- [X] T058 [US2] Implement handleScan() triggering async scan
- [X] T059 [US2] Implement View() showing project info and diff summary
- [X] T060 [US2] Implement scanning spinner during async operation

### Model Integration

- [X] T061 [US2] Add ViewSpecKitProjectDetail case to View() switch in tui/internal/ui/model.go
- [X] T062 [US2] Add ViewSpecKitProjectDetail handling in Update() in tui/internal/ui/model.go
- [X] T063 [US2] Add specKitScanCompleteMsg handler in Update() in tui/internal/ui/model.go
- [X] T064 [US2] Handle navigation from SpecKitUpdater to ViewSpecKitProjectDetail

### Verification

- [X] T065 [US2] Verify scan shows correct file differences by running TUI manually
- [X] T066 [US2] Verify scan shows "up to date" when no differences
- [X] T067 [US2] Verify scanning spinner displays during operation

**Checkpoint**: User Story 2 complete - can scan and see differences ✅

---

## Phase 7: User Story 3 - Preview Changes (Priority: P1) 🎯 MVP

**Goal**: Users can preview exact changes before patching

**Independent Test**: Select project with differences → Choose "Preview" → View diff output.

### Preview Implementation

- [X] T068 [US3] Add previewMode boolean to SpecKitDetailModel in tui/internal/ui/speckitdetail.go
- [X] T069 [US3] Add diffOutput string to SpecKitDetailModel for storing unified diff
- [X] T070 [US3] Implement handlePreview() generating unified diff from scanner
- [X] T071 [US3] Implement renderDiffView() showing file-by-file changes
- [X] T072 [US3] Add file navigation (next/prev file) when multiple files
- [X] T073 [US3] Implement viewport scrolling for long diffs

### Verification

- [X] T074 [US3] Verify preview shows unified diff format by running TUI manually
- [X] T075 [US3] Verify ESC returns to detail view without changes
- [X] T076 [US3] Verify file navigation works with multiple differing files

**Checkpoint**: User Story 3 complete - can preview changes ✅

---

## Phase 8: User Story 4 - Apply Patches with Backup (Priority: P1) 🎯 MVP

**Goal**: Users can apply patches with automatic backup

**Independent Test**: Preview changes → Confirm "Apply" → Verify backup and patched files.

### Apply Implementation

- [X] T077 [US4] Implement handleApply() in SpecKitDetailModel triggering confirmation
- [X] T078 [US4] Show ViewConfirm dialog before patching
- [X] T079 [US4] On confirm, call patcher.CreateBackup then patcher.ApplyPatch
- [X] T080 [US4] Add specKitPatchCompleteMsg handler in model.go
- [X] T081 [US4] Update project status to "up-to-date" after successful patch
- [X] T082 [US4] Display backup path after successful patch
- [X] T083 [US4] Handle patch failure with automatic restore from backup

### Verification

- [X] T084 [US4] Verify backup created at correct path by running TUI manually
- [X] T085 [US4] Verify files patched correctly (line ranges match)
- [X] T086 [US4] Verify status updates to "up to date" after patch
- [X] T087 [US4] Verify patch failure triggers rollback

**Checkpoint**: User Story 4 complete - can apply patches with backup ✅

---

## Phase 9: User Story 5 - Remove Project (Priority: P2)

**Goal**: Users can remove projects from tracking list

**Independent Test**: Select project → Choose "Remove" → Verify removal.

### Implementation

- [X] T088 [US5] Implement handleRemove() showing confirmation dialog
- [X] T089 [US5] On confirm, call config.RemoveProject and save
- [X] T090 [US5] Return to ViewSpecKitUpdater after removal
- [X] T091 [US5] Verify project removed but .specify/ still exists on disk

**Checkpoint**: User Story 5 complete - can remove projects ✅

---

## Phase 10: User Story 6 - Batch Update All (Priority: P2)

**Goal**: Users can update all projects at once

**Independent Test**: With multiple projects needing updates → Select "Update All" → Verify all updated.

### Implementation

- [X] T092 [US6] Implement getProjectsNeedingUpdates() in SpecKitUpdaterModel
- [X] T093 [US6] Create BatchPreviewModel with projects list when "Update All" selected
- [X] T094 [US6] Implement batch processing loop in handleBatchConfirm()
- [X] T095 [US6] Add progress tracking (current/total projects)
- [X] T096 [US6] Continue processing even if one project fails
- [X] T097 [US6] Show summary of success/failure counts after batch

### Verification

- [X] T098 [US6] Verify batch preview shows all projects needing updates
- [X] T099 [US6] Verify batch processes all projects sequentially
- [X] T100 [US6] Verify failure in one project doesn't stop others

**Checkpoint**: User Story 6 complete - batch update works ✅

---

## Phase 11: User Story 7 - Rollback from Backup (Priority: P2)

**Goal**: Users can rollback to previous state

**Independent Test**: After patching → Select "Rollback" → Verify files restored.

### Implementation

- [X] T101 [US7] Show "Rollback" action only when lastBackup exists
- [X] T102 [US7] Implement handleRollback() showing confirmation with backup timestamp
- [X] T103 [US7] On confirm, call patcher.RestoreFromBackup
- [X] T104 [US7] Add specKitRollbackCompleteMsg handler in model.go
- [X] T105 [US7] Update project status and clear lastBackup after rollback
- [X] T106 [US7] Trigger re-scan after rollback to show restored differences

### Verification

- [X] T107 [US7] Verify rollback restores exact pre-patch state by running TUI manually
- [X] T108 [US7] Verify re-scan shows differences after rollback
- [X] T109 [US7] Verify "Rollback" hidden when no backup exists

**Checkpoint**: User Story 7 complete - can rollback from backup ✅

---

## Phase 12: Polish & Edge Cases

**Purpose**: Handle edge cases and cleanup

- [X] T110 Handle permission errors with clear error messages
- [X] T111 Handle paths with spaces correctly
- [X] T112 Handle corrupted config file (reset to empty)
- [X] T113 Add loading states for async operations
- [X] T114 [P] Run `cd tui && go build ./cmd/installer` for final verification
- [X] T115 [P] Test with real speckit project outside this repo

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup
    │
    ▼
Phase 2: Core Types & Config ──► ALL subsequent phases depend on this
    │
    ├─────────────┬─────────────┐
    ▼             ▼             ▼
Phase 3:      Phase 4:      Phase 5: US1 (Add Project)
Scanner       Patcher           │
    │             │             ▼
    │             │         Phase 6: US2 (Scan)
    │             │             │
    └─────────────┴─────────────┤
                                ▼
                          Phase 7: US3 (Preview)
                                │
                                ▼
                          Phase 8: US4 (Apply)
                                │
                                ├─────────────────────────┐
                                ▼                         ▼
                          Phase 9: US5 (Remove)    Phase 10: US6 (Batch)
                                                          │
                                                          ▼
                                                   Phase 11: US7 (Rollback)
                                                          │
                                                          ▼
                                                   Phase 12: Polish
```

### MVP Delivery Path

**MVP = Phases 1-8 (User Stories 1-4)** ✅ COMPLETE

1. Setup (Phase 1) ✅
2. Core Types & Config (Phase 2) ✅
3. Scanner (Phase 3) ✅
4. Patcher (Phase 4) ✅
5. US1: Add Project (Phase 5) ✅
6. US2: Scan (Phase 6) ✅
7. US3: Preview (Phase 7) ✅
8. US4: Apply (Phase 8) ✅

### Post-MVP ✅ COMPLETE

9. US5: Remove (Phase 9) ✅
10. US6: Batch (Phase 10) ✅
11. US7: Rollback (Phase 11) ✅
12. Polish (Phase 12) ✅

**Total: ALL 115 TASKS COMPLETE**

---

## Parallel Opportunities

### After Phase 2:
- Phase 3 (Scanner) and Phase 4 (Patcher) can run in parallel
- Both are independent and don't share files

### After Phase 8:
- Phase 9 (US5) and Phase 10 (US6) can run in parallel
- US5 is simple removal, US6 is batch - different code paths

### Within Phases:
- Tasks marked [P] can run in parallel
- Sequential tasks depend on prior completion

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Commit after each phase or logical checkpoint
- Test each user story independently before moving on
- All file paths relative to repository root
- MVP delivers core value (add, scan, preview, apply)
- P2 stories (remove, batch, rollback) are enhancements

---

## Implementation Summary

**Completed**: 2026-01-22
**Files Created**:
- `tui/internal/speckit/types.go` - Core data types
- `tui/internal/speckit/config.go` - Config persistence
- `tui/internal/speckit/scanner.go` - File comparison logic
- `tui/internal/speckit/patcher.go` - Backup and patch logic
- `tui/internal/ui/speckitupdater.go` - Main list view
- `tui/internal/ui/speckitdetail.go` - Project detail view

**Files Modified**:
- `tui/internal/ui/model.go` - Added ViewStates and navigation
- `tui/internal/ui/extras.go` - Added SpecKit Updater menu item
- `tui/internal/ui/styles.go` - Added SpecKit-specific styles
