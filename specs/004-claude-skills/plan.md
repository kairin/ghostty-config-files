# Implementation Plan: Claude Code Workflow Skills

**Branch**: `004-claude-skills` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-claude-skills/spec.md`

## Summary

Create 4 Claude Code slash command skills (`/health-check`, `/deploy-site`, `/git-sync`, `/full-workflow`) that wrap existing local CI/CD infrastructure. Skills are markdown files with YAML frontmatter defining handoffs and instructions. Project detection enables full features in ghostty-config-files and basic features elsewhere.

## Technical Context

**Language/Version**: Markdown with YAML frontmatter (Claude Code skill format)
**Primary Dependencies**: Existing shell scripts (health-check.sh, astro-build-local.sh, gh-cli-integration.sh, gh-workflow-local.sh)
**Storage**: N/A (no data persistence)
**Testing**: Manual verification - run each skill and verify output
**Target Platform**: Claude Code CLI v2.1.0+ (hot-reload compatible)
**Project Type**: Configuration/tooling (markdown skill files + install script)
**Performance Goals**: `/health-check` <30s, other skills determined by underlying scripts
**Constraints**: Wrap existing scripts only (no new .sh files per constitution)
**Scale/Scope**: 4 skill files + 1 install script

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Script Consolidation

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Check if functionality can be added to existing script | PASS | Skills wrap existing scripts, no new logic |
| No wrapper scripts calling other scripts (max 2-level depth) | PASS | Skills invoke scripts directly (1 level) |
| Maintain script baseline (~118 scripts) | PASS | Adding 1 install script only |
| Test scripts in tests/ exempt | N/A | No test scripts created |

### II. Branch Preservation

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Never delete branches | PASS | `/git-sync` explicitly blocks branch deletion |
| Timestamped branch naming | PASS | FR-033 requires validation of format |
| Use --no-ff for merges | INFO | Skills don't perform merges directly |

### III. Local-First CI/CD

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Run local CI/CD before commits | PASS | `/full-workflow` enforces this (FR-041, FR-042) |
| Validate Ghostty configuration | PASS | Health check validates environment |
| Zero GitHub Actions cost | PASS | All validation runs locally |

### IV. Modularity Limits

| Requirement | Status | Evidence |
|-------------|--------|----------|
| No script exceeds 300 lines | PASS | Skill files are ~50-100 lines each |
| Install script within limits | PASS | Simple copy operations <50 lines |

### V. Symlink Single Source

| Requirement | Status | Evidence |
|-------------|--------|----------|
| AGENTS.md is master file | N/A | Not modifying LLM instructions |
| Symlinks remain symlinks | N/A | Not touching CLAUDE.md/GEMINI.md |

**GATE RESULT: PASS** - No constitutional violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/004-claude-skills/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (skill schema)
├── quickstart.md        # Phase 1 output (usage guide)
├── contracts/           # Phase 1 output (skill interface)
│   └── skill-schema.yaml
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
.claude/commands/
├── health-check.md      # NEW - system diagnostics skill
├── deploy-site.md       # NEW - Astro deployment skill
├── git-sync.md          # NEW - git synchronization skill
└── full-workflow.md     # NEW - orchestration skill

scripts/
└── install-claude-skills.sh  # NEW - installer to ~/.claude/commands/
```

**Structure Decision**: Skills go in `.claude/commands/` (project-level templates). Install script copies to `~/.claude/commands/` (user-level for global availability). No src/ directory needed - this is configuration/tooling only.

## Complexity Tracking

No constitutional violations requiring justification. Design is minimal:
- 4 markdown files (skills)
- 1 shell script (installer)
- Wraps existing infrastructure without modification
