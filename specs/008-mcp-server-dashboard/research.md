# Research: Claude Config Dashboards (MCP Servers + Skills)

**Date**: 2026-01-18
**Feature**: 008-mcp-server-dashboard

## Research Tasks

---

## MCP Servers Dashboard

### 1. Claude Configuration File Location

**Decision**: `~/.claude.json` (global) contains `mcpServers` object at root level

**Rationale**: Examined actual Claude Code installation. The global MCP server configuration is stored in `~/.claude.json` at the root `mcpServers` key. Per-project overrides exist under `projects["/path"].mcpServers` but global servers are at root.

**Alternatives considered**:
- `~/.claude/settings.json` - Does not exist; claude directory contains cache/history
- `~/.config/claude/` - Not used by Claude Code

### 2. MCP Server Configuration Structure

**Decision**: Use JSON structure matching Claude's native format

**Rationale**: Examined actual `~/.claude.json` mcpServers structure:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",           // or "http"
      "command": "/path/to/cmd", // for stdio
      "args": ["arg1", "arg2"],  // for stdio
      "env": { "KEY": "value" }, // environment variables
      "url": "https://..."       // for http type only
    }
  }
}
```

**Alternatives considered**:
- Custom format - Would require translation layer, adds complexity

### 3. Server Status Detection

**Decision**: Status based on configuration presence in `~/.claude.json`

**Rationale**:
- "Connected" = Server exists in mcpServers with valid configuration
- "Not Added" = Server in registry but not in config file
- "Error" = Server in config but missing required fields

Live connectivity testing (actually running the MCP server) is complex and slow - deferred to future enhancement.

**Alternatives considered**:
- Live connection test - Too slow for dashboard display, requires running servers

### 4. MCP Server Registry

**Decision**: Create new `internal/registry/mcp.go` with server definitions

**Rationale**: Follow existing tool registry pattern. Each server needs:
- ID, DisplayName, Description
- Transport type (stdio/http)
- Prerequisites (API keys, npm packages)
- Default configuration template

**Initial Server Set** (7 servers):
1. Context7 - stdio, requires CONTEXT7_API_KEY
2. GitHub - stdio, uses `gh auth token`
3. MarkItDown - stdio, requires uvx
4. Playwright - stdio, requires wrapper script
5. HuggingFace - http (to be added)
6. shadcn - stdio, requires npx
7. shadcn-ui - stdio, requires npx + gh auth

---

## Skills Dashboard

### 5. Skills Source Location

**Decision**: Skills from `.claude/skill-sources/`, agents from `.claude/agent-sources/`

**Rationale**: Examined existing `install-claude-config.sh` script which defines:
- `PROJECT_SKILLS="$PROJECT_ROOT/.claude/skill-sources"` - 5 skills
- `PROJECT_AGENTS="$PROJECT_ROOT/.claude/agent-sources"` - 65 agents

Skills are named with workflow ordering: `001-XX-name.md`

**Current Skills** (from script):
```bash
SKILLS=(
    "001-01-health-check.md"
    "001-02-deploy-site.md"
    "001-03-git-sync.md"
    "001-04-full-workflow.md"
    "001-05-issue-cleanup.md"
)
```

### 6. Skills Installation Target

**Decision**: Skills to `~/.claude/commands/`, agents to `~/.claude/agents/`

**Rationale**: Matches Claude Code's expected locations for user-defined commands and agents:
- `USER_SKILLS="$HOME/.claude/commands"` - slash commands
- `USER_AGENTS="$HOME/.claude/agents"` - agent definitions

### 7. Skills Status Detection

**Decision**: Compare source and target files using modification time

**Rationale**:
- "Installed" = File exists in user directory
- "Not Installed" = File only in project source
- "Outdated" = User file older than source file (mtime comparison)
- "Modified" = User file newer than source (user edited it)

**Alternatives considered**:
- Content hash comparison - More accurate but slower for 70 files
- Git tracking - Over-engineered for simple file copies

### 8. Skills Registry Design

**Decision**: Dynamically scan source directories rather than hardcoded list

**Rationale**: The agent-sources directory has 65 files that change over time. Scanning at runtime:
- Automatically picks up new files
- No need to update registry when adding agents
- Extract metadata from markdown frontmatter or filename

**Implementation**:
```go
func LoadSkills(projectRoot string) ([]Skill, error) {
    // Scan .claude/skill-sources/*.md
    // Extract name from filename (strip 001-XX- prefix)
    // Check installation status by comparing with ~/.claude/commands/
}
```

### 9. Menu Structure

**Decision**: Two separate menu entries in Extras: "MCP Servers" + "Skills & Agents"

**Rationale**: Clarified with user - separate entries provide clearer navigation. The current "Install Claude Config" will be renamed to "Skills & Agents" and converted from script runner to dashboard.

**Menu Changes**:
- Before: `"Install All", "Install Claude Config", "MCP Servers", "Back"`
- After: `"Install All", "Skills & Agents", "MCP Servers", "Back"`

---

## Common Patterns

### 10. TUI Integration Pattern

**Decision**: Add new view states following existing model.go patterns

**Rationale**: Examined existing TUI code:
- `ViewMCPServers` already exists (placeholder)
- Add `ViewSkills` for skills dashboard
- Both use lipgloss for table styling
- Standard keyboard navigation (↑↓ navigate, Enter select, Esc back)

### 11. File Operations

**Decision**: Use Go's standard library for file operations

**Rationale**:
- `os.ReadFile` / `os.WriteFile` for config JSON
- `os.Copy` equivalent for skills (io.Copy)
- `os.Stat` for modification time comparison
- `os.MkdirAll` for creating target directories

---

## Resolved Clarifications

| Item | Resolution |
|------|------------|
| Config file path | `~/.claude.json` (global mcpServers) |
| Config structure | Native Claude mcpServers JSON format |
| MCP status detection | Configuration presence check |
| MCP prerequisites | Registry-defined, TUI prompts |
| Skills source | `.claude/skill-sources/` (5) + `.claude/agent-sources/` (65) |
| Skills target | `~/.claude/commands/` + `~/.claude/agents/` |
| Skills status | File mtime comparison |
| Menu structure | Two separate entries: MCP Servers + Skills & Agents |
