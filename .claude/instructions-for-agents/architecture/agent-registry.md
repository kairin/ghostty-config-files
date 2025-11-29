---
title: Agent Registry
category: architecture
linked-from: AGENTS.md, agent-delegation.md
status: ACTIVE
last-updated: 2025-11-28
---

# Agent Registry (65 Agents)

[<- Back to AGENTS.md](../../../../AGENTS.md) | [Delegation Guide](./agent-delegation.md)

---

## 5-Tier Overview

| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| **0** | **Sonnet** | **5** | **Complete workflow agents** |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 5 | Core domain operations |
| 3 | Sonnet | 4 | Utility/support operations |
| 4 | Haiku | 50 | Atomic execution tasks |

---

## Tier 0: Complete Workflows (Sonnet)

| Agent | Purpose | Delegates To | Parallel-Safe |
|-------|---------|--------------|---------------|
| **000-health** | Full health assessment | 002-health, 003-docs, 002-astro | Yes |
| **000-cleanup** | Repository cleanup | 002-cleanup, 002-git | No |
| **000-commit** | Constitutional commit workflow | 002-git | No |
| **000-deploy** | Complete deployment | 002-git, 002-astro, 002-health, 003-docs | No |
| **000-docs** | Documentation verification | 003-docs, 003-symlink, 002-git | No |

**Natural Language Triggers**:
- "Check project health" → 000-health
- "Clean up the repo" → 000-cleanup
- "Commit my changes" → 000-commit
- "Deploy the website" → 000-deploy
- "Fix documentation" → 000-docs

---

## Tier 1: Orchestrator (Opus)

| Agent | Purpose | Parallel-Safe |
|-------|---------|---------------|
| **001-orchestrator** | Complex task decomposition, multi-agent coordination | No |

---

## Tier 2: Core Operations (Sonnet)

| Agent | Purpose | Haiku Children | Parallel-Safe |
|-------|---------|----------------|---------------|
| **002-git** | Git/GitHub operations | 021-* (7) | No |
| **002-astro** | Astro builds, .nojekyll | 022-* (5) | Yes |
| **002-cleanup** | Repository cleanup | 023-* (6) | Yes |
| **002-compliance** | Documentation compliance | 024-* (5) | Yes |
| **002-health** | Health audits, Context7 | 025-* (6) | Yes |

---

## Tier 3: Utility/Support (Sonnet)

| Agent | Purpose | Haiku Children | Parallel-Safe |
|-------|---------|----------------|---------------|
| **003-cicd** | CI/CD validation | 031-* (6) | Yes |
| **003-docs** | Documentation consistency | 032-* (5) | Yes |
| **003-symlink** | Symlink integrity | 033-* (5) | Yes |
| **003-workflow** | Shared templates (library) | None | N/A |

---

## Tier 4: Haiku Execution Agents (50 total)

### 021-* Git Tasks (Parent: 002-git)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 021-fetch | Fetch remote, analyze divergence | Yes |
| 021-stage | Security scan + stage files | Yes |
| 021-commit | Execute git commit | No |
| 021-push | Push with upstream tracking | No |
| 021-merge | Merge with --no-ff | No |
| 021-branch | Create new branch | Yes |
| 021-pr | Create GitHub PR | Yes |

### 022-* Astro Tasks (Parent: 002-astro)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 022-precheck | Verify Astro project structure | Yes |
| 022-build | Execute npm run build | No |
| 022-validate | Validate build output + .nojekyll | Yes |
| 022-metrics | Calculate build metrics | Yes |
| 022-nojekyll | Create/verify .nojekyll | Yes |

### 023-* Cleanup Tasks (Parent: 002-cleanup)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 023-scandirs | Scan for duplicate directories | Yes |
| 023-scanscripts | Find one-off scripts | Yes |
| 023-remove | Execute file removal | No |
| 023-consolidate | Merge duplicate directories | No |
| 023-archive | Move to archive with timestamp | No |
| 023-metrics | Calculate cleanup impact | Yes |

### 024-* Compliance Tasks (Parent: 002-compliance)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 024-size | Check file size, determine zone | Yes |
| 024-sections | Extract/analyze markdown sections | Yes |
| 024-links | Verify markdown links exist | Yes |
| 024-extract | Extract section to new file | No |
| 024-script-check | Check script proliferation | Yes |

### 025-* Health Tasks (Parent: 002-health)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 025-versions | Check tool versions | Yes |
| 025-context7 | Validate Context7 API key | Yes |
| 025-structure | Verify directory structure | Yes |
| 025-stack | Extract package.json versions | Yes |
| 025-security | Scan for exposed secrets | Yes |
| 025-astro-check | Verify astro.config.mjs | Yes |

### 031-* CI/CD Tasks (Parent: 003-cicd)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 031-tool | Check single tool installation | Yes |
| 031-env | Check environment variable | Yes |
| 031-mcp | Test MCP connectivity | Yes |
| 031-dir | Verify directory exists | Yes |
| 031-file | Check critical file exists | Yes |
| 031-report | Generate setup instructions | No |

### 032-* Documentation Tasks (Parent: 003-docs)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 032-verify | Verify symlink integrity | Yes |
| 032-restore | Restore/create symlink | No |
| 032-backup | Create timestamped backup | Yes |
| 032-crossref | Check markdown link validity | Yes |
| 032-git-mode | Check git symlink tracking | Yes |

### 033-* Symlink Tasks (Parent: 003-symlink)

| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 033-type | Determine file type | Yes |
| 033-hash | Calculate content hash | Yes |
| 033-diff | Compare two files | Yes |
| 033-backup | Create timestamped backup | Yes |
| 033-final | Final verification | Yes |

### 034-* Shared Utilities (Multiple Parents)

| Agent | Task | Used By | Parallel-Safe |
|-------|------|---------|---------------|
| 034-branch-validate | Validate branch name format | 002-git, 002-astro | Yes |
| 034-branch-generate | Generate constitutional branch name | 002-git | Yes |
| 034-commit-format | Format commit message with attribution | 002-git | Yes |
| 034-branch-exists | Check if branch exists local/remote | 002-git | Yes |
| 034-merge-dryrun | Test merge for conflicts | 002-git | Yes |

---

## Parent-Child Summary

```
000-* (Tier 0 Workflows) → Coordinate Tier 2/3 agents
    ├─ 000-health ────→ 002-health, 003-docs, 002-astro
    ├─ 000-cleanup ───→ 002-cleanup, 002-git
    ├─ 000-commit ────→ 002-git
    ├─ 000-deploy ────→ 002-git, 002-astro, 002-health, 003-docs
    └─ 000-docs ──────→ 003-docs, 003-symlink, 002-git

002-git ────────→ 021-* (7 agents)
002-astro ──────→ 022-* (5 agents)
002-cleanup ────→ 023-* (6 agents)
002-compliance ─→ 024-* (5 agents)
002-health ─────→ 025-* (6 agents)
003-cicd ───────→ 031-* (6 agents)
003-docs ───────→ 032-* (5 agents)
003-symlink ────→ 033-* (5 agents)
034-* (5 shared utilities)
```

**Total**: 5 Tier 0 + 1 Opus + 9 Sonnet + 50 Haiku = **65 agents**

---

[<- Back to AGENTS.md](../../../../AGENTS.md) | [Delegation Guide](./agent-delegation.md)
