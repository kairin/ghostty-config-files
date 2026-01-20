# Implementation Plan: TUI Dashboard Consistency

**Branch**: `008-tui-dashboard-consistency` | **Date**: 2026-01-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-tui-dashboard-consistency/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Standardize TUI navigation patterns so all tools (table and menu) route through ViewToolDetail before showing actions, batch operations show preview screens before execution, and "Install Claude Config" runs within the TUI instead of exiting via `tea.ExecProcess`.

## Technical Context

**Language/Version**: Go 1.23
**Primary Dependencies**: Bubbletea v1.2.4, Bubbles v0.20.0, Lipgloss v1.0.0
**Storage**: N/A (in-memory state with cache)
**Testing**: Manual testing + `go build` validation
**Target Platform**: Linux (Ubuntu 25.10)
**Project Type**: Single Go module (TUI application)
**Performance Goals**: Screen transitions <100ms
**Constraints**: No external TUI exits for user operations
**Scale/Scope**: 12 existing ViewStates, adding 2 new (ViewBatchPreview, ViewUpdatePreview)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Script Consolidation | ✅ PASS | No new shell scripts required - all changes in Go code |
| II. Branch Preservation | ✅ PASS | Using timestamped branch `008-tui-dashboard-consistency` |
| III. Local-First CI/CD | ✅ PASS | Must run `go build` before commits |
| IV. Modularity Limits | ✅ PASS | New files ~100-150 lines each, well under 300 limit |
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

**GATE RESULT**: ✅ PASS - Proceeding to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/008-tui-dashboard-consistency/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
tui/
├── cmd/
│   └── installer/       # Main entry point
├── internal/
│   ├── ui/              # UI components (modify here)
│   │   ├── model.go         # Root model - route table tools, add new ViewStates
│   │   ├── extras.go        # Extras view - add batch preview, fix Claude Config
│   │   ├── nerdfonts.go     # Nerd Fonts - add batch preview
│   │   ├── tooldetail.go    # Tool detail - reuse for table tools
│   │   ├── batchpreview.go  # NEW - BatchPreviewModel component
│   │   ├── updatepreview.go # NEW - UpdatePreviewModel component
│   │   └── styles.go        # Styles (add batch preview styles)
│   ├── cache/           # Status caching
│   ├── executor/        # Script execution
│   ├── registry/        # Tool definitions
│   └── config/          # Configuration
└── go.mod
```

**Structure Decision**: Extending existing single Go module structure. New files `batchpreview.go` and `updatepreview.go` will be added to `tui/internal/ui/` following existing component patterns.

## Post-Design Constitution Check

*Re-evaluated after Phase 1 design completion.*

| Principle | Status | Post-Design Notes |
|-----------|--------|-------------------|
| I. Script Consolidation | ✅ PASS | Only Go files created (batchpreview.go). No new shell scripts. |
| II. Branch Preservation | ✅ PASS | Branch `008-tui-dashboard-consistency` in use, will merge with `--no-ff` |
| III. Local-First CI/CD | ✅ PASS | `go build ./cmd/installer` required before each commit |
| IV. Modularity Limits | ✅ PASS | batchpreview.go ~150 lines (under 300 limit) |
| V. Symlink Single Source | ✅ PASS | No changes to AGENTS.md, CLAUDE.md, or GEMINI.md |

### Design Simplification

During research, consolidated ViewBatchPreview and ViewUpdatePreview into a **single component** (`BatchPreviewModel`):
- Same UI structure for all batch previews
- Different data/labels passed based on context
- Reduces code duplication and maintenance burden

### Files Summary

| Action | File | Lines |
|--------|------|-------|
| CREATE | `tui/internal/ui/batchpreview.go` | ~150 |
| MODIFY | `tui/internal/ui/model.go` | +50 |
| MODIFY | (inline in model.go) | Extras/NerdFonts handling |

**GATE RESULT**: ✅ PASS - Ready for implementation

## Complexity Tracking

> No violations - all changes within constitution limits.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
