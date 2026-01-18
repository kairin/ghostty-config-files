# Data Model: Claude Code Workflow Skills

**Feature**: 004-claude-skills
**Date**: 2026-01-18

## Entities

### Skill

A Claude Code slash command defined in `.claude/commands/` directory.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| description | string | Yes | Short description shown in skill listings |
| handoffs | Handoff[] | No | Array of workflow transitions to suggest |
| body | markdown | Yes | Instructions for Claude to execute |

**Validation Rules**:
- description: max 100 characters
- body: must include ## sections for Instructions and Steps
- handoffs: max 4 entries (avoid overwhelming user)

### Handoff

A workflow transition that suggests the next skill to run.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| label | string | Yes | Button text shown to user (max 20 chars) |
| prompt | string | Yes | Context to pass to next skill invocation |

**Validation Rules**:
- label: max 20 characters
- prompt: must reference valid skill (e.g., "Run /deploy-site")

### HealthReport

Structured output from `/health-check` skill.

| Field | Type | Description |
|-------|------|-------------|
| component | string | System component being checked |
| status | enum | PASS, FAIL, WARNING |
| message | string | Details about the check result |
| remediation | string | (optional) Steps to fix if FAIL/WARNING |

### BuildMetrics

Structured output from `/deploy-site` skill.

| Field | Type | Description |
|-------|------|-------------|
| fileCount | number | Number of files in build output |
| bundleSize | string | Total bundle size (e.g., "85KB") |
| buildDuration | string | Build time (e.g., "12.3s") |
| deploymentUrl | string | GitHub Pages URL |

### SyncStatus

Structured output from `/git-sync` skill.

| Field | Type | Description |
|-------|------|-------------|
| branch | string | Current branch name |
| status | enum | up-to-date, behind, ahead, diverged |
| localCommits | number | Commits ahead of remote |
| remoteCommits | number | Commits behind remote |
| branchValid | boolean | Whether name follows YYYYMMDD-HHMMSS format |

## State Transitions

### Skill Execution Flow

```
Idle → Executing → Completed
         ↓
       Failed → (User intervention) → Idle
```

### Full Workflow Stages

```
Start → HealthCheck → DeploySite → GitSync → Complete
           ↓              ↓            ↓
         Abort          Abort        Abort
```

**Abort Conditions**:
- HealthCheck: Critical failure (missing tools, MCP disconnected)
- DeploySite: Build errors, .nojekyll missing and uncreatable
- GitSync: Diverged branches (requires user decision)

## Relationships

```
full-workflow
    ├── health-check (first stage)
    ├── deploy-site (second stage)
    └── git-sync (third stage)

health-check ──handoff──> deploy-site ──handoff──> git-sync
```

## File Locations

| Entity | Storage Location |
|--------|-----------------|
| Skill (project template) | `.claude/commands/{skill-name}.md` |
| Skill (user-level) | `~/.claude/commands/{skill-name}.md` |
| Health report | stdout (structured text) |
| Build metrics | stdout (structured text) |
| Sync status | stdout (structured text) |
