# Implementation Plan: SpecKit Project Updater

**Branch**: `009-speckit-project-updater` | **Date**: 2026-01-21 | **Spec**: [spec.md](spec.md)
**Git Branch**: `20260121-XXXXXX-feat-speckit-project-updater` (constitutional format)
**Input**: Feature specification from `/specs/009-speckit-project-updater/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add a SpecKit Project Updater feature to the TUI Extras menu that allows users to:
1. Track speckit installations across multiple project directories
2. Compare speckit files against canonical versions in this repo
3. Preview and apply patches to enforce constitutional branch naming
4. Manage backups and rollbacks for safety

## Technical Context

**Language/Version**: Go 1.23
**Primary Dependencies**: Bubbletea v1.2.4, Bubbles v0.20.0, Lipgloss v1.0.0
**Storage**: `~/.config/ghostty-installer/speckit-projects.json` (JSON config file)
**Testing**: Manual testing + `go build` validation
**Target Platform**: Linux (Ubuntu 25.10)
**Project Type**: Single Go module (TUI application)
**Performance Goals**: Scan operations <5 seconds per project
**Constraints**: Must work offline, no network dependencies
**Scale/Scope**: 13 existing ViewStates, adding 2 new (ViewSpecKitUpdater, ViewSpecKitProjectDetail)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Script Consolidation | ✅ PASS | No new shell scripts - all changes in Go code |
| II. Branch Preservation | ✅ PASS | Using constitutional branch format `YYYYMMDD-HHMMSS-feat-*` |
| III. Local-First CI/CD | ✅ PASS | Must run `go build` before commits |
| IV. Modularity Limits | ✅ PASS | New files ~200-250 lines each, under 300 limit |
| V. Symlink Single Source | ✅ PASS | Not touching AGENTS.md or symlinks |

### Protected Files Check

| File | Impact | Notes |
|------|--------|-------|
| `docs/.nojekyll` | No impact | Not touched |
| `AGENTS.md` | No impact | Not touched |
| Symlinks | No impact | Not touched |

### Technology Stack Check

| Requirement | Status | Notes |
|-------------|--------|-------|
| Go 1.23+ | ✅ PASS | Using Go 1.23 per go.mod |
| Bubbletea patterns | ✅ PASS | Following existing Elm architecture |
| JSON persistence | ✅ PASS | Using encoding/json for config |

**GATE RESULT**: ✅ PASS - Proceeding to design

## Project Structure

### Documentation (this feature)

```text
specs/009-speckit-project-updater/
├── spec.md              # Feature specification
├── plan.md              # This file (implementation plan)
└── tasks.md             # Task breakdown (to be created)
```

### Source Code (new files)

```text
tui/internal/
├── ui/
│   ├── model.go             # MODIFY: Add ViewSpecKitUpdater, ViewSpecKitProjectDetail states
│   ├── extras.go            # MODIFY: Add menu item for SpecKit Updater
│   ├── speckitupdater.go    # NEW: Main list view for tracked projects
│   ├── speckitdetail.go     # NEW: Single project detail with actions
│   └── styles.go            # MODIFY: Add styles for diff view
├── speckit/                 # NEW: SpecKit package for core logic
│   ├── config.go            # Config persistence (JSON load/save)
│   ├── scanner.go           # File comparison logic
│   ├── patcher.go           # Backup and patch application
│   └── types.go             # TrackedProject, FileDifference types
└── ...
```

### Integration Points

| Component | File | Change |
|-----------|------|--------|
| ViewState enum | `model.go` | Add `ViewSpecKitUpdater`, `ViewSpecKitProjectDetail` |
| Model fields | `model.go` | Add `speckitUpdater *SpecKitUpdaterModel`, `speckitDetail *SpecKitDetailModel` |
| Extras menu | `extras.go` | Add "SpecKit Updater" menu item |
| Navigation | `model.go` | Handle navigation to/from SpecKit views |
| Messages | `model.go` | Add message types for async operations |

## Architecture

### View Flow

```
ViewExtras
    │
    ├─[Select "SpecKit Updater"]─→ ViewSpecKitUpdater (project list)
    │                                    │
    │                                    ├─[Add Project]─→ Text input modal
    │                                    │
    │                                    ├─[Select Project]─→ ViewSpecKitProjectDetail
    │                                    │                          │
    │                                    │                          ├─[Scan]─→ Compare files
    │                                    │                          ├─[Preview]─→ Show diff
    │                                    │                          ├─[Apply]─→ Backup & patch
    │                                    │                          ├─[Rollback]─→ Restore backup
    │                                    │                          └─[Remove]─→ Confirm → Remove
    │                                    │
    │                                    └─[Update All]─→ ViewBatchPreview
    │
    └─[Escape]─→ ViewDashboard
```

### Package Responsibilities

| Package | Responsibility |
|---------|----------------|
| `tui/internal/ui` | TUI views and user interaction |
| `tui/internal/speckit` | Core business logic (config, scan, patch) |
| `tui/internal/config` | May extend for speckit config path |

### Data Flow

1. **Config Loading**: On TUI start, load `~/.config/ghostty-installer/speckit-projects.json`
2. **Project List**: Display tracked projects with cached status
3. **Scan**: Compare project's `.specify/scripts/bash/` against canonical files
4. **Preview**: Generate unified diff for changed files
5. **Patch**: Create backup, apply line-range patches
6. **Persist**: Save updated config after any changes

### Message Types

```go
// Async operation messages
type specKitConfigLoadedMsg struct { config *speckit.ProjectConfig; err error }
type specKitScanCompleteMsg struct { projectPath string; diffs []speckit.FileDifference; err error }
type specKitPatchCompleteMsg struct { projectPath string; backupPath string; err error }
type specKitRollbackCompleteMsg struct { projectPath string; err error }
```

## Key Components

### SpecKitUpdaterModel (speckitupdater.go)

Main list view showing all tracked projects:
- List of tracked projects with status icons
- Actions: Add Project, Update All, Refresh
- Navigation: Arrow keys, Enter to select, Esc to return

### SpecKitDetailModel (speckitdetail.go)

Single project detail view:
- Project path and status
- List of differing files (if scanned)
- Actions: Scan, Preview, Apply, Rollback, Remove
- Diff viewer (inline or scrollable)

### speckit.Config (config.go)

Persistence layer:
- Load/Save JSON config
- Add/Remove tracked projects
- Update project status

### speckit.Scanner (scanner.go)

File comparison:
- Compare `.specify/scripts/bash/*.sh` files
- Identify differing line ranges
- Generate unified diff output

### speckit.Patcher (patcher.go)

Backup and patch:
- Create timestamped backup directory
- Copy affected files to backup
- Apply patches (replace line ranges)
- Restore from backup on failure

## Config File Schema

```json
{
  "version": 1,
  "projects": [
    {
      "path": "/home/user/myproject",
      "lastScanned": "2026-01-21T12:00:00Z",
      "status": "needs-update",
      "lastBackup": "/home/user/myproject/.specify/.backup-20260121-120000"
    }
  ]
}
```

## Canonical Files Reference

The following files from this repo serve as the canonical source for patching:

| File | Purpose |
|------|---------|
| `.specify/scripts/bash/common.sh` | Branch validation regex |
| `.specify/scripts/bash/create-new-feature.sh` | Branch creation with timestamp |

### Patch Targets

**common.sh** - Branch validation (lines ~75-82):
```bash
# Current (old pattern only):
if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then

# Required (add constitutional pattern):
if [[ ! "$branch" =~ ^[0-9]{3}- ]] && [[ ! "$branch" =~ ^[0-9]{8}-[0-9]{6}- ]]; then
```

**create-new-feature.sh** - Branch creation (lines ~283-313):
- Add timestamp generation
- Change branch name format to `YYYYMMDD-HHMMSS-type-description`
- Keep spec directory as `NNN-description`

## Post-Design Constitution Check

*Re-evaluated after design completion.*

| Principle | Status | Post-Design Notes |
|-----------|--------|-------------------|
| I. Script Consolidation | ✅ PASS | Only Go files created. No new shell scripts. |
| II. Branch Preservation | ✅ PASS | Using constitutional format `YYYYMMDD-HHMMSS-feat-*` |
| III. Local-First CI/CD | ✅ PASS | `go build ./cmd/installer` required before each commit |
| IV. Modularity Limits | ✅ PASS | All new files under 300 lines |
| V. Symlink Single Source | ✅ PASS | No changes to AGENTS.md, CLAUDE.md, or GEMINI.md |

### Files Summary

| Action | File | Lines (est) |
|--------|------|-------------|
| CREATE | `tui/internal/speckit/types.go` | ~50 |
| CREATE | `tui/internal/speckit/config.go` | ~100 |
| CREATE | `tui/internal/speckit/scanner.go` | ~150 |
| CREATE | `tui/internal/speckit/patcher.go` | ~150 |
| CREATE | `tui/internal/ui/speckitupdater.go` | ~200 |
| CREATE | `tui/internal/ui/speckitdetail.go` | ~200 |
| MODIFY | `tui/internal/ui/model.go` | +80 |
| MODIFY | `tui/internal/ui/extras.go` | +20 |
| MODIFY | `tui/internal/ui/styles.go` | +30 |

**Total new code**: ~960 lines across 6 new files + ~130 lines in modified files

**GATE RESULT**: ✅ PASS - Ready for task generation

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| New package (speckit) | Separates business logic from UI | Single file would exceed 300-line limit and mix concerns |

## Dependencies

### Internal Dependencies

- `tui/internal/config` - May use for config path utilities
- `tui/internal/cache` - Pattern reference for status caching

### External Dependencies (existing)

- `encoding/json` - Config persistence
- `os` - File operations
- `path/filepath` - Path manipulation
- `bufio` - Line-by-line file reading
- `io` - File copying for backup

No new external dependencies required.

## Testing Strategy

1. **Unit Tests**:
   - `speckit/config_test.go` - Config load/save
   - `speckit/scanner_test.go` - File comparison
   - `speckit/patcher_test.go` - Backup/restore

2. **Integration Tests**:
   - Manual: Add real project, scan, preview, apply, rollback

3. **Build Validation**:
   - `go build ./cmd/installer` must pass
   - TUI must launch without errors

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| File corruption during patch | High | Mandatory backup before any modification |
| Config file corruption | Medium | Schema version + graceful reset |
| Large number of projects (>50) | Low | Pagination in UI, lazy loading |
| Permission errors | Medium | Clear error messages, skip unwritable projects |

## Open Questions

None currently - all clarified in spec.md
