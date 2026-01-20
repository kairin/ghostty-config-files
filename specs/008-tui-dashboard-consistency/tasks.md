# TUI Dashboard Consistency - Implementation Tasks

## Task Summary

| ID | Task | Priority | Effort | Status |
|----|------|----------|--------|--------|
| T01 | Route table tools through ViewToolDetail | P1 | Low | TODO |
| T02 | Create ViewBatchPreview component | P1 | Medium | TODO |
| T03 | Add Update All preview screen | P2 | Low | TODO |
| T04 | Add Install All (Extras) preview | P2 | Low | TODO |
| T05 | Add Install All (Nerd Fonts) preview | P2 | Low | TODO |
| T06 | Convert Claude Config to ViewInstaller | P1 | Medium | TODO |
| T07 | Remove ViewAppMenu (cleanup) | P3 | Low | TODO |
| T08 | Update ViewState enum | P1 | Low | TODO |
| T09 | Add tests for new components | P2 | Medium | TODO |
| T10 | Update documentation | P3 | Low | TODO |

---

## Detailed Tasks

### T01: Route Table Tools Through ViewToolDetail

**Priority**: P1 | **Effort**: Low | **Risk**: Low

**Description**: Change table tool selection to navigate to ViewToolDetail instead of ViewAppMenu.

**File**: `tui/internal/ui/model.go`

**Current Code** (lines 1033-1037):
```go
if m.mainCursor < tableToolCount {
    m.selectedTool = tableTools[m.mainCursor]
    m.currentView = ViewAppMenu
    m.menuCursor = 0
}
```

**New Code**:
```go
if m.mainCursor < tableToolCount {
    tool := tableTools[m.mainCursor]
    toolDetail := NewToolDetailModel(tool, ViewDashboard, m.state, m.cache, m.repoRoot)
    m.toolDetail = &toolDetail
    m.toolDetailFrom = ViewDashboard
    m.currentView = ViewToolDetail
    return m, m.toolDetail.Init()
}
```

**Acceptance Criteria**:
- [ ] Selecting nodejs from table shows ViewToolDetail
- [ ] Selecting ai_tools from table shows ViewToolDetail
- [ ] Selecting antigravity from table shows ViewToolDetail
- [ ] All actions (Install, Reinstall, Uninstall) work from ViewToolDetail
- [ ] ESC returns to Dashboard

---

### T02: Create ViewBatchPreview Component

**Priority**: P1 | **Effort**: Medium | **Risk**: Low

**Description**: Create reusable component for previewing batch operations.

**File**: `tui/internal/ui/batchpreview.go` (NEW)

**Structure**:
```go
type BatchPreviewModel struct {
    title       string           // "Install All - Preview"
    items       []BatchItem      // Items to process
    skipped     []BatchItem      // Items already done
    cursor      int              // Button selection
    confirmText string           // "Install" or "Update"
    returnView  View             // Where to go on cancel
}

type BatchItem struct {
    Name        string
    Description string
    CurrentVer  string
    NewVer      string
    Icon        string  // *, ^, x
}

func (m BatchPreviewModel) Init() tea.Cmd
func (m BatchPreviewModel) Update(msg tea.Msg) (BatchPreviewModel, tea.Cmd)
func (m BatchPreviewModel) View() string
```

**View Layout**:
```
+------------------------------------------------------------------+
|  {title}                                                         |
+------------------------------------------------------------------+
|                                                                  |
|  The following will be {action}:                                 |
|                                                                  |
|  [ ] Item 1        (description)                                 |
|  [ ] Item 2        (description)                                 |
|                                                                  |
|  Already done (will skip):                                       |
|  [*] Item 3        v1.2.3                                        |
|                                                                  |
|  Total: N to {action}, M already done                            |
|                                                                  |
|  [Cancel]    [{confirmText}]                                     |
+------------------------------------------------------------------+
```

**Acceptance Criteria**:
- [ ] Component compiles without errors
- [ ] Shows list of items to process
- [ ] Shows list of skipped items
- [ ] Cancel button returns to previous view
- [ ] Confirm button returns BatchConfirmMsg

---

### T03: Add Update All Preview Screen

**Priority**: P2 | **Effort**: Low | **Risk**: Low

**Description**: Add preview before "Update All" executes.

**File**: `tui/internal/ui/model.go`

**Changes**:
1. Add `batchPreview *BatchPreviewModel` to Model
2. In `handleEnter()` for Update All:
   - Get tools needing updates
   - Create BatchPreviewModel with update info
   - Navigate to ViewBatchPreview

**Current Code** (line 1054):
```go
if menuIndex == 0 {
    return m.startBatchUpdate()
}
```

**New Code**:
```go
if menuIndex == 0 {
    updates := m.getToolsNeedingUpdates()
    preview := NewBatchPreviewModel(
        "Update All - Preview",
        updates,
        m.getUpToDateTools(),
        "Update",
        ViewDashboard,
    )
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

**Acceptance Criteria**:
- [ ] Selecting "Update All" shows preview screen
- [ ] Preview lists tools with current → new versions
- [ ] Cancel returns to dashboard
- [ ] Confirm starts batch update

---

### T04: Add Install All (Extras) Preview

**Priority**: P2 | **Effort**: Low | **Risk**: Low

**Description**: Add preview before "Install All" in Extras executes.

**File**: `tui/internal/ui/model.go`

**Changes**: In extras handling section, replace immediate batch start with preview.

**Current Code** (lines 455-472):
```go
} else if m.extras.IsInstallAllSelected() {
    toInstall := registry.GetExtrasTools()
    // ... starts batch immediately
}
```

**New Code**:
```go
} else if m.extras.IsInstallAllSelected() {
    allTools := registry.GetExtrasTools()
    toInstall, alreadyInstalled := m.partitionByInstallStatus(allTools)
    preview := NewBatchPreviewModel(
        "Install All Extras - Preview",
        toInstall,
        alreadyInstalled,
        "Install",
        ViewExtras,
    )
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

**Acceptance Criteria**:
- [ ] Selecting "Install All" in Extras shows preview
- [ ] Preview distinguishes installed vs not installed
- [ ] Cancel returns to Extras
- [ ] Confirm starts batch install

---

### T05: Add Install All (Nerd Fonts) Preview

**Priority**: P2 | **Effort**: Low | **Risk**: Low

**Description**: Add preview before "Install All" in Nerd Fonts executes.

**File**: `tui/internal/ui/model.go`

**Changes**: In nerdfonts handling section, replace immediate start with preview.

**Acceptance Criteria**:
- [ ] Selecting "Install All" in Nerd Fonts shows preview
- [ ] Preview lists fonts to install vs already installed
- [ ] Cancel returns to Nerd Fonts
- [ ] Confirm starts batch install

---

### T06: Convert Claude Config to ViewInstaller

**Priority**: P1 | **Effort**: Medium | **Risk**: Medium

**Description**: Keep Claude Config installation within TUI using ViewInstaller.

**Files**:
- `tui/internal/registry/registry.go` - Add Claude Config tool entry
- `tui/internal/ui/model.go` - Change handler to use ViewInstaller

**Current Code** (model.go:786-797):
```go
func installClaudeConfigCmd(repoRoot string) tea.Cmd {
    scriptPath := repoRoot + "/scripts/install-claude-config.sh"
    c := exec.Command("bash", scriptPath)
    return tea.ExecProcess(c, func(err error) tea.Msg {
        return claudeConfigResultMsg{success: err == nil, err: err}
    })
}
```

**New Approach**:
1. Create registry entry:
```go
{
    ID:          "claude_config",
    DisplayName: "Claude Config",
    Category:    "extras",
    Description: "Install Claude Code skills and agents",
    Scripts: ToolScripts{
        Check:   "scripts/000-check/check_claude_config.sh",
        Install: "scripts/install-claude-config.sh",
    },
}
```

2. Change handler:
```go
} else if m.extras.IsClaudeConfigSelected() {
    tool, _ := registry.GetTool("claude_config")
    return m, func() tea.Msg {
        return startInstallMsg{tool: tool, resume: false}
    }
}
```

**Acceptance Criteria**:
- [ ] Claude Config appears as tool entry
- [ ] Selecting it shows ViewInstaller
- [ ] Installation progress shown in TUI
- [ ] Success/failure displayed in TUI
- [ ] ESC returns to Extras

---

### T07: Remove ViewAppMenu (Cleanup)

**Priority**: P3 | **Effort**: Low | **Risk**: Low

**Description**: Remove ViewAppMenu after all tools use ViewToolDetail.

**File**: `tui/internal/ui/model.go`

**Changes**:
1. Remove ViewAppMenu from View enum
2. Remove viewAppMenu() function
3. Remove ViewAppMenu case from View() switch
4. Remove ViewAppMenu case from Update() switch
5. Remove handleAppMenuEnter() function
6. Update menuCursor references

**Prerequisite**: T01 must be complete and verified

**Acceptance Criteria**:
- [ ] ViewAppMenu removed from enum
- [ ] All ViewAppMenu code removed
- [ ] Code compiles without errors
- [ ] All tools still work via ViewToolDetail

---

### T08: Update ViewState Enum

**Priority**: P1 | **Effort**: Low | **Risk**: Low

**Description**: Add new ViewStates to the enum.

**File**: `tui/internal/ui/model.go`

**Current Enum**:
```go
const (
    ViewDashboard View = iota
    ViewExtras
    ViewNerdFonts
    ViewMCPServers
    ViewMCPPrereq
    ViewSecretsWizard
    ViewAppMenu
    ViewMethodSelect
    ViewInstaller
    ViewDiagnostics
    ViewConfirm
    ViewToolDetail
)
```

**New Enum**:
```go
const (
    ViewDashboard View = iota
    ViewExtras
    ViewNerdFonts
    ViewMCPServers
    ViewMCPPrereq
    ViewSecretsWizard
    ViewAppMenu        // DEPRECATED - to be removed in T07
    ViewMethodSelect
    ViewInstaller
    ViewDiagnostics
    ViewConfirm
    ViewToolDetail
    ViewBatchPreview   // NEW
)
```

**Acceptance Criteria**:
- [ ] ViewBatchPreview added to enum
- [ ] View() switch handles ViewBatchPreview
- [ ] Update() handles ViewBatchPreview messages

---

### T09: Add Tests for New Components

**Priority**: P2 | **Effort**: Medium | **Risk**: Low

**Description**: Add unit tests for BatchPreviewModel.

**File**: `tui/internal/ui/batchpreview_test.go` (NEW)

**Test Cases**:
1. `TestBatchPreviewModel_Init` - Initializes correctly
2. `TestBatchPreviewModel_View` - Renders expected layout
3. `TestBatchPreviewModel_Cancel` - Returns to previous view
4. `TestBatchPreviewModel_Confirm` - Sends BatchConfirmMsg
5. `TestBatchPreviewModel_EmptyItems` - Handles empty list
6. `TestBatchPreviewModel_Navigation` - Keyboard navigation works

**Acceptance Criteria**:
- [ ] All tests pass
- [ ] Tests cover happy path and edge cases
- [ ] Tests run with `go test ./...`

---

### T10: Update Documentation

**Priority**: P3 | **Effort**: Low | **Risk**: Low

**Description**: Update TUI documentation to reflect changes.

**Files**:
- `.claude/instructions-for-agents/tools/tui-installer.md`
- `README.md` (if TUI section exists)

**Changes**:
1. Document new ViewStates
2. Document consistent navigation flow
3. Update keyboard shortcut reference
4. Add preview screen screenshots/diagrams

**Acceptance Criteria**:
- [ ] Documentation updated
- [ ] All ViewStates documented
- [ ] Navigation flow documented

---

## Implementation Order

```
Phase 1: Foundation (P1 items)
├── T08: Update ViewState enum
├── T02: Create ViewBatchPreview component
├── T01: Route table tools through ViewToolDetail
└── T06: Convert Claude Config to ViewInstaller

Phase 2: Preview Screens (P2 items)
├── T03: Add Update All preview
├── T04: Add Install All (Extras) preview
├── T05: Add Install All (Nerd Fonts) preview
└── T09: Add tests

Phase 3: Cleanup (P3 items)
├── T07: Remove ViewAppMenu
└── T10: Update documentation
```

---

## Estimated Timeline

| Phase | Tasks | Effort |
|-------|-------|--------|
| Phase 1 | T08, T02, T01, T06 | ~4 hours |
| Phase 2 | T03, T04, T05, T09 | ~3 hours |
| Phase 3 | T07, T10 | ~1 hour |
| **Total** | | **~8 hours** |

---

## Verification Checklist

After all tasks complete:

- [ ] All 26 menu items tested manually
- [ ] Table tools go through ViewToolDetail
- [ ] "Update All" shows preview
- [ ] "Install All" (Extras) shows preview
- [ ] "Install All" (Nerd Fonts) shows preview
- [ ] "Install Claude Config" stays in TUI
- [ ] ViewAppMenu removed
- [ ] `go build` succeeds
- [ ] `go test ./...` passes
- [ ] No tea.ExecProcess for user operations (only sudo)
