# Verification: Issue #113 - Verify All 26 Navigation Items

**Issue**: [#113](https://github.com/kairin/ghostty-config-files/issues/113)
**Task**: T049
**Feature**: TUI Dashboard Consistency
**Priority**: P3 Polish

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters
- Completed all previous verification issues (#81-84, #92-94, #100-102, #107-109, #110)

## Overview

This is a comprehensive audit to verify all 26 navigation items in the TUI work correctly.

## Navigation Map

```
┌─────────────────────────────────────────────────────────────────┐
│  TUI Navigation Structure (26 Items)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Dashboard                                                      │
│  ├── Table Items (3)                                            │
│  │   ├── [1] Node.js (nvm)        → ViewToolDetail              │
│  │   ├── [2] Local AI Tools       → ViewToolDetail              │
│  │   └── [3] Google Antigravity   → ViewToolDetail              │
│  │                                                              │
│  ├── Menu Items (6)                                             │
│  │   ├── [4] Ghostty              → ViewGhostty                 │
│  │   ├── [5] Feh                  → ViewFeh                     │
│  │   ├── [6] Nerd Fonts           → ViewNerdFonts               │
│  │   ├── [7] Extras               → ViewExtras                  │
│  │   ├── [8] Boot Diagnostics     → ViewBootDiagnostics         │
│  │   └── [9] Exit                 → Quit                        │
│  │                                                              │
│  ViewToolDetail (from table)                                    │
│  ├── [10] Install                 → Install action              │
│  ├── [11] Reinstall               → Reinstall action            │
│  ├── [12] Uninstall               → Uninstall action            │
│  └── [13] Back / ESC              → Dashboard                   │
│  │                                                              │
│  ViewNerdFonts                                                  │
│  ├── [14] Font selection          → ViewFontDetail              │
│  ├── [15] Install All Missing     → BatchPreview                │
│  └── [16] Back / ESC              → Dashboard                   │
│  │                                                              │
│  ViewExtras                                                     │
│  ├── [17] Update All              → BatchPreview                │
│  ├── [18] Install All Missing     → BatchPreview                │
│  ├── [19] Claude Config Installer → ViewInstaller               │
│  ├── [20] SpecKit Updater         → ViewSpecKitUpdater          │
│  └── [21] Back / ESC              → Dashboard                   │
│  │                                                              │
│  BatchPreview (from various sources)                            │
│  ├── [22] Proceed                 → Execute batch               │
│  └── [23] Cancel / ESC            → Origin view                 │
│  │                                                              │
│  ViewInstaller                                                  │
│  ├── [24] Install/Update          → Progress → Complete         │
│  ├── [25] Verify Setup            → Verify action               │
│  └── [26] Back / ESC              → Extras                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Full Audit Checklist

### Dashboard Navigation (Items 1-9)

| # | Item | Action | Expected Result | Status |
|---|------|--------|-----------------|--------|
| 1 | Node.js (nvm) | Enter | ViewToolDetail with status | [ ] |
| 2 | Local AI Tools | Enter | ViewToolDetail with status | [ ] |
| 3 | Google Antigravity | Enter | ViewToolDetail with status | [ ] |
| 4 | Ghostty | Enter | ViewGhostty | [ ] |
| 5 | Feh | Enter | ViewFeh | [ ] |
| 6 | Nerd Fonts | Enter | ViewNerdFonts | [ ] |
| 7 | Extras | Enter | ViewExtras | [ ] |
| 8 | Boot Diagnostics | Enter | ViewBootDiagnostics | [ ] |
| 9 | Exit | Enter | TUI Exits cleanly | [ ] |

### ViewToolDetail Navigation (Items 10-13)

| # | Item | Action | Expected Result | Status |
|---|------|--------|-----------------|--------|
| 10 | Install | Enter | Installation starts | [ ] |
| 11 | Reinstall | Enter | Reinstallation starts | [ ] |
| 12 | Uninstall | Enter | Uninstallation starts | [ ] |
| 13 | Back / ESC | Enter/ESC | Returns to Dashboard | [ ] |

### ViewNerdFonts Navigation (Items 14-16)

| # | Item | Action | Expected Result | Status |
|---|------|--------|-----------------|--------|
| 14 | Font selection | Enter | ViewFontDetail | [ ] |
| 15 | Install All Missing | Enter | BatchPreview | [ ] |
| 16 | Back / ESC | Enter/ESC | Returns to Dashboard | [ ] |

### ViewExtras Navigation (Items 17-21)

| # | Item | Action | Expected Result | Status |
|---|------|--------|-----------------|--------|
| 17 | Update All | Enter | BatchPreview | [ ] |
| 18 | Install All Missing | Enter | BatchPreview | [ ] |
| 19 | Claude Config Installer | Enter | ViewInstaller | [ ] |
| 20 | SpecKit Updater | Enter | ViewSpecKitUpdater | [ ] |
| 21 | Back / ESC | Enter/ESC | Returns to Dashboard | [ ] |

### BatchPreview Navigation (Items 22-23)

| # | Item | Action | Expected Result | Status |
|---|------|--------|-----------------|--------|
| 22 | Proceed | Enter | Batch operation executes | [ ] |
| 23 | Cancel / ESC | Enter/ESC | Returns to origin | [ ] |

### ViewInstaller Navigation (Items 24-26)

| # | Item | Action | Expected Result | Status |
|---|------|--------|-----------------|--------|
| 24 | Install/Update | Enter | Progress shown → Complete | [ ] |
| 25 | Verify Setup | Enter | Verification runs | [ ] |
| 26 | Back / ESC | Enter/ESC | Returns to Extras | [ ] |

## What You Should See

### PASS if you see:
- [ ] All 26 navigation items work correctly
- [ ] No navigation leads to wrong view
- [ ] No crashes or freezes
- [ ] ESC always returns to parent view
- [ ] All actions execute as expected

### FAIL if you see:
- Any navigation item goes to wrong view
- Any navigation item causes crash
- ESC does not return to parent
- Missing navigation items
- Duplicate or inconsistent behavior

## How to Close This Issue

After verification passes:
```bash
gh issue close 113 --comment "Verified: All 26 navigation items audited and working correctly. Full navigation map verified: Dashboard (9 items), ViewToolDetail (4), ViewNerdFonts (3), ViewExtras (5), BatchPreview (2), ViewInstaller (3)."
```
