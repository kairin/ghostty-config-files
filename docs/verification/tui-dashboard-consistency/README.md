# TUI Dashboard Consistency - Verification Guide Index

**Feature**: TUI Dashboard Consistency
**Spec**: `specs/008-tui-dashboard-consistency/`
**Total Issues**: 16 open issues requiring manual verification

## Quick Start

```bash
# Launch TUI for testing
./start.sh
```

## Verification Documents

### Epic 1: Dashboard Table Selection (Issues #81-84)

| Issue | Task | Document | Description |
|-------|------|----------|-------------|
| [#81](https://github.com/kairin/ghostty-config-files/issues/81) | T017 | [issue-081-nodejs-detail.md](issue-081-nodejs-detail.md) | Node.js table selection → ViewToolDetail |
| [#82](https://github.com/kairin/ghostty-config-files/issues/82) | T018 | [issue-082-aitools-detail.md](issue-082-aitools-detail.md) | AI Tools table selection → ViewToolDetail |
| [#83](https://github.com/kairin/ghostty-config-files/issues/83) | T019 | [issue-083-antigravity-detail.md](issue-083-antigravity-detail.md) | Antigravity table selection → ViewToolDetail |
| [#84](https://github.com/kairin/ghostty-config-files/issues/84) | T020 | [issue-084-esc-returns-dashboard.md](issue-084-esc-returns-dashboard.md) | ESC from detail → Dashboard |

### Epic 2: Extras Menu Batch Operations (Issues #92-94)

| Issue | Task | Document | Description |
|-------|------|----------|-------------|
| [#92](https://github.com/kairin/ghostty-config-files/issues/92) | T028 | [issue-092-update-all-preview.md](issue-092-update-all-preview.md) | Update All → BatchPreview |
| [#93](https://github.com/kairin/ghostty-config-files/issues/93) | T029 | [issue-093-extras-install-preview.md](issue-093-extras-install-preview.md) | Install All Missing → BatchPreview |
| [#94](https://github.com/kairin/ghostty-config-files/issues/94) | T030 | [issue-094-cancel-returns-origin.md](issue-094-cancel-returns-origin.md) | Cancel returns to Extras |

### Epic 3: Claude Config Installer (Issues #100-102)

| Issue | Task | Document | Description |
|-------|------|----------|-------------|
| [#100](https://github.com/kairin/ghostty-config-files/issues/100) | T036 | [issue-100-claude-config-installer.md](issue-100-claude-config-installer.md) | Claude Config → ViewInstaller |
| [#101](https://github.com/kairin/ghostty-config-files/issues/101) | T037 | [issue-101-progress-displays.md](issue-101-progress-displays.md) | Progress visible in TUI |
| [#102](https://github.com/kairin/ghostty-config-files/issues/102) | T038 | [issue-102-esc-returns-extras.md](issue-102-esc-returns-extras.md) | ESC after complete → Extras |

### Epic 4: Nerd Fonts Batch Install (Issues #107-109)

| Issue | Task | Document | Description |
|-------|------|----------|-------------|
| [#107](https://github.com/kairin/ghostty-config-files/issues/107) | T043 | [issue-107-nerdfonts-install-preview.md](issue-107-nerdfonts-install-preview.md) | Install All → Preview |
| [#108](https://github.com/kairin/ghostty-config-files/issues/108) | T044 | [issue-108-preview-missing-only.md](issue-108-preview-missing-only.md) | Preview shows only missing fonts |
| [#109](https://github.com/kairin/ghostty-config-files/issues/109) | T045 | [issue-109-cancel-returns-nerdfonts.md](issue-109-cancel-returns-nerdfonts.md) | Cancel → ViewNerdFonts |

### Epic 5: Code Cleanup & Documentation (Issues #110, #113, #114)

| Issue | Task | Document | Description |
|-------|------|----------|-------------|
| [#110](https://github.com/kairin/ghostty-config-files/issues/110) | T046 | [issue-110-remove-viewappmenu.md](issue-110-remove-viewappmenu.md) | Remove deprecated ViewAppMenu code |
| [#113](https://github.com/kairin/ghostty-config-files/issues/113) | T049 | [issue-113-verify-all-26-items.md](issue-113-verify-all-26-items.md) | Full navigation audit (26 items) |
| [#114](https://github.com/kairin/ghostty-config-files/issues/114) | T050 | [issue-114-update-quickstart.md](issue-114-update-quickstart.md) | Update quickstart documentation |

## Verification Progress

- [ ] #81 - Node.js table selection
- [ ] #82 - AI Tools table selection
- [ ] #83 - Antigravity table selection
- [ ] #84 - ESC returns to Dashboard
- [ ] #92 - Update All preview
- [ ] #93 - Install All Missing preview
- [ ] #94 - Cancel returns to Extras
- [ ] #100 - Claude Config installer
- [ ] #101 - Progress displays
- [ ] #102 - ESC returns to Extras
- [ ] #107 - Nerd Fonts Install All preview
- [ ] #108 - Preview shows only missing
- [ ] #109 - Cancel returns to Nerd Fonts
- [ ] #110 - Remove ViewAppMenu code
- [ ] #113 - Verify all 26 navigation items
- [ ] #114 - Update quickstart docs

## ASCII Diagram Legend

```
┌─────────────────────────────────────────────────────┐
│  Box-drawing characters used in diagrams            │
├─────────────────────────────────────────────────────┤
│  >  = Cursor/selected item                          │
│  ✓  = Installed/success                             │
│  ✗  = Missing/failed                                │
│  ↑↓ = Navigation keys                               │
│  ←  = Indicates change or action                    │
└─────────────────────────────────────────────────────┘
```

## Closing Issues

After verifying each issue, close it with the `gh` CLI:

```bash
gh issue close <number> --comment "Verified: <description of what was verified>"
```
