# Data Model: Claude Agents User-Level Consolidation

**Branch**: `005-claude-agents` | **Date**: 2026-01-18

## Entities

### Agent Source File

A markdown file with YAML frontmatter defining a Claude Code agent.

**Location**: `.claude/agent-sources/`

**Attributes**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| filename | string | Yes | File name following `NNN-name.md` pattern |
| name | string | Yes | Agent name in YAML frontmatter |
| description | string | Yes | Agent description in YAML frontmatter |
| model | enum | Yes | `opus`, `sonnet`, or `haiku` |
| tier | integer | Yes | 0-4 (determines execution priority) |
| category | enum | Yes | `orchestration`, `domain`, `utility`, `atomic` |

**Naming Convention**:
```text
Tier 0: 000-*.md (5 files)  - Workflow orchestrators
Tier 1: 001-*.md (1 file)   - Opus orchestrator
Tier 2: 002-*.md (5 files)  - Domain operations
Tier 3: 003-*.md (4 files)  - Utility/support
Tier 4: 0XX-*.md (50 files) - Atomic execution
```

**Example**:
```yaml
---
name: 001-orchestrator
description: >-
  High-functioning Opus orchestrator for multi-agent coordination
model: opus
tier: 1
category: orchestration
---
```

---

### Installed Agent

A copy of an agent source file at user-level for Claude Code discovery.

**Location**: `~/.claude/agents/`

**Relationship**: 1:1 copy from Agent Source File

**State**: Active (discovered by Claude Code) or Deprecated (to be removed)

---

### Skill Source File

A markdown file defining a Claude Code skill/command.

**Location**: `.claude/skill-sources/`

**Attributes**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| filename | string | Yes | File name following `001-name.md` pattern |
| description | string | Yes | Skill description in YAML frontmatter |
| handoffs | array | No | Links to related skills |

**Files** (4 total):
- `001-health-check.md`
- `001-deploy-site.md`
- `001-git-sync.md`
- `001-full-workflow.md`

---

### Installed Skill

A copy of a skill source file at user-level for Claude Code discovery.

**Location**: `~/.claude/commands/`

**Relationship**: 1:1 copy from Skill Source File

---

### Deprecated File

An old skill or agent file that should be removed during installation.

**Deprecated Skills** (to be removed from `~/.claude/commands/`):
- `health-check.md` (replaced by `001-health-check.md`)
- `deploy-site.md` (replaced by `001-deploy-site.md`)
- `git-sync.md` (replaced by `001-git-sync.md`)
- `full-workflow.md` (replaced by `001-full-workflow.md`)
- `full-git-workflow.md` (obsolete)

---

## Relationships

```text
┌─────────────────────────────────────────────────────────────┐
│                    Repository (Source)                       │
├─────────────────────────────────────────────────────────────┤
│  .claude/skill-sources/     .claude/agent-sources/          │
│  ├── 001-health-check.md    ├── 000-*.md (5)                │
│  ├── 001-deploy-site.md     ├── 001-*.md (1)                │
│  ├── 001-git-sync.md        ├── 002-*.md (5)                │
│  └── 001-full-workflow.md   ├── 003-*.md (4)                │
│                              └── 0XX-*.md (50)               │
│                                                              │
│         │                            │                       │
│         │  install-claude-config.sh  │                       │
│         ▼                            ▼                       │
├─────────────────────────────────────────────────────────────┤
│                    User Level (Installed)                    │
├─────────────────────────────────────────────────────────────┤
│  ~/.claude/commands/        ~/.claude/agents/                │
│  ├── 001-health-check.md    ├── 000-*.md (5)                │
│  ├── 001-deploy-site.md     ├── 001-*.md (1)                │
│  ├── 001-git-sync.md        ├── 002-*.md (5)                │
│  └── 001-full-workflow.md   ├── 003-*.md (4)                │
│                              └── 0XX-*.md (50)               │
│                                                              │
│  Total: 4 skills            Total: 65 agents                 │
└─────────────────────────────────────────────────────────────┘
```

## File Counts

| Entity | Count | Location |
|--------|-------|----------|
| Agent Source Files | 65 | `.claude/agent-sources/` |
| Skill Source Files | 4 | `.claude/skill-sources/` |
| Installed Agents | 65 | `~/.claude/agents/` |
| Installed Skills | 4 | `~/.claude/commands/` |
| Deprecated Skills | 5 | `~/.claude/commands/` (removed) |

## Agent Tier Breakdown

| Tier | Prefix | Count | Model | Purpose |
|------|--------|-------|-------|---------|
| 0 | 000-* | 5 | Sonnet | Complete workflow agents |
| 1 | 001-* | 1 | Opus | Multi-agent orchestration |
| 2 | 002-* | 5 | Sonnet | Core domain operations |
| 3 | 003-* | 4 | Sonnet | Utility/support |
| 4 | 0XX-* | 50 | Haiku | Atomic execution |

**Tier 4 Subcategories**:
- 021-*: 7 Git tasks
- 022-*: 5 Astro tasks
- 023-*: 7 Cleanup tasks
- 024-*: 6 Compliance tasks
- 025-*: 6 Health tasks
- 031-*: 6 CI/CD tasks
- 032-*: 5 Documentation tasks
- 033-*: 5 Symlink tasks
- 034-*: 3 Workflow template tasks
