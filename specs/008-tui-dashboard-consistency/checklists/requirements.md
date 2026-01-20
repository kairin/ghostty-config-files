# TUI Dashboard Consistency - Requirements Checklist

## Functional Requirements Verification

### FR-001: Table Tools Navigate to ViewToolDetail
- [ ] Node.js (nvm) selection → ViewToolDetail
- [ ] Local AI Tools selection → ViewToolDetail
- [ ] Google Antigravity selection → ViewToolDetail
- [ ] ViewToolDetail shows correct status info
- [ ] Actions work from ViewToolDetail

### FR-002: ViewAppMenu Deprecated
- [ ] ViewAppMenu removed from View enum
- [ ] viewAppMenu() function removed
- [ ] handleAppMenuEnter() function removed
- [ ] No code references ViewAppMenu

### FR-003: Update All Shows Preview
- [ ] "Update All" → ViewBatchPreview (not ViewInstaller)
- [ ] Preview lists tools with versions
- [ ] Cancel returns to Dashboard
- [ ] Confirm triggers batch update

### FR-004: Install All (Extras) Shows Preview
- [ ] "Install All" in Extras → ViewBatchPreview
- [ ] Preview distinguishes installed vs missing
- [ ] Cancel returns to Extras
- [ ] Confirm triggers batch install

### FR-005: Install All (Nerd Fonts) Shows Preview
- [ ] "Install All" in Nerd Fonts → ViewBatchPreview
- [ ] Preview lists fonts with status
- [ ] Cancel returns to Nerd Fonts
- [ ] Confirm triggers batch install

### FR-006: Install Claude Config Uses ViewInstaller
- [ ] Claude Config registered as tool
- [ ] Selection triggers ViewInstaller
- [ ] Progress displayed in TUI
- [ ] TUI does not exit during operation

### FR-007: Preview Screens Have Confirm/Cancel
- [ ] ViewBatchPreview has Cancel button
- [ ] ViewBatchPreview has Confirm button
- [ ] Keyboard navigation works
- [ ] ESC triggers Cancel

### FR-008: Visual Feedback for All Operations
- [ ] No operation starts without intermediate screen
- [ ] All operations show progress
- [ ] Success/failure displayed in TUI

### FR-009: Consistent Navigation Flow
- [ ] Dashboard → Detail → Action → Progress → Result
- [ ] Pattern consistent across all tools
- [ ] Back navigation correct at each step

### FR-010: Keyboard Shortcuts Work
- [ ] 'r' refreshes status (Dashboard, Extras, etc.)
- [ ] 'u' triggers Update All (with preview)
- [ ] ESC goes back at all levels
- [ ] Arrow keys navigate menus

---

## Non-Functional Requirements Verification

### NFR-001: No Immediate Execution
- [ ] "Update All" shows preview first
- [ ] "Install All" (Extras) shows preview first
- [ ] "Install All" (Nerd Fonts) shows preview first
- [ ] No batch operation starts without confirmation

### NFR-002: Cancel Before Execution
- [ ] Preview screens have Cancel option
- [ ] Cancel returns to previous view
- [ ] No partial work done on Cancel

### NFR-003: Responsive Transitions
- [ ] View transitions feel instant
- [ ] No visible lag between screens
- [ ] Spinner shown during loading

---

## Success Criteria Verification

### SC-001: 100% Tools Through ViewToolDetail
- [ ] 3 table tools use ViewToolDetail
- [ ] 2 menu tools use ViewToolDetail
- [ ] 7 extras tools use ViewToolDetail
- [ ] Total: 12/12 (100%)

### SC-002: 100% Batch Operations Show Preview
- [ ] Update All shows preview
- [ ] Install All (Extras) shows preview
- [ ] Install All (Nerd Fonts) shows preview
- [ ] Total: 3/3 (100%)

### SC-003: 0 Unexpected TUI Exits
- [ ] Install Claude Config stays in TUI
- [ ] Only sudo auth uses tea.ExecProcess
- [ ] No other tea.ExecProcess for user ops

### SC-004: 26 Menu Items Documented
- [ ] All items in screens.md
- [ ] Navigation targets documented
- [ ] Expected behavior documented

### SC-005: ViewAppMenu Usage = 0
- [ ] No code uses ViewAppMenu
- [ ] Enum value removed
- [ ] Related functions removed

### SC-006: Preview Cancel Works
- [ ] Update All preview → Cancel → Dashboard
- [ ] Install All (Extras) preview → Cancel → Extras
- [ ] Install All (Nerd Fonts) preview → Cancel → Nerd Fonts

### SC-007: Code Compiles
- [ ] `go build ./...` succeeds
- [ ] No compile errors
- [ ] No warnings

---

## Complete Menu Item Verification

### Dashboard Table (3 items)
| Item | ViewToolDetail? | Actions Work? |
|------|-----------------|---------------|
| Node.js (nvm) | [ ] | [ ] |
| Local AI Tools | [ ] | [ ] |
| Google Antigravity | [ ] | [ ] |

### Dashboard Menu (7 items)
| Item | Correct Navigation? |
|------|---------------------|
| Ghostty | [ ] ViewToolDetail |
| Feh | [ ] ViewToolDetail |
| Update All | [ ] ViewBatchPreview |
| Nerd Fonts | [ ] ViewNerdFonts |
| Extras | [ ] ViewExtras |
| Boot Diagnostics | [ ] ViewDiagnostics |
| Exit | [ ] Quit |

### Extras Menu (11 items)
| Item | Correct Navigation? |
|------|---------------------|
| Fastfetch | [ ] ViewToolDetail |
| Glow | [ ] ViewToolDetail |
| Go | [ ] ViewToolDetail |
| Gum | [ ] ViewToolDetail |
| Python/uv | [ ] ViewToolDetail |
| VHS | [ ] ViewToolDetail |
| ZSH | [ ] ViewToolDetail |
| Install All | [ ] ViewBatchPreview |
| Install Claude Config | [ ] ViewInstaller |
| MCP Servers | [ ] ViewMCPServers |
| Back | [ ] ViewDashboard |

### Nerd Fonts Menu (3 items)
| Item | Correct Navigation? |
|------|---------------------|
| Font families (8) | [ ] Action menu → ViewInstaller |
| Install All | [ ] ViewBatchPreview |
| Back | [ ] ViewDashboard |

### MCP Servers Menu (3 items)
| Item | Correct Navigation? |
|------|---------------------|
| Servers (7) | [ ] Action menu |
| Setup Secrets | [ ] ViewSecretsWizard |
| Back | [ ] ViewExtras |

---

## Final Verification

- [ ] All functional requirements met
- [ ] All non-functional requirements met
- [ ] All success criteria met
- [ ] All 26 menu items verified
- [ ] Code compiles and tests pass
- [ ] Documentation updated
- [ ] Manual testing complete
