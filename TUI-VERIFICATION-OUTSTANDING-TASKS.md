# TUI Dashboard Consistency - Outstanding Verification Tasks

> **AUTHORITATIVE SOURCE**: This document tracks 16 outstanding GitHub issues that require manual verification before the TUI Dashboard Consistency feature can be considered complete.

**Last Updated**: 2026-01-21
**Spec**: `specs/008-tui-dashboard-consistency/`
**Repository**: [kairin/ghostty-config-files](https://github.com/kairin/ghostty-config-files)
**Status**: 16 OPEN ISSUES PENDING VERIFICATION

---

## Outstanding Issues Summary

| # | Issue | Title | Type | Priority | Verification Doc |
|---|-------|-------|------|----------|------------------|
| 1 | [#81](https://github.com/kairin/ghostty-config-files/issues/81) | Node.js table selection → ViewToolDetail | Manual Test | P1 MVP | [issue-081](docs/verification/tui-dashboard-consistency/issue-081-nodejs-detail.md) |
| 2 | [#82](https://github.com/kairin/ghostty-config-files/issues/82) | AI Tools table selection → ViewToolDetail | Manual Test | P1 MVP | [issue-082](docs/verification/tui-dashboard-consistency/issue-082-aitools-detail.md) |
| 3 | [#83](https://github.com/kairin/ghostty-config-files/issues/83) | Antigravity table selection → ViewToolDetail | Manual Test | P1 MVP | [issue-083](docs/verification/tui-dashboard-consistency/issue-083-antigravity-detail.md) |
| 4 | [#84](https://github.com/kairin/ghostty-config-files/issues/84) | ESC from ViewToolDetail returns to Dashboard | Manual Test | P1 MVP | [issue-084](docs/verification/tui-dashboard-consistency/issue-084-esc-returns-dashboard.md) |
| 5 | [#92](https://github.com/kairin/ghostty-config-files/issues/92) | Update All shows BatchPreview | Manual Test | P1 MVP | [issue-092](docs/verification/tui-dashboard-consistency/issue-092-update-all-preview.md) |
| 6 | [#93](https://github.com/kairin/ghostty-config-files/issues/93) | Extras Install All shows BatchPreview | Manual Test | P1 MVP | [issue-093](docs/verification/tui-dashboard-consistency/issue-093-extras-install-preview.md) |
| 7 | [#94](https://github.com/kairin/ghostty-config-files/issues/94) | Cancel returns to Extras | Manual Test | P1 MVP | [issue-094](docs/verification/tui-dashboard-consistency/issue-094-cancel-returns-origin.md) |
| 8 | [#100](https://github.com/kairin/ghostty-config-files/issues/100) | Claude Config shows ViewInstaller | Manual Test | P2 Enhancement | [issue-100](docs/verification/tui-dashboard-consistency/issue-100-claude-config-installer.md) |
| 9 | [#101](https://github.com/kairin/ghostty-config-files/issues/101) | Progress displays during installation | Manual Test | P2 Enhancement | [issue-101](docs/verification/tui-dashboard-consistency/issue-101-progress-displays.md) |
| 10 | [#102](https://github.com/kairin/ghostty-config-files/issues/102) | ESC after completion returns to Extras | Manual Test | P2 Enhancement | [issue-102](docs/verification/tui-dashboard-consistency/issue-102-esc-returns-extras.md) |
| 11 | [#107](https://github.com/kairin/ghostty-config-files/issues/107) | Nerd Fonts Install All shows Preview | Manual Test | P2 Enhancement | [issue-107](docs/verification/tui-dashboard-consistency/issue-107-nerdfonts-install-preview.md) |
| 12 | [#108](https://github.com/kairin/ghostty-config-files/issues/108) | Preview shows only missing fonts | Manual Test | P2 Enhancement | [issue-108](docs/verification/tui-dashboard-consistency/issue-108-preview-missing-only.md) |
| 13 | [#109](https://github.com/kairin/ghostty-config-files/issues/109) | Cancel returns to ViewNerdFonts | Manual Test | P2 Enhancement | [issue-109](docs/verification/tui-dashboard-consistency/issue-109-cancel-returns-nerdfonts.md) |
| 14 | [#110](https://github.com/kairin/ghostty-config-files/issues/110) | Remove deprecated ViewAppMenu code | Code Cleanup | P3 Polish | [issue-110](docs/verification/tui-dashboard-consistency/issue-110-remove-viewappmenu.md) |
| 15 | [#113](https://github.com/kairin/ghostty-config-files/issues/113) | Verify all 26 navigation items | Audit | P3 Polish | [issue-113](docs/verification/tui-dashboard-consistency/issue-113-verify-all-26-items.md) |
| 16 | [#114](https://github.com/kairin/ghostty-config-files/issues/114) | Update quickstart documentation | Documentation | P3 Polish | [issue-114](docs/verification/tui-dashboard-consistency/issue-114-update-quickstart.md) |

---

## Quick Verification Status Check

Run this command to verify outstanding issues:

```bash
gh issue list --repo kairin/ghostty-config-files --label "tui-dashboard-consistency" --state open
```

Or view directly at:
**https://github.com/kairin/ghostty-config-files/issues?q=is%3Aopen+label%3Atui-dashboard-consistency**

---

## How to Verify and Close Issues

### Step 1: Launch TUI
```bash
./start.sh
```

### Step 2: Follow Verification Document
Each issue has a detailed verification document with:
- ASCII diagrams showing expected "before" and "after" states
- Step-by-step instructions
- PASS/FAIL criteria checklists

**Verification Documents Location**: `docs/verification/tui-dashboard-consistency/`

### Step 3: Close Issue After Verification
```bash
gh issue close <NUMBER> --comment "Verified: <description>"
```

**Example**:
```bash
gh issue close 81 --comment "Verified: Node.js table selection shows ViewToolDetail with status box (Version: 22.12.0, Method: nvm). Actions menu shows Install/Reinstall/Uninstall/Back."
```

---

## Issues by Epic

### Epic 1: Dashboard Table Selection (4 issues)
**Issues**: [#81](https://github.com/kairin/ghostty-config-files/issues/81), [#82](https://github.com/kairin/ghostty-config-files/issues/82), [#83](https://github.com/kairin/ghostty-config-files/issues/83), [#84](https://github.com/kairin/ghostty-config-files/issues/84)

**Goal**: When selecting tools from the Dashboard table, show ViewToolDetail (not old ViewAppMenu).

| Issue | What to Test | Expected |
|-------|--------------|----------|
| #81 | Select Node.js from table | ViewToolDetail with status box |
| #82 | Select AI Tools from table | ViewToolDetail with status box |
| #83 | Select Antigravity from table | ViewToolDetail with status box |
| #84 | Press ESC from detail view | Return to Dashboard |

### Epic 2: Extras Menu Batch Operations (3 issues)
**Issues**: [#92](https://github.com/kairin/ghostty-config-files/issues/92), [#93](https://github.com/kairin/ghostty-config-files/issues/93), [#94](https://github.com/kairin/ghostty-config-files/issues/94)

**Goal**: Batch operations show preview before executing.

| Issue | What to Test | Expected |
|-------|--------------|----------|
| #92 | Select "Update All" | BatchPreview with tools to update |
| #93 | Select "Install All Missing" | BatchPreview with missing tools |
| #94 | Cancel from preview | Return to Extras menu |

### Epic 3: Claude Config Installer (3 issues)
**Issues**: [#100](https://github.com/kairin/ghostty-config-files/issues/100), [#101](https://github.com/kairin/ghostty-config-files/issues/101), [#102](https://github.com/kairin/ghostty-config-files/issues/102)

**Goal**: Claude Config installation shows progress within TUI.

| Issue | What to Test | Expected |
|-------|--------------|----------|
| #100 | Select "Claude Config Installer" | ViewInstaller with status box |
| #101 | During installation | Progress indicator visible |
| #102 | Press ESC after completion | Return to Extras menu |

### Epic 4: Nerd Fonts Batch Install (3 issues)
**Issues**: [#107](https://github.com/kairin/ghostty-config-files/issues/107), [#108](https://github.com/kairin/ghostty-config-files/issues/108), [#109](https://github.com/kairin/ghostty-config-files/issues/109)

**Goal**: Nerd Fonts batch install shows preview with only missing fonts.

| Issue | What to Test | Expected |
|-------|--------------|----------|
| #107 | Select "Install All" | Preview with fonts to install |
| #108 | Check preview list | Only missing fonts shown |
| #109 | Cancel from preview | Return to ViewNerdFonts |

### Epic 5: Code Cleanup & Documentation (3 issues)
**Issues**: [#110](https://github.com/kairin/ghostty-config-files/issues/110), [#113](https://github.com/kairin/ghostty-config-files/issues/113), [#114](https://github.com/kairin/ghostty-config-files/issues/114)

**Goal**: Clean up deprecated code and update documentation.

| Issue | What to Do | Expected |
|-------|------------|----------|
| #110 | Remove ViewAppMenu code | No references in active code |
| #113 | Audit all 26 navigation items | All items work correctly |
| #114 | Update quickstart docs | Docs match current behavior |

---

## Detailed Verification Guides

All issues have individual verification documents with ASCII diagrams:

```
docs/verification/tui-dashboard-consistency/
├── README.md                           # Index of all verification docs
├── issue-081-nodejs-detail.md          # #81 verification guide
├── issue-082-aitools-detail.md         # #82 verification guide
├── issue-083-antigravity-detail.md     # #83 verification guide
├── issue-084-esc-returns-dashboard.md  # #84 verification guide
├── issue-092-update-all-preview.md     # #92 verification guide
├── issue-093-extras-install-preview.md # #93 verification guide
├── issue-094-cancel-returns-origin.md  # #94 verification guide
├── issue-100-claude-config-installer.md# #100 verification guide
├── issue-101-progress-displays.md      # #101 verification guide
├── issue-102-esc-returns-extras.md     # #102 verification guide
├── issue-107-nerdfonts-install-preview.md # #107 verification guide
├── issue-108-preview-missing-only.md   # #108 verification guide
├── issue-109-cancel-returns-nerdfonts.md # #109 verification guide
├── issue-110-remove-viewappmenu.md     # #110 code review guide
├── issue-113-verify-all-26-items.md    # #113 audit checklist
└── issue-114-update-quickstart.md      # #114 documentation guide
```

---

## Batch Close After All Pass

**Only run after manually verifying ALL tests pass:**

```bash
#!/bin/bash
# Close all TUI dashboard consistency issues

# Manual test issues
for issue in 81 82 83 84 92 93 94 100 101 102 107 108 109; do
  gh issue close $issue --comment "Verified: Manual testing confirmed expected behavior per verification document."
done

# Code cleanup issues (close after completing the work)
# gh issue close 110 --comment "Completed: ViewAppMenu code removed."
# gh issue close 113 --comment "Completed: All 26 navigation items verified."
# gh issue close 114 --comment "Completed: Quickstart documentation updated."
```

---

## Related Resources

- **Feature Spec**: `specs/008-tui-dashboard-consistency/`
- **Verification Index**: `docs/verification/tui-dashboard-consistency/README.md`
- **TUI Source Code**: `tui/internal/ui/`
- **GitHub Issues**: https://github.com/kairin/ghostty-config-files/issues

---

## Troubleshooting

### TUI won't start
```bash
./start.sh
```
The canonical entry point handles all setup. If Go is missing, it will guide you.

### How to check if issues exist
```bash
gh issue list --state open --label "tui-dashboard-consistency"
```

### How to view a specific issue
```bash
gh issue view 81
```

---

**This document serves as undeniable proof of the 16 outstanding tasks for the TUI Dashboard Consistency feature. Each task has a corresponding GitHub issue that can be independently verified.**
