# Verification: Issue #114 - Update Quickstart Documentation

**Issue**: [#114](https://github.com/kairin/ghostty-config-files/issues/114)
**Task**: T050
**Feature**: TUI Dashboard Consistency
**Priority**: P3 Polish

## Prerequisites

- Access to documentation files
- Completed verification of all behavior issues (#81-84, #92-94, #100-102, #107-109)

## Overview

This is a **documentation task**, not a TUI behavior verification. The goal is to ensure the quickstart documentation accurately reflects the current TUI behavior.

## Files to Check

```
┌─────────────────────────────────────────────────────────────────┐
│  Documentation Files                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Primary Documentation:                                         │
│  ├── README.md                                                  │
│  ├── QUICKSTART.md (if exists)                                  │
│  ├── docs/getting-started.md (if exists)                        │
│  └── specs/008-tui-dashboard-consistency/quickstart.md          │
│                                                                 │
│  Secondary References:                                          │
│  ├── AGENTS.md (LLM instructions)                               │
│  └── .claude/instructions-for-agents/guides/                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Documentation Checklist

### 1. TUI Launch Instructions

| Requirement | Current Doc | Correct? |
|-------------|-------------|----------|
| Launch command is `./start.sh` | | [ ] |
| Alternative: `cd tui && go run ./cmd/installer` | | [ ] |
| Prerequisites listed (Go 1.23+, etc.) | | [ ] |

### 2. Navigation Instructions

| Feature | Documented? | Accurate? |
|---------|-------------|-----------|
| Dashboard table selection | | [ ] |
| ViewToolDetail behavior | | [ ] |
| Nerd Fonts batch install | | [ ] |
| Extras menu options | | [ ] |
| ESC key behavior | | [ ] |

### 3. New Features to Document

```
┌─────────────────────────────────────────────────────────────────┐
│  Features Added by TUI Dashboard Consistency                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. ViewToolDetail for table selection                          │
│     - Status box with version, method, location                 │
│     - Install/Reinstall/Uninstall actions                       │
│                                                                 │
│  2. BatchPreview for batch operations                           │
│     - Preview before Update All                                 │
│     - Preview before Install All Missing                        │
│                                                                 │
│  3. Consistent ESC navigation                                   │
│     - ESC always returns to parent view                         │
│     - Cancel returns to origin view                             │
│                                                                 │
│  4. Claude Config Installer in Extras                           │
│     - ViewInstaller with status box                             │
│     - Progress display during installation                      │
│                                                                 │
│  5. SpecKit Updater in Extras                                   │
│     - Project tracking and synchronization                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Verification Steps

1. **Check README.md**:
   ```bash
   grep -A5 "TUI\|start.sh\|installer" README.md
   ```

2. **Check quickstart in specs**:
   ```bash
   cat specs/008-tui-dashboard-consistency/quickstart.md 2>/dev/null
   ```

3. **Check guides**:
   ```bash
   ls .claude/instructions-for-agents/guides/
   ```

4. **Update documentation** with:
   - ViewToolDetail navigation flow
   - BatchPreview behavior
   - ESC key consistency
   - New Extras menu items

## Sample Documentation Update

```markdown
## TUI Navigation Guide

### Dashboard
- Select tools from the table to see details (ViewToolDetail)
- Navigate menu items: Ghostty, Feh, Nerd Fonts, Extras, Boot Diagnostics

### ViewToolDetail
When selecting a tool from the Dashboard table:
- View status, version, and location information
- Actions: Install, Reinstall, Uninstall, Back
- Press ESC to return to Dashboard

### Extras Menu
- **Update All**: Preview tools to update → Proceed or Cancel
- **Install All Missing**: Preview missing tools → Proceed or Cancel
- **Claude Config Installer**: Setup Claude Code configuration
- **SpecKit Updater**: Manage SpecKit project synchronization

### Key Bindings
- ↑↓: Navigate
- Enter: Select
- ESC: Return to parent view
- q: Quit TUI
```

## What You Should See

### PASS if you see:
- [ ] README.md includes accurate TUI section
- [ ] Launch instructions are correct (`./start.sh`)
- [ ] New features are documented
- [ ] Navigation flow is explained
- [ ] Key bindings are listed

### FAIL if you see:
- Outdated navigation instructions
- Missing features in documentation
- Incorrect launch commands
- No mention of ViewToolDetail or BatchPreview

## How to Close This Issue

After documentation is updated:
```bash
gh issue close 114 --comment "Verified: Quickstart documentation updated. Includes ViewToolDetail navigation, BatchPreview behavior, ESC consistency, and Extras menu items (Claude Config Installer, SpecKit Updater)."
```
