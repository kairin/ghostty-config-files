# Research: TUI Dashboard Consistency

**Feature Branch**: `008-tui-dashboard-consistency`
**Research Date**: 2026-01-20
**Status**: Complete

## Overview

This document captures research findings for implementing consistent navigation patterns across the TUI dashboard, batch operation previews, and in-TUI progress for Claude Config installation.

---

## Current State Analysis

### Complete Menu Item Inventory (26 Items)

| # | Location | Item | Current Flow | Expected Flow | Gap? |
|---|----------|------|--------------|---------------|------|
| 1 | Dashboard Table | Node.js (nvm) | Dashboard → ViewAppMenu → ViewInstaller | Dashboard → ViewToolDetail → ViewInstaller | YES |
| 2 | Dashboard Table | Local AI Tools | Dashboard → ViewAppMenu → ViewInstaller | Dashboard → ViewToolDetail → ViewInstaller | YES |
| 3 | Dashboard Table | Google Antigravity | Dashboard → ViewAppMenu → ViewInstaller | Dashboard → ViewToolDetail → ViewInstaller | YES |
| 4 | Dashboard Menu | Ghostty | Dashboard → ViewToolDetail → ViewInstaller | (same) | NO |
| 5 | Dashboard Menu | Feh | Dashboard → ViewToolDetail → ViewInstaller | (same) | NO |
| 6 | Dashboard Menu | Update All | Dashboard → ViewInstaller (immediate) | Dashboard → ViewBatchPreview → ViewInstaller | YES |
| 7 | Dashboard Menu | Nerd Fonts | Dashboard → ViewNerdFonts | (same) | NO |
| 8 | Dashboard Menu | Extras | Dashboard → ViewExtras | (same) | NO |
| 9 | Dashboard Menu | Boot Diagnostics | Dashboard → ViewDiagnostics | (same) | NO |
| 10 | Dashboard Menu | Exit | Quit | (same) | NO |
| 11 | Extras Menu | Fastfetch | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 12 | Extras Menu | Glow | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 13 | Extras Menu | Go | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 14 | Extras Menu | Gum | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 15 | Extras Menu | Python/uv | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 16 | Extras Menu | VHS | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 17 | Extras Menu | ZSH | Extras → ViewToolDetail → ViewInstaller | (same) | NO |
| 18 | Extras Menu | Install All | Extras → ViewInstaller (immediate) | Extras → ViewBatchPreview → ViewInstaller | YES |
| 19 | Extras Menu | Install Claude Config | Extras → tea.ExecProcess (exits TUI) | Extras → ViewInstaller | YES |
| 20 | Extras Menu | MCP Servers | Extras → ViewMCPServers | (same) | NO |
| 21 | Extras Menu | Back | Extras → Dashboard | (same) | NO |
| 22 | Nerd Fonts | Font (8 items) | NerdFonts → Action Menu → ViewInstaller | (same) | NO |
| 23 | Nerd Fonts | Install All | NerdFonts → ViewInstaller (immediate) | NerdFonts → ViewBatchPreview → ViewInstaller | YES |
| 24 | Nerd Fonts | Back | NerdFonts → Dashboard | (same) | NO |
| 25 | MCP Servers | Server (7 items) | MCPServers → Action Menu → Install/Remove | (same) | NO |
| 26 | MCP Servers | Setup Secrets | MCPServers → ViewSecretsWizard | (same) | NO |

**Summary**: 6 out of 26 menu items have gaps (23% inconsistency rate)

---

## Gap Analysis

### Gap 1: Table Tools Skip ViewToolDetail

**Current Behavior**:
- Table tools (nodejs, ai_tools, antigravity) go directly to ViewAppMenu
- ViewAppMenu shows minimal status (just status line) and action buttons
- User cannot see detailed info (version, location, method) before acting

**Root Cause** (model.go:1033-1036):
```go
if m.mainCursor < tableToolCount {
    m.selectedTool = tableTools[m.mainCursor]
    m.currentView = ViewAppMenu  // <-- Goes directly to action menu
    m.menuCursor = 0
}
```

**Expected Behavior**:
- Table tools should navigate to ViewToolDetail (same as menu tools)
- ViewToolDetail shows full status info + action menu
- Consistent UX across all tools

**Fix Location**: `tui/internal/ui/model.go` - `handleEnter()` function
**Effort**: Low (2-3 lines change)
**Risk**: Low (ViewToolDetail component already exists)

---

### Gap 2: Update All No Preview

**Current Behavior**:
- "Update All" immediately starts batch installation
- User has no visibility into which tools will be updated
- No confirmation before starting potentially long operation

**Root Cause** (model.go:1054-1058):
```go
if menuIndex == 0 {
    // "Update All" selected
    return m.startBatchUpdate()  // <-- Immediate execution
}
```

**Expected Behavior**:
- Show ViewUpdatePreview listing tools to be updated
- Display current version → new version for each
- User confirms before starting

**Fix**: Create new ViewUpdatePreview component
**Effort**: Medium (new component, ~150 lines)
**Risk**: Low (follows existing ViewConfirm pattern)

---

### Gap 3: Install All (Extras) No Preview

**Current Behavior**:
- "Install All" in Extras immediately starts batch installation
- No preview of what will be installed
- Reinstalls ALL tools (even installed ones)

**Root Cause** (model.go:455-472):
```go
} else if m.extras.IsInstallAllSelected() {
    toInstall := registry.GetExtrasTools()  // Gets ALL tools
    // ... immediately starts batch installation
}
```

**Expected Behavior**:
- Show ViewBatchPreview listing tools to be installed
- Distinguish between "to install" and "already installed"
- Option to skip already-installed tools

**Fix**: Create ViewBatchPreview component, reuse for multiple contexts
**Effort**: Medium (new component, shared with Nerd Fonts)
**Risk**: Low

---

### Gap 4: Install Claude Config Exits TUI

**Current Behavior**:
- Uses `tea.ExecProcess` which suspends TUI and shows terminal
- User sees raw script output instead of TUI progress view
- After completion, TUI resumes but feels jarring

**Root Cause** (model.go:788-797):
```go
func installClaudeConfigCmd(repoRoot string) tea.Cmd {
    scriptPath := repoRoot + "/scripts/install-claude-config.sh"
    c := exec.Command("bash", scriptPath)
    return tea.ExecProcess(c, func(err error) tea.Msg {  // <-- Exits TUI
        return claudeConfigResultMsg{...}
    })
}
```

**Expected Behavior**:
- Create a "virtual tool" for Claude Config
- Route through ViewInstaller like other tools
- Show progress within TUI

**Fix**: Create registry entry for Claude Config, use ViewInstaller
**Effort**: Medium (need tool entry + script adaptation)
**Risk**: Medium (script must work with pipeline executor)

---

### Gap 5: Install All (Nerd Fonts) No Preview

**Current Behavior**:
- "Install All" in Nerd Fonts immediately starts installation
- No preview of which fonts will be installed
- Actually runs the `install_nerdfonts.sh` script for all fonts

**Root Cause** (model.go:525-535):
```go
} else if m.nerdFonts.IsInstallAllSelected() {
    tool, ok := registry.GetTool("nerdfonts")
    // ... immediately starts installation
}
```

**Expected Behavior**:
- Show ViewBatchPreview listing fonts to be installed
- Show which fonts are already installed vs missing
- Count of fonts to install

**Fix**: Reuse ViewBatchPreview component
**Effort**: Low (reuse existing component)
**Risk**: Low

---

### Gap 6: ViewAppMenu Should Be Deprecated

**Current Behavior**:
- ViewAppMenu exists as a separate view state
- Only used by table tools
- Different UX from ViewToolDetail

**Expected Behavior**:
- Remove ViewAppMenu entirely
- All tools use ViewToolDetail
- Single consistent pattern

**Fix**: After fixing Gap 1, remove ViewAppMenu code
**Effort**: Low (cleanup after main fix)
**Risk**: Low

---

## Priority Matrix

| Gap | Priority | Effort | Risk | Dependencies |
|-----|----------|--------|------|--------------|
| Gap 1: Table tools skip detail | P1 | Low | Low | None |
| Gap 2: Update All preview | P2 | Medium | Low | ViewBatchPreview |
| Gap 3: Install All (Extras) preview | P2 | Medium | Low | ViewBatchPreview |
| Gap 4: Claude Config in TUI | P1 | Medium | Medium | None |
| Gap 5: Install All (Fonts) preview | P2 | Low | Low | ViewBatchPreview |
| Gap 6: Deprecate ViewAppMenu | P3 | Low | Low | Gap 1 |

**Recommended Order**:
1. Gap 1 (table tools) - Quick win, high impact
2. Gap 4 (Claude Config) - High user impact, independent
3. Create ViewBatchPreview component
4. Gap 2, 3, 5 (all preview screens) - Using shared component
5. Gap 6 (cleanup) - After all above complete

---

## Technical Decisions

### Decision 1: Single vs Multiple Preview Components

**Options**:
1. Create single ViewBatchPreview used for all previews
2. Create separate ViewUpdatePreview and ViewInstallPreview

**Decision**: Option 1 - Single ViewBatchPreview
**Rationale**:
- Same visual structure for all previews
- Single component to maintain
- Pass different data/labels based on context

### Decision 2: How to Handle Claude Config

**Options**:
1. Create fake registry.Tool entry for Claude Config
2. Create dedicated ClaudeConfigInstaller model
3. Modify existing script to work with executor.Pipeline

**Decision**: Option 1 - Create registry entry
**Rationale**:
- Consistent with existing patterns
- Minimal new code
- Script can be called as install script

### Decision 3: ViewBatchPreview Placement

**Options**:
1. Before ViewInstaller (user sees preview, confirms, then installation starts)
2. As first phase of ViewInstaller (integrated)

**Decision**: Option 1 - Separate view before ViewInstaller
**Rationale**:
- Clear separation of preview vs execution
- User can cancel before any work starts
- Matches ViewConfirm pattern

---

## Risk Assessment

### Low Risk Items
- Gap 1 (table tools): Simple routing change
- Gap 5 (fonts preview): Reuses shared component
- Gap 6 (cleanup): Mechanical removal

### Medium Risk Items
- Gap 4 (Claude Config): Script integration may have edge cases
- ViewBatchPreview component: New code, but follows existing patterns

### Mitigation Strategies
1. Add unit tests for new ViewBatchPreview
2. Test Claude Config script separately before integration
3. Manual testing of all 26 menu items after changes
4. Keep ViewAppMenu code until all table tools verified working

---

## Dependencies

```
ViewBatchPreview (new)
  └── Required by: Gap 2, Gap 3, Gap 5

Gap 1 (table tools)
  └── Required by: Gap 6 (deprecate ViewAppMenu)

Gap 4 (Claude Config)
  └── Independent - can be done in parallel
```

---

## Metrics to Track

| Metric | Current | Target | How to Verify |
|--------|---------|--------|---------------|
| Menu items with consistent flow | 20/26 (77%) | 26/26 (100%) | Manual audit |
| Operations with preview | 0/3 | 3/3 | Check Update All, Install All x2 |
| tea.ExecProcess usage | 2 (Claude Config, sudo) | 1 (sudo only) | Code search |
| ViewAppMenu usage | 3 (table tools) | 0 | Code search |
| ViewStates count | 12 | 14 (+ViewBatchPreview, +ViewUpdatePreview) | model.go enum |
