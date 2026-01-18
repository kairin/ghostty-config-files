# Quickstart: TUI Detail Views

**Feature**: 006-tui-detail-views
**Estimated Effort**: 4-6 hours

## Prerequisites

- Go 1.23+ installed
- Existing TUI compiles: `cd tui && go build ./cmd/installer`
- Familiarity with Bubbletea pattern (see `nerdfonts.go` as reference)

## Implementation Order

### Step 1: Create ToolDetailModel (P1 - Core)

**File**: `tui/internal/ui/tooldetail.go` (NEW)

1. Copy structure from `nerdfonts.go` as template
2. Replace FontFamily with Tool focus
3. Implement:
   - `NewToolDetailModel()` constructor
   - `Init()` - spinner + status load
   - `Update()` - message handling
   - `View()` - render detail view
   - `HandleKey()` - navigation

**Test**: Compile and visually verify detail view renders

### Step 2: Add View Constant

**File**: `tui/internal/ui/model.go`

1. Add `ViewToolDetail` to View enum (after ViewConfirm)
2. Add fields to Model struct:
   ```go
   toolDetail     *ToolDetailModel
   toolDetailFrom View
   ```

### Step 3: Route to ViewToolDetail

**File**: `tui/internal/ui/model.go`

1. Add ViewToolDetail case in main Update switch
2. Add ViewToolDetail case in main View switch
3. Handle Escape in ViewToolDetail

### Step 4: Simplify Main Dashboard (P2)

**File**: `tui/internal/ui/model.go`

1. Modify `renderMainTable()` to show 3 tools:
   - Node.js, Local AI Tools, Google Antigravity
2. Add Ghostty and Feh as menu items at TOP
3. Handle menu selection → ViewToolDetail navigation

### Step 5: Convert Extras to Menu (P3)

**File**: `tui/internal/ui/extras.go`

1. Remove `renderExtrasTable()` call
2. Replace with navigation menu:
   - Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH (alphabetical)
   - Install All, Install Claude Config, MCP Servers, Back
3. Handle tool selection → ViewToolDetail navigation

## Verification Commands

```bash
# After each step, verify compilation
cd tui && go build ./cmd/installer

# Run and test navigation
./installer
```

## Success Checklist

- [ ] `go build` succeeds with no errors
- [ ] Main dashboard shows 3 tools in table
- [ ] Ghostty and Feh appear at top of main menu
- [ ] Selecting Ghostty shows detail view with all status info
- [ ] Escape from detail view returns to correct parent
- [ ] Extras shows menu, not table
- [ ] Each extras tool navigates to detail view
- [ ] All existing functionality (install, uninstall) works

## Key Files Changed

| File | Change Type |
|------|-------------|
| `tooldetail.go` | NEW |
| `model.go` | MODIFY |
| `extras.go` | MODIFY |

## Reference Implementation

Use `nerdfonts.go` as the reference pattern:
- Lines 24-55: Model struct with all required fields
- Lines 56-101: Constructor with proper initialization
- Lines 200-235: View method structure
- Lines 377-440: HandleKey method pattern
