# Tasks: Claude Config Dashboards (MCP Servers + Skills)

**Input**: Design documents from `/specs/008-mcp-server-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: No tests explicitly requested in specification. Tests can be added later.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US8)
- Include exact file paths in descriptions

## Path Conventions

- **Project**: `tui/internal/` for Go packages
- **Registry**: `tui/internal/registry/` for server/skills definitions
- **Config**: `tui/internal/config/` for file operations
- **UI**: `tui/internal/ui/` for TUI views and actions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic type definitions

- [ ] T001 Create types package with shared types in tui/internal/types/types.go
- [ ] T002 [P] Define TransportType, PrerequisiteType constants in tui/internal/types/types.go
- [ ] T003 [P] Define MCPServerStatus constants (Connected, NotAdded, Error) in tui/internal/types/types.go
- [ ] T004 [P] Define ItemType constants (skill, agent) in tui/internal/types/types.go
- [ ] T005 [P] Define ItemStatus constants (Installed, NotInstalled, Outdated, Modified, Error) in tui/internal/types/types.go

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### MCP Foundation

- [ ] T006 Define Prerequisite struct in tui/internal/types/types.go
- [ ] T007 Define ServerConfig struct matching Claude JSON format in tui/internal/types/types.go
- [ ] T008 Define MCPServer struct in tui/internal/types/types.go
- [ ] T009 Define MCPServerState struct (registry + runtime) in tui/internal/types/types.go

### Skills Foundation

- [ ] T010 Define SkillItem struct in tui/internal/types/types.go

### Config Package Foundation

- [ ] T011 Create config package directory tui/internal/config/
- [ ] T012 Create ClaudeConfig struct skeleton in tui/internal/config/claude.go
- [ ] T013 [P] Create SkillsManager struct skeleton in tui/internal/config/skills.go

### Registry Package Foundation

- [ ] T014 Create registry package mcp.go skeleton in tui/internal/registry/mcp.go
- [ ] T015 [P] Create registry package skills.go skeleton in tui/internal/registry/skills.go

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View MCP Server Status Overview (Priority: P1)

**Goal**: Display all available MCP servers with their current status at a glance

**Independent Test**: Launch TUI → Navigate to MCP Servers → Verify all 7 servers listed with accurate status

### Implementation for User Story 1

- [ ] T016 [US1] Populate MCP server registry with 7 servers (context7, github, markitdown, playwright, huggingface, shadcn, shadcn-ui) in tui/internal/registry/mcp.go
- [ ] T017 [US1] Implement MCPRegistry.All() method in tui/internal/registry/mcp.go
- [ ] T018 [US1] Implement MCPRegistry.Get(id) method in tui/internal/registry/mcp.go
- [ ] T019 [US1] Implement MCPRegistry.Count() method in tui/internal/registry/mcp.go
- [ ] T020 [US1] Implement ClaudeConfig.Load() to read ~/.claude.json in tui/internal/config/claude.go
- [ ] T021 [US1] Implement ClaudeConfig.GetMCPServers() to extract mcpServers map in tui/internal/config/claude.go
- [ ] T022 [US1] Implement ClaudeConfig.HasServer(id) method in tui/internal/config/claude.go
- [ ] T023 [US1] Create MCPDashboardModel struct in tui/internal/ui/mcp_view.go
- [ ] T024 [US1] Implement MCPDashboardModel.Init() in tui/internal/ui/mcp_view.go
- [ ] T025 [US1] Implement MCPDashboardModel.View() with server table rendering in tui/internal/ui/mcp_view.go
- [ ] T026 [US1] Add ViewMCPDashboard state constant to tui/internal/ui/model.go
- [ ] T027 [US1] Add navigation case for ViewMCPDashboard in model.go Update() method

**Checkpoint**: MCP Servers dashboard displays all 7 servers with status - MVP for MCP side

---

## Phase 4: User Story 4 - Navigate Server Actions (Priority: P2)

**Goal**: Keyboard navigation to browse servers and access actions menu

**Independent Test**: Use arrow keys to navigate between servers, press Enter to see actions menu, Esc to close

### Implementation for User Story 4

- [ ] T028 [US4] Add cursor field and navigation logic to MCPDashboardModel in tui/internal/ui/mcp_view.go
- [ ] T029 [US4] Handle up/down arrow keys in MCPDashboardModel.Update() in tui/internal/ui/mcp_view.go
- [ ] T030 [US4] Add showActions boolean and actions menu state in tui/internal/ui/mcp_view.go
- [ ] T031 [US4] Handle Enter key to show actions menu in tui/internal/ui/mcp_view.go
- [ ] T032 [US4] Handle Escape key to close actions/return to extras in tui/internal/ui/mcp_view.go
- [ ] T033 [US4] Render selection highlight in View() method in tui/internal/ui/mcp_view.go
- [ ] T034 [US4] Render context-aware actions menu (Install for NotAdded, Remove for Connected) in tui/internal/ui/mcp_view.go

**Checkpoint**: Full keyboard navigation working for MCP dashboard

---

## Phase 5: User Story 2 - Install/Add MCP Server (Priority: P2)

**Goal**: Select a server and install it to Claude configuration

**Independent Test**: Select "Not Added" server → Choose Install → Provide prerequisites → Verify status becomes "Connected"

### Implementation for User Story 2

- [ ] T035 [US2] Create MCPInstaller struct in tui/internal/ui/mcp_actions.go
- [ ] T036 [US2] Implement prerequisite prompting for api_key type in tui/internal/ui/mcp_actions.go
- [ ] T037 [US2] Implement prerequisite auto-detection for auto type (e.g., gh auth token) in tui/internal/ui/mcp_actions.go
- [ ] T038 [US2] Implement prerequisite validation before install in tui/internal/ui/mcp_actions.go
- [ ] T039 [US2] Implement ClaudeConfig.AddServer(id, config) in tui/internal/config/claude.go
- [ ] T040 [US2] Implement ClaudeConfig.Save() with atomic write (temp file + rename) in tui/internal/config/claude.go
- [ ] T041 [US2] Implement MCPInstaller.Install(server) orchestrating prompts and config update in tui/internal/ui/mcp_actions.go
- [ ] T042 [US2] Wire Install action in MCPDashboardModel to MCPInstaller in tui/internal/ui/mcp_view.go
- [ ] T043 [US2] Add installation progress feedback in MCPDashboardModel.View() in tui/internal/ui/mcp_view.go
- [ ] T044 [US2] Refresh status after successful installation in tui/internal/ui/mcp_view.go

**Checkpoint**: Can install any MCP server through dashboard

---

## Phase 6: User Story 3 - Remove/Uninstall MCP Server (Priority: P3)

**Goal**: Remove a server from Claude configuration

**Independent Test**: Select "Connected" server → Choose Remove → Confirm → Verify status becomes "Not Added"

### Implementation for User Story 3

- [ ] T045 [US3] Add confirmation prompt for remove action in tui/internal/ui/mcp_actions.go
- [ ] T046 [US3] Implement ClaudeConfig.RemoveServer(id) in tui/internal/config/claude.go
- [ ] T047 [US3] Implement MCPInstaller.Remove(serverID) in tui/internal/ui/mcp_actions.go
- [ ] T048 [US3] Wire Remove action in MCPDashboardModel in tui/internal/ui/mcp_view.go
- [ ] T049 [US3] Refresh status after successful removal in tui/internal/ui/mcp_view.go

**Checkpoint**: Full MCP server lifecycle (view, install, remove) complete

---

## Phase 7: User Story 5 - View Skills/Agents Status Overview (Priority: P1)

**Goal**: Display all available skills and agents with installation status

**Independent Test**: Launch TUI → Navigate to Skills & Agents → Verify all 5 skills and 65 agents listed with status

### Implementation for User Story 5

- [ ] T050 [US5] Implement SkillsRegistry.LoadAll(projectRoot) to scan .claude/skill-sources/*.md in tui/internal/registry/skills.go
- [ ] T051 [US5] Implement SkillsRegistry.LoadAll to also scan .claude/agent-sources/*.md in tui/internal/registry/skills.go
- [ ] T052 [US5] Extract item ID from filename (strip .md extension) in tui/internal/registry/skills.go
- [ ] T053 [US5] Extract description from first line of markdown file in tui/internal/registry/skills.go
- [ ] T054 [US5] Implement SkillsRegistry.GetSkills() filter method in tui/internal/registry/skills.go
- [ ] T055 [US5] Implement SkillsRegistry.GetAgents() filter method in tui/internal/registry/skills.go
- [ ] T056 [US5] Implement SkillsRegistry.SkillCount() and AgentCount() in tui/internal/registry/skills.go
- [ ] T057 [US5] Implement SkillsManager.GetStatus(item) comparing source/target mtime in tui/internal/config/skills.go
- [ ] T058 [US5] Implement SkillsManager.RefreshStatus(items) for bulk status update in tui/internal/config/skills.go
- [ ] T059 [US5] Create SkillsDashboardModel struct in tui/internal/ui/skills_view.go
- [ ] T060 [US5] Implement SkillsDashboardModel.Init() to load skills and agents in tui/internal/ui/skills_view.go
- [ ] T061 [US5] Implement SkillsDashboardModel.View() with item table showing type, status in tui/internal/ui/skills_view.go
- [ ] T062 [US5] Add summary counts "5 Skills, 65 Agents" in header in tui/internal/ui/skills_view.go
- [ ] T063 [US5] Add ViewSkillsDashboard state constant to tui/internal/ui/model.go
- [ ] T064 [US5] Add navigation case for ViewSkillsDashboard in model.go Update() method

**Checkpoint**: Skills & Agents dashboard displays all items with status - MVP for Skills side

---

## Phase 8: User Story 6 - Install Skills/Agents (Priority: P2)

**Goal**: Select and install individual skill or agent

**Independent Test**: Select "Not Installed" skill → Choose Install → Verify file copied to ~/.claude/commands/ and status becomes "Installed"

### Implementation for User Story 6

- [ ] T065 [US6] Add cursor and navigation logic to SkillsDashboardModel in tui/internal/ui/skills_view.go
- [ ] T066 [US6] Handle up/down arrow keys in SkillsDashboardModel.Update() in tui/internal/ui/skills_view.go
- [ ] T067 [US6] Add actions menu state to SkillsDashboardModel in tui/internal/ui/skills_view.go
- [ ] T068 [US6] Implement SkillsManager.Install(item) to copy file to target path in tui/internal/config/skills.go
- [ ] T069 [US6] Create target directories (~/.claude/commands/, ~/.claude/agents/) if missing in tui/internal/config/skills.go
- [ ] T070 [US6] Create skills_actions.go with install action handler in tui/internal/ui/skills_actions.go
- [ ] T071 [US6] Wire Install action in SkillsDashboardModel in tui/internal/ui/skills_view.go
- [ ] T072 [US6] Refresh status after successful installation in tui/internal/ui/skills_view.go

**Checkpoint**: Can install individual skills and agents

---

## Phase 9: User Story 7 - Install All Skills/Agents (Priority: P2)

**Goal**: Quick bulk installation of all skills and agents

**Independent Test**: Select "Install All" → Verify all 70 items show as "Installed" with progress feedback

### Implementation for User Story 7

- [ ] T073 [US7] Add "Install All" option to SkillsDashboardModel actions menu in tui/internal/ui/skills_view.go
- [ ] T074 [US7] Implement SkillsManager.InstallAll(items) with progress tracking in tui/internal/config/skills.go
- [ ] T075 [US7] Return (installed, failed, error) counts from InstallAll in tui/internal/config/skills.go
- [ ] T076 [US7] Wire Install All action in SkillsDashboardModel in tui/internal/ui/skills_view.go
- [ ] T077 [US7] Add progress feedback during bulk install in tui/internal/ui/skills_view.go
- [ ] T078 [US7] Refresh all statuses after Install All completes in tui/internal/ui/skills_view.go

**Checkpoint**: Bulk install working - matches current "Install Claude Config" functionality but with dashboard

---

## Phase 10: User Story 8 - Remove/Uninstall Skills (Priority: P3)

**Goal**: Remove installed skills or agents

**Independent Test**: Select "Installed" skill → Choose Remove → Confirm → Verify file deleted and status becomes "Not Installed"

### Implementation for User Story 8

- [ ] T079 [US8] Add confirmation prompt for remove action in tui/internal/ui/skills_actions.go
- [ ] T080 [US8] Implement SkillsManager.Remove(item) to delete target file in tui/internal/config/skills.go
- [ ] T081 [US8] Wire Remove action in SkillsDashboardModel in tui/internal/ui/skills_view.go
- [ ] T082 [US8] Add Update action for outdated items in tui/internal/ui/skills_actions.go
- [ ] T083 [US8] Implement SkillsManager.Update(item) as remove + install in tui/internal/config/skills.go
- [ ] T084 [US8] Refresh status after remove/update in tui/internal/ui/skills_view.go

**Checkpoint**: Full skills lifecycle (view, install, remove, update) complete

---

## Phase 11: Integration & Polish

**Purpose**: Connect dashboards to menu system and final improvements

### Menu Integration

- [ ] T085 Rename "Install Claude Config" to "Skills & Agents" in tui/internal/ui/extras.go
- [ ] T086 Update menu item to navigate to ViewSkillsDashboard in tui/internal/ui/extras.go
- [ ] T087 Verify "MCP Servers" menu item navigates to ViewMCPDashboard in tui/internal/ui/extras.go
- [ ] T088 Add Escape key handling to return from dashboards to Extras menu in tui/internal/ui/model.go

### Error Handling

- [ ] T089 [P] Add error display for config file permission issues in tui/internal/ui/mcp_view.go
- [ ] T090 [P] Add error display for skills directory permission issues in tui/internal/ui/skills_view.go
- [ ] T091 [P] Handle missing ~/.claude.json gracefully (create empty config) in tui/internal/config/claude.go
- [ ] T092 [P] Handle missing source directories with helpful error message in tui/internal/registry/skills.go

### Performance & UX

- [ ] T093 Ensure dashboard loads in <2 seconds (lazy load if needed)
- [ ] T094 Ensure UI responds to input within 200ms
- [ ] T095 Add loading indicator during config operations

### Final Validation

- [ ] T096 Run go build ./cmd/installer successfully
- [ ] T097 Run go test ./... (if tests added)
- [ ] T098 Manual test: MCP Servers dashboard flow (view → install → remove)
- [ ] T099 Manual test: Skills & Agents dashboard flow (view → install → remove → install all)
- [ ] T100 Verify both dashboards accessible from Extras menu

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational - MCP dashboard display
- **US4 (Phase 4)**: Depends on US1 - Navigation requires dashboard to exist
- **US2 (Phase 5)**: Depends on US4 - Install needs navigation to select server
- **US3 (Phase 6)**: Depends on US2 - Remove needs same infrastructure as Install
- **US5 (Phase 7)**: Depends on Foundational - Skills dashboard display (parallel with US1-4)
- **US6 (Phase 8)**: Depends on US5 - Install needs dashboard to exist
- **US7 (Phase 9)**: Depends on US6 - Install All uses same Install infrastructure
- **US8 (Phase 10)**: Depends on US6 - Remove uses same infrastructure
- **Integration (Phase 11)**: Depends on all user stories complete

### User Story Dependencies

```
Foundational (Phase 2)
        │
        ├──────────────────────────────────┐
        │                                  │
        ▼                                  ▼
  [MCP Dashboard Track]            [Skills Dashboard Track]
        │                                  │
     US1 (P1)                          US5 (P1)
        │                                  │
     US4 (P2)                          US6 (P2)
        │                                  │
     US2 (P2)                          US7 (P2)
        │                                  │
     US3 (P3)                          US8 (P3)
        │                                  │
        └──────────────────────────────────┘
                        │
                        ▼
               Integration (Phase 11)
```

### Parallel Opportunities

**Within Foundational Phase:**
- T002, T003, T004, T005 (type constants) can run in parallel
- T012, T013 (config struct skeletons) can run in parallel
- T014, T015 (registry skeletons) can run in parallel

**Between Dashboard Tracks:**
- MCP track (US1 → US4 → US2 → US3) and Skills track (US5 → US6 → US7 → US8) can run in parallel after Foundational

**Within Integration Phase:**
- T089, T090, T091, T092 (error handling) can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch type constant definitions together:
Task: "Define TransportType, PrerequisiteType constants in tui/internal/types/types.go"
Task: "Define MCPServerStatus constants in tui/internal/types/types.go"
Task: "Define ItemType constants in tui/internal/types/types.go"
Task: "Define ItemStatus constants in tui/internal/types/types.go"

# Launch config/registry skeletons together:
Task: "Create ClaudeConfig struct skeleton in tui/internal/config/claude.go"
Task: "Create SkillsManager struct skeleton in tui/internal/config/skills.go"
Task: "Create registry package mcp.go skeleton in tui/internal/registry/mcp.go"
Task: "Create registry package skills.go skeleton in tui/internal/registry/skills.go"
```

## Parallel Example: Two Dashboard Tracks

```bash
# After Foundational completes, launch both tracks:

# Track 1 - MCP Dashboard:
Task: "Populate MCP server registry with 7 servers in tui/internal/registry/mcp.go"

# Track 2 - Skills Dashboard (parallel with Track 1):
Task: "Implement SkillsRegistry.LoadAll(projectRoot) in tui/internal/registry/skills.go"
```

---

## Implementation Strategy

### MVP First (US1 + US5 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (MCP Dashboard display)
4. Complete Phase 7: User Story 5 (Skills Dashboard display)
5. **STOP and VALIDATE**: Both dashboards display items with status
6. This delivers visibility into configuration state

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 + US5 → Both dashboards show status (MVP!)
3. Add US4 + US6 → Navigation and individual install
4. Add US2 + US7 → Full install capability (Install All for skills)
5. Add US3 + US8 → Remove capability
6. Integration → Menu wiring and polish
7. Each phase adds value without breaking previous phases

### Parallel Team Strategy

With two developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: MCP Track (US1 → US4 → US2 → US3)
   - Developer B: Skills Track (US5 → US6 → US7 → US8)
3. Both complete Integration phase together

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- MCP and Skills dashboards are independent tracks after Foundational
- Each track can be delivered separately for faster feedback
- Verify file paths exist before writing (tui/internal/ structure)
- Commit after each logical group of tasks
- Stop at any checkpoint to validate independently
