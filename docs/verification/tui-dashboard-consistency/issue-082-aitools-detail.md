# Verification: Issue #82 - AI Tools Table Selection Shows ViewToolDetail

**Issue**: [#82](https://github.com/kairin/ghostty-config-files/issues/82)
**Task**: T018
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
│  > Local AI Tools       ✓ Installed    1.2.3         1.3.0     │  ← Cursor here
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

## Steps

1. Launch TUI with `./start.sh`
2. Navigate cursor to **Local AI Tools** row in the table (use ↑↓)
3. Press **Enter**

## Expected Result (ViewToolDetail)

```
┌─────────────────────────────────────────────────────────────────┐
│  Local AI Tools - Details                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Status:      ✓ Installed                                 │  │
│  │  Version:     1.2.3                                       │  │
│  │  Latest:      1.3.0                                       │  │
│  │  Components:  Claude Code, Gemini CLI                     │  │
│  │  Location:    ~/.local/bin/                               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Actions:                                                       │
│  > Install                                                      │  ← Cursor here
│    Update                                                       │
│    Uninstall                                                    │
│    Back                                                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Header shows "Local AI Tools - Details" or similar
- [ ] Status box with Version, Latest, Components information
- [ ] Actions menu with Install/Update/Uninstall/Back options
- [ ] Help text shows "esc back" for navigation

### FAIL if you see:
- Simple menu with only action buttons (old ViewAppMenu style)
- No status information box displayed
- TUI crashes or shows error message
- Screen does not change from Dashboard

## How to Close This Issue

After verification passes:
```bash
gh issue close 82 --comment "Verified: AI Tools table selection shows ViewToolDetail with status box displaying version, latest, and components. Actions menu includes Install/Update/Uninstall/Back options."
```
