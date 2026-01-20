# Data Model: TUI Dashboard Consistency

**Feature Branch**: `008-tui-dashboard-consistency`
**Date**: 2026-01-20

## Overview

This feature primarily involves UI navigation and view composition, not persistent data models. The data structures defined here represent in-memory state for the new UI components.

---

## New Entities

### 1. BatchPreviewModel

Manages the batch preview screen state.

```go
type BatchPreviewModel struct {
    // Items to preview
    toolItems   []*registry.Tool    // For tool batch operations
    fontItems   []FontFamily        // For font batch operations
    isFont      bool                // True if showing fonts, false for tools

    // Context
    action      string              // "Install", "Update", "Uninstall"
    title       string              // Header title (e.g., "Install 5 Tools")
    returnView  View                // View to return to on cancel

    // Navigation
    cursor      int                 // 0 = Confirm, 1 = Cancel

    // Status (for tools)
    statuses    map[string]*cache.ToolStatus  // Tool ID → status

    // Flags
    confirmed   bool                // User confirmed action
    cancelled   bool                // User cancelled
}
```

**State Transitions**:
```
Idle → Confirmed  (user presses Enter on Confirm)
Idle → Cancelled  (user presses Enter on Cancel or ESC)
```

**Validation Rules**:
- `toolItems` or `fontItems` must be non-empty (but not both)
- `action` must be one of: "Install", "Update", "Uninstall"
- `returnView` must be a valid ViewState

---

### 2. BatchItem (View-Only)

Represents a single item in the batch preview list.

```go
type BatchItem struct {
    ID          string   // Tool ID or font ID
    DisplayName string   // Human-readable name
    Status      string   // Current status ("Installed", "Missing", "Update Available")
    Action      string   // What will happen ("Will install", "Will update", "Will uninstall")
    Icon        string   // Status icon (checkmark, cross, arrow)
}
```

**Note**: This is a view-only structure for rendering, not persisted.

---

### 3. View Enum Extension

Add new ViewState constant:

```go
const (
    ViewDashboard View = iota    // 0
    ViewExtras                    // 1
    ViewNerdFonts                 // 2
    ViewMCPServers               // 3
    ViewMCPPrereq                // 4
    ViewSecretsWizard            // 5
    ViewAppMenu                  // 6 (deprecated, kept for compatibility)
    ViewMethodSelect             // 7
    ViewInstaller                // 8
    ViewDiagnostics              // 9
    ViewConfirm                  // 10
    ViewToolDetail               // 11
    ViewBatchPreview             // 12 - NEW
)
```

---

## Modified Entities

### 1. Model (Root Model)

Add batch preview component reference:

```go
type Model struct {
    // ... existing fields ...

    // NEW: Batch preview component
    batchPreview     *BatchPreviewModel
    batchPreviewFrom View  // View to return to when exiting batch preview
}
```

---

### 2. Registry Tool (Pseudo-Entry)

For Claude Config, create an in-memory tool entry:

```go
// ClaudeConfigTool returns a pseudo-tool for Claude Config installation
func ClaudeConfigTool() *registry.Tool {
    return &registry.Tool{
        ID:          "claude_config",
        DisplayName: "Claude Config",
        Category:    registry.CategoryExtras,
        Scripts: registry.ToolScripts{
            Check:   "",  // No check needed
            Install: "scripts/install-claude-config.sh",
        },
    }
}
```

---

## Message Types

### New Messages

```go
// BatchPreviewConfirmMsg signals user confirmed batch operation
type BatchPreviewConfirmMsg struct {
    Tools []*registry.Tool
    Fonts []FontFamily
    IsFont bool
}

// BatchPreviewCancelMsg signals user cancelled batch preview
type BatchPreviewCancelMsg struct{}
```

---

## Entity Relationships

```
Model (root)
├── batchPreview *BatchPreviewModel  (1:0..1)
│   └── toolItems []*registry.Tool   (1:n)
│   └── fontItems []FontFamily       (1:n)
└── installer *InstallerModel        (1:0..1)
    └── tool *registry.Tool          (1:1)
```

---

## State Machine: Batch Preview Flow

```
                                    ┌─────────────────┐
                                    │   Dashboard/    │
                                    │   Extras/       │
                                    │   NerdFonts     │
                                    └────────┬────────┘
                                             │ User selects
                                             │ "Install All" / "Update All"
                                             ▼
                                    ┌─────────────────┐
                                    │  Build queue    │
                                    │  (filter items) │
                                    └────────┬────────┘
                                             │
                              ┌──────────────┴──────────────┐
                              │                             │
                        Empty queue                   Non-empty queue
                              │                             │
                              ▼                             ▼
                    ┌─────────────────┐         ┌─────────────────┐
                    │  Show message:  │         │ ViewBatchPreview │
                    │ "Nothing to     │         │ - List items     │
                    │  install/update"│         │ - Confirm/Cancel │
                    └────────┬────────┘         └────────┬────────┘
                             │                           │
                             │                ┌──────────┴──────────┐
                             │                │                     │
                             │           Confirm                  Cancel
                             │                │                     │
                             ▼                ▼                     ▼
                    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
                    │  Return to      │ │  Set batchMode  │ │  Return to      │
                    │  origin view    │ │  Start install  │ │  origin view    │
                    └─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## Validation Rules Summary

| Entity | Field | Rule |
|--------|-------|------|
| BatchPreviewModel | toolItems | Non-empty if !isFont |
| BatchPreviewModel | fontItems | Non-empty if isFont |
| BatchPreviewModel | action | One of: Install, Update, Uninstall |
| BatchPreviewModel | returnView | Valid View constant |
| BatchItem | ID | Non-empty string |
| BatchItem | DisplayName | Non-empty string |

---

## No Database Changes

This feature does not involve any persistent storage. All data structures are in-memory and transient.
