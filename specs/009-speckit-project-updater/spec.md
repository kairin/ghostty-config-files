# Feature Specification: SpecKit Project Updater

**Feature Branch**: `009-speckit-project-updater`
**Git Branch**: `20260121-XXXXXX-feat-speckit-project-updater` (constitutional format)
**Created**: 2026-01-21
**Status**: Draft
**Input**: TUI feature to update speckit installations across computer to enforce constitutional branch naming

## Problem Statement

When users install speckit via `uvx specify-ai init` for a new project, it uses GitHub's default speckit template which includes the older branch naming pattern (`NNN-feature-name`). Users of this repository (ghostty-config-files) have adopted a constitutional branch naming policy that mandates the format `YYYYMMDD-HHMMSS-type-description`.

Currently, there is no way to:
1. Track which projects on the user's computer have speckit installed
2. Compare those projects' speckit files against the canonical version in this repo
3. Automatically patch those files to enforce constitutional branch naming

Users must manually update each project's speckit files, which is error-prone and time-consuming.

## Proposed Solution

Add a "SpecKit Project Updater" feature to the TUI Extras menu that:
1. Maintains a list of project directories where speckit is installed
2. Scans those directories for `.specify/` folders
3. Compares speckit script files against the canonical versions in this repo
4. Shows a preview of proposed changes before patching
5. Creates timestamped backups before any modifications
6. Applies patches to enforce constitutional branch naming

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add Project Directory (Priority: P1)

As a user, I want to add project directories to the SpecKit Updater, so I can track which projects need constitutional branch naming enforcement.

**Why this priority**: Without the ability to add projects, no other functionality works. This is the foundation of the feature.

**Independent Test**: Navigate to SpecKit Project Updater → Add Project → Enter path → Verify project appears in list.

**Acceptance Scenarios**:

1. **Given** user is in SpecKit Project Updater view, **When** they select "Add Project", **Then** they see a text input for directory path
2. **Given** user enters a valid directory with `.specify/`, **When** they confirm, **Then** the project is added to the list with status "Pending Scan"
3. **Given** user enters a directory without `.specify/`, **When** they confirm, **Then** they see error "No speckit installation found"
4. **Given** user enters a non-existent directory, **When** they confirm, **Then** they see error "Directory does not exist"

---

### User Story 2 - Scan Project for Differences (Priority: P1)

As a user, I want to scan a project and see what files differ from the canonical version, so I understand what changes will be made.

**Why this priority**: Users need visibility into changes before applying them. This builds trust and prevents unwanted modifications.

**Independent Test**: Add a project → Select "Scan" → View list of differing files with line numbers.

**Acceptance Scenarios**:

1. **Given** a project is in the list, **When** user selects "Scan", **Then** system compares `.specify/scripts/bash/` files against canonical versions
2. **Given** scan completes, **When** differences exist, **Then** user sees list of files with specific line ranges that differ
3. **Given** scan completes, **When** no differences exist, **Then** user sees "Project is up to date"
4. **Given** scan is in progress, **When** user views the project, **Then** they see a spinner with "Scanning..."

---

### User Story 3 - Preview Changes Before Patching (Priority: P1)

As a user, I want to see exactly what changes will be made to each file before patching, so I can verify the patches are correct.

**Why this priority**: Blind patching could break projects. Users must see changes before applying.

**Independent Test**: Select project with differences → Choose "Preview Changes" → View side-by-side or unified diff.

**Acceptance Scenarios**:

1. **Given** a project has scanned differences, **When** user selects "Preview Changes", **Then** they see ViewDiff screen with file-by-file changes
2. **Given** preview is shown, **When** user navigates between files, **Then** they can see each file's proposed changes
3. **Given** preview is shown, **When** user presses Escape, **Then** they return to project detail without changes
4. **Given** multiple files have changes, **When** user views preview, **Then** they see count "File 1 of N"

---

### User Story 4 - Apply Patches with Backup (Priority: P1)

As a user, I want patches applied with automatic backup, so I can safely update my projects knowing I can rollback.

**Why this priority**: Core functionality - actually applying the changes. Backup is mandatory for safety.

**Independent Test**: Preview changes → Confirm "Apply" → Verify backup created and files patched.

**Acceptance Scenarios**:

1. **Given** user confirms apply, **When** patching starts, **Then** system creates backup at `{project}/.specify/.backup-{YYYYMMDD-HHMMSS}/`
2. **Given** backup is created, **When** patching proceeds, **Then** system modifies only the specific line ranges identified
3. **Given** patching completes successfully, **When** user views project, **Then** status shows "Up to date" with backup timestamp
4. **Given** patching fails, **When** error occurs, **Then** system restores from backup and shows error message

---

### User Story 5 - Remove Project from List (Priority: P2)

As a user, I want to remove projects I no longer want to track, so my list stays manageable.

**Why this priority**: Housekeeping feature, less critical than core functionality.

**Independent Test**: Select project → Choose "Remove" → Verify project no longer in list.

**Acceptance Scenarios**:

1. **Given** a project is in the list, **When** user selects "Remove", **Then** they see confirmation dialog
2. **Given** confirmation shown, **When** user confirms, **Then** project is removed from tracking list
3. **Given** project is removed, **When** user views list, **Then** the project no longer appears
4. **Given** project is removed, **When** the actual `.specify/` still exists, **Then** the files are NOT deleted (only tracking removed)

---

### User Story 6 - Batch Update All Projects (Priority: P2)

As a user, I want to update all tracked projects at once, so I can efficiently enforce constitutional naming across all my work.

**Why this priority**: Convenience feature for users with many projects.

**Independent Test**: With multiple projects showing differences → Select "Update All" → Verify all updated with backups.

**Acceptance Scenarios**:

1. **Given** multiple projects have differences, **When** user selects "Update All", **Then** they see batch preview listing all projects
2. **Given** batch preview shown, **When** user confirms, **Then** system processes each project sequentially with progress
3. **Given** batch update in progress, **When** one project fails, **Then** system shows error but continues with remaining projects
4. **Given** batch update completes, **When** user views list, **Then** each project shows individual success/failure status

---

### User Story 7 - Rollback from Backup (Priority: P2)

As a user, I want to rollback a patched project to its previous state, so I can undo changes if needed.

**Why this priority**: Safety net feature, important but not blocking core use.

**Independent Test**: Select patched project → Choose "Rollback" → Verify files restored from backup.

**Acceptance Scenarios**:

1. **Given** a project has been patched (backup exists), **When** user selects "Rollback", **Then** they see confirmation with backup timestamp
2. **Given** rollback confirmed, **When** system restores, **Then** files are copied from backup to original locations
3. **Given** rollback completes, **When** user scans project, **Then** differences reappear (pre-patch state)
4. **Given** no backup exists, **When** user views project, **Then** "Rollback" option is not shown

---

### Edge Cases

- What happens if canonical files don't exist in this repo? → Error "Canonical speckit files not found in repository"
- What if project path contains spaces? → System handles paths with spaces correctly
- What if user lacks write permission to project? → Error "Permission denied: Cannot write to {path}"
- What if `.specify/.backup-*` already exists? → Create new backup with current timestamp (no overwrite)
- What if project is a git repo with uncommitted changes? → Warning "Project has uncommitted git changes" (proceed anyway)
- What happens if disk is full during backup? → Error "Insufficient disk space for backup", abort patch
- What if config file is corrupted? → Reset to empty list, log warning

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: TUI MUST provide menu item in Extras view for "SpecKit Project Updater"
- **FR-002**: System MUST persist project list to `~/.config/ghostty-installer/speckit-projects.json`
- **FR-003**: System MUST detect speckit presence via existence of `.specify/` directory
- **FR-004**: System MUST compare files against canonical versions in this repo's `.specify/scripts/bash/`
- **FR-005**: System MUST create timestamped backup before patching (`{project}/.specify/.backup-{YYYYMMDD-HHMMSS}/`)
- **FR-006**: System MUST show preview of changes before applying (no silent patching)
- **FR-007**: System MUST support adding, removing, and listing tracked projects
- **FR-008**: System MUST support scanning individual projects or all projects
- **FR-009**: System MUST support rollback to most recent backup
- **FR-010**: System MUST handle errors gracefully and restore from backup on patch failure

### Key Files to Patch

The following canonical files enforce constitutional branch naming and should be patched in target projects:

| File | Lines | Purpose |
|------|-------|---------|
| `.specify/scripts/bash/common.sh` | 75-82 | Branch validation regex - add support for constitutional `YYYYMMDD-HHMMSS-type-*` pattern |
| `.specify/scripts/bash/create-new-feature.sh` | 280-313 | Timestamp generation and branch creation - use constitutional format |

### Patch Details

**common.sh lines 75-82** (branch validation):
- Current: Only accepts `^[0-9]{3}-` pattern
- Required: Also accept `^[0-9]{8}-[0-9]{6}-` (constitutional timestamp) pattern

**create-new-feature.sh lines 280-313** (branch creation):
- Current: Creates branches as `NNN-feature-name`
- Required: Creates branches as `YYYYMMDD-HHMMSS-type-feature-name`
- Spec directories remain as `NNN-feature-name` for organizational purposes

### Key Entities

- **TrackedProject**: A project directory with speckit installation being monitored
  - `path`: Absolute path to project root
  - `lastScanned`: Timestamp of last scan (ISO 8601)
  - `status`: "pending" | "up-to-date" | "needs-update" | "error"
  - `differences`: Array of file differences found
  - `lastBackup`: Path to most recent backup, if exists

- **FileDifference**: A detected difference in a speckit file
  - `file`: Relative path within `.specify/`
  - `lineStart`: First differing line number
  - `lineEnd`: Last differing line number
  - `canonicalContent`: Content from this repo
  - `projectContent`: Content from target project

- **ProjectConfig**: Persisted configuration
  - `projects`: Array of TrackedProject paths
  - `version`: Config schema version

## Non-Functional Requirements

- **NFR-001**: Scanning should complete in <5 seconds per project
- **NFR-002**: Config file must be human-readable JSON
- **NFR-003**: Backup must preserve file permissions
- **NFR-004**: System must work offline (no network required)
- **NFR-005**: Memory usage should not exceed 50MB even with 100 tracked projects

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add at least 20 projects to tracking list
- **SC-002**: Scan correctly identifies 100% of differing lines in speckit files
- **SC-003**: Patches apply successfully without corrupting files
- **SC-004**: Rollback restores files to exact pre-patch state (byte-identical)
- **SC-005**: TUI navigates through all SpecKit Updater views without crashes
- **SC-006**: Config persists between TUI sessions
- **SC-007**: Batch update processes all projects even if some fail

## Clarifications

### Session 2026-01-21

- Q: Should this feature modify files outside `.specify/scripts/bash/`? → A: No, only bash scripts that affect branch naming
- Q: Should we track speckit version? → A: No, focus on specific files that need constitutional naming
- Q: What if user has customized speckit files? → A: Show diff and let user decide; only patch the specific constitutional lines

## Assumptions

- Canonical speckit files in this repo are the authoritative source for constitutional naming
- Users want consistent branch naming across all their speckit projects
- The TUI Extras menu pattern is the correct integration point
- JSON is acceptable format for config persistence
- Users have write access to their project directories

## Out of Scope

- Automatic detection of speckit projects (user must manually add)
- Integration with speckit upstream (this is local enforcement only)
- Patching non-bash speckit files (templates, etc.)
- Git commit/push of patched files (user handles version control)
- Network sync of project list between machines
