# Data Model: Claude Config Dashboards (MCP Servers + Skills)

**Date**: 2026-01-18
**Feature**: 008-mcp-server-dashboard

---

## MCP Servers Entities

### MCPServer (Registry Definition)

Represents an MCP server that can be installed through the dashboard.

| Field | Type | Description |
|-------|------|-------------|
| ID | string | Unique identifier (e.g., "context7") |
| DisplayName | string | Human-readable name (e.g., "Context7") |
| Description | string | Short description for dashboard |
| Transport | TransportType | "stdio" or "http" |
| Prerequisites | []Prerequisite | Required inputs before install |
| ConfigTemplate | ServerConfig | Default configuration template |

### TransportType

| Value | Description |
|-------|-------------|
| stdio | Standard I/O transport (command + args) |
| http | HTTP/HTTPS transport (url endpoint) |

### Prerequisite

| Field | Type | Description |
|-------|------|-------------|
| Key | string | Environment variable or config key |
| Label | string | Human-readable prompt label |
| Type | PrerequisiteType | "api_key", "path", "auto" |
| AutoCommand | string | Command to auto-detect value (optional) |
| Required | bool | Whether prerequisite is mandatory |

### PrerequisiteType

| Value | Description |
|-------|-------------|
| api_key | User must provide API key (masked input) |
| path | User must provide file/command path |
| auto | Auto-detected from system (e.g., gh auth token) |

### ServerConfig

Claude-native MCP server configuration format.

| Field | Type | Description |
|-------|------|-------------|
| Type | string | "stdio" or "http" |
| Command | string | Executable path (stdio only) |
| Args | []string | Command arguments (stdio only) |
| Env | map[string]string | Environment variables |
| URL | string | Endpoint URL (http only) |

### MCPServerStatus

| Value | Description |
|-------|-------------|
| Connected | Server configured and valid in claude.json |
| NotAdded | Server in registry but not configured |
| Error | Server configured but invalid/incomplete |

### MCPServerState

Combined view of registry + runtime state.

| Field | Type | Description |
|-------|------|-------------|
| Server | *MCPServer | Registry definition |
| Status | MCPServerStatus | Current status |
| Config | *ServerConfig | Current configuration (if installed) |

---

## Skills Dashboard Entities

### Skill

Represents a Claude Code slash command extension.

| Field | Type | Description |
|-------|------|-------------|
| ID | string | Unique identifier (filename without .md) |
| DisplayName | string | Human-readable name (derived from filename) |
| Description | string | First line of markdown file |
| Type | ItemType | Always "skill" |
| SourcePath | string | Path in project (`.claude/skill-sources/`) |
| TargetPath | string | Install path (`~/.claude/commands/`) |
| Status | ItemStatus | Current installation status |
| SourceMtime | time.Time | Source file modification time |
| TargetMtime | time.Time | Target file modification time (if installed) |

### Agent

Represents a Claude Code agent definition.

| Field | Type | Description |
|-------|------|-------------|
| ID | string | Unique identifier (filename without .md) |
| DisplayName | string | Human-readable name (derived from filename) |
| Description | string | First line of markdown file |
| Type | ItemType | Always "agent" |
| Tier | string | Agent tier (extracted from filename: 001, 002, etc.) |
| SourcePath | string | Path in project (`.claude/agent-sources/`) |
| TargetPath | string | Install path (`~/.claude/agents/`) |
| Status | ItemStatus | Current installation status |
| SourceMtime | time.Time | Source file modification time |
| TargetMtime | time.Time | Target file modification time (if installed) |

### ItemType

| Value | Description |
|-------|-------------|
| skill | Claude Code slash command |
| agent | Claude Code agent definition |

### ItemStatus

| Value | Description |
|-------|-------------|
| Installed | File exists in user directory, matches source |
| NotInstalled | File only in project source |
| Outdated | User file older than source file |
| Modified | User file newer than source (user edited) |
| Error | File unreadable or corrupted |

### SkillItem

Generic item representing either a skill or agent.

| Field | Type | Description |
|-------|------|-------------|
| ID | string | Unique identifier |
| DisplayName | string | Human-readable name |
| Description | string | Short description |
| Type | ItemType | "skill" or "agent" |
| Status | ItemStatus | Current status |
| SourcePath | string | Project source path |
| TargetPath | string | User install path |

---

## Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MCP SERVERS                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐      ┌─────────────────┐                      │
│  │   MCPServer     │      │  ServerConfig   │                      │
│  │   (Registry)    │──────│  (claude.json)  │                      │
│  └─────────────────┘      └─────────────────┘                      │
│          │                        │                                 │
│          └────────────────────────┘                                │
│                      │                                              │
│                      ▼                                              │
│          ┌─────────────────────┐                                   │
│          │   MCPServerState    │                                   │
│          │   (Dashboard View)  │                                   │
│          └─────────────────────┘                                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        SKILLS & AGENTS                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐      ┌─────────────────┐                      │
│  │ .claude/        │      │ ~/.claude/      │                      │
│  │ skill-sources/  │──────│ commands/       │                      │
│  │ agent-sources/  │      │ agents/         │                      │
│  │ (Project)       │      │ (User)          │                      │
│  └─────────────────┘      └─────────────────┘                      │
│          │                        │                                 │
│          └────────────────────────┘                                │
│                      │                                              │
│                      ▼                                              │
│          ┌─────────────────────┐                                   │
│          │     SkillItem       │                                   │
│          │   (Dashboard View)  │                                   │
│          └─────────────────────┘                                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## State Transitions

### MCP Server States

```
                    ┌──────────────┐
                    │   NotAdded   │
                    └──────┬───────┘
                           │ Install
                           ▼
                    ┌──────────────┐
              ┌─────│  Connected   │─────┐
              │     └──────────────┘     │
              │                          │
        Remove│                          │Config Error
              │                          │
              ▼                          ▼
       ┌──────────────┐          ┌──────────────┐
       │   NotAdded   │          │    Error     │
       └──────────────┘          └──────────────┘
```

### Skill/Agent States

```
                    ┌──────────────┐
                    │ NotInstalled │
                    └──────┬───────┘
                           │ Install
                           ▼
                    ┌──────────────┐
              ┌─────│  Installed   │─────┐
              │     └──────────────┘     │
              │            │             │
        Remove│     Source │        User │
              │     Updated│       Edits │
              │            ▼             ▼
              │     ┌──────────────┐   ┌──────────────┐
              │     │   Outdated   │   │   Modified   │
              │     └──────┬───────┘   └──────────────┘
              │            │ Update
              │            ▼
              │     ┌──────────────┐
              │     │  Installed   │
              ▼     └──────────────┘
       ┌──────────────┐
       │ NotInstalled │
       └──────────────┘
```

---

## Validation Rules

### MCP Servers
1. **MCPServer.ID**: Non-empty, alphanumeric + hyphens, unique in registry
2. **MCPServer.Transport**: Must be "stdio" or "http"
3. **ServerConfig.Command**: Required if Type is "stdio"
4. **ServerConfig.URL**: Required if Type is "http"
5. **Prerequisite.Key**: Non-empty, valid env var name format

### Skills & Agents
1. **SkillItem.ID**: Derived from filename, unique per type
2. **SourcePath**: Must exist and be readable
3. **TargetPath**: Parent directory must be writable
4. **Type**: Must be "skill" or "agent"

---

## Initial Data

### MCP Servers (7)

| ID | Transport | Prerequisites |
|----|-----------|---------------|
| context7 | stdio | CONTEXT7_API_KEY (api_key) |
| github | stdio | GITHUB_PERSONAL_ACCESS_TOKEN (auto: gh auth token) |
| markitdown | stdio | uvx (path, auto-detect) |
| playwright | stdio | wrapper script (path) |
| huggingface | http | HF_TOKEN (api_key) |
| shadcn | stdio | npx (auto-detect) |
| shadcn-ui | stdio | npx + gh auth (auto-detect) |

### Skills (5)

| ID | Source |
|----|--------|
| 001-01-health-check | .claude/skill-sources/001-01-health-check.md |
| 001-02-deploy-site | .claude/skill-sources/001-02-deploy-site.md |
| 001-03-git-sync | .claude/skill-sources/001-03-git-sync.md |
| 001-04-full-workflow | .claude/skill-sources/001-04-full-workflow.md |
| 001-05-issue-cleanup | .claude/skill-sources/001-05-issue-cleanup.md |

### Agents (65)

Dynamically scanned from `.claude/agent-sources/*.md`
