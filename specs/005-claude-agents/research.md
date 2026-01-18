# Research: Claude Agents User-Level Consolidation

**Branch**: `005-claude-agents` | **Date**: 2026-01-18

## Overview

This feature follows the established pattern from skills consolidation (branch `004-claude-skills`). No new technical decisions required - reusing proven approach.

## Decision 1: Directory Naming Convention

**Decision**: Use `.claude/agent-sources/` for agent source files

**Rationale**:
- Mirrors the existing `.claude/skill-sources/` pattern
- Clear naming indicates these are source files, not active agents
- Not in `.claude/agents/` which is auto-discovered by Claude Code

**Alternatives Considered**:
- `.claude/agents-src/` - Rejected: inconsistent with skills naming
- `.agents/` - Rejected: doesn't follow `.claude/` convention
- Keep in `.claude/agents/` - Rejected: causes duplicate discovery at project level

## Decision 2: Combined vs Separate Install Scripts

**Decision**: Create single combined script `install-claude-config.sh`

**Rationale**:
- User requested combined script for simplicity
- Single command for complete Claude Code configuration
- Reduces onboarding friction (one command instead of two)
- Constitution compliant: creates 1, removes 1 = net zero new scripts

**Alternatives Considered**:
- Keep separate scripts (`install-claude-skills.sh` + `install-claude-agents.sh`) - Rejected: more commands for users
- Extend existing `install-claude-skills.sh` - Rejected: name no longer accurate

## Decision 3: Agent File Discovery Pattern

**Decision**: Install all `*.md` files from `.claude/agent-sources/` to `~/.claude/agents/`

**Rationale**:
- Simple glob pattern covers all 65 agents
- No need to maintain explicit file list (unlike skills which have only 4 files)
- Agents follow naming convention (000-*, 001-*, etc.)

**Alternatives Considered**:
- Explicit array of agent filenames - Rejected: too verbose for 65 files
- Pattern matching by tier (000-*, 001-*, etc.) - Rejected: unnecessary complexity

## Decision 4: User-Level Agent Directory

**Decision**: Install to `~/.claude/agents/`

**Rationale**:
- Verified that Claude Code discovers agents from user-level `~/.claude/agents/`
- Mirrors Claude Code's standard directory structure
- Same pattern as `~/.claude/commands/` for skills

**Verification**:
- Skills consolidation proved this pattern works
- Claude Code documentation confirms user-level discovery

## Prior Art

### Skills Consolidation (004-claude-skills)

The skills consolidation feature established the pattern:

| Aspect | Skills | Agents (this feature) |
|--------|--------|----------------------|
| Source location | `.claude/skill-sources/` | `.claude/agent-sources/` |
| Install target | `~/.claude/commands/` | `~/.claude/agents/` |
| File count | 4 | 65 |
| Install script | `install-claude-skills.sh` | `install-claude-config.sh` (combined) |

### Existing Install Script

Reference: `scripts/install-claude-skills.sh` (116 lines)

Key patterns to reuse:
- Color-coded output (GREEN/YELLOW/RED)
- Source directory verification
- Target directory creation
- File copy loop with counters
- Deprecated file removal
- Summary output

## No Unknowns

All technical questions resolved by prior work. Ready to proceed to implementation.
