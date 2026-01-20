# TUI Dashboard Consistency - Manual Verification Guide

**Date**: 2026-01-20
**Spec**: `specs/008-tui-dashboard-consistency/`
**Open Issues**: 16 verification tests

This guide provides step-by-step instructions to manually verify all TUI dashboard consistency changes.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [How to Launch the TUI](#how-to-launch-the-tui)
3. [Test 1: Dashboard Navigation (Issues #81-84)](#test-1-dashboard-navigation-issues-81-84)
4. [Test 2: Batch Preview - Update All (Issue #92)](#test-2-batch-preview---update-all-issue-92)
5. [Test 3: Batch Preview - Extras Install All (Issues #93-94)](#test-3-batch-preview---extras-install-all-issues-93-94)
6. [Test 4: Claude Config In-TUI (Issues #100-102)](#test-4-claude-config-in-tui-issues-100-102)
7. [Test 5: Nerd Fonts Preview (Issues #107-109)](#test-5-nerd-fonts-preview-issues-107-109)
8. [Test 6: Code Cleanup Tasks (Issues #110, #113, #114)](#test-6-code-cleanup-tasks-issues-110-113-114)
9. [Results Recording](#results-recording)
10. [Quick Reference: All 16 Issues](#quick-reference-all-16-issues)

---

## Prerequisites

### Required Software
- Go 1.23+ installed (verified automatically by `./start.sh`)
- Terminal with at least 80x24 characters
- Git repository cloned

### Verify Environment

The `./start.sh` script handles all build and dependency verification automatically. Simply run:

```bash
./start.sh
```

If Go is not installed or other dependencies are missing, the script will provide guidance.

### Verify Current Branch
```bash
git branch --show-current
```
**Expected**: `20260119-012457-feat-mcp-server-dashboard` or `main` (after merge)

---

## How to Launch the TUI

### Canonical Entry Point

```bash
./start.sh
```

**Design Principle**: `./start.sh` is the **single point of entry** for this application. All TUI operations should be launched through this script, which handles:
- Environment setup and validation
- Dependency checks
- TUI initialization
- Proper working directory context

**Why not direct TUI commands?**
The commands `go run ./cmd/installer` and `./tui/ghostty-installer` are internal implementation details. Using `./start.sh` ensures:
- Consistent behavior across environments
- Proper path resolution
- Future-proof if internal structure changes

### TUI Controls Reference
| Key | Action |
|-----|--------|
| `↑` / `k` | Move cursor up |
| `↓` / `j` | Move cursor down |
| `←` / `h` | Move left (in buttons) |
| `→` / `l` | Move right (in buttons) |
| `Enter` | Select / Confirm |
| `Esc` | Back / Cancel |
| `q` | Quit TUI |
| `r` | Refresh status |
| `u` | Update All (from dashboard) |

---

## Test 1: Dashboard Navigation (Issues #81-84)

**Goal**: Verify that selecting tools from the **table** navigates to `ViewToolDetail` (not the old `ViewAppMenu`).

### Issue #81: Verify nodejs table selection shows ViewToolDetail

**Steps**:
1. Launch TUI
2. You should see the main dashboard with a table showing:
   ```
   | APP                    STATUS         VERSION      LATEST    |
   |--------------------------------------------------------------|
   | Node.js (nvm)          * Installed    22.x.x       22.x.x    |
   | Local AI Tools         ...            ...          ...       |
   | Google Antigravity     ...            ...          ...       |
   ```
3. Use `↓` to highlight **Node.js (nvm)** row (if not already highlighted)
4. Press `Enter`

**Expected Result**:
```
+------------------------------------------------------------------+
|  Node.js (nvm) - Details                                         |
|  [description text]                                              |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  |  Status:      * Installed                                    |
|  |  Version:     22.x.x                                         |
|  |  Latest:      22.x.x                                         |
|  |  Method:      nvm                                            |
|  |  Location:    ~/.nvm/versions/node/...                       |
|  +--------------------------------------------------------------+
|                                                                  |
|  Actions:                                                        |
|  > Install                                                       |
|    Reinstall                                                     |
|    Uninstall                                                     |
|    Back                                                          |
```

**PASS Criteria**:
- [ ] Screen shows "Node.js (nvm) - Details" header
- [ ] Status box shows Version, Latest, Method, Location
- [ ] Actions menu shows Install/Reinstall/Uninstall/Back
- [ ] This is NOT a simple menu with just action buttons (that would be old ViewAppMenu)

**FAIL Criteria**:
- Screen shows only action buttons without status details
- Screen looks different from Ghostty's detail view

---

### Issue #82: Verify ai_tools table selection shows ViewToolDetail

**Steps**:
1. From main dashboard (press `Esc` if in detail view)
2. Use `↓` to highlight **Local AI Tools** row
3. Press `Enter`

**Expected Result**:
- Same layout as Node.js detail view
- Header shows "Local AI Tools - Details"
- Status box shows current status (Installed/Missing/Update available)
- Actions menu present

**PASS Criteria**:
- [ ] Screen shows "Local AI Tools - Details" header
- [ ] Status box with Version/Latest/Method/Location
- [ ] Actions menu shows appropriate options

---

### Issue #83: Verify antigravity table selection shows ViewToolDetail

**Steps**:
1. From main dashboard (press `Esc` if in detail view)
2. Use `↓` to highlight **Google Antigravity** row
3. Press `Enter`

**Expected Result**:
- Same layout as other detail views
- Header shows "Google Antigravity - Details"
- Status likely shows "x Missing" since this is a joke tool

**PASS Criteria**:
- [ ] Screen shows "Google Antigravity - Details" header
- [ ] Status box present (even if showing Missing)
- [ ] Actions menu shows Install/Back (since not installed)

---

### Issue #84: Verify ESC from ViewToolDetail returns to Dashboard

**Steps**:
1. From any tool detail view (nodejs, ai_tools, or antigravity)
2. Press `Esc`

**Expected Result**:
- Returns to main dashboard
- Table is visible again
- Same tool row is highlighted (cursor preserved)

**PASS Criteria**:
- [ ] Dashboard is displayed after pressing Esc
- [ ] Table with 3 tools visible
- [ ] Menu items (Ghostty, Feh, Update All, etc.) visible below table

---

## Test 2: Batch Preview - Update All (Issue #92)

**Goal**: Verify that "Update All" shows a preview screen before executing.

### Issue #92: Verify "Update All" shows preview

**Prerequisites**: At least one tool must have an update available. If all tools are up-to-date, this test may not show the preview (it may do nothing or show "No updates available").

**Steps**:
1. From main dashboard
2. Use `↓` to navigate to the menu section below the table
3. Select **Update All (N)** where N is the number of updates
4. Press `Enter`

**Expected Result** (if updates available):
```
+------------------------------------------------------------------+
|  Update 2 Tools                                                  |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  |  ↑ Local AI Tools (1.2.3 → 1.3.0)                            |
|  |  ↑ Fastfetch (2.31.0 → 2.32.0)                               |
|  +--------------------------------------------------------------+
|                                                                  |
|  [Confirm]    [Cancel]                                           |
|                                                                  |
+------------------------------------------------------------------+
|  ↑↓←→ navigate • enter select • esc cancel                       |
+------------------------------------------------------------------+
```

**Alternative Result** (if no updates):
- Nothing happens, or a message appears saying no updates available
- This is acceptable behavior

**PASS Criteria**:
- [ ] If updates exist: Preview screen appears listing tools to update
- [ ] Preview shows version numbers (current → new)
- [ ] Confirm and Cancel buttons are visible
- [ ] Pressing Cancel returns to dashboard without updating

**How to Test Cancel**:
1. If preview appears, use `→` or `l` to highlight Cancel
2. Press `Enter`
3. Should return to dashboard without any updates happening

---

## Test 3: Batch Preview - Extras Install All (Issues #93-94)

**Goal**: Verify that "Install All" in Extras menu shows preview before executing.

### Issue #93: Verify "Install All" (Extras) shows preview

**Steps**:
1. From main dashboard
2. Navigate down to **Extras** menu item
3. Press `Enter` to enter Extras menu
4. You should see:
   ```
   Extras Tools - 7 Additional Tools

   Choose:
   > Fastfetch
     Glow
     Go
     Gum
     Python/uv
     VHS
     ZSH
     ----------------------------------------
     Install All
     Install Claude Config
     MCP Servers
     Back
   ```
5. Navigate to **Install All**
6. Press `Enter`

**Expected Result**:
```
+------------------------------------------------------------------+
|  Install N Tools                                                 |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  |  ✗ Fastfetch                                                 |
|  |  ✗ Go                                                        |
|  |  ✗ Gum                                                       |
|  |  (tools not yet installed listed here)                       |
|  +--------------------------------------------------------------+
|                                                                  |
|  [Confirm]    [Cancel]                                           |
|                                                                  |
+------------------------------------------------------------------+
```

**PASS Criteria**:
- [ ] Preview screen appears (not immediate installation)
- [ ] Shows list of tools that will be installed
- [ ] Only shows tools not yet installed (skips installed ones)
- [ ] Confirm and Cancel buttons visible

---

### Issue #94: Verify Cancel returns to origin view

**Steps**:
1. From the Install All preview screen (above)
2. Use `→` to highlight **Cancel** button
3. Press `Enter`

**Expected Result**:
- Returns to **Extras** menu (not main dashboard)
- Cursor on same position

**Alternative**: Press `Esc` should also cancel and return to Extras

**PASS Criteria**:
- [ ] Cancel button returns to Extras menu
- [ ] Esc key returns to Extras menu
- [ ] No installation was started

---

## Test 4: Claude Config In-TUI (Issues #100-102)

**Goal**: Verify that "Install Claude Config" shows progress within TUI instead of exiting to terminal.

### Issue #100: Verify "Install Claude Config" shows ViewInstaller

**Steps**:
1. From main dashboard, go to **Extras**
2. Navigate to **Install Claude Config**
3. Press `Enter`

**Expected Result**:
```
+------------------------------------------------------------------+
|  * Installing Claude Config                                      |
+------------------------------------------------------------------+
|                                                                  |
|  Stage 1/5: Checking...  (elapsed: 2s)                           |
|                                                                  |
|  +--------------------------------------------------------------+
|  | Installing Claude skills to ~/.claude/commands/...           |
|  | Installing Claude agents to ~/.claude/agents/...             |
|  | ...                                                          |
|  +--------------------------------------------------------------+
|                                                                  |
|  [##########............................] (1/5)                  |
|                                                                  |
+------------------------------------------------------------------+
```

**FAIL Criteria**:
- TUI exits completely
- Terminal shows raw script output
- You see your shell prompt during installation

**PASS Criteria**:
- [ ] TUI stays visible throughout installation
- [ ] Progress indicator visible (stage counter or progress bar)
- [ ] Script output shown in a scrollable area within TUI

---

### Issue #101: Verify installation progress displays in TUI

**Steps**:
1. Continue from above - watch the installation progress

**Expected Result**:
- Live output from the installation script appears
- Progress bar or stage indicator updates
- Text scrolls if output is long

**PASS Criteria**:
- [ ] Output text updates in real-time
- [ ] Can see messages like "Installing...", "Copying files...", etc.
- [ ] Stage/progress indicator changes during installation

---

### Issue #102: Verify ESC returns to Extras after completion

**Steps**:
1. Wait for installation to complete
2. Screen should show completion message:
   ```
   * Installation complete!

   [ESC] Back to Extras
   ```
3. Press `Esc`

**Expected Result**:
- Returns to **Extras** menu (not main dashboard)
- Can navigate normally

**PASS Criteria**:
- [ ] After completion, pressing Esc returns to Extras
- [ ] Extras menu is fully functional after returning

---

## Test 5: Nerd Fonts Preview (Issues #107-109)

**Goal**: Verify that "Install All" in Nerd Fonts shows preview of fonts to install.

### Issue #107: Verify "Install All" (Nerd Fonts) shows preview

**Steps**:
1. From main dashboard, navigate to **Nerd Fonts**
2. Press `Enter`
3. You should see font table:
   ```
   | FONT FAMILY          STATUS         VERSION      |
   |--------------------------------------------------|
   | JetBrainsMono        * Installed    3.3.0        |
   | FiraCode             x Missing      -            |
   | Hack                 x Missing      -            |
   | ...                                              |
   ```
4. Navigate to **Install All (N missing)**
5. Press `Enter`

**Expected Result**:
```
+------------------------------------------------------------------+
|  Install N Fonts                                                 |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  |  ✗ FiraCode                                                  |
|  |  ✗ Hack                                                      |
|  |  ✗ Meslo                                                     |
|  |  (only missing fonts listed)                                 |
|  +--------------------------------------------------------------+
|                                                                  |
|  [Confirm]    [Cancel]                                           |
|                                                                  |
+------------------------------------------------------------------+
```

**PASS Criteria**:
- [ ] Preview screen appears (not immediate installation)
- [ ] Shows font names that will be installed

---

### Issue #108: Verify preview lists only missing fonts, not all fonts

**Steps**:
1. Look at the preview list from above

**Expected Result**:
- Only fonts with "Missing" status are shown
- Fonts already installed (e.g., JetBrainsMono if installed) are NOT in the list

**PASS Criteria**:
- [ ] Installed fonts are NOT listed in preview
- [ ] Only missing fonts are shown
- [ ] Count matches number of missing fonts

---

### Issue #109: Verify Cancel returns to ViewNerdFonts

**Steps**:
1. From the font preview screen
2. Select **Cancel** or press `Esc`

**Expected Result**:
- Returns to Nerd Fonts management screen
- Font table is visible again

**PASS Criteria**:
- [ ] Cancel returns to Nerd Fonts view
- [ ] Font table with all 8 families visible

---

## Test 6: Code Cleanup Tasks (Issues #110, #113, #114)

These are not runtime tests but code/documentation tasks.

### Issue #110: Remove unused ViewAppMenu code

**Task**: After all navigation tests pass, remove the old `ViewAppMenu` code from `tui/internal/ui/model.go`.

**Verification**:
```bash
grep -n "ViewAppMenu" tui/internal/ui/model.go
```

**PASS Criteria**:
- [ ] ViewAppMenu constant removed or marked deprecated
- [ ] No active code paths use ViewAppMenu for table tools
- [ ] Build still succeeds after removal

**Note**: Only do this after confirming all tools use ViewToolDetail.

---

### Issue #113: Manual verification of all 26 menu items

**Task**: Navigate through every menu item in the TUI to verify functionality.

**Checklist**:

**Main Dashboard (7 items)**:
- [ ] Node.js (table) → ViewToolDetail
- [ ] AI Tools (table) → ViewToolDetail
- [ ] Antigravity (table) → ViewToolDetail
- [ ] Ghostty (menu) → ViewToolDetail
- [ ] Feh (menu) → ViewToolDetail
- [ ] Update All → Preview or "no updates"
- [ ] Nerd Fonts → ViewNerdFonts

**Extras (11 items)**:
- [ ] Fastfetch → ViewToolDetail
- [ ] Glow → ViewToolDetail
- [ ] Go → ViewToolDetail
- [ ] Gum → ViewToolDetail
- [ ] Python/uv → ViewToolDetail
- [ ] VHS → ViewToolDetail
- [ ] ZSH → ViewToolDetail
- [ ] Install All → Preview
- [ ] Install Claude Config → ViewInstaller (in-TUI)
- [ ] MCP Servers → ViewMCPServers
- [ ] Back → Dashboard

**Nerd Fonts (8 fonts + 2 actions)**:
- [ ] JetBrainsMono → Action menu
- [ ] FiraCode → Action menu
- [ ] Hack → Action menu
- [ ] Meslo → Action menu
- [ ] CascadiaCode → Action menu
- [ ] SourceCodePro → Action menu
- [ ] IBMPlexMono → Action menu
- [ ] Iosevka → Action menu
- [ ] Install All → Preview
- [ ] Back → Dashboard

---

### Issue #114: Update quickstart.md verification steps

**Task**: Review and update `specs/008-tui-dashboard-consistency/quickstart.md` to reflect actual implementation.

**Verification**:
- [ ] Code snippets match actual implementation
- [ ] File paths are correct
- [ ] Step numbers are accurate
- [ ] Verification commands work

---

## Results Recording

### How to Close a Verified Issue

```bash
# Replace NUMBER with issue number (81, 82, etc.)
# Replace RESULT with what you observed

gh issue close NUMBER --comment "Verified: RESULT"
```

**Example**:
```bash
gh issue close 81 --comment "Verified: nodejs table selection correctly shows ViewToolDetail with status box showing Version 22.12.0, Method nvm, Location ~/.nvm/versions/node/v22.12.0. Actions menu displays Install/Reinstall/Uninstall/Back."
```

### How to Report a Failure

If a test fails, do NOT close the issue. Instead, add a comment:

```bash
gh issue comment NUMBER --body "FAILED: Description of what went wrong

Expected: [what should happen]
Actual: [what happened]
Steps to reproduce: [numbered steps]"
```

---

## Quick Reference: All 16 Issues

| Issue | Test | Expected Behavior |
|-------|------|-------------------|
| #81 | nodejs → ViewToolDetail | Detail view with status box |
| #82 | ai_tools → ViewToolDetail | Detail view with status box |
| #83 | antigravity → ViewToolDetail | Detail view with status box |
| #84 | Esc from detail → Dashboard | Returns to main dashboard |
| #92 | Update All → Preview | Shows tools to update with versions |
| #93 | Extras Install All → Preview | Shows tools to install |
| #94 | Cancel → origin view | Returns to Extras (not dashboard) |
| #100 | Claude Config → ViewInstaller | Progress shown in TUI |
| #101 | Progress displays | Live output visible |
| #102 | Esc after complete → Extras | Returns to Extras menu |
| #107 | Nerd Fonts Install All → Preview | Shows fonts to install |
| #108 | Preview lists missing only | No installed fonts in list |
| #109 | Cancel → ViewNerdFonts | Returns to font management |
| #110 | Remove ViewAppMenu code | Code cleanup task |
| #113 | Verify all 26 items | Navigation audit |
| #114 | Update quickstart.md | Documentation task |

---

## Batch Close Script (After All Pass)

If all tests pass, you can close all issues at once:

```bash
#!/bin/bash
# Only run this after manually verifying ALL tests pass

for issue in 81 82 83 84 92 93 94 100 101 102 107 108 109; do
  gh issue close $issue --comment "Verified: Manual testing confirmed expected behavior."
done

# Code cleanup issues need separate handling
echo "Don't forget to complete and close: #110, #113, #114"
```

---

## Troubleshooting

### TUI won't start

First, ensure you're using the canonical entry point:
```bash
./start.sh
```

If issues persist, verify Go is installed:
```bash
go version  # Should show 1.23+
```

### TUI crashes
Check for nil pointer errors by running with verbose output:
```bash
./start.sh 2>&1 | tee tui-output.log
```

### Can't find an option
- Use `↓`/`↑` to scroll through long menus
- Some options are below the visible area
- Press `q` to quit and restart if stuck

### Screen looks wrong
- Ensure terminal is at least 80 columns wide
- Try maximizing terminal window
- Check for font rendering issues

---

**Last Updated**: 2026-01-20
**Related Spec**: `specs/008-tui-dashboard-consistency/`
**GitHub Issues**: #81-84, #92-94, #100-102, #107-109, #110, #113, #114
