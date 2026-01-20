# Contract: Navigation Flow Contracts

**Component**: `tui/internal/ui/model.go`
**Version**: 1.0.0

## Overview

This document specifies the navigation contracts for consistent tool selection and batch operation flows.

---

## Contract 1: Tool Selection Navigation

### All Tools Must Navigate Through ViewToolDetail

**Rule**: Every tool (table or menu) must navigate to ViewToolDetail before showing action options.

**Before (Inconsistent)**:
```
Table tools:  Dashboard → ViewAppMenu → ViewInstaller
Menu tools:   Dashboard → ViewToolDetail → ViewInstaller
```

**After (Consistent)**:
```
All tools:    Dashboard → ViewToolDetail → ViewInstaller
```

**Implementation Contract**:

```go
// In handleEnter() for dashboard view
if m.mainCursor < tableToolCount {
    // MUST create ToolDetailModel, NOT set ViewAppMenu
    tool := tableTools[m.mainCursor]
    toolDetail := NewToolDetailModel(tool, ViewDashboard, m.state, m.cache, m.repoRoot)
    m.toolDetail = &toolDetail
    m.toolDetailFrom = ViewDashboard
    m.currentView = ViewToolDetail
    return m, m.toolDetail.Init()
}
```

**Verification Criteria**:
- After change, `ViewAppMenu` case is never reached for table tools
- All 3 table tools (nodejs, ai_tools, antigravity) show detail view

---

## Contract 2: Batch Operation Preview

### All Batch Operations Must Show Preview

**Rule**: "Update All", "Install All" (Extras), and "Install All" (Fonts) must show preview before execution.

**Flow Contract**:
```
User selects batch action
    ↓
Create BatchPreviewModel with items
    ↓
Set currentView = ViewBatchPreview
    ↓
User sees preview with item list
    ↓
[Confirm] → Start batch execution
[Cancel]  → Return to origin view
```

**Implementation Contract for Update All**:

```go
// In handleEnter() when Update All selected
func (m Model) handleUpdateAllSelected() (tea.Model, tea.Cmd) {
    toUpdate := m.getToolsNeedingUpdates()

    if len(toUpdate) == 0 {
        // No updates available - do nothing
        return m, nil
    }

    // MUST show preview, NOT start immediately
    preview := NewBatchPreviewModel(toUpdate, m.state.statuses, "Update", ViewDashboard)
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

**Implementation Contract for Install All (Extras)**:

```go
// In extras handling when Install All selected
if m.extras.IsInstallAllSelected() {
    toInstall := registry.GetExtrasTools()

    // MUST show preview, NOT start immediately
    preview := NewBatchPreviewModel(toInstall, m.state.statuses, "Install", ViewExtras)
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

---

## Contract 3: In-TUI Operation Execution

### No Operations Exit TUI Unexpectedly

**Rule**: User-initiated operations must not use `tea.ExecProcess` to exit the TUI.

**Allowed `tea.ExecProcess` Usage**:
- Sudo authentication prompt (system requirement, cannot be avoided)

**Prohibited `tea.ExecProcess` Usage**:
- Install Claude Config
- Any other user operation

**Implementation Contract for Claude Config**:

```go
// MUST NOT use tea.ExecProcess
// MUST use InstallerModel pattern
if m.extras.IsClaudeConfigSelected() {
    claudeConfigTool := &registry.Tool{
        ID:          "claude_config",
        DisplayName: "Claude Config",
        Scripts: registry.ToolScripts{
            Install: "scripts/install-claude-config.sh",
        },
    }

    installer := NewInstallerModel(claudeConfigTool, m.repoRoot)
    m.installer = &installer
    m.currentView = ViewInstaller

    initCmd := m.installer.Init()
    startCmd := func() tea.Msg {
        return InstallerStartMsg{Resume: false}
    }
    return m, tea.Batch(initCmd, startCmd)
}
```

---

## Contract 4: View State Transitions

### Valid Transitions

| From View | To View | Trigger |
|-----------|---------|---------|
| ViewDashboard | ViewToolDetail | Select any tool |
| ViewDashboard | ViewBatchPreview | Select "Update All" |
| ViewDashboard | ViewNerdFonts | Select "Nerd Fonts" |
| ViewDashboard | ViewExtras | Select "Extras" |
| ViewDashboard | ViewDiagnostics | Select "Boot Diagnostics" |
| ViewExtras | ViewToolDetail | Select any extras tool |
| ViewExtras | ViewBatchPreview | Select "Install All" |
| ViewExtras | ViewInstaller | Select "Install Claude Config" |
| ViewExtras | ViewMCPServers | Select "MCP Servers" |
| ViewNerdFonts | ViewBatchPreview | Select "Install All" |
| ViewNerdFonts | ViewInstaller | Select individual font action |
| ViewBatchPreview | ViewInstaller | Confirm batch operation |
| ViewBatchPreview | (origin) | Cancel |
| ViewToolDetail | ViewInstaller | Select Install/Update/Reinstall |
| ViewToolDetail | ViewConfirm | Select Uninstall |
| ViewToolDetail | (origin) | Select Back or ESC |

### Invalid Transitions (After Fix)

| From View | To View | Why Invalid |
|-----------|---------|-------------|
| ViewDashboard | ViewAppMenu | Deprecated - use ViewToolDetail |
| ViewExtras | ViewInstaller (immediate) | Must show ViewBatchPreview first for Install All |
| ViewDashboard | ViewInstaller (immediate) | Must show ViewBatchPreview first for Update All |

---

## Contract 5: Return Navigation

### Consistent Back Navigation

**Rule**: ESC key and "Back" action must return to the logical parent view.

| Current View | Return To |
|--------------|-----------|
| ViewToolDetail | `toolDetailFrom` (stored origin) |
| ViewBatchPreview | `batchPreview.GetReturnView()` |
| ViewInstaller | `extras != nil ? ViewExtras : ViewDashboard` |
| ViewExtras | ViewDashboard |
| ViewNerdFonts | ViewDashboard |
| ViewMCPServers | ViewExtras |
| ViewMCPPrereq | ViewMCPServers |
| ViewSecretsWizard | ViewMCPServers |
| ViewConfirm | `previousView` (stored origin) |

---

## Verification Checklist

- [ ] Table tools navigate to ViewToolDetail
- [ ] Menu tools navigate to ViewToolDetail
- [ ] "Update All" shows ViewBatchPreview
- [ ] "Install All" (Extras) shows ViewBatchPreview
- [ ] "Install All" (Fonts) shows ViewBatchPreview
- [ ] "Install Claude Config" uses ViewInstaller (not tea.ExecProcess)
- [ ] ESC from any view returns to correct parent
- [ ] ViewAppMenu is not reachable from any code path
