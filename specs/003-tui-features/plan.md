# Implementation Plan: Wave 2 - TUI Features

**Branch**: `003-tui-features` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-tui-features/spec.md`

## Summary

Implement 5 TUI features for Wave 2: per-family Nerd Font selection, MCP Server management UI, prerequisites detection, MCP registry, and secrets wizard. All features are Go-based TUI enhancements following existing Bubbletea patterns.

## Technical Context

**Language/Version**: Go 1.21+
**Primary Dependencies**: Bubbletea, Lipgloss, Bubbles (spinner)
**Storage**: `~/.mcp-secrets` (shell script format), font cache
**Testing**: `go test ./...`
**Target Platform**: Linux (Ubuntu)
**Project Type**: TUI application (single binary)
**Performance Goals**: Status checks < 5 seconds, installations < 30 seconds
**Constraints**: No new wrapper scripts (constitution), follow existing patterns
**Scale/Scope**: 7 MCP servers, 8 font families

## Constitution Check

*GATE: Must pass before implementation*

| Principle | Status | Notes |
|-----------|--------|-------|
| Script Consolidation | ✅ PASS | Modifying existing `install_nerdfonts.sh`, no new scripts |
| Branch Preservation | ✅ PASS | Using `003-tui-features` branch |
| Local-First CI/CD | ✅ PASS | Will run `go build` locally |
| Modularity Limits | ✅ PASS | No AGENTS.md changes |
| Symlink Single Source | ✅ PASS | No symlink modifications |

## Project Structure

### Documentation (this feature)

```text
specs/003-tui-features/
├── spec.md              # Feature specification
├── plan.md              # This file
├── tasks.md             # Task breakdown (next step)
└── checklists/
    └── requirements.md  # Quality checklist
```

### Source Code (existing TUI structure)

```text
tui/
├── cmd/installer/main.go           # Entry point
└── internal/
    ├── registry/
    │   ├── registry.go             # Tool registry (existing)
    │   ├── tool.go                 # Tool struct (existing)
    │   └── mcp.go                  # NEW: MCP server registry
    ├── ui/
    │   ├── model.go                # MODIFY: Add MCP view routing
    │   ├── extras.go               # MODIFY: Add MCP menu item
    │   ├── nerdfonts.go            # MODIFY: Per-font selection
    │   ├── mcpservers.go           # NEW: MCP management view
    │   ├── mcpprereq.go            # NEW: Prerequisites view
    │   └── secretswizard.go        # NEW: Secrets wizard
    ├── executor/                    # Existing script execution
    └── cache/                       # Existing status caching

scripts/
└── 004-reinstall/
    └── install_nerdfonts.sh        # MODIFY: Accept font argument
```

## Implementation Phases

### Phase 1: MCP Server Registry (P4) - 1 hr

Create `tui/internal/registry/mcp.go`:
- `MCPServer` struct with ID, DisplayName, Transport, Prerequisites, Secrets
- Registry for all 7 servers with their configurations
- Helper functions: `GetMCPServer()`, `GetAllMCPServers()`

### Phase 2: Per-Family Nerd Font (P1) - 2 hr

Modify `scripts/004-reinstall/install_nerdfonts.sh`:
- Accept optional `$1` argument for single font family

Modify `tui/internal/ui/nerdfonts.go`:
- Add action menu for individual fonts
- Route to single-font installation

### Phase 3: MCP Server Management (P2) - 4 hr

Create `tui/internal/ui/mcpservers.go`:
- `MCPServersModel` following `extras.go` pattern
- Status loading via `claude mcp list`
- Install/Remove actions via `claude mcp add/remove`

Modify `tui/internal/ui/model.go`:
- Add `ViewMCPServers` enum
- Add view routing

Modify `tui/internal/ui/extras.go`:
- Add "MCP Servers" menu item

### Phase 4: Prerequisites Detection (P3) - 2 hr

Modify `tui/internal/registry/mcp.go`:
- Add `CheckPrerequisite()` function
- Add `CheckAllPrerequisites()` method

Create `tui/internal/ui/mcpprereq.go`:
- View showing prerequisite check results
- Fix instructions for failed prerequisites

### Phase 5: Secrets Wizard (P5) - 2 hr

Create `tui/internal/ui/secretswizard.go`:
- Step-by-step wizard for API keys
- Parse/write `~/.mcp-secrets` file
- Skip existing secrets

## Files Summary

| Action | File | Purpose |
|--------|------|---------|
| CREATE | `tui/internal/registry/mcp.go` | MCP server registry |
| CREATE | `tui/internal/ui/mcpservers.go` | MCP management view |
| CREATE | `tui/internal/ui/mcpprereq.go` | Prerequisites view |
| CREATE | `tui/internal/ui/secretswizard.go` | Secrets wizard |
| MODIFY | `tui/internal/ui/model.go` | View routing |
| MODIFY | `tui/internal/ui/nerdfonts.go` | Per-font selection |
| MODIFY | `tui/internal/ui/extras.go` | MCP menu item |
| MODIFY | `scripts/004-reinstall/install_nerdfonts.sh` | Font argument |

## Verification

```bash
# Build TUI
cd tui && go build ./cmd/installer

# Test per-font selection
./scripts/004-reinstall/install_nerdfonts.sh JetBrainsMono
fc-list | grep JetBrains

# Test MCP view
cd tui && go run ./cmd/installer
# Navigate: Extras → MCP Servers

# Test secrets wizard
rm -f ~/.mcp-secrets
# Run wizard, verify file created
```

## Complexity Tracking

No constitution violations. All changes follow existing patterns.
