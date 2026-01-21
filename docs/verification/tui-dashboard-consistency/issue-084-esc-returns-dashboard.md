# Verification: Issue #84 - ESC from ViewToolDetail Returns to Dashboard

**Issue**: [#84](https://github.com/kairin/ghostty-config-files/issues/84)
**Task**: T020
**Feature**: TUI Dashboard Consistency
**Priority**: P1 MVP

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters
- Completed verification of issue #81, #82, or #83 (must reach ViewToolDetail first)

## Starting State (ViewToolDetail)

First, navigate to any tool's detail view (e.g., select Node.js from Dashboard):

```
┌─────────────────────────────────────────────────────────────────┐
│  Node.js (nvm) - Details                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Status:      ✓ Installed                                 │  │
│  │  Version:     22.12.0                                     │  │
│  │  Latest:      22.12.0                                     │  │
│  │  Method:      nvm                                         │  │
│  │  Location:    ~/.nvm/versions/node/v22.12.0              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Actions:                                                       │
│  > Install                                                      │
│    Reinstall                                                    │
│    Uninstall                                                    │
│    Back                                                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │  ← Note: "esc back"
└─────────────────────────────────────────────────────────────────┘
```

## Steps

1. From the Dashboard, select any tool to reach ViewToolDetail (see Issues #81-83)
2. Press **ESC** key

## Expected Result (Dashboard)

```
┌─────────────────────────────────────────────────────────────────┐
│  System Installer • Ghostty, Feh, Local AI Tools                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  APP                    STATUS         VERSION        LATEST    │
│  ─────────────────────────────────────────────────────────────  │
│  > Node.js (nvm)        ✓ Installed    22.12.0       22.12.0   │  ← Cursor returns here
│    Local AI Tools       ✓ Installed    1.2.3         1.3.0     │
│    Google Antigravity   ✗ Missing      -             -         │
│                                                                 │
│  Choose:                                                        │
│    Ghostty                                                      │
│    Feh                                                          │
│    Nerd Fonts                                                   │
│    Extras                                                       │
│    Boot Diagnostics                                             │
│    Exit                                                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • r refresh • q quit               │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Returns to Dashboard view (not some other view)
- [ ] Dashboard table is displayed with all tools
- [ ] Cursor position is preserved (on the tool you came from)
- [ ] TUI remains responsive to further navigation

### FAIL if you see:
- Returns to wrong view (e.g., Extras, Nerd Fonts)
- TUI crashes or freezes
- Dashboard is corrupted or not displayed correctly
- ESC key has no effect

## How to Close This Issue

After verification passes:
```bash
gh issue close 84 --comment "Verified: ESC from ViewToolDetail returns to Dashboard. Cursor position preserved. Navigation continues to work correctly."
```
