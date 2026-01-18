# Feature Specification: Claude Agents User-Level Consolidation

**Feature Branch**: `005-claude-agents`
**Created**: 2026-01-18
**Status**: Draft
**Input**: Consolidate 65 Claude Code agents to user-level installation pattern (same as skills). Move agents from .claude/agents/ to .claude/agent-sources/, create combined install script that copies to ~/.claude/agents/ for cross-computer portability.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fresh System Setup (Priority: P1)

A developer clones the ghostty-config-files repository on a new computer and wants all 65 Claude Code agents available for use across all projects on that system.

**Why this priority**: This is the primary use case - enabling cross-computer portability of Claude Code configuration. Without this, users must manually configure agents on each machine.

**Independent Test**: Can be fully tested by cloning the repo on a fresh system, running the install script, and verifying agents are available in Claude Code.

**Acceptance Scenarios**:

1. **Given** a freshly cloned repository with no user-level agents, **When** the user runs `./scripts/install-claude-config.sh`, **Then** all 65 agents are copied to `~/.claude/agents/` and a success message displays the count of installed agents.

2. **Given** the install script has completed, **When** the user opens Claude Code in any project on that system, **Then** all 65 agents are available for use without duplicates.

3. **Given** agents exist at user level, **When** the user navigates to `.claude/agents/` in the project directory, **Then** the directory is empty or does not exist (no project-level agents causing duplicates).

---

### User Story 2 - Update Agents Across Computers (Priority: P1)

A developer has multiple computers with the repository cloned and wants to update agents on all systems when the agent definitions change.

**Why this priority**: Critical for maintaining consistency across a fleet of development machines - core value proposition.

**Independent Test**: Can be tested by modifying an agent definition, committing, pulling on another machine, and re-running the install script.

**Acceptance Scenarios**:

1. **Given** an agent definition has been updated in the repository, **When** the user runs `git pull && ./scripts/install-claude-config.sh`, **Then** the updated agent is copied to user-level, overwriting the previous version.

2. **Given** the install script runs multiple times (idempotent), **When** no changes have been made to agent sources, **Then** the script completes successfully with no errors and agents remain unchanged.

---

### User Story 3 - Combined Skills and Agents Installation (Priority: P2)

A developer wants a single command to install both skills (4 files) and agents (65 files) to user-level directories.

**Why this priority**: Convenience feature that simplifies onboarding - reduces two commands to one.

**Independent Test**: Can be tested by running the combined script and verifying both `~/.claude/commands/` (skills) and `~/.claude/agents/` (agents) contain the expected files.

**Acceptance Scenarios**:

1. **Given** a clean user-level Claude directory, **When** the user runs `./scripts/install-claude-config.sh`, **Then** 4 skills are installed to `~/.claude/commands/` AND 65 agents are installed to `~/.claude/agents/`.

2. **Given** deprecated skills or agents exist at user level, **When** the install script runs, **Then** deprecated files are removed before new files are installed.

---

### User Story 4 - Clean Up Deprecated Configuration (Priority: P3)

A developer has old agent or skill files from previous versions and wants the install script to clean them up automatically.

**Why this priority**: Maintenance feature to ensure clean state - less critical than core installation.

**Independent Test**: Can be tested by creating dummy deprecated files at user level, running install, and verifying they are removed.

**Acceptance Scenarios**:

1. **Given** old non-prefixed skill files exist at `~/.claude/commands/` (e.g., `health-check.md` instead of `001-health-check.md`), **When** the install script runs, **Then** deprecated files are removed and correct files are installed.

---

### Edge Cases

- What happens when `~/.claude/agents/` directory does not exist? → Script creates it automatically.
- What happens when user has custom agents at user level not from this project? → Script only manages agents that match the project's naming convention; custom agents are preserved.
- What happens when disk is full during installation? → Script fails gracefully with clear error message.
- What happens when source files are missing from `.claude/agent-sources/`? → Script reports which files are missing and continues with available files.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST move all 65 agent definition files from `.claude/agents/` to `.claude/agent-sources/` directory.
- **FR-002**: System MUST create a combined install script `scripts/install-claude-config.sh` that installs both skills and agents.
- **FR-003**: System MUST copy agent files from `.claude/agent-sources/` to `~/.claude/agents/` when the install script runs.
- **FR-004**: System MUST create the `~/.claude/agents/` directory if it does not exist.
- **FR-005**: System MUST remove deprecated skill files from user-level during installation (files without `001-` prefix).
- **FR-006**: System MUST preserve any custom user agents that don't match project naming patterns.
- **FR-007**: System MUST display installation summary showing count of skills and agents installed.
- **FR-008**: System MUST be idempotent - running multiple times produces same result without errors.
- **FR-009**: System MUST remove or deprecate the old `scripts/install-claude-skills.sh` script (superseded by combined script).
- **FR-010**: System MUST ensure `.claude/agents/` directory in the project is empty or removed after migration.

### Key Entities

- **Agent Source File**: A markdown file with YAML frontmatter defining a Claude Code agent, stored in `.claude/agent-sources/` for version control.
- **Installed Agent**: A copy of an agent source file at `~/.claude/agents/` that Claude Code discovers and loads.
- **Install Script**: Bash script that copies skills and agents from project source directories to user-level directories.
- **Deprecated File**: An old skill or agent file that should be removed during installation (e.g., files from previous naming conventions).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 65 agents are successfully installed to user-level on a fresh system in under 5 seconds.
- **SC-002**: Zero duplicate agents appear in Claude Code's available agents list after installation.
- **SC-003**: Installation works identically across all computers where the repository is cloned.
- **SC-004**: A single command (`./scripts/install-claude-config.sh`) installs both skills (4) and agents (65).
- **SC-005**: Repository structure is clean - no agent files exist in `.claude/agents/` after migration.
- **SC-006**: 100% of existing agent functionality is preserved - all 65 agents work after migration.

## Assumptions

- Claude Code discovers agents from `~/.claude/agents/` at user level (verified behavior).
- Agent files use YAML frontmatter with `name:` field for discovery.
- The 5-tier agent hierarchy (0-4) and naming convention (000-*, 001-*, etc.) is preserved.
- Bash shell is available on all target systems (Ubuntu Linux).

## Out of Scope

- Windows or macOS support (Ubuntu Linux only).
- GUI/TUI integration for agent installation (command-line only for now).
- Syncing agents between computers over network (manual git pull + install required).
- Version pinning or rollback of agent definitions.
