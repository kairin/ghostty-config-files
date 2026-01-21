# Verification: Issue #93 - Install All Missing Shows BatchPreview

**Issue**: [#93](https://github.com/kairin/ghostty-config-files/issues/93)
**Task**: T029
**Feature**: TUI Dashboard Consistency
**Priority**: P1 MVP

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters
- At least one tool is not installed (shows as "Missing")

## Starting State (Extras Menu)

Navigate to Dashboard → Extras:

```
┌─────────────────────────────────────────────────────────────────┐
│  Extras                                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Additional Tools and Utilities                                 │
│                                                                 │
│    Update All                                                   │
│  > Install All Missing                                          │  ← Cursor here
│    Claude Config Installer                                      │
│    SpecKit Updater                                              │
│    Back                                                         │
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
3. Select **Install All Missing**
4. Press **Enter**

## Expected Result (BatchPreview)

```
┌─────────────────────────────────────────────────────────────────┐
│  Batch Install Preview                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  The following tools will be installed:                         │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  TOOL                    VERSION TO INSTALL               │  │
│  │  ───────────────────────────────────────────────────────  │  │
│  │  Google Antigravity      latest                           │  │
│  │  Feh                     latest                           │  │
│  │  VHS                     latest                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Total: 3 tools to install                                      │
│                                                                 │
│  > Proceed with Install                                         │  ← Cursor here
│    Cancel                                                       │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc cancel                       │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Header shows "Batch Install Preview" or similar
- [ ] List of missing tools that will be installed
- [ ] Version to be installed shown for each tool
- [ ] "Proceed with Install" and "Cancel" options
- [ ] Total count of tools to install

### FAIL if you see:
- Installation starts immediately without preview
- No list of tools to be installed shown
- TUI crashes or shows error
- Returns to previous menu without showing preview

## Notes

If all tools are already installed, the preview should indicate "All tools are already installed" or similar message.

## How to Close This Issue

After verification passes:
```bash
gh issue close 93 --comment "Verified: Install All Missing shows BatchPreview with list of tools to install, version info, and Proceed/Cancel options."
```
