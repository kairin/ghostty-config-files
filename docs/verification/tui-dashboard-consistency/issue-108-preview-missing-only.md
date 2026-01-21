# Verification: Issue #108 - Preview Shows Only Missing Fonts

**Issue**: [#108](https://github.com/kairin/ghostty-config-files/issues/108)
**Task**: T044
**Feature**: TUI Dashboard Consistency
**Priority**: P2 Enhancement

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters
- Some fonts installed, some missing (mixed state)
- Completed verification of issue #107

## Starting State (Nerd Fonts with Mixed Status)

Navigate to Dashboard → Nerd Fonts with mixed installation status:

```
┌─────────────────────────────────────────────────────────────────┐
│  Nerd Fonts                                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  FONT                   STATUS                                  │
│  ─────────────────────────────────────────────────────────────  │
│    JetBrainsMono        ✓ Installed                             │  ← Already installed
│    FiraCode             ✗ Missing                               │  ← NOT installed
│    Hack                 ✗ Missing                               │  ← NOT installed
│    CascadiaCode         ✓ Installed                             │  ← Already installed
│                                                                 │
│  Options:                                                       │
│  > Install All Missing                                          │
│    Back                                                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## Steps

1. Launch TUI with `./start.sh`
2. Navigate to **Nerd Fonts**
3. Note which fonts are installed (✓) and which are missing (✗)
4. Select **Install All Missing**
5. Press **Enter**
6. Verify the preview list

## Expected Result (Preview Shows ONLY Missing Fonts)

```
┌─────────────────────────────────────────────────────────────────┐
│  Nerd Fonts - Install Preview                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  The following fonts will be installed:                         │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  FONT                    SIZE (approx)                    │  │
│  │  ───────────────────────────────────────────────────────  │  │
│  │  FiraCode Nerd Font      ~15 MB                           │  │  ← Missing font
│  │  Hack Nerd Font          ~12 MB                           │  │  ← Missing font
│  │                                                           │  │
│  │  (JetBrainsMono and CascadiaCode already installed)       │  │  ← NOT in list
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Total: 2 fonts to install                                      │
│                                                                 │
│  > Proceed with Install                                         │
│    Cancel                                                       │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc cancel                       │
└─────────────────────────────────────────────────────────────────┘
```

## What You Should See

### PASS if you see:
- [ ] Preview list contains ONLY missing fonts (FiraCode, Hack)
- [ ] Already installed fonts (JetBrainsMono, CascadiaCode) NOT in preview list
- [ ] Count matches number of missing fonts only
- [ ] No duplicate entries

### FAIL if you see:
- Already installed fonts appear in the preview list
- All fonts listed regardless of installation status
- Count includes already installed fonts
- Incorrect or confusing display of font status

## Verification Checklist

Compare the Nerd Fonts main screen (with status) to the preview:

| Font | Main Screen Status | In Preview? |
|------|-------------------|-------------|
| JetBrainsMono | ✓ Installed | Should be NO |
| FiraCode | ✗ Missing | Should be YES |
| Hack | ✗ Missing | Should be YES |
| CascadiaCode | ✓ Installed | Should be NO |

## How to Close This Issue

After verification passes:
```bash
gh issue close 108 --comment "Verified: Nerd Fonts Install Preview shows ONLY missing fonts. Already installed fonts (JetBrainsMono, CascadiaCode) correctly excluded from preview list."
```
