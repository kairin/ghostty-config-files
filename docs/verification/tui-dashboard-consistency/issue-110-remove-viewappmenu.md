# Verification: Issue #110 - Remove Deprecated ViewAppMenu Code

**Issue**: [#110](https://github.com/kairin/ghostty-config-files/issues/110)
**Task**: T046
**Feature**: TUI Dashboard Consistency
**Priority**: P3 Polish

## Prerequisites

- Access to the TUI source code: `tui/internal/ui/`
- Familiarity with Go code review

## Overview

This is a **code cleanup task**, not a TUI behavior verification. The goal is to verify that deprecated `ViewAppMenu` code has been removed or properly marked as deprecated.

## Code Review Checklist

### Files to Check

```bash
# Search for ViewAppMenu references
grep -r "ViewAppMenu" tui/internal/ui/
grep -r "appmenu" tui/internal/ui/
```

### Expected Results

```
┌─────────────────────────────────────────────────────────────────┐
│  Code Review: ViewAppMenu Removal                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Search Results:                                                │
│                                                                 │
│  tui/internal/ui/model.go:                                      │
│    - ViewAppMenu constant: SHOULD BE REMOVED or deprecated      │
│                                                                 │
│  tui/internal/ui/appmenu.go (if exists):                        │
│    - Entire file: SHOULD BE REMOVED or deprecated               │
│                                                                 │
│  Navigation references:                                         │
│    - Any code navigating TO ViewAppMenu: SHOULD BE REMOVED      │
│    - Any code handling ViewAppMenu: SHOULD BE REMOVED           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Verification Steps

1. **Search for ViewAppMenu constant**:
   ```bash
   grep -n "ViewAppMenu" tui/internal/ui/model.go
   ```
   - Should return no results, OR
   - Should show deprecated comment if kept for reference

2. **Search for appmenu.go file**:
   ```bash
   ls -la tui/internal/ui/appmenu.go 2>/dev/null
   ```
   - File should not exist, OR
   - Should be renamed/marked deprecated

3. **Search for navigation to ViewAppMenu**:
   ```bash
   grep -rn "ViewAppMenu" tui/internal/ui/*.go
   ```
   - Should return no active navigation code

4. **Verify ViewToolDetail is used instead**:
   ```bash
   grep -n "ViewToolDetail" tui/internal/ui/model.go
   ```
   - Should show ViewToolDetail as the replacement

## What You Should See

### PASS if you see:
- [ ] No references to `ViewAppMenu` in active code
- [ ] `ViewToolDetail` is used for tool selection navigation
- [ ] No `appmenu.go` file exists (or is deprecated)
- [ ] Code compiles and runs without ViewAppMenu

### FAIL if you see:
- Active references to `ViewAppMenu` in navigation code
- `appmenu.go` file exists and is actively used
- Mixed usage of ViewAppMenu and ViewToolDetail
- Dead code referencing ViewAppMenu

## Cleanup Commands (if needed)

If ViewAppMenu code is found:

```bash
# List all files with ViewAppMenu
grep -rl "ViewAppMenu" tui/internal/ui/

# Check if appmenu.go exists
ls tui/internal/ui/appmenu.go

# Verify build still works after removal
cd tui && go build ./cmd/installer
```

## How to Close This Issue

After verification passes:
```bash
gh issue close 110 --comment "Verified: ViewAppMenu code removed. No references in active navigation code. ViewToolDetail is used consistently for tool selection. Build succeeds."
```

Or if cleanup was required:
```bash
gh issue close 110 --comment "Completed: Removed deprecated ViewAppMenu code from [list files]. ViewToolDetail now used consistently. Build verified."
```
