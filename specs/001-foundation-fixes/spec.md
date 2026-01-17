# Feature Specification: Wave 0 Foundation Fixes

**Feature Branch**: `001-foundation-fixes`
**Created**: 2026-01-18
**Status**: Draft
**Input**: Three critical blockers that must complete before any other work: LICENSE file creation, broken link fix, and tier definition unification.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - LICENSE File Creation (Priority: P1)

A contributor wants to fork or use the Ghostty Configuration Files project. They check the repository for licensing terms to understand usage rights and obligations before incorporating it into their workflow.

**Why this priority**: Without a LICENSE file, the project has no legal clarity for usage, README badges are broken, and potential contributors may avoid the project due to unclear intellectual property terms.

**Independent Test**: Can be fully tested by verifying LICENSE file exists at repository root with valid MIT license content.

**Acceptance Scenarios**:

1. **Given** the repository root directory, **When** a user looks for licensing information, **Then** they find a LICENSE file with MIT license text including the correct year and copyright holder.
2. **Given** the README.md file, **When** displaying license badges, **Then** the badge link resolves correctly to the LICENSE file.

---

### User Story 2 - Broken Link Resolution (Priority: P1)

An AI assistant (Claude or Gemini) navigates documentation following the local-cicd-operations.md guide. It encounters a link to "Local CI/CD Guide" that should provide operational how-to information but leads to a non-existent file.

**Why this priority**: Broken links cause AI assistants to hit dead ends, reducing their effectiveness when helping users. This directly impacts the core value proposition of AI-assisted development.

**Independent Test**: Can be fully tested by clicking/following all links in local-cicd-operations.md and verifying each target file exists.

**Acceptance Scenarios**:

1. **Given** the file `.claude/instructions-for-agents/requirements/local-cicd-operations.md`, **When** following the link to "Local CI/CD Guide" (`../guides/local-cicd-guide.md`), **Then** the target file exists and contains relevant operational guidance.
2. **Given** all documentation files in `.claude/instructions-for-agents/`, **When** scanning for internal links, **Then** 100% of links resolve to existing files.

---

### User Story 3 - Agent Tier Definition Unification (Priority: P2)

A developer or AI assistant reads documentation about the agent system to understand which agent tier to use for a task. They encounter conflicting tier counts (4-tier vs 5-tier) across different documentation files, causing confusion about the actual architecture.

**Why this priority**: Inconsistent documentation undermines trust and causes incorrect agent selection decisions. While not blocking functionality, it degrades the developer experience.

**Independent Test**: Can be fully tested by comparing tier tables across all architecture documentation files and verifying they describe the same structure.

**Acceptance Scenarios**:

1. **Given** the files `AGENTS.md`, `agent-registry.md`, `agent-delegation.md`, and `system-architecture.md`, **When** comparing their tier definitions, **Then** all files show the same 5-tier structure (Tier 0, 1, 2, 3, 4) with consistent agent counts.
2. **Given** any architecture documentation file, **When** reading about tiers, **Then** the tier numbering, model assignments, and agent counts match all other documentation.

---

### Edge Cases

- What happens when README badge links point to LICENSE before file exists? Badge displays as broken/missing.
- How does the system handle if local-cicd-guide.md is created but empty? Link resolves but provides no value - content must be meaningful.
- What if tier counts change in the future? All documentation files must be updated together to maintain consistency.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST contain a LICENSE file at the root directory with MIT license text
- **FR-002**: LICENSE file MUST include copyright year (2026) and copyright holder name
- **FR-003**: All internal documentation links in `.claude/instructions-for-agents/` MUST resolve to existing files
- **FR-004**: The broken link `../guides/local-cicd-guide.md` MUST either be fixed to point to an existing file or the target file MUST be created
- **FR-005**: All tier definition tables MUST show consistent 5-tier structure across all documentation files
- **FR-006**: Tier definitions MUST include: Tier 0 (Sonnet Workflows, 5 agents), Tier 1 (Opus, 1 agent), Tier 2 (Sonnet Core, 5 agents), Tier 3 (Sonnet Utility, 4 agents), Tier 4 (Haiku, 50 agents)
- **FR-007**: Summary tables MAY combine Tiers 2-3 as "2-3" but MUST note this is a combined count (9 total)

### Key Entities

- **LICENSE**: Legal document defining usage rights; attributes: license type (MIT), year, copyright holder
- **Documentation Link**: Reference from one markdown file to another; attributes: source file, target path, link text
- **Tier Definition**: Agent classification structure; attributes: tier number, model name, agent count, purpose description

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: LICENSE file exists and passes automated license detection tools (e.g., GitHub's license detection shows "MIT")
- **SC-002**: 100% of internal documentation links resolve to existing files (0 broken links)
- **SC-003**: Tier definition consistency: 100% match across all 4 affected documentation files
- **SC-004**: All 3 tasks can be completed in under 40 minutes total effort
- **SC-005**: No Wave 1+ tasks are started before all Wave 0 items are marked complete in ROADMAP.md

## Assumptions

- MIT license is the appropriate choice (based on open-source terminal configuration project nature)
- Copyright holder is the repository owner/maintainer
- The correct tier structure is 5-tier (0-4) based on agent-registry.md as the authoritative source
- Fixing the broken link by creating local-cicd-guide.md is preferred over removing the link (preserves navigation intent)

## Scope Boundaries

**In Scope**:
- LICENSE file creation
- Fixing the specific broken link in local-cicd-operations.md
- Unifying tier tables in 4 documentation files (AGENTS.md, agent-registry.md, agent-delegation.md, system-architecture.md)

**Out of Scope**:
- Other broken links not in local-cicd-operations.md (Wave 1+ concern)
- Content quality improvements beyond tier consistency
- Adding new documentation sections
