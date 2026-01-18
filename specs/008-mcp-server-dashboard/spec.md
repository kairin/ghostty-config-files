# Feature Specification: Claude Config Dashboards (MCP Servers + Skills)

**Feature Branch**: `008-mcp-server-dashboard`
**Created**: 2026-01-18
**Status**: Draft
**Input**: User description: "TUI dashboard for installing claude config with status checking and server management similar to existing tool dashboard pattern"

**Scope**: Two dashboards for Claude Code configuration management:
1. **MCP Servers Dashboard** - Manage MCP server connections in `~/.claude.json`
2. **Skills Dashboard** - Manage skills/agents installation to `~/.claude/commands/` and `~/.claude/agents/`

## Clarifications

### Session 2026-01-18

- Q: What is the Claude configuration file location for MCP servers? → A: `~/.claude.json` (global mcpServers at root level)
- Q: How should the TUI handle server-specific installation prerequisites? → A: Server registry defines prerequisites; TUI prompts for required values (API keys, paths) during install
- Q: Should the feature include both MCP Servers and Skills dashboards? → A: Yes, both dashboards in same feature (MCP Servers + Skills/Agents)
- Q: How should dashboards be organized in the Extras menu? → A: Two separate entries: "MCP Servers" + "Skills & Agents" (rename current "Install Claude Config")

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View MCP Server Status Overview (Priority: P1)

As a user, I want to see a dashboard displaying all available MCP servers with their current status at a glance, so I can quickly understand which servers are installed and connected.

**Why this priority**: This is the foundational view that all other actions depend on. Users need visibility into their current MCP server state before taking any configuration actions.

**Independent Test**: Can be fully tested by launching the TUI, navigating to the MCP Servers section, and verifying all servers are listed with accurate status indicators. Delivers immediate value by providing system visibility.

**Acceptance Scenarios**:

1. **Given** the user launches the TUI and navigates to the MCP Servers menu, **When** the dashboard loads, **Then** all configured MCP servers are displayed in a tabular format showing server name, transport type, status, and description.
2. **Given** some servers are installed and connected while others are not, **When** the dashboard displays, **Then** each server shows its actual current status (Connected, Not Added, Disconnected, Error).
3. **Given** a server's status changes (e.g., connection lost), **When** the user refreshes or re-enters the dashboard, **Then** the updated status is displayed accurately.

---

### User Story 2 - Install/Add MCP Server (Priority: P2)

As a user, I want to select a server from the dashboard and install/add it to my Claude configuration, so I can enable new MCP capabilities without manually editing configuration files.

**Why this priority**: The primary action users will take after viewing status - enabling servers they want to use. This delivers core functionality for the dashboard.

**Independent Test**: Can be fully tested by selecting a "Not Added" server, choosing Install action, and verifying the server appears as "Connected" after completion.

**Acceptance Scenarios**:

1. **Given** a server is displayed with "Not Added" status, **When** the user selects it and chooses "Install", **Then** the installation process begins and shows progress feedback.
2. **Given** installation completes successfully, **When** the user returns to the dashboard, **Then** the server status updates to "Connected".
3. **Given** installation fails, **When** the process completes, **Then** an error message is displayed explaining the failure, and the server remains "Not Added".

---

### User Story 3 - Remove/Uninstall MCP Server (Priority: P3)

As a user, I want to remove a server from my Claude configuration, so I can disable servers I no longer need.

**Why this priority**: Secondary action for maintenance - users need this less frequently than installation but it's essential for complete server lifecycle management.

**Independent Test**: Can be fully tested by selecting a "Connected" server, choosing Remove action, and verifying the server shows "Not Added" after completion.

**Acceptance Scenarios**:

1. **Given** a server is displayed with "Connected" status, **When** the user selects it and chooses "Remove", **Then** a confirmation prompt appears before proceeding.
2. **Given** the user confirms removal, **When** the process completes, **Then** the server status updates to "Not Added".

---

### User Story 4 - Navigate Server Actions (Priority: P2)

As a user, I want to use keyboard navigation to browse servers and access available actions, so I can efficiently manage my configuration without using a mouse.

**Why this priority**: Usability is critical for TUI applications. Users expect standard keyboard navigation patterns.

**Independent Test**: Can be fully tested by using arrow keys to navigate between servers and pressing Enter to access actions menu.

**Acceptance Scenarios**:

1. **Given** the dashboard is displayed, **When** the user presses up/down arrows, **Then** the selection highlight moves between servers.
2. **Given** a server is selected, **When** the user presses Enter, **Then** an actions menu appears with context-appropriate options (Install for uninstalled, Remove for installed).
3. **Given** the actions menu is displayed, **When** the user presses Escape, **Then** the menu closes and returns to the dashboard.

---

### User Story 5 - View Skills/Agents Status Overview (Priority: P1)

As a user, I want to see a dashboard displaying all available skills and agents with their installation status, so I can understand which Claude Code extensions are available and installed.

**Why this priority**: The current "Install Claude Config" menu item just runs a script and returns - users have no visibility into what's installed. This dashboard provides that missing visibility.

**Independent Test**: Can be fully tested by launching the TUI, navigating to the Skills menu, and verifying all skills/agents are listed with accurate status indicators.

**Acceptance Scenarios**:

1. **Given** the user navigates to the Skills dashboard, **When** the dashboard loads, **Then** all available skills and agents are displayed showing name, type (skill/agent), and installation status.
2. **Given** some items are installed while others are not, **When** the dashboard displays, **Then** each item shows its actual status (Installed, Not Installed, Outdated).
3. **Given** a skill file exists in both project and user directories, **When** comparing versions, **Then** the dashboard indicates if the user version is outdated compared to project source.

---

### User Story 6 - Install Skills/Agents (Priority: P2)

As a user, I want to select a skill or agent and install it individually, so I can choose which extensions to enable rather than installing all at once.

**Why this priority**: Gives users granular control over their Claude Code configuration instead of the current all-or-nothing approach.

**Independent Test**: Can be fully tested by selecting an uninstalled skill, choosing Install, and verifying it appears in `~/.claude/commands/`.

**Acceptance Scenarios**:

1. **Given** a skill is displayed with "Not Installed" status, **When** the user selects it and chooses "Install", **Then** the skill file is copied to `~/.claude/commands/`.
2. **Given** an agent is displayed with "Not Installed" status, **When** the user selects it and chooses "Install", **Then** the agent file is copied to `~/.claude/agents/`.
3. **Given** installation completes successfully, **When** the user returns to the dashboard, **Then** the item status updates to "Installed".

---

### User Story 7 - Install All Skills/Agents (Priority: P2)

As a user, I want a quick way to install all skills and agents at once, so I can fully configure Claude Code in one action.

**Why this priority**: Power users want bulk installation; this preserves the existing functionality while adding the dashboard.

**Independent Test**: Can be fully tested by selecting "Install All" and verifying all items show as "Installed".

**Acceptance Scenarios**:

1. **Given** the dashboard is displayed, **When** the user selects "Install All", **Then** all skills and agents are installed with progress feedback.
2. **Given** some items are already installed, **When** "Install All" runs, **Then** existing items are updated/overwritten and new items are added.

---

### User Story 8 - Remove/Uninstall Skills (Priority: P3)

As a user, I want to remove installed skills or agents, so I can clean up extensions I no longer need.

**Why this priority**: Maintenance action needed less frequently but essential for complete lifecycle management.

**Independent Test**: Can be fully tested by selecting an installed skill, choosing Remove, and verifying it's deleted from `~/.claude/commands/`.

**Acceptance Scenarios**:

1. **Given** a skill is displayed with "Installed" status, **When** the user selects it and chooses "Remove", **Then** a confirmation prompt appears.
2. **Given** the user confirms removal, **When** the process completes, **Then** the file is deleted and status updates to "Not Installed".

---

### Edge Cases

**MCP Servers Edge Cases:**
- What happens when no MCP servers are configured in the registry? Display a helpful message indicating no servers are available with guidance on adding them.
- What happens when the Claude configuration file doesn't exist? Prompt to create it or show an error explaining the prerequisite.
- What happens when an installation is interrupted (user cancels or system error)? Roll back any partial changes and show clear status.
- What happens when a server shows "Connected" but is actually unreachable? Provide a way to verify/test connection status on demand.
- What happens when the user lacks permissions to modify the configuration file? Display a clear permission error with suggested resolution.

**Skills Dashboard Edge Cases:**
- What happens when project skill-sources or agent-sources directories don't exist? Display error with guidance to check repository structure.
- What happens when ~/.claude/commands/ or ~/.claude/agents/ don't exist? Create them automatically during installation.
- What happens when a skill file is corrupted or unreadable? Show error status for that specific item, allow others to proceed.
- What happens when user manually edits an installed skill? Show "Modified" status to indicate divergence from source.
- What happens when user lacks write permissions to ~/.claude/? Display clear permission error with suggested resolution.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a list of all available MCP servers defined in the server registry.
- **FR-002**: System MUST show each server's current status (Connected, Not Added, Disconnected, Error).
- **FR-003**: System MUST display server metadata including name, transport type, and description.
- **FR-004**: System MUST support keyboard navigation using arrow keys to select servers.
- **FR-005**: System MUST provide an actions menu when a server is selected (activated by Enter key).
- **FR-006**: System MUST offer "Install" action for servers that are not currently added.
- **FR-007**: System MUST offer "Remove" action for servers that are currently connected.
- **FR-008**: System MUST display installation/removal progress with real-time feedback.
- **FR-009**: System MUST update server status after successful installation or removal.
- **FR-010**: System MUST display error messages when operations fail with clear explanations.
- **FR-011**: System MUST support Escape key to close menus and navigate back.
- **FR-012**: System MUST show a summary count of servers (e.g., "MCP Servers - 7 Servers").
- **FR-013**: System MUST verify server connectivity status by checking if the server configuration exists and is valid.
- **FR-014**: System MUST prompt users for server-specific prerequisites (API keys, paths, environment variables) during installation as defined in the server registry.
- **FR-015**: System MUST validate user-provided prerequisite values before completing installation.

**Skills Dashboard Requirements:**
- **FR-016**: System MUST display a list of all available skills from `.claude/skill-sources/`.
- **FR-017**: System MUST display a list of all available agents from `.claude/agent-sources/`.
- **FR-018**: System MUST show each skill/agent's installation status (Installed, Not Installed, Outdated, Modified).
- **FR-019**: System MUST display item metadata including name, type (skill/agent), and description.
- **FR-020**: System MUST support keyboard navigation using arrow keys to select items.
- **FR-021**: System MUST provide an actions menu when an item is selected (Install, Remove, Update).
- **FR-022**: System MUST offer "Install" action for items that are not currently installed.
- **FR-023**: System MUST offer "Remove" action for items that are currently installed.
- **FR-024**: System MUST offer "Update" action for items that are outdated.
- **FR-025**: System MUST provide "Install All" action to install all skills and agents at once.
- **FR-026**: System MUST copy skill files to `~/.claude/commands/` during installation.
- **FR-027**: System MUST copy agent files to `~/.claude/agents/` during installation.
- **FR-028**: System MUST create target directories if they don't exist.
- **FR-029**: System MUST detect outdated status by comparing file modification times or content hashes.
- **FR-030**: System MUST show a summary count (e.g., "Skills & Agents • 5 Skills, 65 Agents").

### Key Entities

**MCP Server Entities:**
- **MCP Server**: Represents a Model Context Protocol server with properties: name, transport type (HTTP/stdio), status, description, configuration details.
- **Server Status**: The current state of a server - Connected (installed and working), Not Added (available but not configured), Disconnected (configured but not reachable), Error (configuration problem).
- **Server Registry**: Collection of all available MCP servers that can be installed/managed through the dashboard, including each server's prerequisites (required API keys, npm packages, paths, environment variables).
- **Claude Configuration**: The configuration file (`~/.claude.json`) where MCP server settings are stored at the root `mcpServers` key.

**Skills Dashboard Entities:**
- **Skill**: A Claude Code slash command extension (markdown file) with properties: name, description, source path, installation status. Stored in `~/.claude/commands/`.
- **Agent**: A Claude Code agent definition (markdown file) with properties: name, tier, description, source path, installation status. Stored in `~/.claude/agents/`.
- **Item Status**: The current state of a skill/agent - Installed (exists in user directory), Not Installed (only in project source), Outdated (user version differs from source), Modified (user has edited the installed file).
- **Project Sources**: The repository directories containing skill/agent definitions: `.claude/skill-sources/` (5 skills) and `.claude/agent-sources/` (65 agents).
- **User Directories**: Target installation directories: `~/.claude/commands/` for skills, `~/.claude/agents/` for agents.

## Success Criteria *(mandatory)*

### Measurable Outcomes

**MCP Servers Dashboard:**
- **SC-001**: Users can view the status of all MCP servers within 2 seconds of opening the dashboard.
- **SC-002**: Users can install a new MCP server in under 30 seconds from selection to completion.
- **SC-003**: 95% of users can successfully navigate and install a server on their first attempt without documentation.
- **SC-004**: Server status displayed in the dashboard matches actual configuration state with 100% accuracy.
- **SC-005**: All user actions (navigation, selection, installation, removal) respond within 200 milliseconds.
- **SC-006**: Users can manage all 7 currently defined MCP servers through the dashboard without needing to manually edit configuration files.

**Skills Dashboard:**
- **SC-007**: Users can view the status of all skills and agents within 2 seconds of opening the dashboard.
- **SC-008**: Users can install a single skill/agent in under 5 seconds.
- **SC-009**: "Install All" completes for all 70 items (5 skills + 65 agents) in under 10 seconds.
- **SC-010**: Skills/agents status displayed matches actual file system state with 100% accuracy.
- **SC-011**: Users can manage all skills and agents through the dashboard without using command line.
- **SC-012**: The current broken behavior (script runs and returns immediately) is replaced with persistent dashboard view.

## Assumptions

**General:**
- The existing TUI framework and patterns from the tool installation dashboard will be reused for consistency.
- Both dashboards will be accessible from the Extras menu.

**MCP Servers:**
- MCP server definitions (name, transport, description) are available in a registry similar to the tool registry.
- The Claude configuration file is located at `~/.claude.json` with global `mcpServers` at root level.
- Users have appropriate file system permissions to read/write the Claude configuration file.
- The 7 MCP servers referenced in the user's example (Context7, GitHub, MarkItDown, Playwright, HuggingFace, shadcn, shadcn-ui) represent the initial server set to support.
- Server connectivity verification is based on configuration presence rather than live connection testing (to avoid network dependencies during status display).

**Skills Dashboard:**
- The project contains skill source files in `.claude/skill-sources/` (currently 5 skills).
- The project contains agent source files in `.claude/agent-sources/` (currently 65 agents).
- Skills are installed to `~/.claude/commands/` and agents to `~/.claude/agents/`.
- File comparison for outdated status uses modification time (simpler) rather than content hash (more accurate but slower).
- The existing "Install Claude Config" menu item will be renamed to "Skills & Agents" and converted to a dashboard.
- Menu will show two separate entries: "MCP Servers" and "Skills & Agents" (not a sub-menu).
