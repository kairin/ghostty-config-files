# Implementation Plan: Wave 1 - Scripts Documentation Foundation

**Branch**: `002-scripts-documentation` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-scripts-documentation/spec.md`

## Summary

Create comprehensive documentation for the scripts directory (114 scripts across 11 directories), consolidate 5 overlapping MCP guides into a single authoritative source, and fix inaccurate AI tools documentation. This is documentation-only work with no script modifications.

## Technical Context

**Language/Version**: Markdown (GitHub Flavored)
**Primary Dependencies**: None (documentation only)
**Storage**: N/A
**Testing**: Manual verification (file existence, link validation)
**Target Platform**: Documentation for Ubuntu Linux environment
**Project Type**: Documentation enhancement
**Performance Goals**: Script discovery in <30 seconds via README lookup
**Constraints**: Follow existing documentation patterns, no emojis unless present in existing docs
**Scale/Scope**: 114 scripts, 5 MCP guides → 1, 1 doc fix

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Script Consolidation | ✅ PASS | No scripts being created (docs only) |
| II. Branch Preservation | ✅ PASS | Using feature branch `002-scripts-documentation` |
| III. Local-First CI/CD | ✅ PASS | No config changes requiring CI/CD |
| IV. Modularity Limits | ✅ PASS | Documentation files, not scripts |
| V. Symlink Single Source | ✅ PASS | Not touching AGENTS.md symlinks |

**Protected Files Check**:
- `docs/.nojekyll` - NOT TOUCHED
- `AGENTS.md` - NOT TOUCHED (may update references in modular docs)
- `CLAUDE.md` / `GEMINI.md` - NOT TOUCHED

**Governance**: Documentation changes do not require user approval (no destructive operations)

## Project Structure

### Documentation (this feature)

```text
specs/002-scripts-documentation/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── checklists/
│   └── requirements.md  # Spec quality checklist (complete)
└── tasks.md             # Task breakdown (via /speckit.tasks)
```

### Files to Create/Modify

```text
# NEW FILES (4 total)
scripts/README.md                           # P1: Master index (114 scripts)
scripts/007-update/README.md                # P3: Update scripts documentation
scripts/007-diagnostics/README.md           # P4: Boot diagnostics documentation
.claude/instructions-for-agents/guides/mcp-setup.md  # P2: Consolidated MCP guide

# MODIFIED FILES (5 total)
.claude/instructions-for-agents/guides/context7-mcp.md     # Redirect to mcp-setup.md
.claude/instructions-for-agents/guides/github-mcp.md       # Redirect to mcp-setup.md
.claude/instructions-for-agents/guides/markitdown-mcp.md   # Redirect to mcp-setup.md
.claude/instructions-for-agents/guides/playwright-mcp.md   # Redirect to mcp-setup.md
.claude/instructions-for-agents/tools/ai-cli-tools.md      # P5: Fix "not created" claims
```

## Implementation Phases

### Phase 1: Scripts Master Index (P1) - Highest Priority

**Deliverable**: `/scripts/README.md`

**Approach**:
1. Enumerate all 114 scripts using `find scripts/ -name "*.sh"`
2. Group by stage directory (000-007, mcp, vhs, root)
3. Extract descriptions from script headers (first comment block)
4. Create searchable markdown table format

**Structure**:
```markdown
# Scripts Directory Index
## Overview
- Total: 114 scripts
- Stage directories: 000-check through 007-update
- Special directories: mcp/, vhs/
- Root scripts: check_updates.sh, daily-updates.sh, etc.

## Stage Directory Reference
| Stage | Purpose | Script Count |
|-------|---------|--------------|
| 000-check | Tool presence detection | ~14 |
| 001-uninstall | Clean removal | ~13 |
| ...

## Scripts by Category
### 000-check - Detection Scripts
| Script | Purpose |
|--------|---------|
| check_ghostty.sh | Detect Ghostty installation method |
| ...

[Continue for all stages]

## Quick Reference
- Update a tool: `scripts/007-update/update_<tool>.sh`
- Check if installed: `scripts/000-check/check_<tool>.sh`
- Uninstall: `scripts/001-uninstall/uninstall_<tool>.sh`
```

### Phase 2: MCP Documentation Consolidation (P2)

**Deliverable**: Consolidated guide + redirects

**Current State**:
- `mcp-new-machine-setup.md` (324 lines) - comprehensive, already exists
- `context7-mcp.md` (123 lines) - server-specific details
- `github-mcp.md` (170 lines) - server-specific details
- `markitdown-mcp.md` (132 lines) - server-specific details
- `playwright-mcp.md` (233 lines) - server-specific details

**Strategy**:
1. Use `mcp-new-machine-setup.md` as the base (rename to `mcp-setup.md`)
2. Merge unique content from individual guides into expandable sections
3. Convert individual guides to redirect stubs pointing to main guide
4. Update any references in AGENTS.md modular docs

**Redirect Stub Format**:
```markdown
# [Server Name] MCP Setup

> **This guide has been consolidated.**
> See: [MCP Setup Guide](./mcp-setup.md#server-name)

[Brief 2-3 line summary for quick reference]
```

### Phase 3: Update Scripts Documentation (P3)

**Deliverable**: `/scripts/007-update/README.md`

**Content**:
```markdown
# Update Scripts

Scripts for updating installed tools to latest versions.

## Available Update Scripts

| Script | Tool | Method |
|--------|------|--------|
| update_ghostty.sh | Ghostty | snap refresh or source rebuild |
| update_nodejs.sh | Node.js | fnm install latest |
| ... (12 total)

## Usage

### Manual Update
```bash
./scripts/007-update/update_<tool>.sh
```

### Batch Update (via daily-updates.sh)
```bash
./scripts/daily-updates.sh
```

## Logging
- Logs written to: `~/.local/share/ghostty-updates/logs/`
- View logs: `update-logs` alias

## Troubleshooting
[Common issues and solutions]
```

### Phase 4: Boot Diagnostics Documentation (P4)

**Deliverable**: `/scripts/007-diagnostics/README.md`

**Content**:
```markdown
# Boot Diagnostics

System health checks and diagnostic tools.

## Directory Structure
```
007-diagnostics/
├── boot_diagnostics.sh  # Full system diagnostic
├── quick_scan.sh        # Fast health check
├── detectors/           # Individual detection modules
└── lib/                 # Shared diagnostic utilities
```

## Usage

### Quick Scan
```bash
./scripts/007-diagnostics/quick_scan.sh
```

### Full Diagnostics
```bash
./scripts/007-diagnostics/boot_diagnostics.sh
```

## What Gets Checked
[List of diagnostic checks]
```

### Phase 5: AI Tools Documentation Fix (P5)

**Deliverable**: Updated `ai-cli-tools.md`

**Changes Required**:
1. Update status from "PLANNED - Installation scripts not yet implemented" to "IMPLEMENTED"
2. Update scripts table to show existing paths:
   - `scripts/004-reinstall/install_ai_tools.sh` ✅
   - `scripts/001-uninstall/uninstall_ai_tools.sh` ✅
   - `scripts/005-confirm/confirm_ai_tools.sh` ✅
   - `scripts/007-update/update_ai_tools.sh` ✅
3. Remove "Missing Scripts" section or update to reflect reality
4. Update "Last Updated" date

## Verification Plan

### Per-Deliverable Verification

| Deliverable | Verification Method |
|-------------|---------------------|
| scripts/README.md | Count scripts in README matches `find scripts/ -name "*.sh" \| wc -l` |
| mcp-setup.md | Follow guide on hypothetical fresh system (manual review) |
| 007-update/README.md | All 12 update scripts listed |
| 007-diagnostics/README.md | Both scripts and subdirectories documented |
| ai-cli-tools.md | All 4 script paths resolve to existing files |

### Link Validation

```bash
# Check all internal links resolve
grep -roh '\[.*\](\..*\.md)' specs/002-scripts-documentation/ | \
  sed 's/.*(\(.*\))/\1/' | \
  while read link; do test -f "$link" || echo "BROKEN: $link"; done
```

### Final Checklist

- [ ] All new README files created
- [ ] MCP guides consolidated with redirects
- [ ] ai-cli-tools.md reflects current state
- [ ] No broken internal links
- [ ] Documentation follows existing patterns (headers, tables, code blocks)

## Complexity Tracking

> No constitution violations - documentation-only work

| Aspect | Complexity | Rationale |
|--------|------------|-----------|
| Scripts README | Medium | 114 scripts to catalog, but mechanical |
| MCP Consolidation | Medium | Merge 5 files preserving all unique content |
| Update/Diagnostics READMEs | Low | Small focused documents |
| AI Tools Fix | Low | Simple text updates |

## Dependencies

```
P1 (Scripts README) ──┐
                      ├──► Can be parallelized
P2 (MCP Consolidation)┘

P3 (007-update README) ──┐
                         ├──► Can be parallelized
P4 (007-diagnostics README)┘

P5 (AI Tools Fix) ──► Independent, can run anytime
```

## Estimated Effort

| Task | Estimate | Notes |
|------|----------|-------|
| P1: Scripts README | 1 hour | Mechanical enumeration |
| P2: MCP Consolidation | 2 hours | Careful content merge |
| P3: 007-update README | 30 min | 12 scripts to document |
| P4: 007-diagnostics README | 30 min | Small directory |
| P5: AI Tools Fix | 15 min | Simple text updates |
| **Total** | ~4.5 hours | Matches ROADMAP estimate |
