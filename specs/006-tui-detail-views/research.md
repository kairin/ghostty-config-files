# Research: TUI Detail Views

**Feature**: 006-tui-detail-views
**Date**: 2026-01-18
**Status**: Complete

## Technical Context Resolution

All technical context items have been resolved through codebase analysis.

### 1. View State Pattern

**Decision**: Extend existing View enum with `ViewToolDetail`

**Rationale**:
- Existing pattern uses `type View int` with const iota (model.go:21-35)
- Adding `ViewToolDetail` follows established pattern
- No architectural changes required

**Alternatives Considered**:
- Sub-view within extras: Rejected - would complicate back navigation
- Modal overlay: Rejected - doesn't match TUI paradigm

### 2. Component Structure

**Decision**: Create `tooldetail.go` following `nerdfonts.go` pattern

**Rationale**:
- `nerdfonts.go` (584 lines) provides proven pattern for single-focus views
- Components: header, status table, action menu, help text
- Follows Bubbletea model (Init, Update, View, HandleKey)

**Key Pattern Elements** (from nerdfonts.go):
- Model struct with cursor, loading state, spinner, dimensions
- Status rendering with lipgloss styling
- Action menu mode with separate key handling
- Messages for async status loading

### 3. Navigation Stack

**Decision**: Track return destination in Model with `toolDetailFrom View` field

**Rationale**:
- Simple approach: one extra field tracks origin view
- Escape/Back returns to stored origin
- Supports both main dashboard → tool and extras → tool flows

**Implementation**:
```go
// In Model struct (model.go)
toolDetailFrom View  // ViewDashboard or ViewExtras
selectedDetailTool *registry.Tool
```

### 4. Registry Integration

**Decision**: Use existing `registry.GetTool(id)` for status fetching

**Rationale**:
- Registry already contains all tool metadata (registry.go)
- Existing executor.RunCheck() for status checks
- Cache integration via cache.StatusCache

**No changes needed to registry** - existing structure supports all requirements.

### 5. Menu Positioning Clarification

**Decision**: Ghostty and Feh at TOP of main menu (before Update All)

**Source**: Clarification session 2026-01-18

**Menu Order**:
1. Ghostty (new)
2. Feh (new)
3. Update All (N)
4. Nerd Fonts
5. Extras
6. Boot Diagnostics
7. Exit

### 6. Extras Menu Order

**Decision**: Alphabetical order for 7 tools

**Source**: Clarification session 2026-01-18

**Order**: Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH

## Best Practices Applied

### Bubbletea/Lipgloss Patterns

1. **Model copying**: Use pointer to sharedState for mutex-protected data
2. **Async operations**: Return tea.Cmd for status checks, not direct calls
3. **Key handling**: Separate HandleKey method for clean separation
4. **Styling**: Use existing styles from styles.go (TableHeaderStyle, etc.)

### Code Organization

1. **File size**: Keep tooldetail.go under 300 lines (constitution limit)
2. **Single responsibility**: One component per file
3. **Consistent naming**: Follow *Model suffix convention

## Dependencies Verified

| Dependency | Status | Notes |
|------------|--------|-------|
| registry.Tool | ✅ Available | Full metadata for all tools |
| cache.StatusCache | ✅ Available | Existing 5-minute TTL cache |
| executor.RunCheck | ✅ Available | Script execution with output |
| Existing styles | ✅ Available | TableHeaderStyle, StatusStyles, etc. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Navigation confusion | Low | Medium | Clear visual breadcrumb in header |
| Status check delays | Low | Low | Use existing spinner pattern |
| Main table breakage | Low | High | Test 3-tool table before commit |

## Conclusion

No NEEDS CLARIFICATION items remain. All technical decisions resolved through:
- Codebase analysis (nerdfonts.go pattern)
- Clarification session (menu ordering)
- Existing infrastructure (registry, cache, executor)

Ready to proceed with Phase 1 design artifacts.
