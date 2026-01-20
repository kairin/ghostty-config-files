# Quickstart: TUI Dashboard Consistency Implementation

**Feature Branch**: `008-tui-dashboard-consistency`
**Date**: 2026-01-20

## Prerequisites

- Go 1.23+ installed
- Repository cloned and on correct branch
- Familiarity with Bubbletea patterns

## Quick Setup

```bash
# Navigate to TUI directory
cd tui

# Ensure dependencies are up to date
go mod tidy

# Build to verify current state compiles
go build ./cmd/installer
```

---

## Implementation Order

### Step 1: Create BatchPreviewModel Component

**File**: `tui/internal/ui/batchpreview.go`

```go
// Package ui - batchpreview.go provides the batch operation preview view
package ui

import (
    "fmt"
    "strings"

    tea "github.com/charmbracelet/bubbletea"
    "github.com/charmbracelet/lipgloss"
    "github.com/kairin/ghostty-installer/internal/cache"
    "github.com/kairin/ghostty-installer/internal/registry"
)

// BatchPreviewModel manages the batch preview screen
type BatchPreviewModel struct {
    // Items to preview
    toolItems []*registry.Tool
    fontItems []FontFamily
    isFont    bool

    // Context
    action     string
    returnView View

    // Statuses (for version display)
    statuses map[string]*cache.ToolStatus

    // Navigation: 0 = Confirm, 1 = Cancel
    cursor int

    // Flags
    confirmed bool
    cancelled bool

    // Dimensions
    width  int
    height int
}

// NewBatchPreviewModel creates a batch preview for tools
func NewBatchPreviewModel(
    items []*registry.Tool,
    statuses map[string]*cache.ToolStatus,
    action string,
    returnView View,
) BatchPreviewModel {
    return BatchPreviewModel{
        toolItems:  items,
        statuses:   statuses,
        action:     action,
        returnView: returnView,
        cursor:     0,
        isFont:     false,
    }
}

// NewBatchPreviewModelForFonts creates a batch preview for fonts
func NewBatchPreviewModelForFonts(
    fonts []FontFamily,
    action string,
    returnView View,
) BatchPreviewModel {
    return BatchPreviewModel{
        fontItems:  fonts,
        action:     action,
        returnView: returnView,
        cursor:     0,
        isFont:     true,
    }
}

func (m BatchPreviewModel) Init() tea.Cmd { return nil }

func (m BatchPreviewModel) Update(msg tea.Msg) (BatchPreviewModel, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.WindowSizeMsg:
        m.width = msg.Width
        m.height = msg.Height
    case tea.KeyMsg:
        switch msg.String() {
        case "up", "k", "left", "h":
            if m.cursor > 0 { m.cursor-- }
        case "down", "j", "right", "l":
            if m.cursor < 1 { m.cursor++ }
        case "enter":
            if m.cursor == 0 {
                m.confirmed = true
            } else {
                m.cancelled = true
            }
        case "esc":
            m.cancelled = true
        }
    }
    return m, nil
}

func (m BatchPreviewModel) View() string {
    var b strings.Builder

    // Header
    count := len(m.toolItems)
    if m.isFont { count = len(m.fontItems) }
    title := fmt.Sprintf("%s %d %s", m.action, count, m.itemType())
    b.WriteString(HeaderStyle.Render(title))
    b.WriteString("\n\n")

    // Item list
    b.WriteString(m.renderItemList())
    b.WriteString("\n")

    // Buttons
    b.WriteString(m.renderButtons())
    b.WriteString("\n\n")

    // Help
    b.WriteString(HelpStyle.Render("↑↓←→ navigate • enter select • esc cancel"))

    return b.String()
}

func (m BatchPreviewModel) itemType() string {
    if m.isFont {
        if len(m.fontItems) == 1 { return "Font" }
        return "Fonts"
    }
    if len(m.toolItems) == 1 { return "Tool" }
    return "Tools"
}

func (m BatchPreviewModel) renderItemList() string {
    var b strings.Builder

    if m.isFont {
        for _, font := range m.fontItems {
            icon := IconCross
            if font.Status == "Installed" { icon = IconCheckmark }
            b.WriteString(fmt.Sprintf("  %s %s\n", icon, font.DisplayName))
        }
    } else {
        for _, tool := range m.toolItems {
            status := m.statuses[tool.ID]
            icon := IconCross
            versionInfo := ""
            if status != nil {
                if status.IsInstalled() { icon = IconCheckmark }
                if status.NeedsUpdate() {
                    icon = IconArrowUp
                    versionInfo = fmt.Sprintf(" (%s → %s)", status.Version, status.LatestVer)
                }
            }
            b.WriteString(fmt.Sprintf("  %s %s%s\n", icon, tool.DisplayName, versionInfo))
        }
    }

    // Box styling
    boxStyle := lipgloss.NewStyle().
        BorderStyle(lipgloss.RoundedBorder()).
        BorderForeground(ColorPrimary).
        Padding(1, 2)

    return boxStyle.Render(b.String())
}

func (m BatchPreviewModel) renderButtons() string {
    confirmStyle := lipgloss.NewStyle().Padding(0, 2).Border(lipgloss.RoundedBorder())
    cancelStyle := confirmStyle.Copy()

    if m.cursor == 0 {
        confirmStyle = confirmStyle.BorderForeground(ColorPrimary).Foreground(ColorPrimary).Bold(true)
        cancelStyle = cancelStyle.BorderForeground(ColorMuted)
    } else {
        confirmStyle = confirmStyle.BorderForeground(ColorMuted)
        cancelStyle = cancelStyle.BorderForeground(ColorPrimary).Foreground(ColorPrimary).Bold(true)
    }

    return lipgloss.JoinHorizontal(
        lipgloss.Center,
        confirmStyle.Render("Confirm"),
        "  ",
        cancelStyle.Render("Cancel"),
    )
}

// Query methods
func (m BatchPreviewModel) IsConfirmed() bool { return m.confirmed }
func (m BatchPreviewModel) IsCancelled() bool { return m.cancelled }
func (m BatchPreviewModel) GetTools() []*registry.Tool { return m.toolItems }
func (m BatchPreviewModel) GetFonts() []FontFamily { return m.fontItems }
func (m BatchPreviewModel) GetReturnView() View { return m.returnView }
```

---

### Step 2: Add ViewBatchPreview Constant

**File**: `tui/internal/ui/model.go` (line ~36)

```go
const (
    // ... existing constants ...
    ViewToolDetail               // 11
    ViewBatchPreview             // 12 - NEW
)
```

---

### Step 3: Add BatchPreview Field to Model

**File**: `tui/internal/ui/model.go` (in Model struct)

```go
type Model struct {
    // ... existing fields ...

    // Batch preview component
    batchPreview     *BatchPreviewModel
}
```

---

### Step 4: Fix Table Tool Navigation

**File**: `tui/internal/ui/model.go` (in handleEnter, ~line 1033)

Replace:
```go
if m.mainCursor < tableToolCount {
    m.selectedTool = tableTools[m.mainCursor]
    m.currentView = ViewAppMenu
    m.menuCursor = 0
}
```

With:
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

---

### Step 5: Add BatchPreview Handling in Update

**File**: `tui/internal/ui/model.go` (in Update method, after ToolDetail handling)

```go
// If batch preview is active, delegate messages to it
if m.currentView == ViewBatchPreview && m.batchPreview != nil {
    newPreview, cmd := m.batchPreview.Update(msg)
    m.batchPreview = &newPreview

    if keyMsg, ok := msg.(tea.KeyMsg); ok && keyMsg.String() == "enter" {
        if m.batchPreview.IsConfirmed() {
            // Start batch operation
            if m.batchPreview.isFont {
                // Font batch - use nerdfonts tool
                tool, _ := registry.GetTool("nerdfonts")
                m.selectedTool = tool
                m.batchPreview = nil
                return m, func() tea.Msg {
                    return startInstallMsg{tool: tool, resume: false}
                }
            } else {
                m.batchQueue = m.batchPreview.GetTools()
                m.batchIndex = 0
                m.batchMode = true
                m.batchPreview = nil
                firstTool := m.batchQueue[0]
                m.selectedTool = firstTool
                return m, func() tea.Msg {
                    return startInstallMsg{tool: firstTool, resume: false}
                }
            }
        }
        if m.batchPreview.IsCancelled() {
            returnView := m.batchPreview.GetReturnView()
            m.batchPreview = nil
            m.currentView = returnView
            return m, nil
        }
    }

    if keyMsg, ok := msg.(tea.KeyMsg); ok && keyMsg.String() == "esc" {
        returnView := m.batchPreview.GetReturnView()
        m.batchPreview = nil
        m.currentView = returnView
        return m, nil
    }

    return m, cmd
}
```

---

### Step 6: Add BatchPreview View Case

**File**: `tui/internal/ui/model.go` (in View method)

```go
case ViewBatchPreview:
    if m.batchPreview != nil {
        return m.batchPreview.View()
    }
    return m.viewDashboard()
```

---

### Step 7: Route Update All to Preview

**File**: `tui/internal/ui/model.go` (in handleEnter, update startBatchUpdate call)

Replace direct `m.startBatchUpdate()` with preview creation:
```go
if menuIndex == 0 {
    // "Update All" selected - show preview
    toUpdate := m.getToolsNeedingUpdates()
    if len(toUpdate) == 0 {
        return m, nil
    }
    m.state.mu.RLock()
    statuses := make(map[string]*cache.ToolStatus)
    for k, v := range m.state.statuses {
        statuses[k] = v
    }
    m.state.mu.RUnlock()
    preview := NewBatchPreviewModel(toUpdate, statuses, "Update", ViewDashboard)
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

---

### Step 8: Route Extras Install All to Preview

**File**: `tui/internal/ui/model.go` (in extras handling)

Replace immediate batch start with preview:
```go
} else if m.extras.IsInstallAllSelected() {
    toInstall := registry.GetExtrasTools()
    if len(toInstall) == 0 {
        return m, nil
    }
    m.state.mu.RLock()
    statuses := make(map[string]*cache.ToolStatus)
    for k, v := range m.state.statuses {
        statuses[k] = v
    }
    m.state.mu.RUnlock()
    preview := NewBatchPreviewModel(toInstall, statuses, "Install", ViewExtras)
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

---

### Step 9: Fix Claude Config to Use ViewInstaller

**File**: `tui/internal/ui/model.go` (in extras handling)

Replace tea.ExecProcess with InstallerModel:
```go
} else if m.extras.IsClaudeConfigSelected() {
    // Create pseudo-tool for Claude Config
    claudeConfigTool := &registry.Tool{
        ID:          "claude_config",
        DisplayName: "Claude Config",
        Scripts: registry.ToolScripts{
            Install: "scripts/install-claude-config.sh",
        },
    }
    m.selectedTool = claudeConfigTool
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

### Step 10: Route Nerd Fonts Install All to Preview

**File**: `tui/internal/ui/model.go` (in nerdfonts handling)

Replace immediate install with preview:
```go
} else if m.nerdFonts.IsInstallAllSelected() {
    // Get missing fonts for preview
    var missingFonts []FontFamily
    for _, font := range m.nerdFonts.fonts {
        if font.Status != "Installed" {
            missingFonts = append(missingFonts, font)
        }
    }
    if len(missingFonts) == 0 {
        return m, nil
    }
    preview := NewBatchPreviewModelForFonts(missingFonts, "Install", ViewNerdFonts)
    m.batchPreview = &preview
    m.currentView = ViewBatchPreview
    return m, nil
}
```

---

## Verification Steps

```bash
# Build the TUI
cd tui
go build ./cmd/installer

# Run and test each scenario
./ghostty-installer

# Test 1: Table tool navigation
# Select Node.js → Should see ToolDetail view

# Test 2: Update All preview
# (If updates available) Select Update All → Should see preview

# Test 3: Extras Install All
# Go to Extras → Install All → Should see preview

# Test 4: Claude Config in TUI
# Go to Extras → Install Claude Config → Should see progress in TUI

# Test 5: Nerd Fonts Install All
# Go to Nerd Fonts → Install All → Should see preview of missing fonts
```

---

## Rollback

If issues arise:
```bash
git checkout -- tui/internal/ui/
```
