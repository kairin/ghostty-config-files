# Feature Specification: Package Manager Migration (apt → snap/App Center)

**Feature Branch**: `005-apt-snap-migration`
**Created**: 2025-11-09
**Status**: Draft
**Input**: User description: "Migrate system applications from apt/apt-get installation to snap/Ubuntu App Center with comprehensive safety checks. Requirements: (1) Detect all apt-installed applications that have snap/App Center alternatives, (2) Verify Ubuntu App Center version matches current Ubuntu system version with dynamic version detection (no hardcoded values), (3) Audit existing installations showing package name, version, installation method, and dependencies, (4) Safely uninstall apt packages with dependency impact analysis, (5) Verify snap/App Center alternatives exist and are functionally equivalent before migration, (6) Implement pre-migration system health checks to prevent breakage (essential services, boot dependencies, package conflicts), (7) Provide rollback mechanism if migration causes issues, (8) Test migration on non-critical packages first before system-critical applications. Priority: System stability and zero breakage over migration speed."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Safe Package Audit and Detection (Priority: P1)

As a system administrator, I want to audit all currently installed apt packages and identify which ones have snap/App Center alternatives available, so that I can make informed decisions about migration candidates without risking system stability.

**Why this priority**: This is foundational and zero-risk. It provides visibility into the current state without making any changes. This delivers immediate value by showing what can be migrated and establishes trust before any destructive operations.

**Independent Test**: Can be fully tested by running the audit command on a system with mixed apt/snap packages and verifying that the report accurately identifies packages, versions, installation methods, dependencies, and available alternatives without making any system modifications.

**Acceptance Scenarios**:

1. **Given** a system with apt-installed packages, **When** I run the audit command, **Then** I see a complete report showing package name, current version, installation method (apt/snap/manual), and dependency tree
2. **Given** the audit is complete, **When** I review the report, **Then** I see which packages have snap/App Center alternatives with version comparison and functional equivalence status
3. **Given** critical system packages exist, **When** the audit runs, **Then** packages marked as essential services or boot dependencies are flagged with warning indicators
4. **Given** I want to verify App Center compatibility, **When** the system checks App Center version, **Then** it dynamically detects the Ubuntu version and validates App Center compatibility without hardcoded version strings

---

### User Story 2 - Test Migration on Non-Critical Packages (Priority: P2)

As a system administrator, I want to perform trial migrations on non-critical packages first, with automatic rollback capability, so that I can validate the migration process works correctly before attempting system-critical applications.

**Why this priority**: This provides real-world validation with minimal risk. Testing on non-critical packages (like user applications, development tools) proves the migration mechanism works before touching essential services.

**Independent Test**: Can be fully tested by migrating a non-critical apt package (e.g., htop, tree) to its snap equivalent, verifying functionality, and testing the rollback mechanism to restore the apt version.

**Acceptance Scenarios**:

1. **Given** a non-critical apt package identified in the audit, **When** I request migration, **Then** the system performs pre-migration health checks (disk space, network connectivity, snap daemon status) before proceeding
2. **Given** pre-checks pass, **When** migration starts, **Then** the system creates a complete backup of the current package state including configuration files and dependency metadata
3. **Given** the apt package is uninstalled, **When** the snap alternative is installed, **Then** the system verifies functional equivalence by checking command availability, version compatibility, and configuration migration
4. **Given** migration completes, **When** I test the application, **Then** it functions identically to the apt version with configurations preserved
5. **Given** migration fails or produces errors, **When** rollback is triggered (automatic or manual), **Then** the system restores the exact previous state including apt package, configurations, and dependencies

---

### User Story 3 - System-Wide Migration with Safety Guarantees (Priority: P3)

As a system administrator, I want to migrate all eligible apt packages to snap/App Center equivalents with comprehensive safety checks and rollback protection, so that I can modernize package management while ensuring zero system breakage.

**Why this priority**: This is the full implementation of the migration vision. It builds on proven audit and test-migration capabilities but carries the highest risk due to potential impact on system-critical packages.

**Independent Test**: Can be fully tested by running full system migration on a VM or test system, verifying all packages migrate successfully, system boots correctly, essential services remain functional, and rollback capability works for the entire migration batch.

**Acceptance Scenarios**:

1. **Given** audit and test migrations are complete, **When** I initiate system-wide migration, **Then** packages are migrated in dependency-safe order (leaf packages before dependencies, non-critical before system-critical)
2. **Given** a package is marked for migration, **When** dependency analysis runs, **Then** the system identifies all reverse dependencies and ensures snap alternatives exist for the entire dependency chain
3. **Given** essential services are detected (systemd services, network managers, display servers), **When** migration planning occurs, **Then** these packages are scheduled last and flagged for extra verification
4. **Given** a batch of packages migrates, **When** post-migration validation runs, **Then** the system verifies all systemd services restart successfully, boot process remains intact, and no package conflicts exist
5. **Given** any migration step fails critical validation, **When** the failure is detected, **Then** the system automatically rolls back the current batch and preserves system stability with detailed failure logs

---

### Edge Cases

- What happens when a snap alternative exists but is functionally incomplete (missing features or plugins compared to apt version)?
  → System detects feature disparity via capability comparison and flags package as "requires manual review" rather than auto-migrating

- How does the system handle packages with multiple snap providers (e.g., Chromium available from multiple publishers)?
  → System ONLY accepts snaps from official/verified publishers. If multiple verified publishers exist, select the one marked as official upstream maintainer. Non-verified alternatives are rejected and package is flagged for manual review

- What happens when disk space is insufficient for both apt and snap versions during migration?
  → Pre-migration checks detect space requirements, calculate total needed space (old + new + buffer), and abort if insufficient with clear error message

- How are packages with custom apt repository configurations (PPAs) handled?
  → System identifies PPA-sourced packages, checks if official snap equivalents exist, and preserves PPA configurations in case of rollback

- What happens if snapd itself is not installed or is outdated?
  → Pre-flight checks verify snapd installation, auto-install if missing (with permission), and upgrade to required version before any migrations

- How does rollback work if the apt repository cache has been cleared?
  → System preserves downloaded .deb files and apt state in migration backup directory before any uninstalls, enabling offline rollback

- What happens when a migrated package requires different environment variables or paths?
  → System creates compatibility shims/wrappers that maintain legacy paths and environment expectations, logging any behavioral differences

- How are packages that are dependencies of both apt and snap packages handled?
  → System detects hybrid dependency scenarios, maintains both versions in isolated namespaces if necessary, and clearly documents the hybrid state

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST dynamically detect Ubuntu version and validate App Center/snapd compatibility without hardcoded version strings
- **FR-002**: System MUST audit all apt-installed packages including name, version, installation method, full dependency tree (unlimited depth traversal), and configuration file locations
- **FR-003**: System MUST identify snap/App Center alternatives for each apt package by querying snap store API and validating package equivalence
- **FR-004**: System MUST perform pre-migration health checks including disk space calculation, network connectivity, snapd daemon status, and essential service identification
- **FR-005**: System MUST analyze dependency impact before uninstalling any apt package, identifying reverse dependencies and ensuring complete migration paths exist
- **FR-006**: System MUST create timestamped, reversible backups of package state including .deb files, configuration files, dependency metadata, and systemd service definitions before any modifications
- **FR-007**: System MUST uninstall apt packages safely using dependency-aware removal that preserves configurations and checks for orphaned dependencies
- **FR-008**: System MUST verify snap alternative functional equivalence by comparing command availability, version compatibility, feature parity (executable presence + critical command-line flags support via command + flags comparison method), and configuration migration requirements. Equivalence scoring uses weighted algorithm: name matching (20%), version compatibility (30%), feature parity (30%), configuration compatibility (20%) with total score 0-100 where ≥70 indicates acceptable equivalence
- **FR-009**: System MUST implement rollback mechanism that restores exact previous state including apt package reinstallation, configuration restoration, and dependency graph reconstruction
- **FR-010**: System MUST migrate packages in dependency-safe order (leaf packages first, then dependencies, non-critical before system-critical)
- **FR-011**: System MUST validate essential services after migration by checking systemd service status, boot process integrity, and package conflict resolution
- **FR-012**: System MUST support dry-run mode where health checks execute for real (disk space, network, snapd status) while migration operations (backup, uninstall, install) are simulated with detailed action predictions
- **FR-013**: System MUST log all migration actions with timestamps, success/failure status, package details, and rollback instructions
- **FR-014**: System MUST detect and flag system-critical packages (boot dependencies, init system, kernel modules, display servers) requiring manual review
- **FR-015**: System MUST preserve custom package configurations during migration and validate configuration compatibility with snap alternatives
- **FR-016**: System MUST verify snap publisher trust and ONLY accept official/verified publishers (identified by verified/starred validation status from snapd API), rejecting all non-verified alternatives to ensure security (packages without verified alternatives flagged for manual review)
- **FR-017**: System MUST handle packages from PPAs by checking official snap equivalents and preserving PPA configurations for rollback
- **FR-018**: System MUST calculate total disk space requirements including both apt and snap versions during transition, plus 20% overhead buffer (calculated as (apt_size + snap_size) * 1.20) for rollback data, metadata, and logs
- **FR-019**: System MUST provide detailed migration reports showing successful migrations, failed attempts, packages requiring manual review, and rollback actions taken

### Assumptions

- User has sudo/root privileges to install, remove, and configure packages
- System has network connectivity to access snap store and apt repositories
- snapd is installable on the target Ubuntu system (Ubuntu 16.04+)
- Disk space is available for temporary storage of both apt and snap versions during migration
- Essential system services can be identified via systemd service analysis and package metadata
- Snap alternatives provide functional equivalence for most common user-space applications
- User can tolerate brief service interruptions during migration of individual packages
- System uses systemd for service management (Ubuntu default since 15.04)
- App Center availability correlates with Ubuntu LTS release cycle and snap ecosystem maturity
- Configuration file formats between apt and snap versions are documented or discoverable

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: System audit completes in under 2 minutes for typical Ubuntu desktop installation (100-300 packages)
- **SC-002**: Package equivalence detection achieves >90% accuracy in identifying functionally equivalent snap alternatives
- **SC-003**: Pre-migration health checks detect 100% of blocking conditions (disk space, missing snapd, network issues) before attempting modifications
- **SC-004**: Test migration on non-critical packages completes successfully with zero functional regressions in >95% of cases
- **SC-005**: Rollback mechanism restores previous state with 100% accuracy (no orphaned files, broken dependencies, or configuration loss)
- **SC-006**: System-critical packages (init, boot, essential services) are correctly identified and flagged in 100% of audits
- **SC-007**: Full system migration preserves system bootability in 100% of cases (system boots successfully after migration)
- **SC-008**: Essential services (network, display, authentication) remain functional after migration in 100% of cases
- **SC-009**: Migration process logs sufficient detail to enable manual troubleshooting and rollback for any failed package
- **SC-010**: Dry-run mode accurately predicts migration actions with >98% accuracy compared to actual execution
- **SC-011**: Dependency analysis correctly identifies all reverse dependencies preventing 100% of "broken package" states
- **SC-012**: Migration performance handles typical desktop package sets (50-100 packages) in under 30 minutes including all safety checks

### Key Entities *(if data involved)*

- **Package Installation Record**: Current package name, version, installation method (apt/snap/manual), installation date, configuration files, dependency list
- **Migration Candidate**: apt package, matching snap alternative, functional equivalence score, risk level (critical/non-critical), migration priority
- **Health Check Result**: Check type (disk space/network/snapd/services), status (pass/fail/warning), measured value, threshold requirement, blocking severity
- **Dependency Graph**: Package nodes, dependency edges (depends/recommends/suggests), reverse dependency tracking, essential service annotations
- **Migration Backup**: Timestamp, package .deb file, configuration snapshots, dependency metadata, systemd service definitions, rollback instructions
- **Migration Log Entry**: Timestamp, action type (audit/check/backup/uninstall/install/verify/rollback), package affected, outcome (success/failure), error details

## Clarifications

### Session 2025-11-09

- Q: FR-002 requires auditing the "dependency tree" for all packages. How deep should the dependency tree collection go to balance completeness with performance? → A: Full depth (unlimited) - Traverse entire dependency graph regardless of depth
- Q: FR-008 requires verifying "feature parity" between apt and snap packages. How should the system determine if features match? → A: Command + critical flags comparison - Verify all executables exist and support same primary command-line flags
- Q: FR-018 requires calculating disk space including "buffer for rollback data." How much additional buffer space should be reserved? → A: 20% overhead - Standard safety margin for backup operations
- Q: FR-016 requires verifying snap publisher trust. How should the system prioritize publishers when multiple snap alternatives exist? → A: Official publisher only - Reject all non-verified alternatives (strict but may block valid migrations)
- Q: FR-012 requires dry-run mode to show "planned migration actions without executing changes." Which operations should actually execute vs simulate? → A: Health checks execute, migrations simulate - Pre-checks run for real, package operations predicted
