# Research: Wave 0 Foundation Fixes

**Date**: 2026-01-18
**Branch**: `001-foundation-fixes`
**Status**: Complete

## Research Tasks

This is a documentation-only feature. Research focused on verifying:
1. MIT license format requirements
2. Broken link target location
3. Canonical tier structure

---

## 1. MIT License Format

**Decision**: Use standard MIT license text with 2026 year

**Rationale**:
- MIT is the most permissive widely-used open source license
- Specification already determined MIT as appropriate choice
- Standard format ensures GitHub's license detection works correctly

**Alternatives Considered**:
- Apache 2.0: More complex, patent clauses unnecessary for config files
- BSD 3-Clause: Similar permissiveness, less widely recognized
- Unlicense: Too permissive, no attribution requirements

**License Template**:
```text
MIT License

Copyright (c) 2026 [Repository Owner]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 2. Broken Link Investigation

**Decision**: Create new file at `.claude/instructions-for-agents/guides/local-cicd-guide.md`

**Rationale**:
- Link exists in `local-cicd-operations.md` pointing to `../guides/local-cicd-guide.md`
- The guides directory exists: `.claude/instructions-for-agents/guides/`
- Creating the file preserves navigation intent (vs. removing the link)
- Content should provide operational how-to guidance complementing the requirements doc

**Alternatives Considered**:
- Remove the broken link: Loses navigation intent
- Redirect to existing file: No existing file serves the same purpose
- Inline the content: Would make `local-cicd-operations.md` too long

**Content Scope for New File**:
- Step-by-step local CI/CD workflow
- Common commands and their purposes
- Troubleshooting common issues
- Quick reference for daily operations

---

## 3. Tier Structure Verification

**Decision**: Use 5-tier structure (Tier 0-4) from `agent-registry.md` as source of truth

**Canonical Structure** (verified from `agent-registry.md`):

| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| **0** | **Sonnet** | **5** | Complete workflow agents (000-*) |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 5 | Core domain operations |
| 3 | Sonnet | 4 | Utility/support operations |
| 4 | Haiku | 50 | Atomic execution tasks |

**Total**: 65 agents

**Current State Analysis**:

| File | Current Format | Needs Update |
|------|---------------|--------------|
| `agent-registry.md` | 5-tier (correct) | No (source of truth) |
| `AGENTS.md` | Shows "2-3" combined | Yes - expand to full 5-tier |
| `agent-delegation.md` | Unknown | Check required |
| `system-architecture.md` | Unknown | Check required |

**Rationale**:
- `agent-registry.md` has most detailed agent information (65 agents documented)
- Combining tiers 2-3 loses granularity for agent selection
- Full 5-tier view provides clearer guidance for delegation decisions

**Alternatives Considered**:
- 4-tier (combining 2-3): Simpler but loses information
- Summary tables with footnotes: Acceptable where space is limited

---

## Summary

All NEEDS CLARIFICATION items resolved:

| Item | Resolution |
|------|------------|
| License format | MIT standard template |
| Broken link fix | Create new guide file |
| Tier structure | 5-tier from agent-registry.md |

**Phase 0 Complete** - Ready for Phase 1 (Design & Contracts)
