# Implementation Plan: TUI Detail Views

**Branch**: `006-tui-detail-views` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-tui-detail-views/spec.md`

## Summary

Restructure the Go TUI navigation to use focused detail views instead of cramped tables. Create a reusable `ViewToolDetail` component (based on `nerdfonts.go` pattern) that displays single-tool status with action menu. Simplify main dashboard to 3 tools in table, move Ghostty/Feh to menu navigation. Convert Extras from 7-row table to navigation menu where each tool leads to its detail view.

## Technical Context

**Language/Version**: Go 1.23+
**Primary Dependencies**: Bubbletea (TUI framework), Lipgloss (styling), Bubbles (spinner component)
**Storage**: N/A (runtime state only, existing cache.StatusCache)
**Testing**: Manual TUI testing, `go build` compilation check
**Target Platform**: Linux terminal (Ghostty, xterm-compatible)
**Project Type**: Single project (TUI application)
**Performance Goals**: Instant navigation (<100ms view transitions)
**Constraints**: 300 line limit per file (constitution), existing Bubbletea patterns
**Scale/Scope**: 12 tools total (5 main + 7 extras), 9 new detail view routes

## Constitution Check

*GATE: All checks pass. No violations.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Script Consolidation | ✅ PASS | No new scripts - Go code only |
| II. Branch Preservation | ✅ PASS | Using timestamped branch 006-tui-detail-views |
| III. Local-First CI/CD | ✅ PASS | `go build` before commit |
| IV. Modularity Limits | ✅ PASS | New file tooldetail.go < 300 lines |
| V. Symlink Single Source | ✅ N/A | Not touching AGENTS.md |

**Protected Files**: None affected by this feature.

## Project Structure

### Documentation (this feature)

```text
specs/006-tui-detail-views/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Technical decisions
├── data-model.md        # Entity definitions
├── quickstart.md        # Implementation guide
├── contracts/           # Interface contracts
│   └── component-interfaces.go
└── checklists/
    └── requirements.md  # Validation checklist
```

### Source Code (repository root)

```text
tui/
├── cmd/
│   └── installer/
│       └── main.go           # Entry point (no changes)
└── internal/
    ├── cache/                # Status caching (no changes)
    ├── config/               # Configuration (no changes)
    ├── detector/             # Tool detection (no changes)
    ├── diagnostics/          # Boot diagnostics (no changes)
    ├── executor/             # Script execution (no changes)
    ├── registry/             # Tool registry (no changes)
    └── ui/
        ├── tooldetail.go     # NEW - ViewToolDetail component
        ├── model.go          # MODIFY - View routing, menu changes
        ├── extras.go         # MODIFY - Remove table, add menu
        ├── nerdfonts.go      # Reference implementation (no changes)
        ├── styles.go         # Existing styles (no changes)
        └── [other files]     # No changes
```

**Structure Decision**: Existing Go TUI project structure. Adding one new file (`tooldetail.go`) and modifying two existing files (`model.go`, `extras.go`).

## Implementation Phases

### Phase 1: ViewToolDetail Component (P1 - Core)

**Deliverable**: `tui/internal/ui/tooldetail.go`

**Tasks**:
1. Create ToolDetailModel struct with required fields
2. Implement NewToolDetailModel constructor
3. Implement Init() with spinner and status loading
4. Implement Update() for message handling
5. Implement View() with status table and action menu
6. Implement HandleKey() for navigation
7. Add helper methods (IsBackSelected, GetSelectedAction)

**Reference**: Copy structure from `nerdfonts.go` lines 24-55, 200-235, 377-440

**Estimated Lines**: ~250 lines (under 300 limit)

### Phase 2: View Routing (P1 - Core)

**Deliverable**: Modified `tui/internal/ui/model.go`

**Tasks**:
1. Add `ViewToolDetail` to View enum (after ViewConfirm)
2. Add `toolDetail *ToolDetailModel` field to Model
3. Add `toolDetailFrom View` field for back navigation
4. Add ViewToolDetail case in Update() switch
5. Add ViewToolDetail case in View() switch
6. Handle navigation to/from ViewToolDetail

**Estimated Changes**: ~50 lines added/modified

### Phase 3: Main Dashboard Restructure (P2)

**Deliverable**: Modified `tui/internal/ui/model.go`

**Tasks**:
1. Modify renderMainTable() to show 3 tools only:
   - Node.js, Local AI Tools, Google Antigravity
2. Add Ghostty and Feh as menu items at TOP of menu:
   - Menu order: Ghostty, Feh, Update All, Nerd Fonts, Extras, Boot Diagnostics, Exit
3. Handle Ghostty/Feh selection → navigate to ViewToolDetail
4. Track origin (ViewDashboard) for back navigation

**Estimated Changes**: ~40 lines modified

### Phase 4: Extras Menu Conversion (P3)

**Deliverable**: Modified `tui/internal/ui/extras.go`

**Tasks**:
1. Remove renderExtrasTable() call from View()
2. Replace with navigation menu rendering
3. Menu order (alphabetical): Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH
4. Keep: Install All, Install Claude Config, MCP Servers, Back
5. Handle tool selection → navigate to ViewToolDetail
6. Track origin (ViewExtras) for back navigation

**Estimated Changes**: ~60 lines modified

### Phase 5: ROADMAP Update

**Deliverable**: Modified `ROADMAP.md`

**Tasks**:
1. Add Wave 6a: TUI Detail Views section
2. Document 4 tasks with completion status
3. Link to specs/006-tui-detail-views/
4. Update verification summary table

## Verification Plan

### Compilation Check

```bash
cd tui && go build ./cmd/installer
# Must exit 0 with no errors
```

### Manual Testing Checklist

1. **Main Dashboard**:
   - [ ] Table shows exactly 3 tools (Node.js, AI Tools, Antigravity)
   - [ ] Menu shows Ghostty at position 1
   - [ ] Menu shows Feh at position 2
   - [ ] Selecting Ghostty opens detail view

2. **Tool Detail View**:
   - [ ] Header shows tool name and description
   - [ ] Status table shows all fields (status, version, latest, method, location)
   - [ ] Header is fully visible (no clipping)
   - [ ] Action menu shows appropriate options
   - [ ] Escape returns to previous view

3. **Extras View**:
   - [ ] No table displayed (menu only)
   - [ ] 7 tools in alphabetical order
   - [ ] Selecting tool opens detail view
   - [ ] Back returns to main dashboard

4. **Functionality**:
   - [ ] Install action works from detail view
   - [ ] Uninstall action works from detail view
   - [ ] Refresh (r key) updates status

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| nerdfonts.go pattern | Internal | Available |
| registry.GetTool() | Internal | Available |
| cache.StatusCache | Internal | Available |
| executor.RunCheck() | Internal | Available |
| Existing styles | Internal | Available |

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Navigation confusion | Clear header with tool name |
| Breaking existing features | Test all operations before commit |
| Code duplication | Extract shared patterns to helpers |

## Complexity Tracking

*No constitution violations - table empty.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | - | - |

## Files Changed Summary

| File | Action | Est. Lines |
|------|--------|------------|
| `tui/internal/ui/tooldetail.go` | CREATE | ~250 |
| `tui/internal/ui/model.go` | MODIFY | ~90 |
| `tui/internal/ui/extras.go` | MODIFY | ~60 |
| `ROADMAP.md` | MODIFY | ~30 |

**Total**: ~430 lines (1 new file, 3 modified files)

## Next Steps

Run `/speckit.tasks` to generate detailed task breakdown.
