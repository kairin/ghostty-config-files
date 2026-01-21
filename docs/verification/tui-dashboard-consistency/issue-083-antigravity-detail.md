# Verification: Issue #83 - Antigravity Table Selection Shows ViewToolDetail

**Issue**: [#83](https://github.com/kairin/ghostty-config-files/issues/83)
**Task**: T019
**Feature**: TUI Dashboard Consistency
**Priority**: P1 MVP

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters

## Starting State (Dashboard)

```
┌─────────────────────────────────────────────────────────────────┐
│  System Installer • Ghostty, Feh, Local AI Tools                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  APP                    STATUS         VERSION        LATEST    │
│  ─────────────────────────────────────────────────────────────  │
│    Node.js (nvm)        ✓ Installed    22.12.0       22.12.0   │
│    Local AI Tools       ✓ Installed    1.2.3         1.3.0     │
│  > Google Antigravity   ✗ Missing      -             -         │  ← Cursor here
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

## Steps

1. Launch TUI with `./start.sh`
2. Navigate cursor to **Google Antigravity** row in the table (use ↑↓)
3. Press **Enter**

## Expected Result (ViewToolDetail for Missing Tool)

```
┌─────────────────────────────────────────────────────────────────┐
│  Google Antigravity - Details                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Status:      ✗ Not Installed                             │  │
│  │  Version:     -                                           │  │
│  │  Latest:      (available)                                 │  │
│  │  Description: Easter egg / demo tool                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Actions:                                                       │
│  > Install                                                      │  ← Cursor here
│    Back                                                         │
│                                                                 │
│                                                                 │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Header shows "Google Antigravity - Details" or similar
- [ ] Status box shows "Not Installed" or "Missing" status
- [ ] Actions menu shows "Install" option (and possibly "Back")
- [ ] Help text shows "esc back" for navigation

### FAIL if you see:
- Simple menu with only action buttons (old ViewAppMenu style)
- No status information box displayed
- TUI crashes or shows error message
- Screen does not change from Dashboard

## Notes

This tests the ViewToolDetail view for a **missing/not installed** tool. The display should differ slightly from installed tools (no version info, only Install action available).

## How to Close This Issue

After verification passes:
```bash
gh issue close 83 --comment "Verified: Antigravity (missing tool) table selection shows ViewToolDetail with status box displaying 'Not Installed' status. Actions menu shows Install option only."
```
