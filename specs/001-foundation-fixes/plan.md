# Implementation Plan: Wave 0 Foundation Fixes

**Branch**: `001-foundation-fixes` | **Date**: 2026-01-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-foundation-fixes/spec.md`

## Summary

Three critical foundation tasks that must complete before any other development work:
1. Create MIT LICENSE file for legal clarity
2. Fix broken link to `local-cicd-guide.md`
3. Unify agent tier definitions across 4 documentation files

This is a **documentation-only feature** with no code changes.

## Technical Context

**Language/Version**: Markdown (documentation only)
**Primary Dependencies**: N/A
**Storage**: N/A (static files)
**Testing**: Manual verification (link checking, file existence, content comparison)
**Target Platform**: GitHub repository
**Project Type**: Documentation
**Performance Goals**: N/A
**Constraints**: N/A
**Scale/Scope**: 6 files total (1 LICENSE + 1 new guide + 4 existing docs to update)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Script Consolidation | PASS | No scripts created - documentation only |
| II. Branch Preservation | PASS | Using `001-foundation-fixes` branch, no deletions |
| III. Local-First CI/CD | PASS | Will run validation before commits |
| IV. Modularity Limits | PASS | No scripts involved |
| V. Symlink Single Source | PASS | AGENTS.md edits only for tier unification |

**Gate Result**: All principles satisfied. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-foundation-fixes/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output (minimal for docs-only)
├── data-model.md        # Phase 1 output (entities only, no DB)
├── quickstart.md        # Implementation guide
├── contracts/           # N/A for documentation feature
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Files to Create/Modify

```text
Repository Root:
├── LICENSE              # NEW: MIT license file

Documentation:
├── .claude/instructions-for-agents/
│   ├── guides/
│   │   └── local-cicd-guide.md    # NEW: Fix broken link
│   ├── architecture/
│   │   ├── agent-registry.md      # UPDATE: Tier table (source of truth)
│   │   ├── agent-delegation.md    # UPDATE: Tier table
│   │   └── system-architecture.md # UPDATE: Tier table
│   └── requirements/
│       └── local-cicd-operations.md  # VERIFY: Link works after fix
└── AGENTS.md                         # UPDATE: Tier table
```

**Structure Decision**: No source code structure needed. This is purely documentation work targeting existing markdown files.

## Complexity Tracking

> No violations to justify - all Constitution gates pass.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

## Implementation Tasks

### Task 1: LICENSE File Creation (P1)

**Goal**: Create MIT LICENSE file at repository root

**Steps**:
1. Create `LICENSE` file with standard MIT license text
2. Use copyright year: 2026
3. Use copyright holder: Repository maintainer
4. Verify GitHub detects license correctly

**Acceptance**: GitHub license detection shows "MIT"

### Task 2: Broken Link Fix (P1)

**Goal**: Fix broken link `../guides/local-cicd-guide.md`

**Steps**:
1. Create `.claude/instructions-for-agents/guides/local-cicd-guide.md`
2. Add meaningful content about local CI/CD operations
3. Content should complement (not duplicate) `local-cicd-operations.md`
4. Verify link in `local-cicd-operations.md` resolves

**Acceptance**: All links in `local-cicd-operations.md` resolve to existing files

### Task 3: Tier Unification (P2)

**Goal**: Unify tier definitions across 4 files

**Canonical Structure** (from `agent-registry.md`):
| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| 0 | Sonnet | 5 | Complete workflows |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 5 | Core operations |
| 3 | Sonnet | 4 | Utility operations |
| 4 | Haiku | 50 | Atomic execution |

**Files to Update**:
1. `AGENTS.md` - Update tier table
2. `.claude/instructions-for-agents/architecture/agent-delegation.md` - Update tier table
3. `.claude/instructions-for-agents/architecture/system-architecture.md` - Update tier table
4. `.claude/instructions-for-agents/architecture/agent-registry.md` - Verify (source of truth)

**Acceptance**: Tier counts and model assignments match across all 4 files
