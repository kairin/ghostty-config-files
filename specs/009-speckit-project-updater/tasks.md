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

- [ ] T001 Verify current build compiles with `cd tui && go build ./cmd/installer`
- [ ] T002 Create directory `tui/internal/speckit/`
- [ ] T003 Add ViewSpecKitUpdater constant to View enum in tui/internal/ui/model.go
- [ ] T004 [P] Add ViewSpecKitProjectDetail constant to View enum in tui/internal/ui/model.go
- [ ] T005 [P] Add speckitUpdater field (*SpecKitUpdaterModel) to Model struct in tui/internal/ui/model.go
- [ ] T006 [P] Add speckitDetail field (*SpecKitDetailModel) to Model struct in tui/internal/ui/model.go

**Checkpoint**: Package structure ready, ViewStates defined

---

## Phase 2: Core Types & Config Persistence

**Purpose**: Define data structures and implement config persistence (enables all user stories)

**⚠️ CRITICAL**: User Stories 1-7 depend on this phase for config loading/saving

### Types (tui/internal/speckit/types.go)

- [ ] T007 Create tui/internal/speckit/types.go with package declaration
- [ ] T008 Define ProjectStatus type (string enum: pending, up-to-date, needs-update, error)
- [ ] T009 Define FileDifference struct (File, LineStart, LineEnd, CanonicalContent, ProjectContent)
- [ ] T010 Define TrackedProject struct (Path, LastScanned, Status, Differences, LastBackup)
- [ ] T011 Define ProjectConfig struct (Version, Projects)

### Config Persistence (tui/internal/speckit/config.go)

- [ ] T012 Create tui/internal/speckit/config.go with package declaration
- [ ] T013 Implement getConfigPath() returning ~/.config/ghostty-installer/speckit-projects.json
- [ ] T014 Implement LoadConfig() (JSON load, returns *ProjectConfig, creates empty if missing)
- [ ] T015 Implement SaveConfig(*ProjectConfig) (JSON save with indentation)
- [ ] T016 Implement AddProject(path string) (validates .specify/ exists, adds to config)
- [ ] T017 Implement RemoveProject(path string) (removes from config by path)
- [ ] T018 Implement UpdateProjectStatus(path, status, diffs, backup) (updates existing project)

**Checkpoint**: Config can be loaded, saved, and modified

---

## Phase 3: Scanner Implementation

**Purpose**: File comparison logic (enables User Stories 2, 3)

### Scanner (tui/internal/speckit/scanner.go)

- [ ] T019 Create tui/internal/speckit/scanner.go with package declaration
- [ ] T020 Implement getCanonicalFilePaths(repoRoot string) returning list of canonical bash scripts
- [ ] T021 Implement readFileLines(path string) returning []string and error
- [ ] T022 Implement compareFiles(canonicalPath, projectPath string) returning []FileDifference
- [ ] T023 Implement ScanProject(projectPath, repoRoot string) returning ([]FileDifference, error)
- [ ] T024 Implement generateUnifiedDiff(canonical, project []string, filename string) returning string
- [ ] T025 Verify scanner compiles with `cd tui && go build ./cmd/installer`

**Checkpoint**: Can scan a project and identify differing lines

---

## Phase 4: Patcher Implementation

**Purpose**: Backup and patch logic (enables User Stories 4, 7)

### Patcher (tui/internal/speckit/patcher.go)

- [ ] T026 Create tui/internal/speckit/patcher.go with package declaration
- [ ] T027 Implement createBackupDir(projectPath string) returning backup path with timestamp
- [ ] T028 Implement copyFile(src, dst string) for backup operations
- [ ] T029 Implement CreateBackup(projectPath string, files []string) returning backupPath, error
- [ ] T030 Implement ApplyPatch(projectPath, repoRoot string, diffs []FileDifference) returning error
- [ ] T031 Implement RestoreFromBackup(projectPath, backupPath string) returning error
- [ ] T032 Implement GetLatestBackup(projectPath string) returning backupPath, error
- [ ] T033 Verify patcher compiles with `cd tui && go build ./cmd/installer`

**Checkpoint**: Can backup, patch, and rollback files

---

## Phase 5: User Story 1 - Add Project Directory (Priority: P1) 🎯 MVP

**Goal**: Users can add project directories to the SpecKit Updater

**Independent Test**: Navigate to SpecKit Updater → Add Project → Enter path → Verify project appears in list.

### SpecKitUpdaterModel (tui/internal/ui/speckitupdater.go)

- [ ] T034 [US1] Create tui/internal/ui/speckitupdater.go with package declaration
- [ ] T035 [US1] Define SpecKitUpdaterModel struct (projects, cursor, loading, state, config, repoRoot)
- [ ] T036 [US1] Define menu items (Add Project, Update All, Refresh, Back)
- [ ] T037 [US1] Implement NewSpecKitUpdaterModel constructor
- [ ] T038 [US1] Implement Init() returning config load command
- [ ] T039 [US1] Implement Update() with keyboard navigation (arrow keys, enter, esc)
- [ ] T040 [US1] Implement handleAddProject() showing text input modal
- [ ] T041 [US1] Implement handleProjectSelect() navigating to ViewSpecKitProjectDetail
- [ ] T042 [US1] Implement View() rendering project list with status icons
- [ ] T043 [US1] Add styles for speckit views in tui/internal/ui/styles.go

### Model Integration

- [ ] T044 [US1] Add ViewSpecKitUpdater case to View() switch in tui/internal/ui/model.go
- [ ] T045 [US1] Add ViewSpecKitUpdater handling in Update() for key messages in tui/internal/ui/model.go
- [ ] T046 [US1] Add specKitConfigLoadedMsg handler in Update() in tui/internal/ui/model.go
- [ ] T047 [US1] Add "SpecKit Updater" menu item to ExtrasModel in tui/internal/ui/extras.go
- [ ] T048 [US1] Handle navigation from Extras to ViewSpecKitUpdater in tui/internal/ui/model.go

### Verification

- [ ] T049 [US1] Verify add project with valid path works by running TUI manually
- [ ] T050 [US1] Verify add project with invalid path shows error
- [ ] T051 [US1] Verify project list persists after TUI restart

**Checkpoint**: User Story 1 complete - can add and list projects

---

## Phase 6: User Story 2 - Scan Project for Differences (Priority: P1) 🎯 MVP

**Goal**: Users can scan projects and see differing files

**Independent Test**: Add a project → Select "Scan" → View list of differing files.

### SpecKitDetailModel (tui/internal/ui/speckitdetail.go)

- [ ] T052 [US2] Create tui/internal/ui/speckitdetail.go with package declaration
- [ ] T053 [US2] Define SpecKitDetailModel struct (project, scanning, diffs, cursor, repoRoot)
- [ ] T054 [US2] Define menu items (Scan, Preview, Apply, Rollback, Remove, Back)
- [ ] T055 [US2] Implement NewSpecKitDetailModel constructor
- [ ] T056 [US2] Implement Init() returning nil command
- [ ] T057 [US2] Implement Update() with keyboard navigation
- [ ] T058 [US2] Implement handleScan() triggering async scan
- [ ] T059 [US2] Implement View() showing project info and diff summary
- [ ] T060 [US2] Implement scanning spinner during async operation

### Model Integration

- [ ] T061 [US2] Add ViewSpecKitProjectDetail case to View() switch in tui/internal/ui/model.go
- [ ] T062 [US2] Add ViewSpecKitProjectDetail handling in Update() in tui/internal/ui/model.go
- [ ] T063 [US2] Add specKitScanCompleteMsg handler in Update() in tui/internal/ui/model.go
- [ ] T064 [US2] Handle navigation from SpecKitUpdater to ViewSpecKitProjectDetail

### Verification

- [ ] T065 [US2] Verify scan shows correct file differences by running TUI manually
- [ ] T066 [US2] Verify scan shows "up to date" when no differences
- [ ] T067 [US2] Verify scanning spinner displays during operation

**Checkpoint**: User Story 2 complete - can scan and see differences

---

## Phase 7: User Story 3 - Preview Changes (Priority: P1) 🎯 MVP

**Goal**: Users can preview exact changes before patching

**Independent Test**: Select project with differences → Choose "Preview" → View diff output.

### Preview Implementation

- [ ] T068 [US3] Add previewMode boolean to SpecKitDetailModel in tui/internal/ui/speckitdetail.go
- [ ] T069 [US3] Add diffOutput string to SpecKitDetailModel for storing unified diff
- [ ] T070 [US3] Implement handlePreview() generating unified diff from scanner
- [ ] T071 [US3] Implement renderDiffView() showing file-by-file changes
- [ ] T072 [US3] Add file navigation (next/prev file) when multiple files
- [ ] T073 [US3] Implement viewport scrolling for long diffs

### Verification

- [ ] T074 [US3] Verify preview shows unified diff format by running TUI manually
- [ ] T075 [US3] Verify ESC returns to detail view without changes
- [ ] T076 [US3] Verify file navigation works with multiple differing files

**Checkpoint**: User Story 3 complete - can preview changes

---

## Phase 8: User Story 4 - Apply Patches with Backup (Priority: P1) 🎯 MVP

**Goal**: Users can apply patches with automatic backup

**Independent Test**: Preview changes → Confirm "Apply" → Verify backup and patched files.

### Apply Implementation

- [ ] T077 [US4] Implement handleApply() in SpecKitDetailModel triggering confirmation
- [ ] T078 [US4] Show ViewConfirm dialog before patching
- [ ] T079 [US4] On confirm, call patcher.CreateBackup then patcher.ApplyPatch
- [ ] T080 [US4] Add specKitPatchCompleteMsg handler in model.go
- [ ] T081 [US4] Update project status to "up-to-date" after successful patch
- [ ] T082 [US4] Display backup path after successful patch
- [ ] T083 [US4] Handle patch failure with automatic restore from backup

### Verification

- [ ] T084 [US4] Verify backup created at correct path by running TUI manually
- [ ] T085 [US4] Verify files patched correctly (line ranges match)
- [ ] T086 [US4] Verify status updates to "up to date" after patch
- [ ] T087 [US4] Verify patch failure triggers rollback

**Checkpoint**: User Story 4 complete - can apply patches with backup

---

## Phase 9: User Story 5 - Remove Project (Priority: P2)

**Goal**: Users can remove projects from tracking list

**Independent Test**: Select project → Choose "Remove" → Verify removal.

### Implementation

- [ ] T088 [US5] Implement handleRemove() showing confirmation dialog
- [ ] T089 [US5] On confirm, call config.RemoveProject and save
- [ ] T090 [US5] Return to ViewSpecKitUpdater after removal
- [ ] T091 [US5] Verify project removed but .specify/ still exists on disk

**Checkpoint**: User Story 5 complete - can remove projects

---

## Phase 10: User Story 6 - Batch Update All (Priority: P2)

**Goal**: Users can update all projects at once

**Independent Test**: With multiple projects needing updates → Select "Update All" → Verify all updated.

### Implementation

- [ ] T092 [US6] Implement getProjectsNeedingUpdates() in SpecKitUpdaterModel
- [ ] T093 [US6] Create BatchPreviewModel with projects list when "Update All" selected
- [ ] T094 [US6] Implement batch processing loop in handleBatchConfirm()
- [ ] T095 [US6] Add progress tracking (current/total projects)
- [ ] T096 [US6] Continue processing even if one project fails
- [ ] T097 [US6] Show summary of success/failure counts after batch

### Verification

- [ ] T098 [US6] Verify batch preview shows all projects needing updates
- [ ] T099 [US6] Verify batch processes all projects sequentially
- [ ] T100 [US6] Verify failure in one project doesn't stop others

**Checkpoint**: User Story 6 complete - batch update works

---

## Phase 11: User Story 7 - Rollback from Backup (Priority: P2)

**Goal**: Users can rollback to previous state

**Independent Test**: After patching → Select "Rollback" → Verify files restored.

### Implementation

- [ ] T101 [US7] Show "Rollback" action only when lastBackup exists
- [ ] T102 [US7] Implement handleRollback() showing confirmation with backup timestamp
- [ ] T103 [US7] On confirm, call patcher.RestoreFromBackup
- [ ] T104 [US7] Add specKitRollbackCompleteMsg handler in model.go
- [ ] T105 [US7] Update project status and clear lastBackup after rollback
- [ ] T106 [US7] Trigger re-scan after rollback to show restored differences

### Verification

- [ ] T107 [US7] Verify rollback restores exact pre-patch state by running TUI manually
- [ ] T108 [US7] Verify re-scan shows differences after rollback
- [ ] T109 [US7] Verify "Rollback" hidden when no backup exists

**Checkpoint**: User Story 7 complete - can rollback from backup

---

## Phase 12: Polish & Edge Cases

**Purpose**: Handle edge cases and cleanup

- [ ] T110 Handle permission errors with clear error messages
- [ ] T111 Handle paths with spaces correctly
- [ ] T112 Handle corrupted config file (reset to empty)
- [ ] T113 Add loading states for async operations
- [ ] T114 [P] Run `cd tui && go build ./cmd/installer` for final verification
- [ ] T115 [P] Test with real speckit project outside this repo

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

**MVP = Phases 1-8 (User Stories 1-4)**

1. Setup (Phase 1) - 15 min
2. Core Types & Config (Phase 2) - 30 min
3. Scanner (Phase 3) - 45 min
4. Patcher (Phase 4) - 45 min
5. US1: Add Project (Phase 5) - 1 hour
6. US2: Scan (Phase 6) - 45 min
7. US3: Preview (Phase 7) - 45 min
8. US4: Apply (Phase 8) - 45 min

**MVP Total: ~5.5 hours**

### Post-MVP

9. US5: Remove (Phase 9) - 30 min
10. US6: Batch (Phase 10) - 1 hour
11. US7: Rollback (Phase 11) - 45 min
12. Polish (Phase 12) - 30 min

**Total: ~8 hours**

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
