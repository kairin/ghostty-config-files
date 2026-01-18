# Tasks: Wave 2 - TUI Features

**Input**: Design documents from `/specs/003-tui-features/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: No automated tests requested - manual verification only.

**Organization**: Tasks are grouped by user story for independent implementation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Verify existing structure and prepare for implementation

- [X] T001 Verify TUI compiles with `cd tui && go build ./cmd/installer`
- [X] T002 Review existing patterns in `tui/internal/registry/registry.go`
- [X] T003 Review existing patterns in `tui/internal/ui/extras.go`

---

## Phase 2: User Story 4 - MCP Server Registry (Priority: P4 - Foundation)

**Goal**: Create data-driven registry for all 7 MCP servers

**Independent Test**: `GetAllMCPServers()` returns 7 servers with correct configurations

### Implementation for User Story 4

- [X] T004 [US4] Create `tui/internal/registry/mcp.go` with MCPTransport type (http/stdio)
- [X] T005 [US4] Add MCPPrerequisite struct (ID, Name, CheckCmd, FixInstructions)
- [X] T006 [US4] Add MCPSecret struct (EnvVar, Name, Description, GetURL, Required)
- [X] T007 [US4] Add MCPServer struct (ID, DisplayName, Transport, URL, Command, Prerequisites, Secrets)
- [X] T008 [P] [US4] Define context7 server (HTTP, CONTEXT7_API_KEY secret)
- [X] T009 [P] [US4] Define github server (stdio, Node.js + gh auth prerequisites)
- [X] T010 [P] [US4] Define markitdown server (stdio, uvx prerequisite)
- [X] T011 [P] [US4] Define playwright server (stdio, Node.js + AppArmor prerequisites)
- [X] T012 [P] [US4] Define hf-mcp-server (HTTP, HUGGINGFACE_TOKEN secret)
- [X] T013 [P] [US4] Define shadcn server (stdio, Node.js prerequisite)
- [X] T014 [P] [US4] Define shadcn-ui server (stdio, Node.js + gh auth prerequisites)
- [X] T015 [US4] Add GetMCPServer(id) function
- [X] T016 [US4] Add GetAllMCPServers() function returning ordered slice
- [X] T017 [US4] Add MCPServerCount() function

**Checkpoint**: MCP registry ready - can query all 7 servers with their configurations

---

## Phase 3: User Story 1 - Per-Family Nerd Font Selection (Priority: P1)

**Goal**: Enable individual font family installation instead of "Install All" only

**Independent Test**: Navigate to Nerd Fonts → Select JetBrainsMono → Font installs alone

### Implementation for User Story 1

- [X] T018 [US1] Modify `scripts/004-reinstall/install_nerdfonts.sh` to accept optional `$1` font family argument
- [X] T019 [US1] Update font installation loop in script to use `FONTS` array based on `$1`
- [X] T020 [US1] Add FontFamily struct to `tui/internal/ui/nerdfonts.go` if not exists
- [X] T021 [US1] Add action menu state (menuMode, actionItems, actionCursor) to NerdFontsModel
- [X] T022 [US1] Implement action menu rendering in NerdFontsModel.View()
- [X] T023 [US1] Modify HandleKey to show action menu on individual font selection
- [X] T024 [US1] Add installSingleFont(fontID string) method returning tea.Cmd
- [X] T025 [US1] Add nerdFontInstallMsg{fontID string} message type to `tui/internal/ui/model.go`
- [X] T026 [US1] Handle nerdFontInstallMsg in Model.Update() - route to installer with font arg
- [X] T027 [US1] Verify single font installation with `./scripts/004-reinstall/install_nerdfonts.sh JetBrainsMono`

**Checkpoint**: User can install individual fonts from TUI

---

## Phase 4: User Story 2 - TUI MCP Server Management (Priority: P2)

**Goal**: Add MCP Servers view under Extras with install/remove capabilities

**Independent Test**: Navigate to Extras → MCP Servers → See 7 servers with Connected/Disconnected status

### Implementation for User Story 2

- [X] T028 [US2] Create `tui/internal/ui/mcpservers.go` with MCPServersModel struct
- [X] T029 [US2] Add MCPServerStatus struct (Connected bool, Error string)
- [X] T030 [US2] Add mcpStatusLoadedMsg and mcpAllLoadedMsg message types
- [X] T031 [US2] Implement NewMCPServersModel(state, cache, repoRoot) constructor
- [X] T032 [US2] Implement Init() tea.Cmd - start spinner and refresh statuses
- [X] T033 [US2] Implement refreshMCPStatuses() - run `claude mcp list` and parse output
- [X] T034 [US2] Implement parseMCPListOutput(output string) - extract server connection status
- [X] T035 [US2] Implement Update(msg tea.Msg) - handle status messages, navigation
- [X] T036 [US2] Implement View() string - render server list with status, purple styling
- [X] T037 [US2] Implement HandleKey(msg tea.KeyMsg) - cursor navigation, enter for actions
- [X] T038 [US2] Add action menu for servers (Install/Remove/Back)
- [X] T039 [US2] Implement installMCPServer(server *MCPServer) tea.Cmd - run `claude mcp add`
- [X] T040 [US2] Implement removeMCPServer(server *MCPServer) tea.Cmd - run `claude mcp remove`
- [X] T041 [US2] Add ViewMCPServers to View enum in `tui/internal/ui/model.go`
- [X] T042 [US2] Add mcpServers *MCPServersModel field to Model struct
- [X] T043 [US2] Add case ViewMCPServers in Model.Update() for delegation
- [X] T044 [US2] Add "MCP Servers" menu item to `tui/internal/ui/extras.go`
- [X] T045 [US2] Handle MCP Servers selection in extras.go HandleKey

**Checkpoint**: MCP Servers view fully functional with install/remove

---

## Phase 5: User Story 3 - MCP Prerequisites Detection (Priority: P3)

**Goal**: Check and display prerequisites before MCP server installation

**Independent Test**: Select playwright → See Node.js ✓, AppArmor ✗ with fix instructions

### Implementation for User Story 3

- [X] T046 [US3] Add PrerequisiteResult struct to `tui/internal/registry/mcp.go`
- [X] T047 [US3] Add SecretResult struct to `tui/internal/registry/mcp.go`
- [X] T048 [US3] Implement CheckPrerequisite(prereq MCPPrerequisite) (bool, string)
- [X] T049 [US3] Implement (s *MCPServer) CheckAllPrerequisites() []PrerequisiteResult
- [X] T050 [US3] Implement (s *MCPServer) CheckSecrets() []SecretResult
- [X] T051 [US3] Create `tui/internal/ui/mcpprereq.go` with MCPPrereqModel struct
- [X] T052 [US3] Add fields: server, prereqResults, secretResults, cursor
- [X] T053 [US3] Implement View() - show prerequisites with ✓/✗ and fix instructions
- [X] T054 [US3] Implement HandleKey() - navigation and back action
- [X] T055 [US3] Add showPrerequisiteErrorMsg type to mcpservers.go
- [X] T056 [US3] Integrate prerequisite check before install in mcpservers.go handleInstall()
- [X] T057 [US3] Add ViewMCPPrereq to View enum in model.go
- [X] T058 [US3] Add case ViewMCPPrereq in Model.Update() for delegation

**Checkpoint**: Prerequisites displayed before install attempt

---

## Phase 6: User Story 5 - Secrets Template Setup Wizard (Priority: P5)

**Goal**: Guide user through setting up ~/.mcp-secrets file

**Independent Test**: Run wizard → Enter keys → ~/.mcp-secrets created with correct format

### Implementation for User Story 5

- [X] T059 [US5] Create `tui/internal/ui/secretswizard.go` with SecretsWizardModel struct
- [X] T060 [US5] Add fields: step, secrets, inputValue, values map, finished, error
- [X] T061 [US5] Implement collectAllRequiredSecrets() - gather from MCP registry
- [X] T062 [US5] Implement parseExistingSecrets() - read ~/.mcp-secrets if exists
- [X] T063 [US5] Implement filterMissingSecrets(all, existing) - skip already-set secrets
- [X] T064 [US5] Implement NewSecretsWizardModel() constructor
- [X] T065 [US5] Implement Init() tea.Cmd
- [X] T066 [US5] Implement Update(msg tea.Msg) - handle input, navigation
- [X] T067 [US5] Implement View() - render current step with input field
- [X] T068 [US5] Implement HandleKey() - enter to advance, esc to skip, text input
- [X] T069 [US5] Implement writeSecretsFile() - create/update ~/.mcp-secrets with export syntax
- [X] T070 [US5] Add ViewSecretsWizard to View enum in model.go
- [X] T071 [US5] Add case ViewSecretsWizard in Model.Update()
- [X] T072 [US5] Add "Setup Secrets" menu item to MCP Servers view or Extras

**Checkpoint**: Secrets wizard creates valid ~/.mcp-secrets

---

## Phase 7: Polish & Verification

**Purpose**: Final testing and documentation

- [X] T073 Verify TUI builds without errors: `cd tui && go build ./cmd/installer`
- [X] T074 Test per-font installation: install single font, verify with fc-list
- [X] T075 Test MCP view: check all 7 servers display with status
- [X] T076 Test prerequisites: verify Node.js check for playwright
- [X] T077 Test secrets wizard: create ~/.mcp-secrets from scratch
- [X] T078 Update ROADMAP.md to mark Wave 2 as complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - verify build
- **Phase 2 (US4 Registry)**: Foundation for P2, P3, P5
- **Phase 3 (US1 Fonts)**: Independent - can run parallel with Phase 2
- **Phase 4 (US2 MCP UI)**: Depends on Phase 2 (registry)
- **Phase 5 (US3 Prerequisites)**: Depends on Phase 2 + Phase 4
- **Phase 6 (US5 Wizard)**: Depends on Phase 2 + Phase 5
- **Phase 7 (Polish)**: Depends on all previous phases

### Optimal Execution Order

```
T001-T003 (Setup)
    ↓
T004-T017 (US4 Registry) ←→ T018-T027 (US1 Fonts) [parallel possible]
    ↓
T028-T045 (US2 MCP UI)
    ↓
T046-T058 (US3 Prerequisites)
    ↓
T059-T072 (US5 Wizard)
    ↓
T073-T078 (Polish)
```

### Parallel Opportunities

**Within Phase 2 (US4)**:
- T008-T014 can run in parallel (7 server definitions)

**Between Phases**:
- Phase 2 (US4) and Phase 3 (US1) can run in parallel

---

## Notes

- All paths relative to repository root
- Follow existing patterns in registry.go and extras.go
- Use purple/magenta styling for MCP views (Lipgloss Color "135")
- No new wrapper scripts - pure Go implementation except nerdfonts.sh modification
- Commit after each story completion
