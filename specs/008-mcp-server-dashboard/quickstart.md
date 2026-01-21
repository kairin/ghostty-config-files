# Quickstart: Claude Config Dashboards (MCP Servers + Skills)

**Feature**: 008-mcp-server-dashboard
**Date**: 2026-01-18

## Overview

This feature adds two dashboards to the existing Ghostty TUI installer:
1. **MCP Servers Dashboard** - View and manage MCP server connections in `~/.claude.json`
2. **Skills & Agents Dashboard** - View and manage skills/agents installation (replacing broken "Install Claude Config")

## Prerequisites

- Go 1.23+
- Existing TUI codebase in `tui/`
- Claude Code installed (`~/.claude.json` exists or will be created)
- Project has `.claude/skill-sources/` and `.claude/agent-sources/` directories

## Quick Implementation Path

### Phase 1: MCP Servers Dashboard

#### 1.1 Create MCP Server Registry

Create `tui/internal/registry/mcp.go`:

```go
package registry

// MCPServer represents an MCP server definition
type MCPServer struct {
    ID            string
    DisplayName   string
    Description   string
    Transport     string // "stdio" or "http"
    Prerequisites []Prerequisite
    ConfigTemplate ServerConfig
}

// Initial servers (7 total)
var mcpServers = map[string]*MCPServer{
    "context7": {...},
    "github": {...},
    "markitdown": {...},
    "playwright": {...},
    "huggingface": {...},
    "shadcn": {...},
    "shadcn-ui": {...},
}
```

#### 1.2 Create Claude Config Handler

Create `tui/internal/config/claude.go`:

```go
package config

// ClaudeConfig handles ~/.claude.json read/write
type ClaudeConfig struct {
    path string
    data map[string]interface{}
}

func (c *ClaudeConfig) Load() error { ... }
func (c *ClaudeConfig) GetMCPServers() map[string]*ServerConfig { ... }
func (c *ClaudeConfig) AddServer(id string, cfg *ServerConfig) error { ... }
func (c *ClaudeConfig) RemoveServer(id string) error { ... }
func (c *ClaudeConfig) Save() error { ... }
```

#### 1.3 Create MCP Dashboard View

Create `tui/internal/ui/mcp_view.go`:

```go
package ui

// MCPDashboardModel is the Bubbletea model for MCP dashboard
type MCPDashboardModel struct {
    servers []MCPServerState
    cursor  int
}

func (m MCPDashboardModel) View() string {
    // Render table with server status
}
```

---

### Phase 2: Skills & Agents Dashboard

#### 2.1 Create Skills Registry

Create `tui/internal/registry/skills.go`:

```go
package registry

// SkillItem represents a skill or agent
type SkillItem struct {
    ID          string
    DisplayName string
    Description string
    Type        string // "skill" or "agent"
    SourcePath  string
    TargetPath  string
    Status      string
}

// LoadSkills dynamically scans source directories
func LoadSkills(projectRoot string) ([]SkillItem, error) {
    // Scan .claude/skill-sources/*.md
    // Scan .claude/agent-sources/*.md
    // Check installation status
}
```

#### 2.2 Create Skills File Operations

Create `tui/internal/config/skills.go`:

```go
package config

// SkillsManager handles skill/agent file operations
type SkillsManager struct {
    projectRoot string
    userDir     string
}

func (m *SkillsManager) Install(item *SkillItem) error { ... }
func (m *SkillsManager) Remove(item *SkillItem) error { ... }
func (m *SkillsManager) Update(item *SkillItem) error { ... }
func (m *SkillsManager) InstallAll(items []SkillItem) (int, int, error) { ... }
func (m *SkillsManager) GetStatus(item *SkillItem) ItemStatus { ... }
```

#### 2.3 Create Skills Dashboard View

Create `tui/internal/ui/skills_view.go`:

```go
package ui

// SkillsDashboardModel is the Bubbletea model for Skills dashboard
type SkillsDashboardModel struct {
    items  []SkillItem
    cursor int
    filter string // "all", "skills", "agents"
}

func (m SkillsDashboardModel) View() string {
    // Render table with item status
    // Show counts: "5 Skills, 65 Agents"
}
```

---

### Phase 3: Integration

#### 3.1 Update Main TUI Model

Update `tui/internal/ui/model.go`:
- Add `ViewMCPDashboard` and `ViewSkillsDashboard` states
- Handle navigation to/from both dashboards

#### 3.2 Update Extras Menu

Update `tui/internal/ui/extras.go`:
- Rename "Install Claude Config" to "Skills & Agents"
- Keep "MCP Servers" entry
- Connect to new dashboard views

## File Checklist

### MCP Servers Dashboard
| File | Purpose | Lines Est. |
|------|---------|------------|
| `internal/registry/mcp.go` | Server registry | ~150 |
| `internal/config/claude.go` | Config read/write | ~200 |
| `internal/ui/mcp_view.go` | Dashboard view | ~250 |
| `internal/ui/mcp_actions.go` | Install/remove actions | ~150 |

### Skills Dashboard
| File | Purpose | Lines Est. |
|------|---------|------------|
| `internal/registry/skills.go` | Skills/agents scanner | ~150 |
| `internal/config/skills.go` | File operations | ~200 |
| `internal/ui/skills_view.go` | Dashboard view | ~250 |
| `internal/ui/skills_actions.go` | Install/remove/update actions | ~150 |

### Integration
| File | Purpose | Lines Est. |
|------|---------|------------|
| `internal/ui/model.go` | Integration (modify) | +100 |
| `internal/ui/extras.go` | Menu update (modify) | +20 |

**Total new code**: ~1,500 lines (well under 300 per file)

## Testing Strategy

1. **Unit tests** for config read/write
2. **Unit tests** for registry lookups
3. **Unit tests** for file status detection
4. **Integration test** for install/remove flow
5. **Manual test** with TUI interaction

## Build & Run

```bash
cd tui
go build ./cmd/installer
./installer
# Navigate to Extras → "MCP Servers" or "Skills & Agents"
```

## Key Design Decisions

1. **No live connectivity test** - MCP status based on config presence only
2. **File mtime comparison** - Skills status uses modification time, not content hash
3. **Atomic config writes** - Write to temp file, rename
4. **Dynamic scanning** - Skills registry scans directories at runtime
5. **Follow existing patterns** - Match tool dashboard UX
6. **Extensible design** - Easy to add new servers/skills

## Directory Paths

| Type | Source (Project) | Target (User) |
|------|------------------|---------------|
| Skills | `.claude/skill-sources/` | `~/.claude/commands/` |
| Agents | `.claude/agent-sources/` | `~/.claude/agents/` |
| MCP Config | N/A | `~/.claude.json` |

## Next Steps

After `/speckit.plan` completes:
1. Run `/speckit.tasks` to generate task breakdown
2. Implement Phase 1 first (MCP Dashboard)
3. Implement Phase 2 (Skills Dashboard)
4. Implement Phase 3 (Integration)
5. Run local CI/CD before push
