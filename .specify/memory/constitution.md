<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 2.0.0 (MAJOR - restructured principles, added governance enforcement)

Modified principles:
- (new) I. Script Consolidation
- (new) II. Branch Preservation
- (new) III. Local-First CI/CD
- (new) IV. Modularity Limits
- (new) V. Symlink Single Source

Added sections:
- Technology Stack (new section)
- Governance (expanded with 4-tier enforcement and amendment process)

Removed sections:
- Generic placeholder sections replaced with project-specific content

Templates requiring updates:
- .specify/templates/plan-template.md: ✅ Already has Constitution Check section (compatible)
- .specify/templates/spec-template.md: ✅ Compatible (no constitution-specific references)
- .specify/templates/tasks-template.md: ✅ Compatible (no constitution-specific references)

Follow-up TODOs: None
-->

# Ghostty Configuration Files Constitution

## Core Principles

### I. Script Consolidation

Enhance existing scripts instead of creating new wrapper/helper scripts. Before ANY new `.sh` file, verify the functionality cannot be added to existing code.

**Enforcement**:
- MUST check if functionality can be added to existing script before creating new file
- MUST NOT create wrapper scripts that call other scripts (max 2-level call depth)
- MUST maintain script baseline (~118 scripts; significant increases require justification)
- Test scripts in `tests/` directory are exempt from this principle

**Rationale**: Prevents codebase sprawl, reduces maintenance burden, avoids script call chains exceeding 2 levels deep.

### II. Branch Preservation

Never delete git branches. Use timestamped naming (`YYYYMMDD-HHMMSS-type-description`). All merges use `--no-ff` to preserve history.

**Enforcement**:
- MUST NOT delete any git branch without explicit user permission
- MUST use timestamped branch naming format: `YYYYMMDD-HHMMSS-type-description`
- MUST use `--no-ff` flag for all merges to preserve branch history
- MUST preserve branches after merge for audit trails and rollback capability

**Rationale**: All branches contain valuable configuration history for audit trails and rollback capability.

### III. Local-First CI/CD

ALL testing runs locally before any GitHub push. Run `.runners-local/workflows/gh-workflow-local.sh all` and `ghostty +show-config` before commits.

**Enforcement**:
- MUST run local CI/CD workflow before any commit affecting configuration
- MUST validate Ghostty configuration with `ghostty +show-config`
- MUST NOT push to GitHub until local validation passes
- MUST achieve zero GitHub Actions cost through local-first testing

**Rationale**: Zero GitHub Actions cost strategy. Ensures validation before remote operations.

### IV. Modularity Limits

No script exceeds 300 lines (hard limit). Extract functions to libraries or split into subcommand modules when approaching limit.

**Enforcement**:
- MUST NOT exceed 300 lines per script file
- MUST extract reusable logic to library functions when approaching limit
- MUST split large scripts into subcommand modules
- SHOULD refactor existing oversized scripts when touched

**Rationale**: Prevents monolithic scripts that are difficult to maintain, test, and understand.

### V. Symlink Single Source

AGENTS.md is the master file for all LLM instructions. CLAUDE.md and GEMINI.md are symlinks that MUST remain symlinks - never convert to regular files.

**Enforcement**:
- MUST edit only `AGENTS.md` for LLM instruction updates
- MUST NOT convert `CLAUDE.md` or `GEMINI.md` symlinks to regular files
- MUST NOT create separate content in symlinked files
- MUST verify symlink integrity after any operation touching these files

**Rationale**: Single source of truth for all LLM instructions across all AI assistants.

## Technology Stack

**Required Versions**:
- Ghostty v1.2.3+ with 2025 CGroup optimizations
- Python: UV-first dependency management (no direct pip)
- Node.js: Latest version via fnm (not LTS)
- Go 1.23+ for TUI components

**Prohibited Patterns**:
- Direct pip usage (use UV instead)
- LTS Node.js versions (use latest via fnm)
- Outdated Ghostty without CGroup optimizations

## Additional Constraints

### Security & Safety

- MUST NOT commit sensitive data (API keys, passwords, credentials)
- MUST NOT delete `docs/.nojekyll` (breaks GitHub Pages CSS/JS)
- MUST obtain user approval for: file deletion, merge to main, >5 file changes, deployments

### Protected Files

| File | Protection Level | Consequence of Violation |
|------|------------------|--------------------------|
| `docs/.nojekyll` | CRITICAL | Breaks all CSS/JS on GitHub Pages |
| `AGENTS.md` | PROTECTED | Single source of truth for LLM instructions |
| `CLAUDE.md` | SYMLINK-ONLY | Must remain symlink to AGENTS.md |
| `GEMINI.md` | SYMLINK-ONLY | Must remain symlink to AGENTS.md |

## Governance

### Amendment Process

- Constitutional violations MUST NOT retry - immediately escalate to user
- Override requires: documented justification + explicit user approval + commit message record
- Monthly audit cycle (24th of month) for compliance review

### Enforcement Layers

| Layer | Type | Trigger |
|-------|------|---------|
| 1 | Pre-commit validation | Automated on every commit |
| 2 | CI/CD gate checks | Automated on workflow run |
| 3 | Monthly audits | Scheduled (24th of month) |
| 4 | User approval gates | On-demand for destructive operations |

### Versioning Policy

- **MAJOR**: Backward incompatible governance/principle removals or redefinitions
- **MINOR**: New principle/section added or materially expanded guidance
- **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements

### Compliance Reference

All PRs and reviews MUST verify compliance with this constitution. Use `AGENTS.md` for runtime development guidance.

**Version**: 2.0.0 | **Ratified**: 2025-11-18 | **Last Amended**: 2026-01-18
