# Implementation Plan: Claude Config Dashboards (MCP Servers + Skills)

**Branch**: `008-mcp-server-dashboard` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-mcp-server-dashboard/spec.md`

## Summary

Add two configuration dashboards to the existing Go TUI installer:
1. **MCP Servers Dashboard** - View and manage MCP server connections in `~/.claude.json`
2. **Skills & Agents Dashboard** - View and manage skills/agents installation (replacing broken "Install Claude Config" script runner)

Both dashboards follow existing TUI patterns using Bubbletea/Bubbles/Lipgloss with tabular status display and keyboard navigation.

## Technical Context

**Language/Version**: Go 1.23 (existing TUI codebase)
**Primary Dependencies**: charmbracelet/bubbletea v1.2.4, charmbracelet/bubbles v0.20.0, charmbracelet/lipgloss v1.0.0
**Storage**:
- MCP: JSON file (`~/.claude.json` - mcpServers key)
- Skills: File copy (`~/.claude/commands/`, `~/.claude/agents/`)
**Testing**: Go test (`go test ./...`)
**Target Platform**: Linux (Ubuntu 25.10)
**Project Type**: Single project (extending existing TUI)
**Performance Goals**: <2s dashboard load, <200ms UI response, <10s Install All
**Constraints**: Must integrate with existing TUI patterns, no new dependencies
**Scale/Scope**: 7 MCP servers, 5 skills, 65 agents

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Script Consolidation | PASS | No new bash scripts - all Go code in existing TUI |
| II. Branch Preservation | PASS | Using branch `008-mcp-server-dashboard` |
| III. Local-First CI/CD | PASS | Will run `go build ./...` and `go test ./...` locally before push |
| IV. Modularity Limits | PASS | New Go files will be <300 lines each |
| V. Symlink Single Source | N/A | Not modifying AGENTS.md/CLAUDE.md/GEMINI.md |

**Gate Result**: PASS - No violations. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/008-mcp-server-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Go interfaces)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
tui/
├── cmd/
│   └── installer/
│       └── main.go              # Entry point (existing)
└── internal/
    ├── registry/
    │   ├── registry.go          # Existing tool registry
    │   ├── tool.go              # Tool struct definition
    │   ├── mcp.go               # NEW: MCP server registry
    │   └── skills.go            # NEW: Skills/agents registry
    ├── config/
    │   ├── claude.go            # NEW: ~/.claude.json read/write
    │   └── skills.go            # NEW: Skills file operations
    ├── ui/
    │   ├── model.go             # Main TUI model (MODIFY: add views)
    │   ├── extras.go            # Extras menu (MODIFY: rename menu item)
    │   ├── mcp_view.go          # NEW: MCP dashboard view
    │   ├── mcp_actions.go       # NEW: MCP install/remove actions
    │   ├── skills_view.go       # NEW: Skills dashboard view
    │   └── skills_actions.go    # NEW: Skills install/remove actions
    └── executor/
        └── pipeline.go          # Existing pipeline (not needed for these features)
```

**Structure Decision**: Extend existing TUI structure. Two new view files per dashboard plus supporting registry/config packages.

## Complexity Tracking

No violations to justify - all gates pass.

## Implementation Phases

### Phase 1: MCP Servers Dashboard
- Create MCP server registry with 7 servers
- Create Claude config JSON handler
- Create MCP dashboard view with status display
- Add install/remove actions with prerequisite prompts

### Phase 2: Skills Dashboard
- Create skills/agents registry from source directories
- Create skills file operations (copy, delete, compare)
- Create skills dashboard view with status display
- Add install/remove/update actions + "Install All"
- Rename menu item from "Install Claude Config" to "Skills & Agents"

### Phase 3: Integration & Polish
- Update extras.go menu structure
- Add navigation between dashboards
- Test both dashboards end-to-end
- Run local CI/CD validation
