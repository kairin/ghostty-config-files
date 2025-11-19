---
title: "Agent System Architecture"
description: "Complete guide to the 9-agent constitutional orchestration system"
pubDate: 2025-11-15
author: "AI Integration Team"
tags: ["ai", "agents", "orchestration", "architecture"]
targetAudience: "all"
constitutional: true
---

> **Note**: This documentation reflects the agent system as of 2025-11-15. AGENTS.md remains the single source of truth for implementation details.

## Overview

The ghostty-config-files project employs a sophisticated **9-agent constitutional orchestration system** designed for parallel workflow execution, dependency management, automated verification, and iterative refinement. This system maximizes efficiency while maintaining strict constitutional compliance and zero GitHub Actions cost.

## Agent Registry (9 Specialized Agents)

### Core Coordination

#### 1. **master-orchestrator** (35KB)
**Primary Function**: Multi-agent coordination and parallel execution planning

**When to Invoke**:
- Complex multi-step requests requiring multiple agents
- Spec-Kit workflow execution
- Tasks with parallel execution opportunities
- Dependency-aware task decomposition

**Key Capabilities**:
- Parallel workflow decomposition
- Dependency management with topological sorting
- Automated verification and testing
- Iterative refinement on failures
- Spec-Kit integration (spec.md, plan.md, tasks.md)

**Example**:
```
User: "Review all documentation, fix issues, run tests, and deploy"
AI: Uses master-orchestrator to coordinate documentation-guardian,
    constitutional-compliance-agent, testing, and astro-build-specialist
    in parallel phases with dependency management.
```

**Parallel-Safe**: ✅ Yes (coordinates other agents)
**Dependencies**: None (top-level coordinator)

---

### Documentation Integrity Agents

#### 2. **symlink-guardian** (16KB)
**Primary Function**: Verify and restore CLAUDE.md/GEMINI.md symlinks to AGENTS.md

**When to Invoke**:
- Pre-commit validation
- Post-merge verification
- On-demand symlink integrity checks
- When CLAUDE.md or GEMINI.md are accidentally modified as regular files

**Key Capabilities**:
- Symlink integrity verification
- Intelligent content merging (when symlinks diverge)
- Automatic symlink restoration
- Pre-commit MANDATORY validation

**Constitutional Requirement**: CLAUDE.md and GEMINI.md MUST be symlinks to AGENTS.md (single source of truth)

**Example Workflow**:
```bash
# Verify symlinks before commit
symlink-guardian detects CLAUDE.md is a regular file
→ Merges unique content from CLAUDE.md into AGENTS.md
→ Deletes CLAUDE.md regular file
→ Creates symlink: CLAUDE.md → AGENTS.md
→ Prevents commit until symlinks are valid
```

**Parallel-Safe**: ✅ Yes
**Dependencies**: None

---

#### 3. **constitutional-compliance-agent** (22KB)
**Primary Function**: Ensure AGENTS.md remains <40KB by modularizing large sections

**When to Invoke**:
- AGENTS.md size approaching 40KB limit
- Adding substantial content to AGENTS.md
- Proactive documentation modularization audits
- When sections exceed 250 lines

**Key Capabilities**:
- AGENTS.md size monitoring
- Automatic section modularization
- Extract large sections to separate files
- Maintain cross-references and navigation
- Preserve constitutional compliance

**Modularization Strategy**:
```
IF AGENTS.md > 40KB:
  1. Identify largest sections
  2. Extract to documentations/[category]/[section].md
  3. Replace with summary + link in AGENTS.md
  4. Update cross-references
  5. Verify all links valid
```

**Parallel-Safe**: ✅ Yes
**Dependencies**: None

---

#### 4. **documentation-guardian** (18KB)
**Primary Function**: Enforce AGENTS.md as single source of truth

**When to Invoke**:
- AGENTS.md modifications detected
- Symlink integrity issues
- Documentation consistency audits
- Cross-reference validation needed

**Key Capabilities**:
- Single source of truth enforcement
- Documentation consistency verification
- Cross-reference validation
- Link integrity checks
- Duplicate content detection

**Constitutional Requirement**: All AI assistant instructions MUST originate from AGENTS.md. CLAUDE.md and GEMINI.md are symlinks only.

**Parallel-Safe**: ✅ Yes
**Dependencies**: symlink-guardian (run symlink checks first)

---

### Build & Deployment Agents

#### 5. **astro-build-specialist** (18KB)
**Primary Function**: Astro.build operations and .nojekyll validation

**When to Invoke**:
- Website content changes require rebuild
- Deployment to GitHub Pages
- Build failure troubleshooting
- .nojekyll file integrity verification

**Key Capabilities**:
- Astro build execution
- Build output validation
- **CRITICAL**: .nojekyll file verification
- GitHub Pages deployment readiness
- Build artifact management

**Critical Validation**:
```bash
# MANDATORY checks before deployment
✅ docs/.nojekyll exists (WITHOUT this, ALL CSS/JS return 404)
✅ docs/index.html exists
✅ docs/_astro/ directory exists
✅ All HTML pages generated correctly
```

**Parallel-Safe**: ✅ Yes
**Dependencies**: None (delegates Git operations to git-operations-specialist)

---

#### 6. **git-operations-specialist** (19KB)
**Primary Function**: ALL Git and GitHub operations with constitutional compliance

**When to Invoke**:
- Any commit, push, pull, fetch operation
- Branch creation or management
- Conflict resolution
- GitHub CLI operations (issues, PRs, releases)

**Key Capabilities**:
- Constitutional branch naming (YYYYMMDD-HHMMSS-type-description)
- Branch preservation enforcement (NEVER delete without permission)
- Constitutional commit formatting
- Merge operations (always --no-ff)
- GitHub CLI integration

**Constitutional Workflow**:
```bash
# MANDATORY workflow for ALL commits
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="${DATETIME}-feat-description"
git checkout -b "$BRANCH"
git add .
git commit -m "Message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH"
git checkout main
git merge "$BRANCH" --no-ff
git push origin main
# NEVER: git branch -d "$BRANCH" (preserve ALL branches)
```

**Parallel-Safe**: ❌ NO (SEQUENTIAL ONLY - conflicts if parallel)
**Dependencies**: symlink-guardian, documentation-guardian (run before Git operations)

---

### Validation & Health Agents

#### 7. **project-health-auditor** (19KB)
**Primary Function**: Comprehensive health checks and Context7 MCP integration

**When to Invoke**:
- Scheduled weekly health audits
- First-time project setup
- Context7 MCP troubleshooting
- Standards compliance verification
- Before major deployments

**Key Capabilities**:
- Context7 MCP configuration validation
- GitHub MCP authentication checks
- Project configuration audits
- Best practices verification (via Context7 queries)
- System state validation

**Health Metrics Monitored**:
- Context7 API key configuration
- GitHub CLI authentication
- MCP server connectivity
- Configuration file validity
- Documentation integrity
- Build status

**Parallel-Safe**: ✅ Yes
**Dependencies**: None

---

#### 8. **repository-cleanup-specialist** (21KB)
**Primary Function**: Identify redundancy and consolidate directory structures

**When to Invoke**:
- Post-migration cleanup needed
- Repository clutter detected
- Redundant file identification
- Directory consolidation required
- Proactive cleanup audits

**Key Capabilities**:
- Redundant file detection
- Directory structure consolidation
- Dead symlink removal
- Orphaned file identification
- Constitutional cleanup workflows

**Safety Protocols**:
- ALWAYS delegate Git operations to git-operations-specialist
- NEVER delete without constitutional workflow
- Preserve branch history
- Backup before cleanup

**Parallel-Safe**: ✅ Yes
**Dependencies**: None (delegates Git to git-operations-specialist)

---

### Shared Utilities

#### 9. **constitutional-workflow-orchestrator** (18KB)
**Primary Function**: Shared workflow templates and utility functions

**When to Invoke**: NOT invoked directly - referenced by other agents as a library

**Key Capabilities**:
- Standardized branch naming templates
- Constitutional commit message formatting
- Merge operation templates
- Workflow function library
- Code reuse across agents

**Usage Pattern**:
```markdown
Other agents reference templates like:
"Use constitutional-workflow-orchestrator templates for branch naming"
"Follow constitutional-workflow-orchestrator commit format"
```

**Parallel-Safe**: N/A (utility library, not directly invoked)
**Dependencies**: None

---

## Agent Delegation Network

```mermaid
graph TD
    A[master-orchestrator<br/>TOP-LEVEL COORDINATOR] --> B[symlink-guardian<br/>PARALLEL-SAFE]
    A --> C[constitutional-compliance-agent<br/>PARALLEL-SAFE]
    A --> D[documentation-guardian<br/>PARALLEL-SAFE]
    A --> E[project-health-auditor<br/>PARALLEL-SAFE]
    A --> F[repository-cleanup-specialist<br/>PARALLEL-SAFE]
    A --> G[astro-build-specialist<br/>PARALLEL-SAFE]
    A --> H[git-operations-specialist<br/>SEQUENTIAL ONLY]

    D -.requires.-> B
    H -.requires.-> B
    H -.requires.-> D
    F -.delegates Git.-> H
    G -.delegates Git.-> H

    B -.uses.-> I[constitutional-workflow-orchestrator<br/>UTILITY LIBRARY]
    C -.uses.-> I
    H -.uses.-> I

    style A fill:#ff6b6b
    style H fill:#ffd43b
    style I fill:#51cf66
    style B fill:#74c0fc
    style C fill:#74c0fc
    style D fill:#74c0fc
    style E fill:#74c0fc
    style F fill:#74c0fc
    style G fill:#74c0fc
```

**Legend**:
- **Red**: Master coordinator
- **Yellow**: Sequential-only (no parallel execution)
- **Green**: Utility library (not directly invoked)
- **Blue**: Parallel-safe agents

---

## Parallel Execution Strategy

### Phase-Based Execution

**Phase 1 (Parallel)**:
```bash
├─ symlink-guardian
├─ constitutional-compliance-agent
├─ project-health-auditor
└─ repository-cleanup-specialist
```

**Phase 2 (Parallel, depends on Phase 1)**:
```bash
├─ documentation-guardian (requires symlink-guardian complete)
└─ astro-build-specialist
```

**Phase 3 (Sequential ONLY)**:
```bash
└─ git-operations-specialist (requires ALL previous phases complete)
```

### Dependency Management

**Strict Ordering Rules**:
1. symlink-guardian MUST complete before documentation-guardian
2. documentation-guardian MUST complete before git-operations-specialist
3. git-operations-specialist MUST run sequentially (never parallel)
4. Parallel agents can run simultaneously if no dependencies

**Example Multi-Agent Workflow**:
```
User Request: "Audit project, fix issues, rebuild website, commit changes"

master-orchestrator decomposition:
┌─ Phase 1 (Parallel) ─────────────────────┐
│ • project-health-auditor                 │
│ • symlink-guardian                       │
│ • constitutional-compliance-agent        │
└──────────────────────────────────────────┘
         ↓ (wait for completion)
┌─ Phase 2 (Parallel) ─────────────────────┐
│ • documentation-guardian                 │
│ • astro-build-specialist                 │
└──────────────────────────────────────────┘
         ↓ (wait for completion)
┌─ Phase 3 (Sequential) ───────────────────┐
│ • git-operations-specialist              │
└──────────────────────────────────────────┘
```

---

## Slash Command Integration

The agent system is exposed through constitutional slash commands:

### /guardian-health
**Agents Invoked**: project-health-auditor, documentation-guardian, astro-build-specialist

**Execution**: ALL THREE IN PARALLEL

**Output**: Consolidated health report covering:
- Context7 MCP status
- GitHub MCP status
- Documentation symlinks
- Astro build status
- GitHub Pages deployment readiness

---

### /guardian-documentation
**Agents Invoked**: master-orchestrator, constitutional-compliance-agent, documentation-guardian, symlink-guardian

**Execution**: Coordinated by master-orchestrator

**Output**: Comprehensive documentation integrity report:
- Agent system verification (9 agents + registry)
- Documentation structure (documentations/ organization)
- Symlink integrity (CLAUDE.md/GEMINI.md → AGENTS.md)
- Cross-reference validation
- Consolidation compliance
- Agent documentation consistency

---

### /guardian-cleanup
**Agents Invoked**: repository-cleanup-specialist, git-operations-specialist

**Execution**: Sequential (cleanup analysis → Git operations)

**Output**: Cleanup report with constitutional Git workflow

---

### /guardian-commit
**Agents Invoked**: symlink-guardian, git-operations-specialist

**Execution**: Sequential (symlink verification → Git commit)

**Output**: Constitutional commit with branch preservation

---

### /guardian-deploy
**Agents Invoked**: astro-build-specialist, git-operations-specialist

**Execution**: Sequential (build validation → deployment commit)

**Output**: Complete deployment with constitutional compliance

---

## Verification & Testing Loop

**Every agent execution includes**:

```python
def verify_and_finalize(results):
    verification_checks = [
        check_symlink_integrity(),
        check_documentation_size(),
        check_build_output(),
        check_git_status(),
        check_constitutional_compliance()
    ]

    if any_check_fails:
        # Identify which agents need re-execution
        retry_agents = determine_retry_agents(failed_checks)

        # Re-execute with improved context
        return execute_orchestrated_workflow(
            generate_retry_plan(retry_agents, failed_checks)
        )

    return success
```

---

## Error Handling & Recovery

### Error Classification

**Transient Errors**:
- Action: Retry immediately
- Max retries: 3

**Input Errors**:
- Action: Fix input and retry
- Max retries: 2

**Dependency Failures**:
- Action: Fix upstream agent, then retry downstream
- Max retries: 2

**Constitutional Violations**:
- Action: Abort and report to user immediately
- Max retries: 0 (manual intervention required)

---

## Constitutional Compliance

**ALL agents enforce**:
1. Branch preservation (NEVER delete without permission)
2. Constitutional branch naming (YYYYMMDD-HHMMSS-type-description)
3. Constitutional commit formatting (with Claude Code footer)
4. Zero GitHub Actions cost (all CI/CD runs locally first)
5. Symlink integrity (CLAUDE.md/GEMINI.md → AGENTS.md)
6. Documentation size limits (AGENTS.md < 40KB)
7. .nojekyll file preservation (CRITICAL for GitHub Pages)

---

## Best Practices

### For AI Assistants

**DO**:
- Use master-orchestrator for complex multi-agent tasks
- Verify symlink integrity before Git operations
- Run parallel agents simultaneously when possible
- Always check dependencies before execution
- Validate all outputs before marking tasks complete

**DON'T**:
- Run git-operations-specialist in parallel
- Skip dependency validation
- Bypass constitutional workflows
- Delete branches without explicit permission
- Remove .nojekyll file under any circumstances

---

## Agent File Locations

All agents stored in:
```
.claude/agents/
├── master-orchestrator.md
├── symlink-guardian.md
├── constitutional-compliance-agent.md
├── documentation-guardian.md
├── git-operations-specialist.md
├── astro-build-specialist.md
├── project-health-auditor.md
├── repository-cleanup-specialist.md
└── constitutional-workflow-orchestrator.md
```

All slash commands stored in:
```
.claude/commands/
├── guardian-health.md
├── guardian-documentation.md
├── guardian-cleanup.md
├── guardian-commit.md
└── guardian-deploy.md
```

---

## References

- **AGENTS.md**: Single source of truth for AI assistant instructions
- **AGENT_REGISTRY.md**: (Planned) Centralized agent capability registry
- **.claude/agents/**: Agent implementation files
- **.claude/commands/**: Slash command definitions
- **documentations/developer/architecture/**: Architecture documentation
- **.runners-local/workflows/**: Local CI/CD infrastructure

---

**Version**: 1.0
**Last Updated**: 2025-11-15
**Status**: ACTIVE - CONSTITUTIONAL COMPLIANCE REQUIRED
