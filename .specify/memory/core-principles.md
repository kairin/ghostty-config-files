# Core Constitutional Principles

This document contains the 6 fundamental, non-negotiable principles that govern all development work in the Ghostty Configuration Files project.

## I. Branch Preservation & Git Strategy

**NEVER DELETE BRANCHES** without explicit user permission. All branches contain valuable configuration history. Branches must be merged to main but preserved after merge.

**Branch Naming Format** (MANDATORY): `YYYYMMDD-HHMMSS-type-short-description`

**Examples**:
- `20250919-143000-feat-context-menu-integration`
- `20250919-143515-fix-performance-optimization`
- `20250919-144030-docs-agents-enhancement`

**Git Workflow**:
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-description"
git checkout -b "$BRANCH_NAME"
git add .
git commit -m "Descriptive message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
# NEVER: git branch -d "$BRANCH_NAME"
```

**Rationale**: Branch preservation maintains complete development history for configuration debugging, regression analysis, and architectural decision archaeology. The datetime-based naming provides chronological ordering and prevents naming conflicts in multi-developer scenarios.

**Detailed Guide**: [git-strategy.md](git-strategy.md)

---

## II. GitHub Pages Infrastructure Protection

**`.nojekyll` File is ABSOLUTELY CRITICAL**. This file MUST exist in the Astro build output directory to disable Jekyll processing and allow `_astro/` directory assets to load correctly.

**Location**: `docs/.nojekyll` (empty file, no content needed)

**Impact Without This File**: ALL CSS/JS assets return 404 errors, breaking the entire site.

**Protection Layers**:
- Primary: Astro `public/` directory (automatic copy to build output)
- Secondary: Vite plugin automation (implemented in astro.config.mjs)
- Tertiary: Post-build validation scripts
- Quaternary: Pre-commit git hooks

**Rationale**: GitHub Pages defaults to Jekyll processing which ignores directories starting with underscore. Astro outputs assets to `_astro/`, requiring Jekyll to be disabled via `.nojekyll` file. This is a GitHub Pages technical requirement with no alternative solution.

**Detailed Guide**: [github-pages-infrastructure.md](github-pages-infrastructure.md)

---

## III. Local CI/CD First

**EVERY configuration change MUST complete local validation BEFORE any GitHub deployment**. This ensures zero GitHub Actions consumption and prevents production failures.

**Pre-Deployment Verification Steps**:
1. Run local workflow: `./.runners-local/workflows/gh-workflow-local.sh local`
2. Verify build success: `./.runners-local/workflows/gh-workflow-local.sh status`
3. Test configuration: `ghostty +show-config && ./scripts/check_updates.sh`
4. Only then proceed with git workflow

**Rationale**: Local CI/CD validation prevents consuming GitHub Actions minutes (staying within free tier), enables rapid iteration without network latency, and catches configuration errors before they reach production. Performance target: <2 minutes for complete local workflow execution.

**Detailed Guide**: [local-cicd.md](local-cicd.md)

---

## IV. Agent File Integrity

**Single Source of Truth**: `AGENTS.md` is the authoritative LLM instructions file containing all non-negotiable requirements.

**Symlink Structure** (MANDATORY):
- `AGENTS.md` - Regular file (single source of truth)
- `CLAUDE.md` - Symlink to AGENTS.md (Claude Code integration)
- `GEMINI.md` - Symlink to AGENTS.md (Gemini CLI integration)

**NEVER**:
- Split AGENTS.md into multiple files without maintaining symlink integrity
- Convert AGENTS.md symlinks to regular files
- Create agent-specific divergent instructions

**Documentation Migration**:
- Content may be COPIED from AGENTS.md to website/src/ for Astro site
- AGENTS.md remains intact as single source
- Symlinks continue pointing to AGENTS.md (not to website/src/)

**Rationale**: Symlink structure ensures all AI assistants (Claude, Gemini, future additions) receive identical instructions, preventing configuration drift and contradictory guidance. Single source of truth simplifies updates and guarantees consistency.

**Detailed Guide**: [agent-file-integrity.md](agent-file-integrity.md)

---

## V. LLM Conversation Logging

**All AI assistants working on this repository MUST save complete conversation logs** with system state snapshots for debugging and continuity.

**Requirements**:
- Complete logs: Save entire conversation from start to finish
- Exclude sensitive data: Remove API keys, passwords, personal information
- Storage location: `documentations/development/conversation_logs/`
- Naming convention: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- System state: Capture before/after system states
- CI/CD logs: Include local workflow execution logs

**Rationale**: Conversation logs provide debugging context for configuration issues, enable session continuity across interruptions, and document architectural decisions for future reference. System state snapshots facilitate root cause analysis and regression debugging.

**Detailed Guide**: [conversation-logging.md](conversation-logging.md)

---

## VI. Zero-Cost Operations

**No GitHub Actions minutes consumed for routine operations**. All CI/CD workflows execute locally before any GitHub interaction.

**Cost Monitoring Commands**:
```bash
# Check usage
gh api user/settings/billing/actions

# Monitor workflows
gh run list --limit 10 --json status,conclusion,name,createdAt

# Verify compliance
./.runners-local/workflows/gh-pages-setup.sh
```

**Performance Targets**:
- Startup time: <500ms for new Ghostty instance (CGroup optimization)
- Memory usage: <100MB baseline with optimized scrollback
- CI/CD performance: <2 minutes for complete local workflow
- Configuration validity: 100% successful validation rate

**Rationale**: Free tier GitHub Actions provides 2,000 minutes/month. Local-first approach prevents accidental consumption, enables offline development, and provides immediate feedback without network dependency.

**Detailed Guide**: [zero-cost-operations.md](zero-cost-operations.md)

---

**Version**: 1.2.0
**Last Updated**: 2025-11-16
**Authority**: AGENTS.md (single source of truth)
