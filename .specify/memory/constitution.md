# Ghostty Configuration Files - Project Constitution

<!--
Sync Impact Report (2025-10-27):
  Version: 1.0.0 (Initial constitution ratification)
  Derived from: AGENTS.md (project root, single source of truth)

  Principles Extracted:
    I. Branch Preservation & Git Strategy
    II. GitHub Pages Infrastructure Protection
    III. Local CI/CD First
    IV. Agent File Integrity (CRITICAL: symlink requirement)
    V. LLM Conversation Logging
    VI. Zero-Cost Operations

  Template Sync Status:
    ✅ plan-template.md: Constitution Check section aligned
    ✅ spec-template.md: Requirements validation aligned
    ✅ tasks-template.md: Task categorization aligned
    ✅ commands/*.md: Agent-specific references verified

  Critical Fixes Applied:
    ✅ CLAUDE.md converted from regular file to symlink → AGENTS.md
    ✅ AGENTS.md updated with Active Technologies and Recent Changes sections
    ✅ GEMINI.md symlink verified (already correct)

  Follow-up Actions Required:
    - Update specs/001-repo-structure-refactor/spec.md FR-011 to clarify AGENTS.md remains intact
    - Update specs/001-repo-structure-refactor/tasks.md T034 to specify content COPY (not split) to docs-source/
-->

## Core Principles

### I. Branch Preservation & Git Strategy (NON-NEGOTIABLE)

**NEVER DELETE BRANCHES** without explicit user permission. All branches contain valuable configuration history. Branches must be merged to main but preserved after merge.

**Branch Naming Format** (MANDATORY): `YYYYMMDD-HHMMSS-type-short-description`

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

### II. GitHub Pages Infrastructure Protection (NON-NEGOTIABLE)

**`.nojekyll` File is ABSOLUTELY CRITICAL**. This file MUST exist in the Astro build output directory to disable Jekyll processing and allow `_astro/` directory assets to load correctly.

**Location**: `docs/.nojekyll` (empty file, no content needed)

**Impact Without This File**: ALL CSS/JS assets return 404 errors, breaking the entire site.

**Protection Protocol**:
- Primary: Astro `public/` directory (automatic copy to build output)
- Secondary: Vite plugin automation (implemented in astro.config.mjs)
- Tertiary: Post-build validation scripts
- Quaternary: Pre-commit git hooks

**Rationale**: GitHub Pages defaults to Jekyll processing which ignores directories starting with underscore. Astro outputs assets to `_astro/`, requiring Jekyll to be disabled via `.nojekyll` file. This is a GitHub Pages technical requirement with no alternative solution.

### III. Local CI/CD First (MANDATORY)

**EVERY configuration change MUST complete local validation BEFORE any GitHub deployment**. This ensures zero GitHub Actions consumption and prevents production failures.

**Pre-Deployment Verification Steps**:
1. Run local workflow: `./local-infra/runners/gh-workflow-local.sh local`
2. Verify build success: `./local-infra/runners/gh-workflow-local.sh status`
3. Test configuration: `ghostty +show-config && ./scripts/check_updates.sh`
4. Only then proceed with git workflow

**Local Workflow Tools**:
- `./local-infra/runners/gh-workflow-local.sh` - Local GitHub Actions simulation
- `./local-infra/runners/gh-pages-setup.sh` - Zero-cost Pages configuration
- Commands: `local`, `status`, `trigger`, `pages`, `all`

**Rationale**: Local CI/CD validation prevents consuming GitHub Actions minutes (staying within free tier), enables rapid iteration without network latency, and catches configuration errors before they reach production. Performance target: <2 minutes for complete local workflow execution.

### IV. Agent File Integrity (CRITICAL SYMLINK REQUIREMENT)

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
- Content may be COPIED from AGENTS.md to docs-source/ for Astro site
- AGENTS.md remains intact as single source
- Symlinks continue pointing to AGENTS.md (not to docs-source/)

**Rationale**: Symlink structure ensures all AI assistants (Claude, Gemini, future additions) receive identical instructions, preventing configuration drift and contradictory guidance. Single source of truth simplifies updates and guarantees consistency.

### V. LLM Conversation Logging (MANDATORY)

**All AI assistants working on this repository MUST save complete conversation logs** with system state snapshots for debugging and continuity.

**Requirements**:
- Complete logs: Save entire conversation from start to finish
- Exclude sensitive data: Remove API keys, passwords, personal information
- Storage location: `documentations/development/conversation_logs/`
- Naming convention: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- System state: Capture before/after system states
- CI/CD logs: Include local workflow execution logs

**Rationale**: Conversation logs provide debugging context for configuration issues, enable session continuity across interruptions, and document architectural decisions for future reference. System state snapshots facilitate root cause analysis and regression debugging.

### VI. Zero-Cost Operations (MANDATORY)

**No GitHub Actions minutes consumed for routine operations**. All CI/CD workflows execute locally before any GitHub interaction.

**Cost Monitoring**:
```bash
# Check usage
gh api user/settings/billing/actions

# Monitor workflows
gh run list --limit 10 --json status,conclusion,name,createdAt

# Verify compliance
./local-infra/runners/gh-pages-setup.sh
```

**Performance Targets**:
- Startup time: <500ms for new Ghostty instance (CGroup optimization)
- Memory usage: <100MB baseline with optimized scrollback
- CI/CD performance: <2 minutes for complete local workflow
- Configuration validity: 100% successful validation rate

**Rationale**: Free tier GitHub Actions provides 2,000 minutes/month. Local-first approach prevents accidental consumption, enables offline development, and provides immediate feedback without network dependency.

## Additional Constraints

### Technology Stack (NON-NEGOTIABLE)

**Terminal Environment**:
- Ghostty: Latest from source (Zig 0.14.0) with 2025 optimizations
- ZSH: Oh My ZSH with productivity plugins
- Context Menu: Nautilus integration

**AI Integration**:
- Claude Code: Latest CLI via npm
- Gemini CLI: Google's AI assistant with Ptyxis integration
- Node.js: Latest LTS via NVM

**Local CI/CD**:
- GitHub CLI: For workflow simulation and API access
- Local Runners: Shell-based workflow execution
- Performance Monitoring: System state and timing analysis

### Documentation Structure (CONSTITUTIONAL REQUIREMENT)

- `docs/` - Astro.build output ONLY → GitHub Pages deployment (DO NOT manually edit)
- `documentations/` - All other documentation → installation guides, screenshots, manuals, specs
- `specs/` - Feature specifications with planning artifacts

### Directory Nesting Limit

Maximum 2 levels of nesting from repository root to maintain simplicity for configuration projects. Top-level directories limited to 4-5 to prevent organizational complexity.

## Quality Gates

### Before Every Configuration Change

1. **Local CI/CD Execution**: Run `./local-infra/runners/gh-workflow-local.sh all`
2. **Configuration Validation**: Run `ghostty +show-config` to ensure validity
3. **Performance Testing**: Execute `./local-infra/runners/performance-monitor.sh`
4. **Backup Creation**: Automatic timestamped backup of existing configuration
5. **User Preservation**: Extract and preserve user customizations
6. **Documentation**: Update relevant docs if adding features
7. **Conversation Log**: Save complete AI conversation log with system state

### Validation Criteria

- Local CI/CD workflows execute successfully
- Configuration validates without errors via `ghostty +show-config`
- All 2025 performance optimizations present and functional
- User customizations preserved and functional
- Context menu integration works correctly
- GitHub Actions usage remains within free tier limits
- All logging systems capture complete information

## Absolute Prohibitions

### DO NOT

- **NEVER REMOVE `docs/.nojekyll`** - This breaks ALL CSS/JS loading on GitHub Pages
- Delete branches without explicit user permission
- Use GitHub Actions for anything that consumes minutes
- Skip local CI/CD validation before GitHub deployment
- Ignore existing user customizations during updates
- Apply configuration changes without backup
- Commit sensitive data (API keys, passwords, personal information)
- Bypass the intelligent update system for configuration changes
- Remove Jekyll-related files without verifying `.nojekyll` preservation
- Convert CLAUDE.md or GEMINI.md from symlinks to regular files

### DO NOT BYPASS

- Branch preservation requirements
- Local CI/CD execution requirements
- Zero-cost operation constraints
- Configuration validation steps
- User customization preservation
- Logging and debugging requirements
- Agent file symlink integrity

## Governance

### Amendment Process

1. **Proposal**: Document proposed constitutional change with rationale
2. **Impact Analysis**: Assess impact on existing workflows, templates, and artifacts
3. **Template Sync**: Update plan-template.md, spec-template.md, tasks-template.md
4. **Version Increment**: Semantic versioning (MAJOR.MINOR.PATCH)
5. **Propagation**: Update dependent documentation (README, quickstart, agent files)
6. **Validation**: Run full local CI/CD to verify no breakage
7. **Ratification**: Merge via standard git workflow with constitution amendment commit message

### Versioning Policy

- **MAJOR**: Backward incompatible principle removals or redefinitions
- **MINOR**: New principle/section added or materially expanded guidance
- **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements

### Compliance Review

All PRs/reviews must verify constitutional compliance before merge. Complexity additions must be justified in spec.md "Complexity Tracking" section. Use AGENTS.md (project root) for runtime development guidance.

### Supersedence

This constitution supersedes all other practices except explicit project requirements in spec.md files. When conflicts arise, constitutional principles take precedence unless explicitly justified in "Complexity Tracking" section of the spec.

---

**Version**: 1.0.0
**Ratified**: 2025-10-27
**Last Amended**: 2025-10-27
**Authority**: AGENTS.md (single source of truth)
**Status**: ACTIVE - MANDATORY COMPLIANCE
