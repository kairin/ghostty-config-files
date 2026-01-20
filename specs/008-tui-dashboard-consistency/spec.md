# Feature Specification: TUI Dashboard Consistency

**Feature Branch**: `008-tui-dashboard-consistency`
**Created**: 2026-01-20
**Status**: Draft
**Input**: Ensure all TUI menu items show appropriate dashboard/status screens before executing actions. Currently some items execute immediately without user feedback, causing confusion.

## Problem Statement

The TUI currently has inconsistent navigation patterns:
1. **Table tools** (nodejs, ai_tools, antigravity) skip the detail view and go directly to action menu
2. **Batch operations** ("Install All", "Update All") execute immediately without preview
3. **Install Claude Config** exits the TUI entirely using `tea.ExecProcess`
4. Users cannot understand what is happening during some operations

## Current TUI ViewStates (12 States)

| State | Name | Purpose |
|-------|------|---------|
| 0 | ViewDashboard | Main menu with tool table and navigation |
| 1 | ViewExtras | Extras tools menu (7 tools + actions) |
| 2 | ViewNerdFonts | Nerd Fonts management (8 font families) |
| 3 | ViewMCPServers | MCP Servers management (7 servers) |
| 4 | ViewMCPPrereq | MCP prerequisites checklist |
| 5 | ViewSecretsWizard | MCP secrets configuration wizard |
| 6 | ViewAppMenu | Per-tool action menu (legacy) |
| 7 | ViewMethodSelect | Installation method selector (Ghostty) |
| 8 | ViewInstaller | Installation/uninstall progress view |
| 9 | ViewDiagnostics | Boot diagnostics dashboard |
| 10 | ViewConfirm | Confirmation dialog |
| 11 | ViewToolDetail | Single tool detail dashboard |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Tool Navigation (Priority: P1)

As a user, I want all tools (table and menu) to navigate through ViewToolDetail before showing actions, so I have a consistent experience and understand what I'm about to do.

**Why this priority**: This inconsistency is the most confusing for users. Table tools skip directly to action menu while menu tools show detail views.

**Independent Test**: Select nodejs from the table and verify it shows ViewToolDetail before actions. Compare to selecting Ghostty from menu.

**Acceptance Scenarios**:

1. **Given** the user is on the main dashboard, **When** they select "Node.js (nvm)" from the table, **Then** they see ViewToolDetail with status info and action menu
2. **Given** the user is on the main dashboard, **When** they select "Local AI Tools" from the table, **Then** they see ViewToolDetail with status info and action menu
3. **Given** ViewToolDetail is shown for a table tool, **When** user selects an action, **Then** the appropriate operation starts

---

### User Story 2 - Batch Operation Preview (Priority: P2)

As a user, I want to see a preview of what will be updated/installed before batch operations execute, so I can confirm the list of tools before proceeding.

**Why this priority**: Users currently have no visibility into what "Update All" or "Install All" will do until execution starts.

**Independent Test**: Select "Update All" and verify a preview screen shows which tools will be updated before starting.

**Acceptance Scenarios**:

1. **Given** updates are available, **When** user selects "Update All", **Then** they see a preview screen listing tools to be updated
2. **Given** the preview screen is shown, **When** user confirms, **Then** batch installation starts
3. **Given** the preview screen is shown, **When** user presses Escape, **Then** they return to dashboard without action

---

### User Story 3 - Claude Config In-TUI Progress (Priority: P1)

As a user, I want "Install Claude Config" to show progress within the TUI instead of exiting to terminal, so I maintain context and see what happened.

**Why this priority**: Current implementation uses `tea.ExecProcess` which suspends the TUI, confusing users who suddenly see terminal output.

**Independent Test**: Select "Install Claude Config" from Extras and verify progress is shown in a TUI view.

**Acceptance Scenarios**:

1. **Given** user is in Extras view, **When** they select "Install Claude Config", **Then** they see ViewInstaller progress view
2. **Given** Claude Config is installing, **When** the operation completes, **Then** success/failure is shown in TUI
3. **Given** Claude Config installation is complete, **When** user presses Escape, **Then** they return to Extras view

---

### User Story 4 - Nerd Fonts Install All Preview (Priority: P2)

As a user, I want to see which fonts will be installed before "Install All" executes in Nerd Fonts, so I can confirm the list.

**Why this priority**: Currently "Install All" starts immediately without showing which fonts are missing.

**Independent Test**: From Nerd Fonts with some fonts missing, select "Install All" and verify preview is shown.

**Acceptance Scenarios**:

1. **Given** some Nerd Fonts are missing, **When** user selects "Install All", **Then** they see preview of fonts to be installed
2. **Given** the preview is shown, **When** user confirms, **Then** batch installation starts
3. **Given** all fonts are installed, **When** user views menu, **Then** "Install All" is not shown

---

### Edge Cases

- What if no updates are available when "Update All" is selected? → Show message "All tools are up to date" and return to dashboard
- What if all Extras tools are installed when "Install All" is selected? → Execute reinstall for all (current behavior)
- What happens if MCP server installation fails? → Show error in MCP Servers view with option to retry
- What if user cancels during batch operation? → Cancel current tool, offer resume or abort remaining

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Table tools (nodejs, ai_tools, antigravity) MUST navigate to ViewToolDetail before showing actions
- **FR-002**: ViewAppMenu MUST be deprecated in favor of ViewToolDetail for all tools
- **FR-003**: "Update All" MUST show a ViewBatchPreview screen listing tools to be updated
- **FR-004**: "Install All" (Extras) MUST show a ViewBatchPreview screen listing tools to be installed
- **FR-005**: "Install All" (Nerd Fonts) MUST show preview of fonts to be installed
- **FR-006**: "Install Claude Config" MUST execute within TUI using ViewInstaller pattern
- **FR-007**: All batch preview screens MUST include Confirm/Cancel actions
- **FR-008**: All operations MUST provide visual feedback within the TUI
- **FR-009**: Navigation flow MUST be consistent: Dashboard → Detail → Action → Progress → Result
- **FR-010**: Existing keyboard shortcuts (r for refresh, esc for back) MUST continue to work

### Non-Functional Requirements

- **NFR-001**: No operation should start without at least one intermediate screen showing what will happen
- **NFR-002**: Users should be able to cancel any operation before it begins
- **NFR-003**: Screen transitions should feel responsive (<100ms)

### Key Entities

- **ViewBatchPreview**: New view state for batch operation previews
- **ViewUpdatePreview**: New view state specifically for "Update All" preview
- **BatchItem**: Represents a single item in a batch operation (tool or font)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of tool selections (table and menu) go through ViewToolDetail
- **SC-002**: 100% of batch operations show preview before execution
- **SC-003**: 0 operations exit the TUI unexpectedly (no tea.ExecProcess for user operations)
- **SC-004**: All 26 menu items have documented expected dashboard flow
- **SC-005**: ViewAppMenu usage reduced to 0 (fully replaced by ViewToolDetail)
- **SC-006**: Users can cancel any operation from preview screens
- **SC-007**: TUI compiles without errors after changes (`go build` succeeds)

## Clarifications

### Session 2026-01-20

- Q: Should batch previews show estimated time? → A: No, focus on what will be done, not how long
- Q: Can users skip preview screens? → A: No, preview is mandatory for batch operations
- Q: Should ViewBatchPreview use table or list format? → A: List format with status icons

## Assumptions

- The existing ViewToolDetail component can be reused for table tools
- Adding new ViewStates (ViewBatchPreview, ViewUpdatePreview) is straightforward
- The executor package can provide progress for Claude Config installation
- Users prefer explicit confirmation over immediate execution for batch operations

## Implementation Notes

### Files to Modify

| File | Changes |
|------|---------|
| `tui/internal/ui/model.go` | Add ViewBatchPreview, ViewUpdatePreview states; route table tools through ViewToolDetail |
| `tui/internal/ui/extras.go` | Change Install Claude Config to use ViewInstaller; add batch preview for Install All |
| `tui/internal/ui/nerdfonts.go` | Add batch preview for Install All |
| `tui/internal/ui/batchpreview.go` | New file - BatchPreviewModel component |
| `tui/internal/ui/updatepreview.go` | New file - UpdatePreviewModel component |

### Migration Path

1. Create ViewBatchPreview and ViewUpdatePreview components
2. Route table tools through ViewToolDetail (single change in handleEnter)
3. Add preview for "Update All"
4. Add preview for "Install All" (Extras and Nerd Fonts)
5. Convert Install Claude Config to ViewInstaller pattern
6. Remove ViewAppMenu usage (cleanup)
