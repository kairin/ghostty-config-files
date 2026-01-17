---
title: Agent Delegation Guide
category: architecture
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2025-11-28
---

# Agent Delegation Guide

[<- Back to AGENTS.md](../../../../AGENTS.md) | [Full Registry](./agent-registry.md)

---

## 5-Tier Hierarchy

```
Tier 0 (Sonnet Workflows) ─ Complete automated workflows
    │
    ├─ 000-health ────→ Health assessment workflow
    ├─ 000-cleanup ───→ Repository cleanup workflow
    ├─ 000-commit ────→ Constitutional commit workflow
    ├─ 000-deploy ────→ Complete deployment workflow
    └─ 000-docs ──────→ Documentation verification workflow
    │
    └─ (All Tier 0 agents delegate to Tier 2/3 agents)

001-orchestrator (Opus) ─ Strategic coordination (for complex multi-domain tasks)
    │
    ├─ Tier 2 (Sonnet Core)
    │   ├─ 002-git ──────→ 021-* (7 Haiku)
    │   ├─ 002-astro ────→ 022-* (5 Haiku)
    │   ├─ 002-cleanup ──→ 023-* (6 Haiku)
    │   ├─ 002-compliance → 024-* (5 Haiku)
    │   └─ 002-health ───→ 025-* (6 Haiku)
    │
    ├─ Tier 3 (Sonnet Utility)
    │   ├─ 003-cicd ─────→ 031-* (6 Haiku)
    │   ├─ 003-docs ─────→ 032-* (5 Haiku)
    │   ├─ 003-symlink ──→ 033-* (5 Haiku)
    │   └─ 003-workflow (no children)
    │
    └─ 034-* (5 Shared Haiku utilities)
```

### Tier 0 Workflow Agents

These are **complete workflow agents** that automate common tasks:

| Agent | Natural Language Trigger | What It Does |
|-------|--------------------------|--------------|
| **000-health** | "Check project health" | Full health assessment |
| **000-cleanup** | "Clean up the repo" | Remove obsolete files |
| **000-commit** | "Commit my changes" | Constitutional git commit |
| **000-deploy** | "Deploy the website" | Build and deploy to GitHub Pages |
| **000-docs** | "Fix documentation" | Verify and fix documentation |

---

## Delegation Decision Tree

```
Task Received
    │
    ├─ Simple/direct? → Execute directly (no agent)
    │   Examples: Read a file, answer a question, run single command
    │
    └─ Needs agent?
        │
        ├─ COMPLETE WORKFLOW (standard automated task)
        │   → Tier 0 (000-*)
        │   Examples: "deploy website", "commit changes", "check health"
        │   Triggers: Natural language matching workflow descriptions
        │
        ├─ ATOMIC (single op, deterministic)
        │   → Haiku tier (021-034-*)
        │   Examples: Validate branch name, check file exists
        │
        ├─ MODERATE (2-5 steps, focused domain)
        │   → Sonnet tier (002-*, 003-*)
        │   Examples: Git commit flow, build website
        │
        └─ COMPLEX (multi-domain, parallel, judgment)
            → Opus (001-orchestrator)
            Examples: Full audit with fixes, custom multi-agent orchestration
```

---

## Cost/Complexity Matrix

| Tier | Model | Cost | Token Budget | When to Use |
|------|-------|------|--------------|-------------|
| 0 | Sonnet | $$ | ~2-3K tokens | Complete workflows (000-*), end-to-end operations |
| 1 | Opus | $$$ | ~10K tokens | Multi-agent parallel orchestration |
| 2-3 | Sonnet | $$ | ~2-3K tokens | Domain operations, sequenced workflow |
| 4 | Haiku | $ | ~500 tokens | Single atomic task, no judgment |

**Token Optimization**: ~40% reduction by delegating atomic tasks to Haiku tier.

---

## When to Delegate to Haiku

**DO delegate**:
- Single atomic operation needed
- Task is repeatable and deterministic
- No complex decision-making required
- Speed/cost optimization desired

**DO NOT delegate**:
- Complex multi-step reasoning needed
- User judgment required
- Context7 queries (requires parent MCP access)
- Error handling with multiple options

---

## Delegation Examples

### Good Delegation

```
Task: "Check if branch name is valid"
Agent: 034-branch-validate (Haiku)
Why: Single atomic validation, no reasoning needed

Task: "Commit and push my changes"
Agent: 002-git (Sonnet) → delegates to 021-stage, 034-commit-format, 021-commit, 021-push
Why: Multi-step workflow with sequencing, focused domain

Task: "Review all documentation, fix issues, run tests, deploy"
Agent: 001-orchestrator (Opus) → coordinates 002-compliance, 003-docs, 002-astro, 002-git
Why: Complex multi-domain task requiring parallel execution
```

### Anti-Patterns (What NOT to Do)

```
WRONG: Using Opus for "check if branch name is valid"
Why: 70x cost waste - Haiku can do this

WRONG: Using Haiku for "run complete project audit with fixes"
Why: Haiku cannot reason about multi-system coordination

WRONG: Skipping parent agent when Haiku needs context
Why: Haiku agents expect pre-validated input from parents
```

---

## When NOT to Use Agents

**Execute directly (no agent)**:
- Reading files or exploring code
- Answering questions about the codebase
- Single shell command that isn't part of a workflow
- Explaining or documenting something

---

## Execution Mode Decision Tree

Use this to determine whether tasks can run in parallel or must be sequential:

```
┌────────────────────────────────────────────────────────────┐
│ STEP 1: Is the operation STATE-MUTATING?                  │
│         (git commit, file delete, push, write)            │
│                                                            │
│   YES → SEQUENTIAL execution only (wait for completion)   │
│   NO  → Continue to Step 2                                │
└────────────────────────────────────────────────────────────┘
                           │ NO
                           ▼
┌────────────────────────────────────────────────────────────┐
│ STEP 2: Does this task DEPEND on another task's output?   │
│                                                            │
│   YES → SEQUENTIAL (run after dependency completes)       │
│   NO  → PARALLEL eligible                                 │
└────────────────────────────────────────────────────────────┘
```

### Agent Parallel-Safety Reference

| Category | Agents | Mode | Notes |
|----------|--------|------|-------|
| Analysis/Validation | 002-compliance, 002-health, 003-cicd | PARALLEL | Read-only operations |
| Build/Docs | 002-astro, 003-docs, 003-symlink | PARALLEL | Isolated outputs |
| Git Operations | 002-git, 021-* | SEQUENTIAL | Repository state mutations |
| Cleanup | 002-cleanup (analysis only) | PARALLEL | But deletions are SEQUENTIAL |
| Workflow | 003-workflow | N/A | Library only, never invoked |

---

## Scenario Reference Protocols

### Scenario A: Bug Fix Protocol

```
User: "Fix the bug in scripts/check_updates.sh"

CLASSIFICATION: ATOMIC/MODERATE (single file, focused fix)
ORCHESTRATOR: No
AGENTS: Direct work → 002-git for commit

WORKFLOW:
1. Read script, understand current behavior
2. Identify bug location and root cause
3. Edit existing script (DO NOT create wrapper)
4. Validate: ./.runners-local/workflows/gh-workflow-local.sh all
5. Git workflow: branch → commit → merge → preserve
```

### Scenario B: Deployment Protocol

```
User: "Deploy the Astro website"

CLASSIFICATION: COMPLEX (multi-domain, parallel opportunities)
ORCHESTRATOR: Yes (001-orchestrator)
AGENTS: 002-git, 002-astro, 002-health, 003-symlink, 003-docs

WORKFLOW:
Phase 1 (PARALLEL): Pre-validation
├─ 002-git → fetch, check sync
├─ 002-health → environment validation
└─ 003-symlink → verify CLAUDE.md/GEMINI.md

Phase 2 (SEQUENTIAL): Local CI/CD
└─ ./.runners-local/workflows/gh-workflow-local.sh all

Phase 3 (SEQUENTIAL): Astro Build
└─ 002-astro → npm run build, verify .nojekyll

Phase 4 (SEQUENTIAL): Git Workflow
└─ 002-git → branch, commit, merge, push

Phase 5 (PARALLEL): Verification
├─ 002-health → deployment success check
└─ 003-docs → documentation integrity
```

### Scenario C: Cleanup Protocol

```
User: "Clean up redundant files in the repo"

CLASSIFICATION: MODERATE (requires user approval)
ORCHESTRATOR: Yes (for approval gate)
AGENTS: 002-cleanup → 023-* Haiku agents

WORKFLOW:
1. PRE-CLEANUP (PARALLEL analysis):
   ├─ 023-scandirs → duplicate directories
   ├─ 023-scanscripts → orphaned scripts
   └─ 024-script-check → proliferation violations

2. USER APPROVAL GATE:
   └─ Present findings, WAIT for explicit approval

3. EXECUTE (SEQUENTIAL after approval):
   ├─ 023-remove → delete approved files
   └─ 023-consolidate → merge directories

4. POST-CLEANUP VALIDATION:
   └─ Local CI/CD, symlink check
```

### Scenario D: Feature Addition Protocol

```
User: "Add a metrics panel to the dashboard"

CLASSIFICATION: MODERATE (multi-step, incremental)
ORCHESTRATOR: Maybe (depends on complexity)
AGENTS: Domain-specific (e.g., 002-astro for web features)

WORKFLOW:
1. PLANNING:
   ├─ Use TodoWrite to break into tasks
   ├─ Identify files to MODIFY (not create)
   └─ Constitutional check: Can this enhance existing code? YES → proceed

2. INVESTIGATION:
   ├─ Read existing dashboard code
   ├─ Understand current patterns
   └─ Identify integration points

3. INCREMENTAL EXECUTION:
   ├─ Task 1: Add data source → existing file
   ├─ Task 2: Add UI component → existing component
   ├─ Task 3: Wire integration → existing orchestration
   └─ Task 4: Add tests → tests/ directory (allowed)

4. VALIDATION & GIT:
   └─ Local CI/CD → branch → commit → merge
```

### Scenario E: Investigation Protocol

```
User: "The CI/CD pipeline is failing intermittently"

CLASSIFICATION: VARIABLE (explore first, propose before acting)
ORCHESTRATOR: No (investigation phase)
AGENTS: Explore first, then determine

WORKFLOW:
1. ASK CLARIFYING QUESTIONS:
   ├─ "When did this start happening?"
   ├─ "What error messages are you seeing?"
   └─ "Does it fail on specific operations?"

2. INVESTIGATION (PARALLEL reads):
   ├─ Read recent workflow logs
   ├─ Check git history for recent changes
   └─ Review CI/CD configuration

3. ROOT CAUSE ANALYSIS:
   ├─ Identify most likely cause(s)
   ├─ Validate hypothesis with evidence
   └─ Propose solution approach

4. USER DECISION GATE:
   └─ Present findings, await confirmation

5. IMPLEMENTATION (after approval):
   ├─ Apply minimal fix
   ├─ Avoid over-engineering
   └─ Document what was wrong and why
```

---

## Complete Registry

For the full 65-agent registry with parent-child relationships and parallel-safe indicators, see:

**[Agent Registry](./agent-registry.md)**

---

[<- Back to AGENTS.md](../../../../AGENTS.md) | [Full Registry](./agent-registry.md)
