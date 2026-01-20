# Contract: BatchPreviewModel Interface

**Component**: `tui/internal/ui/batchpreview.go`
**Version**: 1.0.0

## Overview

BatchPreviewModel is a Bubbletea component that displays a preview of items to be batch-processed (installed, updated, or uninstalled) and allows user confirmation before execution.

---

## Constructor Contracts

### NewBatchPreviewModel

Creates a batch preview for tools.

```go
func NewBatchPreviewModel(
    items []*registry.Tool,
    statuses map[string]*cache.ToolStatus,
    action string,
    returnView View,
) BatchPreviewModel
```

**Preconditions**:
- `items` must be non-nil and non-empty
- `action` must be one of: "Install", "Update", "Uninstall"
- `returnView` must be a valid View constant

**Postconditions**:
- Returns initialized BatchPreviewModel with cursor at Confirm button
- `isFont` is false

**Example**:
```go
tools := m.getToolsNeedingUpdates()
preview := NewBatchPreviewModel(tools, m.state.statuses, "Update", ViewDashboard)
```

---

### NewBatchPreviewModelForFonts

Creates a batch preview for Nerd Fonts.

```go
func NewBatchPreviewModelForFonts(
    fonts []FontFamily,
    action string,
    returnView View,
) BatchPreviewModel
```

**Preconditions**:
- `fonts` must be non-nil and non-empty
- `action` must be one of: "Install", "Uninstall"
- `returnView` must be a valid View constant

**Postconditions**:
- Returns initialized BatchPreviewModel with cursor at Confirm button
- `isFont` is true

---

## Method Contracts

### Init

```go
func (m BatchPreviewModel) Init() tea.Cmd
```

**Behavior**: Returns nil (no initialization commands needed)

---

### Update

```go
func (m BatchPreviewModel) Update(msg tea.Msg) (BatchPreviewModel, tea.Cmd)
```

**Handled Messages**:
| Message Type | Behavior |
|--------------|----------|
| `tea.KeyMsg "up", "k"` | Move cursor up |
| `tea.KeyMsg "down", "j"` | Move cursor down |
| `tea.KeyMsg "enter"` | Set confirmed/cancelled based on cursor |
| `tea.KeyMsg "esc"` | Set cancelled = true |
| `tea.WindowSizeMsg` | Update dimensions |

**Postconditions**:
- After Enter on Confirm: `m.IsConfirmed()` returns true
- After Enter on Cancel or ESC: `m.IsCancelled()` returns true

---

### View

```go
func (m BatchPreviewModel) View() string
```

**Output Format**:
```
┌─────────────────────────────────────────────┐
│  Update 3 Tools                             │
├─────────────────────────────────────────────┤
│  ↑ Node.js (nvm)         v20.10.0 → v22.1.0 │
│    Local AI Tools        v1.0.0 → v1.1.0    │
│    Gum                   v0.13.0 → v0.14.0  │
├─────────────────────────────────────────────┤
│  > [Confirm]   [Cancel]                     │
└─────────────────────────────────────────────┘
↑↓ navigate • enter select • esc cancel
```

---

### IsConfirmed

```go
func (m BatchPreviewModel) IsConfirmed() bool
```

**Returns**: true if user confirmed the batch operation

---

### IsCancelled

```go
func (m BatchPreviewModel) IsCancelled() bool
```

**Returns**: true if user cancelled the batch operation

---

### GetTools

```go
func (m BatchPreviewModel) GetTools() []*registry.Tool
```

**Returns**: Slice of tools in the batch (nil if isFont is true)

---

### GetFonts

```go
func (m BatchPreviewModel) GetFonts() []FontFamily
```

**Returns**: Slice of fonts in the batch (nil if isFont is false)

---

### GetReturnView

```go
func (m BatchPreviewModel) GetReturnView() View
```

**Returns**: View to return to when exiting

---

## Integration Contract

### Parent Model Responsibilities

The parent Model must:

1. Create BatchPreviewModel when batch operation is triggered
2. Set `m.currentView = ViewBatchPreview`
3. Store reference: `m.batchPreview = &preview`
4. Delegate Update/View calls to batch preview
5. Check `IsConfirmed()` / `IsCancelled()` on Enter
6. On confirm: Set batch mode and start installation
7. On cancel: Clear batch preview and return to origin view

### Example Integration (in model.go Update)

```go
if m.currentView == ViewBatchPreview && m.batchPreview != nil {
    newPreview, cmd := m.batchPreview.Update(msg)
    m.batchPreview = &newPreview

    if keyMsg, ok := msg.(tea.KeyMsg); ok && keyMsg.String() == "enter" {
        if m.batchPreview.IsConfirmed() {
            // Start batch operation
            m.batchQueue = m.batchPreview.GetTools()
            m.batchIndex = 0
            m.batchMode = true
            m.batchPreview = nil
            m.currentView = ViewInstaller
            return m, func() tea.Msg {
                return startInstallMsg{tool: m.batchQueue[0]}
            }
        } else if m.batchPreview.IsCancelled() {
            // Return to origin
            m.currentView = m.batchPreview.GetReturnView()
            m.batchPreview = nil
            return m, nil
        }
    }

    return m, cmd
}
```

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Empty items slice | Caller should check before creating model |
| Invalid action | Undefined behavior (caller must validate) |
| Invalid returnView | Will navigate to invalid view (caller must validate) |
