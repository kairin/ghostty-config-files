---
title: "Slash Command Reference"
description: "Complete guide to constitutional slash commands for workflow automation"
pubDate: 2025-11-15
author: "AI Integration Team"
tags: ["ai", "commands", "workflows", "automation"]
targetAudience: "all"
constitutional: true
---

> **Note**: This documentation reflects slash commands as of 2025-11-15. Command implementations are in `.claude/commands/`.

## Overview

Constitutional slash commands provide high-level workflow automation by coordinating multiple specialized agents. All commands enforce constitutional compliance, zero GitHub Actions cost, and parallel execution where possible.

---

## Guardian Command Suite

### /guardian-health

**Purpose**: Execute comprehensive project health assessment

**Agents Invoked** (Parallel):
- 002-health
- 003-docs
- 002-astro

**Use Cases**:
- Weekly scheduled health audits
- Pre-deployment verification
- First-time project setup validation
- MCP integration troubleshooting
- Standards compliance checks

**Output Format**:
```
🏥 PROJECT HEALTH REPORT
========================

✅/❌ Context7 MCP Status
✅/❌ GitHub MCP Status
✅/❌ Documentation Symlinks
✅/❌ Astro Build Status
✅/❌ GitHub Pages Deployment

[Detailed findings from each agent]

Overall Status: HEALTHY / NEEDS ATTENTION / CRITICAL
```

**Example Invocation**:
```bash
/guardian-health
```

**Execution Time**: ~30-60 seconds (agents run in parallel)

---

### /guardian-documentation

**Purpose**: Comprehensive documentation integrity verification

**Agents Invoked** (Coordinated by 001-orchestrator):
- 001-orchestrator (coordinator)
- 002-compliance
- 003-docs
- 003-symlink

**Verification Scope**:

#### 1. Agent System Verification
- All 9 agents documented in AGENT_REGISTRY.md
- Agent capabilities match implementations
- Delegation network accuracy
- No undocumented agents in `.claude/agents/`

#### 2. Documentation Structure
- AGENTS.md < 40KB limit
- Symlinks intact (CLAUDE.md, GEMINI.md → AGENTS.md)
- documentations/ properly organized
- website/src/ vs documentations/ separation
- .runners-local/README.md exists

#### 3. Cross-Reference Integrity
- All internal links valid
- No broken references to moved files
- Quick Links section current
- Spec-Kit documentation up-to-date

#### 4. Consolidation Compliance
- No scattered documentation
- Single source of truth maintained
- No duplicate README.md conflicts
- All docs in proper subdirectories

#### 5. Agent Documentation
- All agents have proper frontmatter
- Invocation examples complete
- Delegation patterns documented
- AGENT_REGISTRY.md synchronized

#### 6. Slash Commands
- All guardian-* commands consistent
- Command descriptions accurate
- Output formats documented

**Output Format**:
```
📚 DOCUMENTATION INTEGRITY REPORT
===================================

🤖 AGENT SYSTEM STATUS
✅/❌ All 9 agents documented
✅/❌ Agent capabilities accurate
✅/❌ Delegation network up-to-date

📁 DOCUMENTATION STRUCTURE
✅/❌ AGENTS.md < 40KB (current: XXkB)
✅/❌ Symlinks intact
✅/❌ documentations/ organized

🔗 CROSS-REFERENCE INTEGRITY
✅/❌ All internal links valid
✅/❌ No broken references

🗂️ CONSOLIDATION COMPLIANCE
✅/❌ No scattered documentation
✅/❌ Single source of truth maintained

ISSUES FOUND: X
- [List of specific issues]

RECOMMENDATIONS:
- [Specific actions to fix]

Overall Status: EXCELLENT / GOOD / NEEDS ATTENTION / CRITICAL
```

**Example Invocation**:
```bash
/guardian-documentation
```

**Execution Time**: ~45-90 seconds (complex multi-agent coordination)

**When to Invoke**:
- After adding new agents
- After major documentation reorganization
- Before large commits affecting documentation
- When links may be broken (file moves/renames)
- Weekly documentation health check
- After merging documentation branches

---

### /guardian-cleanup

**Purpose**: Identify redundant files and consolidate directory structures with constitutional Git workflow

**Agents Invoked** (Sequential):
1. 002-cleanup (analysis)
2. 002-git (Git operations)

**Cleanup Scope**:
- Redundant file detection
- Dead symlink removal
- Orphaned file identification
- Directory structure consolidation
- Obsolete script archival

**Safety Protocols**:
- Constitutional branch naming
- Branch preservation (NEVER delete)
- Backup before cleanup
- User confirmation for destructive operations

**Output Format**:
```
🧹 REPOSITORY CLEANUP REPORT
==============================

📊 ANALYSIS RESULTS
- Redundant files: X found
- Dead symlinks: X found
- Orphaned files: X found
- Directory consolidation opportunities: X

🗑️ CLEANUP ACTIONS
✅ Archived X verification reports
✅ Consolidated X directories
✅ Removed X dead symlinks

📝 GIT OPERATIONS
Branch: YYYYMMDD-HHMMSS-cleanup-description
Commit: [hash]
Status: ✅ SUCCESS

SUMMARY: [Brief description of cleanup]
```

**Example Invocation**:
```bash
/guardian-cleanup
```

**Execution Time**: ~1-3 minutes (depends on repository size)

---

### /guardian-commit

**Purpose**: Execute fully automatic constitutional Git commit workflow

**Agents Invoked** (Sequential):
1. 003-symlink (pre-commit validation)
2. 002-git (commit workflow)

**Workflow Steps**:
1. Verify symlink integrity (CLAUDE.md, GEMINI.md)
2. Analyze staged changes with `git status` and `git diff`
3. Review recent commit messages for style consistency
4. Draft constitutional commit message
5. Create timestamped branch (YYYYMMDD-HHMMSS-type-description)
6. Commit with Claude Code footer
7. Merge to main with --no-ff
8. Push to origin
9. Preserve branch (NEVER delete)

**Constitutional Commit Format**:
```
feat(component): Brief description of changes

Detailed explanation focusing on "why" not "what"

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Output Format**:
```
📝 CONSTITUTIONAL COMMIT REPORT
================================

✅ Symlink integrity verified
✅ Changes analyzed
✅ Commit message drafted

Branch: 20251115-143000-feat-description
Commit: b2679e8
Merge: SUCCESS ✅
Push: SUCCESS ✅

BRANCH PRESERVED (as required by constitution)
```

**Example Invocation**:
```bash
/guardian-commit "feat: Add new feature description"
```

**Execution Time**: ~20-40 seconds

**When to Invoke**:
- Ready to commit changes with constitutional compliance
- Need automatic branch creation and naming
- Want guaranteed symlink integrity
- Require branch preservation enforcement

---

### /guardian-deploy

**Purpose**: Execute complete deployment workflow - Astro build, validation, commit, and GitHub Pages deployment

**Agents Invoked** (Sequential):
1. 002-astro (build and validation)
2. 002-git (deployment commit)

**Deployment Steps**:
1. **Build Phase**:
   - Run Astro build
   - Validate docs/index.html exists
   - Verify docs/_astro/ assets directory
   - **CRITICAL**: Verify docs/.nojekyll exists
   - Count generated HTML pages

2. **Validation Phase**:
   - All build outputs present
   - No build errors or warnings
   - Asset directory integrity
   - GitHub Pages deployment readiness

3. **Git Phase** (Constitutional):
   - Create timestamped branch
   - Commit build artifacts
   - Merge to main
   - Push to origin
   - Preserve branch

**Critical Validation**:
```bash
✅ docs/.nojekyll exists (WITHOUT this, CSS/JS returns 404)
✅ docs/index.html exists
✅ docs/_astro/ directory exists
✅ All pages generated successfully
```

**Output Format**:
```
🚀 DEPLOYMENT REPORT
=====================

🏗️ BUILD STATUS
✅ Astro build completed
✅ Generated XX HTML pages
✅ Assets compiled to docs/_astro/
✅ .nojekyll file verified (CRITICAL)

✅ VALIDATION PASSED
- docs/index.html: EXISTS
- docs/_astro/: EXISTS
- docs/.nojekyll: EXISTS

📝 GIT OPERATIONS
Branch: 20251115-150000-deploy-website-update
Commit: [hash]
Merge: SUCCESS ✅
Push: SUCCESS ✅

🌐 DEPLOYMENT STATUS
GitHub Pages: READY
URL: https://[username].github.io/ghostty-config-files/

DEPLOYMENT COMPLETE ✅
```

**Example Invocation**:
```bash
/guardian-deploy
```

**Execution Time**: ~2-4 minutes (build time + Git operations)

**When to Invoke**:
- Website content updated (website/src/)
- Ready to deploy to GitHub Pages
- Need complete build validation
- Want zero-cost deployment workflow

---

## Spec-Kit Integration Commands

### /speckit.constitution

**Purpose**: Create or update project constitution with principle synchronization

**Execution**: Interactive principle input → Template updates

**Output**: Updated constitution.md and dependent templates

---

### /speckit.specify

**Purpose**: Create or update feature specification from natural language

**Input**: Feature description (natural language)

**Output**: spec.md with structured specification

---

### /speckit.plan

**Purpose**: Execute implementation planning workflow

**Input**: spec.md

**Output**: plan.md with design artifacts

---

### /speckit.tasks

**Purpose**: Generate actionable, dependency-ordered tasks.md

**Input**: spec.md, plan.md

**Output**: tasks.md with executable task list

---

### /speckit.implement

**Purpose**: Execute implementation by processing all tasks in tasks.md

**Input**: tasks.md

**Output**: Complete feature implementation

---

### /speckit.analyze

**Purpose**: Perform cross-artifact consistency analysis

**Input**: spec.md, plan.md, tasks.md

**Output**: Analysis report with recommendations

---

### /speckit.checklist

**Purpose**: Generate custom checklist for current feature

**Input**: User requirements

**Output**: Feature-specific checklist

---

### /speckit.clarify

**Purpose**: Identify underspecified areas and ask clarification questions

**Input**: spec.md

**Output**: Updated spec.md with clarified details

---

## Command Naming Conventions

**Guardian Commands** (`/guardian-*`):
- Infrastructure and operational workflows
- Health checks and validation
- Cleanup and maintenance
- Git and deployment operations

**Spec-Kit Commands** (`/speckit.*`):
- Feature specification and planning
- Implementation workflows
- Task management
- Cross-artifact analysis

---

## Constitutional Requirements

**ALL slash commands MUST**:
1. Enforce branch preservation (NEVER delete branches)
2. Use constitutional branch naming (YYYYMMDD-HHMMSS-type-description)
3. Include Claude Code footer in commits
4. Run local CI/CD workflows (zero GitHub Actions cost)
5. Verify symlink integrity before Git operations
6. Validate .nojekyll file before deployments
7. Execute parallel agents simultaneously when possible
8. Respect dependency ordering for sequential agents

---

## Command File Locations

All slash commands stored in:
```
.claude/commands/
├── guardian-health.md
├── guardian-documentation.md
├── guardian-cleanup.md
├── guardian-commit.md
├── guardian-deploy.md
├── speckit.constitution.md
├── speckit.specify.md
├── speckit.plan.md
├── speckit.tasks.md
├── speckit.implement.md
├── speckit.analyze.md
├── speckit.checklist.md
└── speckit.clarify.md
```

---

## Best Practices

### For AI Assistants

**DO**:
- Use guardian commands for infrastructure operations
- Use speckit commands for feature development
- Invoke /guardian-health before major changes
- Invoke /guardian-documentation after doc updates
- Use /guardian-deploy for zero-cost deployments
- Trust the orchestration - agents handle complexity

**DON'T**:
- Mix guardian and speckit workflows unnecessarily
- Skip pre-deployment /guardian-health checks
- Bypass constitutional Git workflows
- Delete branches created by slash commands
- Remove .nojekyll file during cleanup

---

## Troubleshooting

### Command Not Found

**Issue**: Slash command not recognized

**Solutions**:
1. Verify command file exists in `.claude/commands/`
2. Check command name spelling (case-sensitive)
3. Restart Claude Code to reload commands
4. Check `.claude/commands/` permissions

---

### Agent Execution Failures

**Issue**: Agent fails during command execution

**Solutions**:
1. Check error message for specific agent failure
2. Verify agent dependencies satisfied
3. Run /guardian-health to check system state
4. Review .runners-local/logs/ for detailed errors
5. Retry with improved context

---

### Build Failures in /guardian-deploy

**Issue**: Astro build fails during deployment

**Solutions**:
1. Check Node.js version (latest via fnm required)
2. Run `npm install` in website/ directory
3. Verify astro.config.mjs syntax
4. Check website/src/ for TypeScript errors
5. Review build logs in terminal output

---

## Advanced Usage

### Chaining Commands

```bash
# Complete workflow: health check → deploy
/guardian-health
# Review health report
/guardian-deploy
```

### Conditional Execution

```bash
# Only deploy if health check passes
/guardian-health
# If status = HEALTHY:
/guardian-deploy
```

---

## Performance Metrics

**Guardian Command Suite**:
- /guardian-health: ~30-60s (parallel execution)
- /guardian-documentation: ~45-90s (complex coordination)
- /guardian-cleanup: ~1-3min (analysis + Git)
- /guardian-commit: ~20-40s (validation + commit)
- /guardian-deploy: ~2-4min (build + validation + commit)

**Spec-Kit Command Suite**:
- /speckit.specify: ~1-2min (specification generation)
- /speckit.plan: ~2-3min (planning artifacts)
- /speckit.tasks: ~30-60s (task decomposition)
- /speckit.implement: Variable (depends on task complexity)
- /speckit.analyze: ~1-2min (cross-artifact analysis)

---

## References

- **AGENTS.md**: Agent system implementation details
- **.claude/agents/**: Agent implementation files
- **.claude/commands/**: Slash command definitions
- **spec-kit/guides/**: Spec-Kit workflow documentation
- **documentations/developer/**: Developer architecture guides

---

**Version**: 1.0
**Last Updated**: 2025-11-15
**Status**: ACTIVE - CONSTITUTIONAL COMPLIANCE REQUIRED
