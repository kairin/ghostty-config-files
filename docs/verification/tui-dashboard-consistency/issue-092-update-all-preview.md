# Verification: Issue #92 - Update All Shows BatchPreview

**Issue**: [#92](https://github.com/kairin/ghostty-config-files/issues/92)
**Task**: T028
**Feature**: TUI Dashboard Consistency
**Priority**: P1 MVP

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters
- At least one tool has an available update

## Starting State (Extras Menu)

Navigate to Dashboard → Extras:

```
┌─────────────────────────────────────────────────────────────────┐
│  Extras                                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Additional Tools and Utilities                                 │
│                                                                 │
│  > Update All                                                   │  ← Cursor here
│    Install All Missing                                          │
│    Claude Config Installer                                      │
│    SpecKit Updater                                              │
│    Back                                                         │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## Steps

1. Launch TUI with `./start.sh`
2. Navigate to **Extras** from Dashboard menu
3. Select **Update All**
4. Press **Enter**

## Expected Result (BatchPreview)

```
┌─────────────────────────────────────────────────────────────────┐
│  Batch Update Preview                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  The following tools will be updated:                           │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  TOOL              CURRENT     →    LATEST                │  │
│  │  ───────────────────────────────────────────────────────  │  │
│  │  Node.js           22.11.0     →    22.12.0               │  │
│  │  Claude Code       1.0.0       →    1.1.0                 │  │
│  │  Ghostty           1.2.0       →    1.2.3                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Total: 3 tools to update                                       │
│                                                                 │
│  > Proceed with Update                                          │  ← Cursor here
│    Cancel                                                       │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc cancel                       │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Header shows "Batch Update Preview" or similar
- [ ] List of tools that will be updated with version info
- [ ] Current version → Latest version displayed for each tool
- [ ] "Proceed with Update" and "Cancel" options
- [ ] Total count of tools to update

### FAIL if you see:
- Updates start immediately without preview
- No list of tools to be updated shown
- TUI crashes or shows error
- Returns to previous menu without showing preview

## Notes

If no tools need updates, the preview should indicate "All tools are up to date" or similar message.

## How to Close This Issue

After verification passes:
```bash
gh issue close 92 --comment "Verified: Update All shows BatchPreview with list of tools to update, current/latest versions, and Proceed/Cancel options."
```
