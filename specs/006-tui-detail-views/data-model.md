# Data Model: TUI Detail Views

**Feature**: 006-tui-detail-views
**Date**: 2026-01-18

## Entities

### 1. ToolDetailModel (NEW)

Represents the detail view state for a single tool.

| Field | Type | Description |
|-------|------|-------------|
| tool | *registry.Tool | The tool being displayed |
| status | *cache.ToolStatus | Current status (installed, version, etc.) |
| cursor | int | Current menu selection (0-3) |
| loading | bool | Whether status check is in progress |
| spinner | spinner.Model | Loading indicator |
| returnTo | View | View to return to on Back/Escape |
| state | *sharedState | Shared status data (pointer) |
| cache | *cache.StatusCache | Status cache reference |
| repoRoot | string | Repository root path |
| width | int | Terminal width |
| height | int | Terminal height |

**Menu Items** (by status):
- Installed: Install/Update, Reinstall, Uninstall, Back
- Not Installed: Install, Back
- ZSH (special): adds Configure option

### 2. View Enum Extension

Add to existing View enum in model.go:

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
    ViewToolDetail  // NEW
)
```

### 3. Model Extensions

Add to root Model struct in model.go:

| Field | Type | Description |
|-------|------|-------------|
| toolDetail | *ToolDetailModel | Active tool detail component |
| toolDetailFrom | View | Origin view for back navigation |

## State Transitions

### Navigation Flow

```
ViewDashboard
    │
    ├─> Ghostty menu item ──> ViewToolDetail (returnTo=ViewDashboard)
    ├─> Feh menu item ──────> ViewToolDetail (returnTo=ViewDashboard)
    ├─> Nerd Fonts ─────────> ViewNerdFonts (unchanged)
    └─> Extras ─────────────> ViewExtras
                                   │
                                   ├─> Fastfetch ──> ViewToolDetail (returnTo=ViewExtras)
                                   ├─> Glow ───────> ViewToolDetail (returnTo=ViewExtras)
                                   ├─> Go ─────────> ViewToolDetail (returnTo=ViewExtras)
                                   ├─> Gum ────────> ViewToolDetail (returnTo=ViewExtras)
                                   ├─> Python/uv ──> ViewToolDetail (returnTo=ViewExtras)
                                   ├─> VHS ────────> ViewToolDetail (returnTo=ViewExtras)
                                   └─> ZSH ────────> ViewToolDetail (returnTo=ViewExtras)
```

### Back Navigation

```
ViewToolDetail ─── Escape/Back ───> returnTo (ViewDashboard or ViewExtras)
```

## Messages (Bubbletea)

### New Message Types

```go
// toolDetailStatusLoadedMsg signals that tool status has loaded
type toolDetailStatusLoadedMsg struct {
    toolID string
    status *cache.ToolStatus
}
```

### Existing Messages Used

- `spinner.TickMsg` - spinner animation
- `tea.WindowSizeMsg` - terminal resize
- `tea.KeyMsg` - keyboard input

## Registry Data (Existing)

Tool registry already provides all required metadata:

```go
type Tool struct {
    ID          string      // "ghostty", "feh", etc.
    DisplayName string      // "Ghostty", "Feh", etc.
    Description string      // Full description
    Category    string      // "main" or "extras"
    Scripts     Scripts     // Check, Install, Uninstall, Update paths
    // ... other fields
}
```

No changes required to registry structure.

## Status Data (Existing)

Status cache already provides:

```go
type ToolStatus struct {
    ID        string   // Tool identifier
    Status    string   // "Installed", "Missing", "Unknown"
    Version   string   // Current version
    LatestVer string   // Latest available
    Method    string   // "apt", "source", "snap", etc.
    Location  string   // Binary path
    Details   []string // Additional info
}
```

No changes required to cache structure.
