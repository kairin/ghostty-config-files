# Verification: Issue #107 - Nerd Fonts Install All Shows Preview

**Issue**: [#107](https://github.com/kairin/ghostty-config-files/issues/107)
**Task**: T043
**Feature**: TUI Dashboard Consistency
**Priority**: P2 Enhancement

## Prerequisites

- TUI builds successfully: `./start.sh`
- Terminal at least 80x24 characters
- At least one Nerd Font is not installed

## Starting State (Nerd Fonts Menu)

Navigate to Dashboard → Nerd Fonts:

```
┌─────────────────────────────────────────────────────────────────┐
│  Nerd Fonts                                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  FONT                   STATUS                                  │
│  ─────────────────────────────────────────────────────────────  │
│    JetBrainsMono        ✓ Installed                             │
│    FiraCode             ✗ Missing                               │
│    Hack                 ✗ Missing                               │
│    CascadiaCode         ✓ Installed                             │
│                                                                 │
│  Options:                                                       │
│  > Install All Missing                                          │  ← Cursor here
│    Back                                                         │
│                                                                 │
│                                                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate • enter select • esc back                         │
└─────────────────────────────────────────────────────────────────┘
```

## Steps

1. Launch TUI with `./start.sh`
2. Navigate to **Nerd Fonts** from Dashboard menu
3. Select **Install All Missing** (or similar batch install option)
4. Press **Enter**

## Expected Result (BatchPreview for Fonts)

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
│  │  FiraCode Nerd Font      ~15 MB                           │  │
│  │  Hack Nerd Font          ~12 MB                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Total: 2 fonts (~27 MB download)                               │
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
- [ ] Header shows "Install Preview" or similar for fonts
- [ ] List of fonts that will be installed
- [ ] Size information for each font (optional but helpful)
- [ ] "Proceed with Install" and "Cancel" options
- [ ] Total count of fonts to install

### FAIL if you see:
- Installation starts immediately without preview
- No list of fonts to be installed shown
- TUI crashes or shows error
- Returns to previous menu without showing preview

## Notes

If all fonts are already installed, the preview should indicate "All fonts are already installed" or similar message.

## How to Close This Issue

After verification passes:
```bash
gh issue close 107 --comment "Verified: Nerd Fonts Install All shows preview with list of fonts to install, size info, and Proceed/Cancel options."
```
