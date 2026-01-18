# Research: Claude Code Workflow Skills

**Feature**: 004-claude-skills
**Date**: 2026-01-18
**Status**: Complete

## Research Summary

No NEEDS CLARIFICATION items in Technical Context. All technical decisions are straightforward based on existing infrastructure and Claude Code skill format.

## Decisions

### 1. Skill File Format

**Decision**: Markdown with YAML frontmatter (standard Claude Code skill format)

**Rationale**:
- Existing `full-git-workflow.md` in `~/.claude/commands/` demonstrates the format
- YAML frontmatter for metadata (description, handoffs)
- Markdown body for instructions and workflow steps

**Alternatives Considered**:
- JSON format: Rejected - not supported by Claude Code
- Pure markdown: Rejected - needs structured metadata

### 2. Handoff Implementation

**Decision**: Use YAML `handoffs` array in frontmatter with `label` and `prompt` fields

**Rationale**:
- Claude Code v2.1.0+ supports handoff buttons
- Enables smooth workflow progression between skills
- Example format:
  ```yaml
  handoffs:
    - label: "Deploy Site"
      prompt: "Run /deploy-site"
  ```

**Alternatives Considered**:
- Text-based handoff suggestions: Rejected - less interactive
- No handoffs: Rejected - contradicts spec requirements (FR-003)

### 3. Project Detection Strategy

**Decision**: Check for `.runners-local/` directory or `AGENTS.md` file

**Rationale**:
- These markers are unique to ghostty-config-files project
- Enables graceful degradation in other projects
- Simple bash test: `[ -d ".runners-local" ] || [ -f "AGENTS.md" ]`

**Alternatives Considered**:
- Check git remote URL: Rejected - fragile if remote changes
- Check package.json name: Rejected - not present in all directories
- Environment variable: Rejected - requires manual setup

### 4. Existing Skill Replacement

**Decision**: New `/git-sync` replaces `full-git-workflow.md`

**Rationale**:
- Spec clarification (Session 2026-01-18): "Replace - new `/git-sync` supersedes `full-git-workflow`"
- Install script will remove old skill from `~/.claude/commands/`
- New skill is more focused (sync only, not commit workflow)

**Alternatives Considered**:
- Keep both: Rejected - overlap causes confusion
- Rename only: Rejected - functionality differs

### 5. Script Integration Approach

**Decision**: Skills execute scripts via bash commands, not imports

**Rationale**:
- Claude Code runs bash commands natively
- Scripts are already tested and functional
- No code duplication needed

**Alternatives Considered**:
- Inline script logic: Rejected - violates script consolidation principle
- Source scripts: Rejected - unnecessary complexity

## Best Practices Applied

### Claude Code Skills

1. **Hot-reload compatibility**: Skills reload without Claude Code restart (v2.1.0+)
2. **Structured output**: Skills should report structured summaries (PASS/FAIL/WARNING)
3. **Error handling**: Skills should provide clear error messages with remediation
4. **Constitutional compliance**: Skills enforce project rules (no branch deletion, local CI/CD first)

### Shell Script Integration

1. **Exit codes**: Check script exit codes for pass/fail determination
2. **Output capture**: Capture and parse script output for metrics
3. **Timeout handling**: Health check must complete in <30 seconds

## Dependencies Verified

| Script | Path | Status | Notes |
|--------|------|--------|-------|
| health-check.sh | `.runners-local/workflows/` | Exists (29KB) | Full diagnostics |
| astro-build-local.sh | `.runners-local/workflows/` | Exists (14KB) | Build workflow |
| astro-complete-workflow.sh | `.runners-local/workflows/` | Exists (1.8KB) | Deploy workflow |
| gh-cli-integration.sh | `.runners-local/workflows/` | Exists (8KB) | Git operations |
| gh-workflow-local.sh | `.runners-local/workflows/` | Exists (34KB) | CI/CD orchestrator |

All dependencies exist and are functional.
