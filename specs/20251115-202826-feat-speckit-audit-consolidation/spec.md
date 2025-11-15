# Feature Specification: Spec-Kit Audit & Consolidation

**Feature Branch**: `001-speckit-audit-consolidation`
**Created**: 2025-11-15
**Status**: Draft
**Input**: User description: "consolidate all speckit requirements help me review which specification has been implemented, and for those implementation that's outside of spec-kit can you incorporate them especially those that are latest. help to review why some tools are not installed at all even though it is a requirement, list out all the apps and tools to be installed via this application. and help me identify the reason why there are installed application but there are multiple app icons when clicking on 'Show Apps' within ubuntu 25.10"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Specification Implementation Audit (Priority: P1)

As a project maintainer, I want to review all existing specifications (001, 002, 004, 005, and task archives) and identify their implementation status, so that I can understand which features are complete, partially complete, or not yet started, and ensure spec-kit methodologies are applied consistently across all specifications.

**Why this priority**: This provides foundational visibility into the current state of the project. Without knowing what's implemented vs. planned, we cannot effectively prioritize future work or identify gaps in the development process.

**Independent Test**: Can be fully tested by generating a comprehensive audit report that lists each specification, its stated goals, implementation status percentage, and evidence of completion (commits, files, functionality), verifiable against the actual codebase state.

**Acceptance Scenarios**:

1. **Given** multiple specifications exist in documentations/specifications/ and specs/ directories, **When** I run the audit command, **Then** I see a complete report showing each specification's number, name, implementation status (percentage complete), and key deliverables with their completion status
2. **Given** Spec 001 (repo-structure-refactor) claims 24% completion, **When** I review the audit, **Then** I see exactly which phases are complete (1-3) and which are pending (4-7) with specific task references
3. **Given** Spec 002 (advanced-terminal-productivity) exists, **When** the audit runs, **Then** I see its implementation status showing whether AI tools (zsh-codex, Copilot CLI), advanced themes (Powerlevel10k/Starship), and performance optimizations are implemented or planned
4. **Given** Spec 004 (modern-web-development) and Spec 005 (apt-snap-migration) exist, **When** I review the audit, **Then** I see their planning status and whether implementation has begun

---

### User Story 2 - Tool Installation Audit & Gap Analysis (Priority: P2)

As a system administrator, I want to audit all required tools defined in CLAUDE.md and README.md against actual installation status, identifying missing tools and determining why they weren't installed, so that I can ensure the system meets all documented requirements and understand installation gaps.

**Why this priority**: This directly addresses the user's concern about missing required tools. It's critical for system completeness but secondary to understanding specification status since missing tools may be due to incomplete spec implementation.

**Independent Test**: Can be fully tested by comparing the required tools list from documentation against actual system installation status (via command -v checks), generating a report showing installed vs. missing tools with installation method tracking (apt, snap, cargo, npm, manual).

**Acceptance Scenarios**:

1. **Given** README.md lists required modern Unix tools (eza, bat, ripgrep, fzf, zoxide, fd), **When** I run the tool audit, **Then** I see each tool's installation status with version numbers for installed tools and "NOT INSTALLED" markers for missing tools
2. **Given** bat and ripgrep are documented as required but not installed, **When** the audit analyzes installation logs, **Then** I see the reason why installation was skipped (e.g., not in start.sh install script, manual installation required, or installation failed)
3. **Given** multiple installation methods exist (apt, snap, cargo, npm), **When** the audit runs, **Then** I see which method was used for each installed tool and which method should be used for missing tools
4. **Given** AI tools require Node.js via fnm, **When** the audit checks dependencies, **Then** I see the complete dependency chain showing fnm → Node.js → npm → Claude Code/Gemini CLI with status for each link

---

### User Story 3 - Duplicate App Icon Investigation (Priority: P3)

As an Ubuntu 25.10 user, I want to understand why multiple app icons appear in "Show Apps" for the same application, and get a remediation plan to eliminate duplicates, so that I have a clean, organized application menu without confusion.

**Why this priority**: This is a user experience issue affecting the desktop environment but doesn't impact core terminal functionality or project development. It's important for polish but less critical than specification and tool audits.

**Independent Test**: Can be fully tested by scanning /usr/share/applications and ~/.local/share/applications for duplicate .desktop files, identifying snap vs. apt installations for the same application, and providing a conflict resolution report.

**Acceptance Scenarios**:

1. **Given** apps may be installed via both snap and apt, **When** I run the duplicate detection scan, **Then** I see a report listing applications with multiple .desktop entries, showing the file paths and installation methods for each duplicate
2. **Given** gnome-calculator, gnome-characters, evince, and libreoffice are installed as snaps, **When** the scan checks for apt versions, **Then** I see whether apt packages also exist and are causing duplicate icons
3. **Given** duplicate icons are detected, **When** the remediation plan is generated, **Then** I see specific commands to safely remove duplicates (preferring snap over apt for Ubuntu 25.10 per Spec 005 migration strategy)
4. **Given** no duplicate .desktop files exist at the filesystem level, **When** icons still appear multiple times, **Then** the audit investigates GNOME Shell cache, AppStream metadata, and desktop environment configuration issues

---

### Edge Cases

- What happens when a specification exists but has no implementation tracking (no tasks.md or progress indicators)? → Audit marks it as "STATUS UNKNOWN - Manual review required" with recommendation to add tracking
- How does the audit handle tools installed via unconventional methods (compiled from source, AppImage, Flatpak)? → Scans common installation locations (/usr/local/bin, ~/.local/bin, /opt) and marks as "CUSTOM INSTALLATION" with detected path
- What happens when desktop files exist for removed applications (orphaned entries)? → Flags as "ORPHANED" with validation check to confirm binary is missing and suggests removal
- How are spec-kit specifications (in specs/) differentiated from legacy specifications (in documentations/specifications/)? → Audit categorizes by directory and marks newer spec-kit format vs. legacy format
- What happens when a tool is required by one spec but not others? → Audit shows requirement source (which spec or documentation mandates it) to aid prioritization
- How does the audit handle version mismatches (installed version older/newer than required)? → Shows both required and installed versions with upgrade/downgrade recommendations

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST scan all specification directories (documentations/specifications/, specs/) and identify every specification by number, name, branch, and status
- **FR-002**: System MUST calculate implementation completion percentage for each specification based on tasks.md progress tracking or manual analysis of deliverables
- **FR-003**: System MUST identify which specifications follow spec-kit methodology (have spec.md, tasks.md, plan.md) vs. legacy format
- **FR-004**: System MUST extract and list all required tools from CLAUDE.md and README.md including core tools, modern Unix tools, AI tools, and development dependencies
- **FR-005**: System MUST verify installation status for each required tool using command -v checks and version detection
- **FR-006**: System MUST identify the installation method for each tool (apt, snap, cargo, npm, fnm, manual/source build)
- **FR-007**: System MUST analyze why missing tools weren't installed by checking start.sh script, installation logs, and dependency requirements
- **FR-008**: System MUST scan /usr/share/applications and ~/.local/share/applications for .desktop files and detect filename duplicates
- **FR-009**: System MUST identify applications installed via both snap and apt that could cause duplicate icons
- **FR-010**: System MUST provide remediation commands for removing duplicate desktop entries safely
- **FR-011**: System MUST generate a consolidated report showing all audit findings (specifications, tools, duplicates) in a single document
- **FR-012**: System MUST identify tools required by specifications but not listed in main documentation (spec-specific requirements)
- **FR-013**: System MUST track dependency chains (e.g., AI tools require Node.js which requires fnm) and validate complete installation paths
- **FR-014**: System MUST distinguish between required tools (mandatory for core functionality) and optional tools (nice-to-have or spec-specific)
- **FR-015**: System MUST provide actionable recommendations for each finding (install missing tools, complete pending specs, remove duplicates)

### Key Entities *(include if feature involves data)*

- **Specification Record**: Specification number/ID, name, branch name, directory path, status (draft/planning/implementation/complete), completion percentage, deliverables list (spec.md, plan.md, tasks.md presence), implementation evidence (commits, files, features)
- **Tool Record**: Tool name, required status (mandatory/optional), documentation source (README/CLAUDE/spec), installation status (installed/missing), installed version, installation method (apt/snap/cargo/npm/manual), installation path, dependency requirements
- **Desktop Entry Record**: Application name, .desktop file paths (all locations), installation method per entry (snap/apt/manual), duplicate status (unique/duplicate), recommended action (keep/remove)
- **Audit Report**: Timestamp, specification summary table, tool status matrix, duplicate icon findings, dependency validation results, actionable recommendations list, missing tool installation commands

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Specification audit accurately identifies all 5+ specifications and correctly calculates completion percentages within ±5% of manual verification
- **SC-002**: Tool audit detects 100% of required tools listed in CLAUDE.md and README.md with accurate installation status
- **SC-003**: Missing tool analysis correctly identifies installation gaps for bat and ripgrep and provides valid installation commands
- **SC-004**: Duplicate icon detection identifies all applications with multiple .desktop entries and provides safe removal commands
- **SC-005**: Consolidated audit report is generated in under 30 seconds on typical Ubuntu 25.10 system
- **SC-006**: Audit findings enable user to install all missing required tools in under 10 minutes following provided commands
- **SC-007**: Remediation of duplicate icons reduces "Show Apps" clutter, eliminating all confirmed duplicates after following recommendations
- **SC-008**: Dependency chain validation correctly maps all tool dependencies (e.g., Claude/Gemini → npm → Node.js → fnm) with 100% accuracy
- **SC-009**: Specification consolidation identifies all spec-kit format specifications and flags legacy specifications for potential migration
- **SC-010**: Report provides clear action items prioritized by impact (critical missing tools first, optional tools last)

## Current State Analysis *(included for context, not part of standard spec template)*

### Existing Specifications (Documented in CLAUDE.md and Files)

#### Implemented/In-Progress Specifications

1. **Spec 001: Repository Structure Refactoring** (documentations/specifications/001-repo-structure-refactor/)
   - Status: 24% complete (Phase 1-3 complete, Phase 4-7 pending)
   - Evidence: manage.sh exists, scripts/ modular structure started, documentations/ centralization complete
   - Outstanding: Full start.sh refactoring into 10+ modules, complete Astro documentation migration

2. **Spec 002: Advanced Terminal Productivity** (documentations/specifications/002-advanced-terminal-productivity/)
   - Status: Planning/specification only (no implementation detected)
   - Evidence: Spec exists but no tasks.md, plan.md, or implementation commits found
   - Outstanding: All four phases (AI integration, advanced theming, performance optimization, team features)

3. **Spec 004: Modern Web Development Stack** (documentations/specifications/004-modern-web-development/)
   - Status: Planning complete, awaiting /tasks command
   - Evidence: spec.md and OVERVIEW.md exist with complete requirements
   - Outstanding: Implementation tasks generation and execution

4. **Spec 005: Package Manager Migration** (specs/005-apt-snap-migration/)
   - Status: Specification draft complete
   - Evidence: spec.md with comprehensive FR-001 through FR-019
   - Outstanding: Implementation planning and execution

5. **Task Archive Consolidation** (specs/20251111-042534-feat-task-archive-consolidation/)
   - Status: Active feature development
   - Evidence: Branch exists with spec.md and tasks.md
   - Outstanding: Implementation completion

### Tool Installation Status (from System Audit)

#### Installed Tools (15/17 required tools = 88% coverage)

**Core Tools:**
- ✅ Ghostty 1.1.4-main+4742177da (built from source with Zig 0.14.0)
- ✅ ZSH 5.9 (Ubuntu system package)
- ✅ Zig 0.14.0 (manual installation to /usr/local/bin/)

**Modern Unix Tools (4/6 installed):**
- ✅ eza (Ubuntu apt package)
- ❌ **bat** (MISSING - documented as required in README:13)
- ❌ **ripgrep** (MISSING - documented as required in README:13)
- ✅ fzf 0.60 (Ubuntu apt package)
- ✅ zoxide 0.9.8 (installed to ~/.local/bin/)
- ✅ fd 10.3.0 (installed as fdfind to ~/.local/bin/)

**AI & Development Tools:**
- ✅ fnm 1.38.1 (Fast Node Manager in ~/.local/share/fnm/)
- ✅ Node.js v25.2.0 (via fnm)
- ✅ npm 11.6.2 (via fnm)
- ✅ Claude Code 2.0.42 (npm global in ~/.npm-global/bin/)
- ✅ Gemini CLI (alias to ptyxis wrapper)
- ✅ GitHub CLI 2.83.1 (apt package)
- ✅ uv 0.9.9 (Python package manager in ~/.local/bin/)
- ✅ specify (spec-kit CLI in ~/.local/bin/)

#### Missing Tool Analysis

**bat** and **ripgrep** are documented as required in README.md:13 but not installed:

- **Root Cause**: start.sh installation script likely doesn't include these tools in the automated installation sequence, or installation was attempted but failed silently
- **Installation Method**: Both available via apt on Ubuntu 25.10
- **Dependency Impact**: Non-critical - these are convenience tools for better file viewing (bat) and faster searching (ripgrep), not required for core Ghostty or AI tool functionality
- **Recommendation**: Add to start.sh automated installation or document as optional tools

### Duplicate App Icon Investigation (from System Scan)

**Finding**: Zero duplicate .desktop files at filesystem level (139 total .desktop files, no filename duplicates detected)

**Snap Installation Status**: 42 snap packages installed including:
- gnome-calculator (snap)
- gnome-characters (snap)
- evince (snap)
- libreoffice (snap)

**apt Package Check**: No conflicting apt packages found for these applications (dpkg query returned no matches)

**Conclusion**: If user experiences duplicate icons in "Show Apps", the issue is likely:
1. GNOME Shell cache inconsistency (requires `killall gnome-shell` or logout/login)
2. AppStream metadata duplication (snap and system AppStream both indexing)
3. Desktop environment specific bug in Ubuntu 25.10

**Remediation**: Recommend GNOME Shell cache refresh rather than package removal since no filesystem-level duplicates exist.

## Assumptions

- User has admin access to review specification files and installation logs
- System is Ubuntu 25.10 with standard directory structure (/usr/share/applications, ~/.local/share/applications)
- Specifications follow either spec-kit format (spec.md, tasks.md, plan.md) or legacy format (various structures)
- Required tools list in CLAUDE.md and README.md is authoritative and complete
- Tool installation methods are documented or discoverable via package manager queries
- Desktop entry duplicates are primarily caused by snap vs. apt package conflicts per Spec 005 migration context
- GNOME is the desktop environment (for .desktop file processing and "Show Apps" menu)
- Audit can access all specification directories and system commands without permission issues
