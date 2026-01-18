# Feature Specification: Wave 2 - TUI Features

**Feature Branch**: `003-tui-features`
**Created**: 2026-01-18
**Status**: Draft
**Input**: User description: "Wave 2: TUI Features - (1) Per-family Nerd Font selection, (2) TUI MCP Server Management, (3) MCP prerequisites detection, (4) MCP server registry, (5) Secrets template setup wizard"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Per-Family Nerd Font Selection (Priority: P1)

Users want to install individual Nerd Font families instead of all 8 at once. Currently, the TUI shows all 8 font families as rows but only supports "Install All" - selecting an individual font does nothing.

**Why this priority**: Fastest to implement (2 hr), no dependencies, immediate user value. Existing UI shows per-font rows - just needs install action wired up.

**Independent Test**: Navigate to Dashboard → Nerd Fonts → Select "JetBrainsMono" → Press Enter → Font installs individually. User can verify by checking `~/.local/share/fonts/NerdFonts/JetBrainsMono*`.

**Acceptance Scenarios**:

1. **Given** user is on Nerd Fonts view, **When** they select a specific font family (e.g., FiraCode), **Then** only that font family is installed
2. **Given** user has some fonts installed, **When** they view the Nerd Fonts menu, **Then** each font shows its individual installed/not-installed status
3. **Given** user selects "Install All", **When** installation completes, **Then** all 8 font families are installed (existing behavior preserved)
4. **Given** user selects an already-installed font, **When** they press Enter, **Then** they see options to reinstall or uninstall

---

### User Story 2 - TUI MCP Server Management (Priority: P2)

Users want to manage MCP servers through the TUI instead of running CLI commands manually. This adds an "MCP Servers" category under the Extras menu showing all 7 servers with their connection status.

**Why this priority**: Core feature that enables the remaining MCP stories (P3-P5). Must be implemented before prerequisites detection or registry.

**Independent Test**: Navigate to Dashboard → Extras → MCP Servers → View shows 7 servers with status (Connected/Disconnected). User can select a server and see install/remove options.

**Acceptance Scenarios**:

1. **Given** user opens Extras menu, **When** they see the menu items, **Then** "MCP Servers" appears as a new category
2. **Given** user selects MCP Servers, **When** the view loads, **Then** all 7 servers are listed with connection status
3. **Given** a server shows "Disconnected", **When** user selects it and chooses "Install", **Then** the server is added via `claude mcp add`
4. **Given** a server shows "Connected", **When** user selects it and chooses "Remove", **Then** the server is removed via `claude mcp remove`
5. **Given** user installs a server, **When** installation completes, **Then** status refreshes to show "Connected"

---

### User Story 3 - MCP Prerequisites Detection (Priority: P3)

Before installing an MCP server, users need to know if prerequisites are missing. Each MCP server has different requirements (Node.js, Python UV, GitHub CLI, API keys).

**Why this priority**: Depends on P2 (MCP view must exist). Prevents failed installations due to missing dependencies.

**Independent Test**: Navigate to MCP Servers → Select "playwright" → View shows prerequisites check: ✓ Node.js, ✓ fnm, ✗ AppArmor fix (if Ubuntu 23.10+). User sees what's missing before attempting install.

**Acceptance Scenarios**:

1. **Given** user views an MCP server, **When** the detail view loads, **Then** prerequisites are shown with pass/fail status
2. **Given** a prerequisite is missing, **When** user tries to install, **Then** they see which prerequisites need to be installed first
3. **Given** all prerequisites pass, **When** user initiates install, **Then** installation proceeds normally
4. **Given** GitHub MCP selected, **When** prerequisites checked, **Then** system verifies `gh auth status` passes
5. **Given** Context7 MCP selected, **When** prerequisites checked, **Then** system verifies `CONTEXT7_API_KEY` is set

---

### User Story 4 - MCP Server Registry (Priority: P4)

The TUI needs a data-driven registry of all 7 MCP servers with their configuration details, similar to how tools are defined in `registry/registry.go`.

**Why this priority**: Depends on P2 for UI context. Provides the data model for P3 (prerequisites) and P5 (secrets wizard).

**Independent Test**: MCP registry can be queried programmatically to get server details. Adding a new MCP server requires only adding an entry to the registry (no code changes elsewhere).

**Acceptance Scenarios**:

1. **Given** the MCP registry exists, **When** queried for a server, **Then** it returns name, command, transport type, prerequisites list
2. **Given** a new MCP server needs adding, **When** developer adds registry entry, **Then** it appears in TUI automatically
3. **Given** registry entry for "context7", **When** queried, **Then** returns HTTP transport, Context7 API key requirement
4. **Given** registry entry for "playwright", **When** queried, **Then** returns stdio transport, Node.js + AppArmor prerequisites

---

### User Story 5 - Secrets Template Setup Wizard (Priority: P5)

Users need a guided wizard to set up their `~/.mcp-secrets` file with required API keys. The wizard should detect existing secrets and only prompt for missing ones.

**Why this priority**: Depends on P3 (prerequisites) and P4 (registry). Enables complete self-service MCP setup.

**Independent Test**: Run wizard → Detects no `~/.mcp-secrets` → Prompts for Context7 key → Prompts for HuggingFace token → Creates file with correct format. If file exists, only prompts for missing keys.

**Acceptance Scenarios**:

1. **Given** user has no `~/.mcp-secrets`, **When** they access secrets wizard, **Then** wizard creates file with all required keys
2. **Given** user has partial secrets file, **When** wizard runs, **Then** only missing keys are prompted
3. **Given** user enters API key, **When** they confirm, **Then** key is saved to `~/.mcp-secrets` with correct export syntax
4. **Given** secrets file is created, **When** user starts new shell, **Then** secrets are available as environment variables
5. **Given** user declines to enter a key, **When** wizard completes, **Then** that key is left as placeholder with instructions

---

### Edge Cases

- What happens when `claude mcp add` fails (network error, invalid key)?
  - Show error message, offer retry, preserve existing configuration
- How does system handle Ubuntu 23.10+ AppArmor restriction for Playwright?
  - Prerequisites check detects AppArmor setting, shows fix command before install
- What if user has existing `~/.mcp-secrets` with different format?
  - Parse existing file, preserve unknown entries, add missing keys
- What if `claude mcp list` command format changes?
  - Use structured JSON output (`--json` flag if available), fallback to text parsing

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: TUI MUST support individual Nerd Font family installation (not just "Install All")
- **FR-002**: TUI MUST display MCP Servers as a category under Extras menu
- **FR-003**: TUI MUST show connection status for each MCP server (Connected/Disconnected)
- **FR-004**: TUI MUST check prerequisites before MCP server installation
- **FR-005**: TUI MUST provide MCP server registry with configuration data for all 7 servers
- **FR-006**: TUI MUST provide secrets wizard to create/update `~/.mcp-secrets`
- **FR-007**: System MUST run `claude mcp add` with correct arguments for each server type
- **FR-008**: System MUST support both HTTP and stdio transport types for MCP servers
- **FR-009**: System MUST preserve existing MCP server configurations when adding new ones
- **FR-010**: System MUST validate API keys are set before attempting installation (for servers requiring them)

### Key Entities

- **MCPServer**: Server ID, display name, transport type (http/stdio), command/URL, prerequisites list, secrets required
- **Prerequisite**: Type (tool/env/system), check command, fix instructions
- **Secret**: Key name, description, env variable name, optional validation regex

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can install individual Nerd Font families in under 30 seconds each
- **SC-002**: All 7 MCP servers visible in TUI with accurate connection status
- **SC-003**: Prerequisites check completes in under 5 seconds per server
- **SC-004**: 100% of MCP server installations succeed when prerequisites pass
- **SC-005**: Secrets wizard creates valid `~/.mcp-secrets` file that loads correctly in new shell sessions
- **SC-006**: Zero manual CLI commands required for complete MCP setup (all via TUI)

## Assumptions

- Claude Code CLI (`claude`) is installed and in PATH
- User has permissions to create/modify files in `~/.local/share/fonts/` and `~/.mcp-secrets`
- MCP server packages are available via npm/uvx as documented
- GitHub CLI authentication persists between sessions
- The existing 5-stage pipeline pattern in TUI is appropriate for MCP server installation
