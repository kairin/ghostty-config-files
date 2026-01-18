# Implementation Plan: Claude Agents User-Level Consolidation

**Branch**: `005-claude-agents` | **Date**: 2026-01-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-claude-agents/spec.md`

## Summary

Consolidate 65 Claude Code agents from project-level (`.claude/agents/`) to user-level (`~/.claude/agents/`) following the same pattern established for skills consolidation. Create a combined install script that installs both skills (4) and agents (65) in a single command.

## Technical Context

**Language/Version**: Bash 5.x (Ubuntu default shell)
**Primary Dependencies**: Git (for `git mv`), coreutils (cp, mkdir, rm, ls)
**Storage**: Filesystem (markdown files with YAML frontmatter)
**Testing**: Manual verification via install script execution
**Target Platform**: Ubuntu Linux 24.04+
**Project Type**: Single (shell scripts - no src/ directory needed)
**Performance Goals**: Install 69 files (4 skills + 65 agents) in under 5 seconds
**Constraints**: Must be idempotent, preserve file integrity, follow constitutional principles
**Scale/Scope**: 65 agent files, 4 skill files, 1 combined install script

## Constitution Check

*GATE: ✅ PASSED - All principles satisfied*

### I. Script Consolidation ✅
- **Status**: COMPLIANT
- **Rationale**: Creates 1 new script (`install-claude-config.sh`), removes 1 old script (`install-claude-skills.sh`) = net zero new scripts
- **Call depth**: Single script, no nested calls (depth = 1)

### II. Branch Preservation ✅
- **Status**: COMPLIANT
- **Rationale**: Using timestamped branch naming via SpecKit (`005-claude-agents`)
- **Action**: Will use `--no-ff` for merge to main

### III. Local-First CI/CD ✅
- **Status**: COMPLIANT
- **Rationale**: No CI/CD changes required; script is manually tested
- **Action**: Will run `gh-workflow-local.sh` before final commit

### IV. Modularity Limits ✅
- **Status**: COMPLIANT
- **Rationale**: Install script will be ~100 lines (well under 300 limit)
- **Reference**: Existing `install-claude-skills.sh` is 116 lines

### V. Symlink Single Source ✅
- **Status**: NOT AFFECTED
- **Rationale**: This feature doesn't touch AGENTS.md, CLAUDE.md, or GEMINI.md

### Security & Safety ✅
- **Status**: COMPLIANT
- **Rationale**: No sensitive data involved; no protected files modified
- **User approval**: Will request for merge to main (>5 files changed)

## Project Structure

### Documentation (this feature)

```text
specs/005-claude-agents/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output (no unknowns - minimal)
├── data-model.md        # Phase 1 output (entity definitions)
├── quickstart.md        # Phase 1 output (testing guide)
├── checklists/          # Validation checklists
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Implementation tasks
```

### Source Code (repository root)

```text
# Agent sources (new location - not auto-discovered by Claude Code)
.claude/agent-sources/
├── 000-*.md              # 5 Tier 0 agents (workflow orchestrators)
├── 001-*.md              # 1 Tier 1 agent (Opus orchestrator)
├── 002-*.md              # 5 Tier 2 agents (domain operations)
├── 003-*.md              # 4 Tier 3 agents (utility/support)
└── 0XX-*.md              # 50 Tier 4 agents (atomic execution)
    ├── 021-*.md          # 7 Git tasks
    ├── 022-*.md          # 5 Astro tasks
    ├── 023-*.md          # 7 Cleanup tasks
    ├── 024-*.md          # 6 Compliance tasks
    ├── 025-*.md          # 6 Health tasks
    ├── 031-*.md          # 6 CI/CD tasks
    ├── 032-*.md          # 5 Documentation tasks
    ├── 033-*.md          # 5 Symlink tasks
    └── 034-*.md          # 3 Workflow template tasks

# Skill sources (existing - already migrated in previous work)
.claude/skill-sources/
├── 001-health-check.md
├── 001-deploy-site.md
├── 001-git-sync.md
└── 001-full-workflow.md

# Install scripts
scripts/
├── install-claude-config.sh   # NEW: Combined installer (skills + agents)
└── install-claude-skills.sh   # REMOVE: Superseded by combined script

# User-level installation targets (not in repo)
~/.claude/
├── agents/               # 65 installed agents
└── commands/             # 4 installed skills
```

**Structure Decision**: Shell script pattern following established `install-claude-skills.sh` as template. Source files in `.claude/*-sources/` directories, install script copies to user-level `~/.claude/` directories.

## Complexity Tracking

No constitution violations. This feature follows the established skills consolidation pattern exactly.

## Implementation Phases

### Phase 1: Setup
- Create `.claude/agent-sources/` directory
- Verify `.claude/skill-sources/` exists with 4 files

### Phase 2: Migration
- Move 65 agent files from `.claude/agents/` to `.claude/agent-sources/` using `git mv`
- Verify all files moved successfully
- Verify `.claude/agents/` is empty

### Phase 3: Combined Install Script
- Create `scripts/install-claude-config.sh` based on existing skills installer
- Add skills installation (4 files from `.claude/skill-sources/`)
- Add agents installation (65 files from `.claude/agent-sources/`)
- Add deprecated file cleanup
- Add installation summary output

### Phase 4: Cleanup
- Remove old `scripts/install-claude-skills.sh`
- Update documentation references

### Phase 5: Verification
- Run combined install script
- Verify user-level installation (4 skills + 65 agents)
- Test agent availability in Claude Code
- Commit all changes

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Agent files not discovered at user level | Low | High | Verified behavior in skills consolidation |
| Git history lost during move | Low | Medium | Use `git mv` to preserve history |
| Install script fails mid-execution | Low | Medium | Idempotent design - safe to re-run |
| Custom user agents overwritten | Low | Low | Script only manages project agents |

## Dependencies

- **Prerequisite**: Skills consolidation complete (done - branch `004-claude-skills`)
- **Blocking**: None - this work can proceed immediately
- **Downstream**: TUI integration (future - out of scope)
