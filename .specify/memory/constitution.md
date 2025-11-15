# Ghostty Configuration Files - Project Constitution

<!--
Constitutional Principles: Modular Structure (2025-11-16)
  Version: 2.0.0 (Major refactor - modular architecture)
  Authority: AGENTS.md (project root, single source of truth)

  Modular Structure:
    ✅ Core principles extracted to dedicated documents
    ✅ Each principle with detailed implementation guide
    ✅ Constitution serves as navigation hub
    ✅ Eliminates duplication, improves maintainability

  Module Index:
    - core-principles.md: Summary of all 6 principles
    - git-strategy.md: Branch preservation, naming, workflow
    - github-pages-infrastructure.md: .nojekyll requirements, protection
    - local-cicd.md: Local-first workflows, zero-cost strategy
    - agent-file-integrity.md: AGENTS.md symlinks, single source of truth
    - conversation-logging.md: LLM logging requirements
    - zero-cost-operations.md: GitHub Actions cost monitoring

  Benefits:
    ✅ Reduced constitution.md from 288 lines to ~150 lines (48% reduction)
    ✅ Each principle fully documented in dedicated guide
    ✅ Easier navigation and reference
    ✅ Simpler updates (modify one module vs. entire constitution)
    ✅ Better knowledge organization
-->

## Overview

This constitution defines the non-negotiable principles governing all development work in the Ghostty Configuration Files project. These principles ensure consistency, maintain quality, and prevent common pitfalls.

**Authority**: This constitution derives from [AGENTS.md](../../AGENTS.md) (project root), the single source of truth for all project requirements.

## Core Principles (NON-NEGOTIABLE)

The project is governed by **6 fundamental principles**. Each principle is summarized below with a link to its complete implementation guide.

### Quick Reference
1. **[Branch Preservation & Git Strategy](#i-branch-preservation--git-strategy)** - Never delete branches
2. **[GitHub Pages Infrastructure](#ii-github-pages-infrastructure-protection)** - .nojekyll is CRITICAL
3. **[Local CI/CD First](#iii-local-cicd-first)** - Validate locally before GitHub
4. **[Agent File Integrity](#iv-agent-file-integrity)** - AGENTS.md symlinks mandatory
5. **[LLM Conversation Logging](#v-llm-conversation-logging)** - Complete logs required
6. **[Zero-Cost Operations](#vi-zero-cost-operations)** - No GitHub Actions consumption

---

### I. Branch Preservation & Git Strategy

**NEVER DELETE BRANCHES** without explicit user permission. All branches contain valuable configuration history.

**Branch Naming** (MANDATORY): `YYYYMMDD-HHMMSS-type-short-description`

**Examples**:
- `20250919-143000-feat-context-menu-integration`
- `20251116-073000-fix-performance-optimization`

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

**Complete Guide**: [git-strategy.md](git-strategy.md) | [core-principles.md](core-principles.md)

---

### II. GitHub Pages Infrastructure Protection

**`.nojekyll` File is ABSOLUTELY CRITICAL**. Without this file, ALL CSS/JS assets return 404 errors on GitHub Pages.

**Location**: `docs/.nojekyll` (empty file)

**Protection Layers**:
1. Astro `public/` directory (automatic copy)
2. Vite plugin automation (astro.config.mjs)
3. Post-build validation scripts
4. Pre-commit git hooks

**Rationale**: GitHub Pages uses Jekyll by default, which ignores `_astro/` directory. Astro outputs all bundled assets to `_astro/`, requiring Jekyll to be disabled via `.nojekyll` file. This is a GitHub Pages technical requirement with no alternative.

**Complete Guide**: [github-pages-infrastructure.md](github-pages-infrastructure.md) | [core-principles.md](core-principles.md)

---

### III. Local CI/CD First

**EVERY configuration change MUST complete local validation BEFORE any GitHub deployment**.

**Required Steps**:
```bash
# 1. Run local workflow
./.runners-local/workflows/gh-workflow-local.sh local

# 2. Verify build success
./.runners-local/workflows/gh-workflow-local.sh status

# 3. Test configuration
ghostty +show-config && ./scripts/check_updates.sh

# 4. Only then proceed with git workflow
```

**Performance Target**: <2 minutes for complete local workflow execution

**Complete Guide**: [local-cicd.md](local-cicd.md) | [core-principles.md](core-principles.md)

---

### IV. Agent File Integrity

**Single Source of Truth**: `AGENTS.md` is the authoritative LLM instructions file.

**Symlink Structure** (MANDATORY):
```
AGENTS.md           # Regular file (single source of truth)
CLAUDE.md           # Symlink → AGENTS.md
GEMINI.md           # Symlink → AGENTS.md
```

**Verification**:
```bash
readlink CLAUDE.md GEMINI.md  # Should output: AGENTS.md
```

**NEVER**:
- Convert symlinks to regular files
- Create agent-specific divergent instructions
- Point symlinks to website/src/ files

**Complete Guide**: [agent-file-integrity.md](agent-file-integrity.md) | [core-principles.md](core-principles.md)

---

### V. LLM Conversation Logging

**All AI assistants MUST save complete conversation logs** with system state snapshots.

**Requirements**:
- **Storage**: `documentations/development/conversation_logs/`
- **Naming**: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- **Content**: Complete conversation + system state (before/after)
- **Security**: Remove API keys, passwords, personal information

**Complete Guide**: [conversation-logging.md](conversation-logging.md) | [core-principles.md](core-principles.md)

---

### VI. Zero-Cost Operations

**No GitHub Actions minutes consumed for routine operations**. All CI/CD workflows execute locally.

**Cost Monitoring**:
```bash
# Check usage
gh api user/settings/billing/actions

# Target: 0 minutes/month
# Limit: 2,000 minutes/month (free tier)
```

**Performance Targets**:
- Startup time: <500ms (Ghostty CGroup optimization)
- Memory usage: <100MB baseline
- CI/CD performance: <2 minutes complete workflow
- Configuration validity: 100% success rate

**Complete Guide**: [zero-cost-operations.md](zero-cost-operations.md) | [core-principles.md](core-principles.md)

---

## Additional Constraints

### Technology Stack (NON-NEGOTIABLE)

**Terminal Environment**:
- Ghostty: Latest from source (Zig 0.14.0) with 2025 optimizations
- ZSH: Oh My ZSH with productivity plugins
- Context Menu: Nautilus integration

**AI Integration**:
- Claude Code: Latest CLI via npm
- Gemini CLI: Google's AI assistant with Ptyxis integration
- Node.js: Latest version (v25.2.0+) via fnm (Fast Node Manager)

**Local CI/CD**:
- GitHub CLI: Workflow simulation and API access
- Local Runners: Shell-based workflow execution
- Performance Monitoring: System state and timing analysis

### Documentation Structure

**Centralized Documentation Hierarchy**:
- `docs/` - Astro.build output ONLY → GitHub Pages (DO NOT manually edit)
- `website/src/` - Astro source files → Editable markdown documentation
- `documentations/` - Centralized documentation hub:
  - `user/` - End-user documentation
  - `developer/` - Developer documentation
  - `specifications/` - Active feature specifications
  - `archive/` - Historical/obsolete documentation

### Directory Nesting Limit

Maximum 2 levels of nesting from repository root. Top-level directories limited to 4-5 to prevent complexity.

### Removed Features

**Screenshot Functionality** (removed 2025-11-09):
- Installation hangs during screenshot capture
- Unnecessary complexity for terminal configuration project
- All related artifacts removed: `.screenshot-tools/`, screenshot scripts, tests

---

## Quality Gates

### Before Every Configuration Change

1. **Local CI/CD Execution**: Run `./.runners-local/workflows/gh-workflow-local.sh all`
2. **Configuration Validation**: Run `ghostty +show-config`
3. **Performance Testing**: Execute `./.runners-local/workflows/performance-monitor.sh`
4. **Backup Creation**: Automatic timestamped backup
5. **User Preservation**: Extract and preserve customizations
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

---

## Absolute Prohibitions

### DO NOT

- **NEVER REMOVE `docs/.nojekyll`** - Breaks ALL CSS/JS loading on GitHub Pages
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

---

## Governance

### Amendment Process

1. **Proposal**: Document proposed change with rationale
2. **Impact Analysis**: Assess impact on workflows, templates, artifacts
3. **Template Sync**: Update plan-template.md, spec-template.md, tasks-template.md
4. **Version Increment**: Semantic versioning (MAJOR.MINOR.PATCH)
5. **Propagation**: Update dependent documentation (README, quickstart, agent files)
6. **Validation**: Run full local CI/CD to verify no breakage
7. **Ratification**: Merge via standard git workflow with amendment commit message

### Versioning Policy

- **MAJOR**: Backward incompatible principle removals or redefinitions
- **MINOR**: New principle/section added or materially expanded guidance
- **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements

### Compliance Review

All PRs/reviews must verify constitutional compliance before merge. Complexity additions must be justified in spec.md "Complexity Tracking" section. Use AGENTS.md (project root) for runtime development guidance.

### Supersedence

This constitution supersedes all other practices except explicit project requirements in spec.md files. When conflicts arise, constitutional principles take precedence unless explicitly justified in "Complexity Tracking" section of the spec.

---

## Module Index

Complete constitutional implementation guides:

1. **[core-principles.md](core-principles.md)** - Summary of all 6 principles
2. **[git-strategy.md](git-strategy.md)** - Branch preservation, naming, workflow details
3. **[github-pages-infrastructure.md](github-pages-infrastructure.md)** - .nojekyll requirements, protection layers
4. **[local-cicd.md](local-cicd.md)** - Local-first workflows, pipeline stages
5. **[agent-file-integrity.md](agent-file-integrity.md)** - AGENTS.md symlinks, verification
6. **[conversation-logging.md](conversation-logging.md)** - LLM logging requirements, examples
7. **[zero-cost-operations.md](zero-cost-operations.md)** - GitHub Actions cost monitoring, alerts

---

**Version**: 2.0.0
**Ratified**: 2025-10-27
**Last Amended**: 2025-11-16
**Amendment Summary**: Major refactor to modular architecture. Core principles extracted to dedicated documents with complete implementation guides. Constitution now serves as navigation hub with summaries and links.
**Authority**: AGENTS.md (single source of truth)
**Status**: ACTIVE - MANDATORY COMPLIANCE
