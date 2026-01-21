# Verification: Issue #100 - Claude Config Shows ViewInstaller

**Issue**: [#100](https://github.com/kairin/ghostty-config-files/issues/100)
**Task**: T036
**Feature**: TUI Dashboard Consistency
**Priority**: P2 Enhancement

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters

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
│    Install All Missing                                          │
│  > Claude Config Installer                                      │  ← Cursor here
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
3. Select **Claude Config Installer**
4. Press **Enter**

## Expected Result (ViewInstaller)

```
┌─────────────────────────────────────────────────────────────────┐
│  Claude Config Installer                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Install Claude Code configuration and MCP server setup         │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Component               Status                           │  │
│  │  ───────────────────────────────────────────────────────  │  │
│  │  CLAUDE.md symlink       ✓ Configured                     │  │
│  │  MCP servers             ✓ 7 servers active               │  │
│  │  API keys                ⚠ 1 key missing                  │  │
│  │  Settings                ✓ Default profile                │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  > Install/Update Config                                        │  ← Cursor here
│    Verify Setup                                                 │
│    Back                                                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Header shows "Claude Config Installer" or similar
- [ ] Status box showing component configuration status
- [ ] Actions like "Install/Update Config" and "Verify Setup"
- [ ] Help text shows "esc back" for navigation

### FAIL if you see:
- Simple menu without status information
- Installation starts immediately without preview
- TUI crashes or shows error
- Screen does not change from Extras

## How to Close This Issue

After verification passes:
```bash
gh issue close 100 --comment "Verified: Claude Config Installer shows ViewInstaller with status box for CLAUDE.md symlink, MCP servers, API keys, and Settings. Install/Update and Verify options available."
```
