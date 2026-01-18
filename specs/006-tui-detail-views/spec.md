# Feature Specification: TUI Detail Views

**Feature Branch**: `006-tui-detail-views`
**Created**: 2026-01-18
**Status**: Draft
**Input**: Restructure Go TUI (tui/internal/ui/) to use Nerd Fonts-style detail views. PROBLEMS: (1) Extras header cut off, (2) Main dashboard too crowded with 5 tools, (3) Extras shows 7 tools in one table. SOLUTION: (1) Move Ghostty and Feh from main table to dedicated menu items with ViewToolDetail, (2) Keep only Node.js, AI Tools, Antigravity in main table, (3) Convert Extras from table to navigation menu where each tool gets ViewToolDetail.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Individual Tool Details (Priority: P1)

As a user, I want to select a tool from the menu and see its complete status information on a dedicated detail view, so I can understand the tool's installation status, version, and available actions without visual clutter.

**Why this priority**: This is the core UX improvement. Without the detail view component, no other restructuring can happen. The reusable ViewToolDetail component enables all subsequent changes.

**Independent Test**: Can be fully tested by navigating to any tool's detail view and verifying all status information is visible with clear header, and actions work correctly.

**Acceptance Scenarios**:

1. **Given** the user is on the main dashboard, **When** they select "Ghostty" menu item, **Then** they see a dedicated detail view showing Ghostty's status, version, latest version, method, and location with all content visible without scrolling
2. **Given** the user is viewing a tool's detail view, **When** they press Escape or select "Back", **Then** they return to the previous menu
3. **Given** the user is viewing a tool's detail view, **When** they select an action (Install/Update/Reinstall/Uninstall), **Then** the appropriate operation is executed with visual feedback

---

### User Story 2 - Simplified Main Dashboard (Priority: P2)

As a user, I want the main dashboard to display only 3 tools in its status table (Node.js, AI Tools, Antigravity) with Ghostty and Feh accessible as dedicated menu items, so the dashboard fits on screen and is easy to scan.

**Why this priority**: Reduces visual clutter on the main screen. Depends on P1 (ViewToolDetail component) being available.

**Independent Test**: Can be tested by launching the TUI and verifying the main table shows exactly 3 tools, and Ghostty/Feh are accessible via menu navigation.

**Acceptance Scenarios**:

1. **Given** the TUI starts, **When** the main dashboard loads, **Then** the status table shows only Node.js, Local AI Tools, and Google Antigravity
2. **Given** the main dashboard is displayed, **When** the user views the menu, **Then** "Ghostty" and "Feh" appear as separate menu items (not in the table)
3. **Given** the main dashboard is displayed, **When** the user selects "Ghostty" or "Feh" from the menu, **Then** they navigate to the respective ViewToolDetail view

---

### User Story 3 - Menu-Based Extras Navigation (Priority: P3)

As a user, I want the Extras section to show a navigation menu instead of a crowded table, so I can easily find and manage each of the 7 extra tools without the header being cut off.

**Why this priority**: Fixes the header cut-off issue and improves extras navigation. Depends on P1 (ViewToolDetail) and mirrors the approach from P2.

**Independent Test**: Can be tested by navigating to Extras and verifying each tool (Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH) appears as a menu item that leads to its detail view.

**Acceptance Scenarios**:

1. **Given** the user navigates to Extras, **When** the Extras view loads, **Then** they see a clean header "Extras Tools" followed by a menu of 7 tools plus action items
2. **Given** the user is in Extras view, **When** they select any tool (e.g., "Fastfetch"), **Then** they navigate to ViewToolDetail for that tool
3. **Given** the user is in Extras view, **When** viewing the screen, **Then** the header is fully visible (not cut off)

---

### Edge Cases

- What happens when a tool's status check is still loading? The detail view shows a loading spinner with "Loading..." status
- How does the system handle tools with no uninstall script? The "Uninstall" action is disabled/hidden for that tool
- What happens when navigating back from a deep view (Extras → Tool Detail → Back)? User returns to Extras, not main dashboard
- How does the system handle window resize while viewing a tool detail? The view reflows appropriately

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: TUI MUST provide a reusable ViewToolDetail component that displays a single tool's complete status information (status, version, latest version, method, location)
- **FR-002**: ViewToolDetail MUST show the tool name and description as a visible header at the top of the view
- **FR-003**: ViewToolDetail MUST provide an action menu with Install/Update, Reinstall, Uninstall, and Back options (Configure for ZSH only)
- **FR-004**: Main dashboard MUST display exactly 3 tools in its status table: Node.js, Local AI Tools, Google Antigravity
- **FR-005**: Main dashboard menu MUST include Ghostty and Feh as separate navigation items at the top of the menu (before Update All), leading to ViewToolDetail
- **FR-006**: Extras view MUST replace its 7-tool table with a navigation menu listing tools in alphabetical order: Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH
- **FR-007**: Each tool in Extras menu MUST navigate to ViewToolDetail when selected
- **FR-008**: Navigation MUST support going back from ViewToolDetail to the originating view (main dashboard or extras)
- **FR-009**: All views MUST display their headers completely without clipping or scrolling
- **FR-010**: The Nerd Fonts view (ViewNerdFonts) MUST remain unchanged as it already uses the target pattern

### Key Entities

- **Tool**: Represents an installable tool with ID, display name, description, status, version, latest version, installation method, location, and associated scripts (check, install, uninstall, update, configure)
- **View State**: Represents the current navigation state including view type, selected tool, and return destination
- **Tool Status**: Contains runtime status information for a tool including installation state, current version, update availability

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All tool detail views display complete headers without clipping (0% of header text truncated)
- **SC-002**: Main dashboard table shows exactly 3 tools, not 5
- **SC-003**: Extras view displays as a navigation menu with 7 items, not a 7-row table
- **SC-004**: Users can navigate from main dashboard to any tool's detail view in 2 or fewer selections
- **SC-005**: Users can navigate from Extras to any extra tool's detail view in 2 selections (Extras → Tool)
- **SC-006**: Navigation back (Escape key or Back menu item) returns user to correct parent view 100% of the time
- **SC-007**: TUI compiles without errors after all changes (`go build` succeeds)
- **SC-008**: All existing functionality (install, uninstall, update, refresh) continues to work through the new navigation structure

## Clarifications

### Session 2026-01-18

- Q: Where should Ghostty and Feh menu items be positioned in main dashboard menu? → A: Top of menu (before Update All) - emphasizes primary tools
- Q: What ordering should be used for the 7 tools in Extras menu? → A: Alphabetical order (Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH)

## Assumptions

- The existing nerdfonts.go implementation provides a suitable pattern to follow for ViewToolDetail
- Tool registry already contains all necessary metadata (scripts, display names) for each tool
- The current view state management in model.go can be extended to support ViewToolDetail
- Users prefer focused single-tool views over dense multi-tool tables for detailed operations
