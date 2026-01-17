# Feature Specification: Wave 1 - Scripts Documentation Foundation

**Feature Branch**: `002-scripts-documentation`
**Created**: 2026-01-18
**Status**: Draft
**Input**: User description: "Wave 1: Foundation - Create documentation for scripts directory including: (1) /scripts/README.md master index for 114 scripts, (2) Consolidate 4+ overlapping MCP guides into single source, (3) /scripts/007-update/README.md for update script discovery, (4) /scripts/007-diagnostics/README.md for boot diagnostics docs, (5) Update ai-cli-tools.md to fix 'not created' text since scripts actually exist"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Script Discovery via Master Index (Priority: P1)

A developer or AI assistant needs to find the right script for a specific task (e.g., "how do I update Ghostty?" or "where is the uninstall script for Node.js?"). Currently, with 114 scripts across 11 directories and no index, discovery requires manual exploration or grep searches.

**Why this priority**: This is the highest-value deliverable. Without a master index, both humans and AI waste time navigating the scripts directory. The index enables efficient task execution and reduces errors from using wrong scripts.

**Independent Test**: Can be fully tested by searching the README for any tool name (e.g., "ghostty", "nodejs", "zsh") and finding the correct script path within 10 seconds.

**Acceptance Scenarios**:

1. **Given** I am in the `/scripts` directory, **When** I open README.md, **Then** I see a categorized index of all 114 scripts with brief descriptions
2. **Given** I need to update a specific tool, **When** I search the README for that tool name, **Then** I find the exact script path and its purpose
3. **Given** I am an AI assistant tasked with running a script, **When** I read the scripts README, **Then** I can identify the correct script without exploring subdirectories

---

### User Story 2 - MCP Setup from Single Source (Priority: P2)

A developer setting up a new machine needs to configure MCP servers. Currently, 5 separate MCP documentation files exist with overlapping information, causing confusion about which guide to follow.

**Why this priority**: MCP configuration is critical for AI assistant functionality. Consolidation eliminates confusion and ensures consistent setup across machines.

**Independent Test**: Can be fully tested by following the consolidated guide on a fresh system to configure all 7 MCP servers successfully.

**Acceptance Scenarios**:

1. **Given** I need to set up MCP servers, **When** I look for documentation, **Then** I find ONE authoritative guide (not 5 separate files)
2. **Given** I am configuring Context7 MCP, **When** I follow the consolidated guide, **Then** I have all necessary information without referencing other documents
3. **Given** the 4 individual MCP guides (context7, github, markitdown, playwright), **When** consolidated, **Then** they redirect to or are replaced by the single source

---

### User Story 3 - Update Script Discovery (Priority: P3)

A maintainer wants to understand what update scripts exist and how they work. The `007-update/` directory contains 12 update scripts but no documentation explaining their purpose, usage, or dependencies.

**Why this priority**: Update scripts are run frequently (daily cron, manual updates). Documentation prevents misuse and aids troubleshooting.

**Independent Test**: Can be fully tested by reading the README and understanding how to update any tool without examining script source code.

**Acceptance Scenarios**:

1. **Given** I am in `/scripts/007-update/`, **When** I open README.md, **Then** I see a list of all 12 update scripts with their purposes
2. **Given** I want to update a specific tool manually, **When** I read the README, **Then** I understand any prerequisites and expected behavior
3. **Given** I am troubleshooting a failed update, **When** I consult the README, **Then** I find information about logs and common issues

---

### User Story 4 - Boot Diagnostics Understanding (Priority: P4)

A developer needs to run system diagnostics or understand the boot diagnostics feature. The `007-diagnostics/` directory has scripts but no documentation explaining the diagnostic workflow.

**Why this priority**: Diagnostics are used for troubleshooting and health checks. Documentation enables proper usage.

**Independent Test**: Can be fully tested by reading the README and successfully running boot diagnostics without prior knowledge.

**Acceptance Scenarios**:

1. **Given** I am in `/scripts/007-diagnostics/`, **When** I open README.md, **Then** I understand what diagnostics are available
2. **Given** I want to run a quick system scan, **When** I read the README, **Then** I know which script to use and what output to expect

---

### User Story 5 - Accurate AI Tools Documentation (Priority: P5)

A developer reading `ai-cli-tools.md` sees "scripts not yet created" but the scripts actually exist. This causes confusion and wastes time.

**Why this priority**: Inaccurate documentation erodes trust and causes unnecessary investigation. Quick fix with high ROI.

**Independent Test**: Can be fully tested by verifying that all script paths mentioned in the documentation exist and the status reflects reality.

**Acceptance Scenarios**:

1. **Given** the ai-cli-tools.md file, **When** I read the status section, **Then** it accurately reflects that scripts exist
2. **Given** the scripts table in ai-cli-tools.md, **When** I check each listed path, **Then** all paths resolve to actual files

---

### Edge Cases

- What happens when a script is added/removed? README should include "last updated" date and note about keeping index current
- How does consolidated MCP guide handle server-specific troubleshooting? Include expandable/linked sections per server
- What if update script fails silently? 007-update README should document log locations

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `/scripts/README.md` MUST list all scripts organized by stage directory (000-007, mcp, vhs)
- **FR-002**: `/scripts/README.md` MUST include brief description (10-20 words) for each script
- **FR-003**: MCP documentation MUST be consolidated into single authoritative file at `.claude/instructions-for-agents/guides/mcp-setup.md`
- **FR-004**: Individual MCP guides (context7-mcp.md, github-mcp.md, markitdown-mcp.md, playwright-mcp.md) MUST redirect to or be replaced by consolidated guide
- **FR-005**: `/scripts/007-update/README.md` MUST document all 12 update scripts with usage examples
- **FR-006**: `/scripts/007-diagnostics/README.md` MUST explain diagnostic workflow including detectors/ and lib/ subdirectories
- **FR-007**: `ai-cli-tools.md` MUST be updated to reflect that 4 scripts now exist (install, uninstall, confirm, update)
- **FR-008**: All new documentation MUST follow existing project documentation patterns (markdown, no emojis unless existing)

### Key Entities

- **Script**: Shell script file with stage prefix (000-007), tool name, and action (check, install, uninstall, etc.)
- **MCP Server**: Model Context Protocol server configuration (7 total: Context7, GitHub, MarkItDown, Playwright, HuggingFace, shadcn x2)
- **Stage Directory**: Numbered directory (000-007) representing installation pipeline stage

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Time to find correct script reduces from >2 minutes (manual search) to <30 seconds (README lookup)
- **SC-002**: MCP documentation consolidation reduces file count from 5 to 1 primary guide (with optional per-server details)
- **SC-003**: 100% of scripts in `/scripts/` directory are documented in the master README
- **SC-004**: New contributor can set up all MCP servers following only the consolidated guide (no external references needed)
- **SC-005**: ai-cli-tools.md accurately reflects current state with 0 false "not created" claims

## Assumptions

- Existing script organization (000-007 stages) is stable and will not change during this work
- The 5 MCP guide files can be consolidated without losing critical information
- Script descriptions can be derived from script headers, filenames, and brief code review
- The `mcp-new-machine-setup.md` file is the best candidate for the consolidated guide location
- No new scripts will be added during this documentation sprint

## Out of Scope

- Creating new scripts (documentation only)
- Refactoring existing scripts
- Automated documentation generation tooling
- Changes to script functionality
- Non-scripts documentation (outside `/scripts/` directory, except MCP consolidation and ai-cli-tools fix)
