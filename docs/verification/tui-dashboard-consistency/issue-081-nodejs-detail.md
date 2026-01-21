# Verification: Issue #81 - Node.js Table Selection Shows ViewToolDetail

**Issue**: [#81](https://github.com/kairin/ghostty-config-files/issues/81)
**Task**: T017
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
│  > Node.js (nvm)        ✓ Installed    22.12.0       22.12.0   │  ← Cursor here
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

## Steps

1. Launch TUI with `./start.sh`
2. Navigate cursor to **Node.js (nvm)** row in the table (use ↑↓ if needed)
3. Press **Enter**

## Expected Result (ViewToolDetail)

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
│  > Install                                                      │  ← Cursor here
│    Reinstall                                                    │
│    Uninstall                                                    │
│    Back                                                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Header shows "Node.js (nvm) - Details" or similar
- [ ] Status box with Version, Latest, Method, Location information
- [ ] Actions menu with Install/Reinstall/Uninstall/Back options
- [ ] Help text shows "esc back" for navigation

### FAIL if you see:
- Simple menu with only action buttons (old ViewAppMenu style)
- No status information box displayed
- TUI crashes or shows error message
- Screen does not change from Dashboard

## How to Close This Issue

After verification passes:
```bash
gh issue close 81 --comment "Verified: Node.js table selection shows ViewToolDetail with status box displaying version, method, and location. Actions menu includes Install/Reinstall/Uninstall/Back options."
```
