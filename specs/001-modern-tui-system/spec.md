# Feature Specification: Modern TUI Installation System

**Feature Branch**: `001-modern-tui-system`
**Created**: 2025-11-18
**Status**: Draft
**Input**: User description: "Implement robust TUI system with gum framework, adaptive box drawing, real verification tests, collapsible output, uv/fnm package management, and app duplicate detection/cleanup"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fresh Installation Experience (Priority: P1)

A user runs `./start.sh` on a fresh Ubuntu system and sees a beautiful, professional installation process with proper box drawing, real-time progress, and collapsible output like Docker. Professional appearance measured by SC-002: Zero broken box characters across all terminal types.

**Why this priority**: This is the primary user journey and the most common use case. Without a working installation system, nothing else matters. This delivers immediate value by providing a functional terminal environment.

**Independent Test**: Can be fully tested by running `./start.sh` on a clean Ubuntu VM and verifying: (1) no broken box characters appear, (2) all components install successfully, (3) verification tests pass with real system checks, (4) output collapses completed tasks to single lines. Delivers a working Ghostty terminal environment.

**Acceptance Scenarios**:

1. **Given** fresh Ubuntu 25.10 system, **When** user runs `./start.sh`, **Then** sees UTF-8 box drawing (╔═╗) if terminal supports it, or ASCII boxes (+=-|) if SSH/legacy terminal
2. **Given** installation running, **When** task completes, **Then** output collapses to single line: `✓ Task name (duration)` with green checkmark
3. **Given** all tasks complete, **When** user checks system, **Then** all components verified with real tests (not hard-coded success messages)
4. **Given** installation process, **When** error occurs, **Then** error auto-expands with recovery suggestions and continue-or-abort option

---

### User Story 2 - SSH Installation Support (Priority: P1)

A user connects via SSH and runs installation, receiving readable ASCII box drawing instead of broken UTF-8 characters.

**Why this priority**: SSH installations are extremely common for server setups and remote development. Broken characters make the installation appear unprofessional and difficult to follow. This ensures installation works universally.

**Independent Test**: Can be tested by SSHing into a remote system and running `./start.sh`. Verify ASCII boxes (+=-|) appear instead of broken UTF-8, all progress indicators work, verification tests pass. Delivers remote installation capability.

**Acceptance Scenarios**:

1. **Given** SSH connection to remote system, **When** user runs `./start.sh`, **Then** system detects SSH_CONNECTION and uses ASCII box drawing automatically
2. **Given** legacy terminal (TERM=linux), **When** installation runs, **Then** uses ASCII fallback for all UI elements
3. **Given** manual override via `BOX_DRAWING=utf8`, **When** installation runs, **Then** forces UTF-8 boxes even on SSH (for advanced users with capable terminals)

---

### User Story 3 - Re-run and Resume Safety (Priority: P1)

A user's installation fails halfway through, or they want to update their system. Running `./start.sh` again safely skips completed tasks, preserves customizations, and resumes from where it stopped.

**Why this priority**: Idempotency is critical for reliability and user confidence. Users should never fear re-running installation for updates or recovery. This prevents configuration corruption and data loss.

**Independent Test**: Run `./start.sh` twice in succession. First run completes fully. Second run detects existing installations via real verification functions, skips completed tasks (shows `↷ Already installed`), completes in <30 seconds. User customizations remain intact.

**Acceptance Scenarios**:

1. **Given** Ghostty already installed, **When** user runs `./start.sh` again, **Then** verification function detects existing installation and skips task
2. **Given** user has custom ZSH configuration, **When** installation updates ZSH, **Then** preserves user customizations and only updates framework components
3. **Given** installation interrupted at task 5 of 10, **When** user re-runs `./start.sh`, **Then** state persistence allows resuming from task 5

---

### User Story 4 - Duplicate App Detection and Cleanup (Priority: P2)

A user wants to clean up their Ubuntu system which has accumulated duplicate applications (snap vs apt versions, disabled snaps, multiple browsers). The system detects duplicates and recommends cleanup.

**Why this priority**: Addresses real problem from app audit (4GB+ waste from duplicates). Important for system maintenance but not critical for initial installation. Delivers immediate disk space savings and cleaner app drawer.

**Independent Test**: Run app audit command, receive report of duplicates (e.g., "Firefox: snap enabled + apt removed candidate, VLC: snap + apt both active"). Follow cleanup recommendations, verify duplicates removed, app drawer shows single icons, disk space recovered. Can be tested independently of installation system.

**Acceptance Scenarios**:

1. **Given** system with duplicate apps, **When** user runs app audit, **Then** receives categorized report of duplicates with disk usage and recommendations
2. **Given** audit identifies snap+apt duplicates, **When** user approves cleanup, **Then** system safely removes duplicates while preserving user data and preferences
3. **Given** 10 disabled snap versions, **When** cleanup executes, **Then** removes disabled snaps and recovers 2GB+ disk space
4. **Given** 4 browsers installed, **When** user selects preferred browser, **Then** system offers to remove others while preserving bookmarks/settings

---

### User Story 5 - Best Practice App Installation (Priority: P2)

All applications are installed following best practices from Context7 MCP, ensuring optimal installation method (snap vs apt), proper configuration, and security compliance.

**Why this priority**: Ensures long-term system health and consistency. Not blocking for basic functionality but critical for professional deployments. Prevents future issues from improper installations.

**Independent Test**: Query Context7 for recommended installation methods for common apps (Ghostty, Chrome, VS Code). Compare current installations against recommendations. Generate compliance report. Can be tested independently by running Context7 queries.

**Acceptance Scenarios**:

1. **Given** app to install, **When** installation checks Context7, **Then** uses recommended method (snap/apt/source) and configuration
2. **Given** existing non-compliant installation, **When** audit runs, **Then** flags non-compliance and suggests migration path
3. **Given** security-sensitive app, **When** installing, **Then** follows Context7 security hardening recommendations

---

### User Story 6 - Verbose Mode Toggle (Priority: P3)

A user debugging an installation issue can press 'v' or use `--verbose` flag to expand all collapsed output and see full logs in real-time.

**Why this priority**: Nice-to-have for debugging but not essential for basic functionality. Users can always check logs in `/tmp/ghostty-start-logs/`. Enhances troubleshooting experience.

**Independent Test**: Run `./start.sh`, wait for tasks to collapse, press 'v' key. Verify all collapsed tasks expand to show full output. Run `./start.sh --verbose` and verify no tasks collapse. Delivers debugging capability.

**Acceptance Scenarios**:

1. **Given** installation running with collapsed output, **When** user presses 'v', **Then** all collapsed tasks expand to show full output
2. **Given** `./start.sh --verbose` executed, **When** tasks complete, **Then** output remains expanded (no collapsing)
3. **Given** verbose mode active, **When** user presses 'v' again, **Then** toggles back to collapsed mode

---

### User Story 7 - Parallel Task Execution (Priority: P3)

Independent tasks (e.g., installing Ghostty while setting up ZSH) execute in parallel with visual progress for each, completing installation faster.

**Why this priority**: Performance optimization that improves user experience but not critical for MVP. Sequential execution is acceptable for initial version. Delivers faster installation times.

**Independent Test**: Run installation with parallel execution enabled. Verify multiple spinners shown simultaneously for independent tasks. Compare total time against sequential baseline (should be 30-40% faster). Can be tested by comparing parallel vs sequential execution.

**Acceptance Scenarios**:

1. **Given** 5 independent tasks detected, **When** installation runs, **Then** up to 3 tasks execute in parallel with separate progress indicators
2. **Given** task dependency detected, **When** parallel execution runs, **Then** dependent tasks wait for prerequisites to complete
3. **Given** parallel execution, **When** one task fails, **Then** other tasks continue and aggregate errors at end

---

### Edge Cases

- **What happens when gum is not installed?** System gracefully degrades to plain text output with basic formatting (colors, checkmarks) and installs gum as first task for improved UX on subsequent runs.
- **What happens when terminal doesn't support UTF-8?** Automatic detection via TERM environment variable and SSH_CONNECTION triggers ASCII fallback. Manual override via `BOX_DRAWING=ascii` environment variable.
- **How does system handle network failures during package installation?** Error handler detects network errors, provides recovery suggestions (check connection, retry, skip), allows user to continue or abort. Failed tasks logged for retry on next run.
- **What happens when verification function fails but installation appeared successful?** Error expands with full diagnostic output, suggested fixes, and option to skip verification (not recommended). Logs capture full context for troubleshooting.
- **How does system handle conflicting package versions?** Detects conflicts during pre-installation phase, reports to user with recommendations, offers to resolve automatically or abort.
- **What happens when disk space is insufficient?** Pre-flight check calculates required space, compares against available, warns user if insufficient, suggests cleanup options (including app duplicate removal).
- **How does system handle interrupted installations (killed process, power loss)?** State persistence in JSON files allows resume from last checkpoint. Incomplete tasks re-verified on next run.
- **What happens when user has non-standard shell (fish, tcsh)?** Detection of current shell, warnings about limited support, offers to install ZSH, preserves existing shell configuration.

## Requirements *(mandatory)*

### Functional Requirements

#### TUI Framework & Box Drawing
- **FR-001**: System MUST use gum (Charm Bracelet) exclusively for all TUI elements (spinners, progress bars, prompts, styled output)
- **FR-002**: System MUST detect terminal capability via TERM environment variable and SSH_CONNECTION to choose UTF-8 or ASCII box drawing
- **FR-003**: System MUST render UTF-8 double-line boxes (╔═╗ ║ ╚═╝) for modern terminals (Ghostty, xterm, alacritty, kitty, tmux, screen)
- **FR-004**: System MUST render ASCII boxes (+=-|) for SSH connections and legacy terminals
- **FR-005**: System MUST support manual override via BOX_DRAWING environment variable (utf8/ascii)
- **FR-006**: System MUST gracefully degrade to plain text if gum unavailable, with installation of gum as first priority task

#### Verification & Testing
- **FR-007**: System MUST implement real verification functions that check actual system state (NOT hard-coded success messages)
- **FR-008**: Every installation task MUST have corresponding `verify_<component>()` function
- **FR-009**: Verification functions MUST check command existence via `command -v`, version numbers, file contents, and service status
- **FR-010**: Verification functions MUST return proper exit codes (0=success, 1=failure) for automated testing
- **FR-011**: System MUST implement multi-layer verification: unit tests (per-component), integration tests (cross-component), health checks (pre/post)
- **FR-012**: System MUST capture verification results in structured JSON logs with timestamps, exit codes, and diagnostic output

#### Progressive Summarization & Output Management
- **FR-013**: System MUST collapse completed tasks to single-line summaries: `✓ Task name (duration)`
- **FR-014**: System MUST show active task with full output and animated spinner via gum
- **FR-015**: System MUST show queued tasks with pending status indicator (⏸)
- **FR-016**: System MUST auto-expand errors with recovery suggestions and continue-or-abort prompt
- **FR-017**: System MUST support verbose mode toggle (press 'v' or --verbose flag) to expand/collapse all output
- **FR-018**: System MUST display overall progress percentage and time estimates
- **FR-019**: System MUST use color-coded output (green=success, yellow=warning, red=error, blue=info)

#### Modular Architecture
- **FR-020**: System MUST organize code in modular lib/ structure with lib/core/, lib/ui/, lib/tasks/, lib/verification/
- **FR-021**: System MUST implement lib/core/logging.sh for structured logging (JSON + human-readable)
- **FR-022**: System MUST implement lib/core/state.sh for state management and resume capability
- **FR-023**: System MUST implement lib/core/errors.sh for error handling with recovery suggestions
- **FR-024**: System MUST implement lib/ui/tui.sh for gum integration and TUI components
- **FR-025**: System MUST implement lib/ui/boxes.sh for adaptive box drawing functions
- **FR-026**: System MUST implement lib/ui/collapsible.sh for progressive summarization
- **FR-027**: System MUST implement lib/ui/progress.sh for progress bars and spinners
- **FR-028**: System MUST implement lib/tasks/*.sh for each installation component (ghostty.sh, zsh.sh, python_uv.sh, nodejs_fnm.sh, ai_tools.sh)
- **FR-029**: System MUST implement lib/verification/unit_tests.sh for per-component verification
- **FR-030**: System MUST implement lib/verification/integration_tests.sh for cross-component validation
- **FR-031**: System MUST implement lib/verification/health_checks.sh for pre/post installation checks

#### Package Management
- **FR-032**: System MUST use uv exclusively for ALL Python package operations (uv pip install, uv run, uv venv)
- **FR-033**: System MUST prohibit usage of pip, pip3, python -m pip, poetry, pipenv for Python packages
- **FR-034**: System MUST use fnm exclusively for ALL Node.js version management (fnm install, fnm use, fnm default)
- **FR-035**: System MUST prohibit usage of nvm, n, asdf, manual Node.js installation
- **FR-036**: System MUST verify uv installation with real version check: `uv --version` returns valid version
- **FR-037**: System MUST verify fnm installation with real startup time check: <50ms (constitutional requirement)
- **FR-038**: System MUST install latest Node.js version (v25.2.0+) via fnm for AI tools and Astro documentation site

#### Structured Logging
- **FR-039**: System MUST implement dual-format logging: human-readable console output + structured JSON logs
- **FR-040**: System MUST write human-readable logs to /tmp/ghostty-start-logs/start-TIMESTAMP.log
- **FR-041**: System MUST write structured JSON logs to /tmp/ghostty-start-logs/start-TIMESTAMP.log.json
- **FR-042**: System MUST write critical errors to /tmp/ghostty-start-logs/errors.log
- **FR-043**: System MUST capture performance metrics in /tmp/ghostty-start-logs/performance.json
- **FR-044**: System MUST capture system state snapshots in /tmp/ghostty-start-logs/system_state_TIMESTAMP.json
- **FR-045**: System MUST implement log rotation keeping last 10 installations
- **FR-046**: System MUST log task timing (start time, end time, duration) for performance analysis

#### Error Handling & Recovery
- **FR-047**: Error messages MUST include: what failed, why it likely failed, how to fix it
- **FR-048**: Errors MUST auto-expand in collapsible output with full diagnostic information
- **FR-049**: System MUST provide continue-or-abort option for non-critical errors
- **FR-050**: System MUST implement rollback capability for failed tasks where applicable
- **FR-051**: System MUST aggregate all errors at end of installation with summary report
- **FR-052**: System MUST provide recovery suggestions specific to error type (network, permissions, dependencies, conflicts)

#### Idempotency & Resume Capability
- **FR-053**: System MUST check existing state before installation and skip if already installed
- **FR-054**: System MUST preserve user customizations during updates (e.g., .zshrc, .bashrc, ~/.config/ghostty/config, shell aliases, environment variables)
- **FR-055**: System MUST backup critical files before modification with timestamped backups
- **FR-056**: System MUST implement restore capability for failed modifications
- **FR-057**: System MUST persist installation state in JSON files for resume capability after interruption
- **FR-058**: System MUST detect interrupted installations and resume from last checkpoint

#### Performance Standards
- **FR-059**: System MUST complete total installation in <10 minutes on fresh Ubuntu system
- **FR-060**: System MUST validate fnm startup time <50ms (constitutional requirement)
- **FR-061**: System MUST validate gum startup time <10ms (verified during installation)
- **FR-062**: System MUST execute independent tasks in parallel where dependencies allow (maximum 3 concurrent tasks for system stability and resource management)
- **FR-063**: System MUST update progress feedback at least every 5 seconds during long-running tasks

#### App Duplicate Detection & Cleanup
- **FR-064**: System MUST scan for duplicate applications (snap vs apt, disabled snaps, multiple browsers)
- **FR-065**: System MUST categorize duplicates by type: enabled duplicates, disabled snaps, unnecessary browsers
- **FR-066**: System MUST calculate disk usage for each duplicate category
- **FR-067**: System MUST generate audit report with recommendations in /tmp/ubuntu-apps-audit.md
- **FR-068**: System MUST provide safe cleanup commands that preserve user data and preferences
- **FR-069**: System MUST verify app icon clarity in Ubuntu "Show Apps" after cleanup (no duplicate icons)
- **FR-070**: System MUST support selective cleanup (user chooses which duplicates to remove)

#### Context7 Integration for Best Practices
- **FR-071**: System MUST query Context7 MCP for recommended installation methods before installing apps
- **FR-072**: System MUST follow Context7 recommendations for snap vs apt vs source installation
- **FR-073**: System MUST validate existing installations against Context7 best practices
- **FR-074**: System MUST generate compliance report flagging non-compliant installations
- **FR-075**: System MUST suggest migration paths for non-compliant installations

### Key Entities *(include if feature involves data)*

- **Installation Task**: Represents a single installation step (name, description, verify_function, dependencies, estimated_duration, status [pending/in_progress/completed/failed], actual_duration, error_message). Tasks are organized in lib/tasks/ with separate files per component.

- **System State Snapshot**: Captures complete system state at specific points (timestamp, hostname, kernel_version, os_version, installed_packages, disk_usage, memory_usage, active_services). Used for before/after comparison and debugging. Stored as JSON in /tmp/ghostty-start-logs/system_state_TIMESTAMP.json.

- **Verification Result**: Outcome of verification function execution (task_name, verify_function, exit_code, stdout, stderr, duration, timestamp, success_boolean). Stored in structured logs for analysis and debugging.

- **App Installation Record**: Details of installed application (app_name, installation_method [snap/apt/source], version, disk_usage, install_date, icon_path, compliance_status). Used for duplicate detection and Context7 validation.

- **Cleanup Plan**: Generated recommendations for duplicate removal (duplicate_type, apps_affected, disk_space_recoverable, user_data_locations, cleanup_commands, risk_level [low/medium/high], user_approval_required). User reviews and approves before execution.

- **Performance Metrics**: Task-level timing and system resource usage (task_name, start_time, end_time, duration, cpu_usage, memory_usage, disk_io). Aggregated for performance dashboard and optimization analysis.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Installation completes in <10 minutes on fresh Ubuntu 25.10 system (constitutional performance requirement)
- **SC-002**: Zero broken box characters across all supported terminals (Ghostty, xterm, SSH, legacy) verified by visual testing
- **SC-003**: 100% of installation tasks have real verification functions (no hard-coded success messages) verified by code inspection
- **SC-004**: Verification accuracy ≥99% (verification passes IFF component actually installed) measured by integration tests
- **SC-005**: Re-running installation completes in <30 seconds with all tasks correctly skipped (idempotency) verified by automated testing
- **SC-006**: Error recovery suggestions provided for 100% of errors with actionable next steps verified by error injection testing
- **SC-007**: App duplicate cleanup recovers ≥4GB disk space on typical system (based on audit findings) verified by before/after measurement
- **SC-008**: App icon clarity: Zero duplicate icons in Ubuntu "Show Apps" after cleanup verified by manual inspection
- **SC-009**: Installation success rate ≥99% across different Ubuntu configurations (fresh install, existing system, SSH, VM) measured by CI/CD testing
- **SC-010**: Parallel execution reduces installation time by 30-40% compared to sequential baseline measured by performance benchmarks
- **SC-011**: User satisfaction: 90% of users rate installation experience as "professional" and "easy to follow" measured by user surveys (future)
- **SC-012**: fnm startup time <50ms (constitutional requirement) verified during installation and in performance tests
- **SC-013**: gum startup time <10ms verified during installation
- **SC-014**: All Context7 recommendations followed for app installations (100% compliance) verified by audit
- **SC-015**: User customizations preserved: 100% retention of ZSH configs, Ghostty themes, shell aliases during updates verified by diff testing

## Scope

### In Scope
- Complete TUI system redesign using gum framework
- Adaptive UTF-8/ASCII box drawing with automatic detection
- Real verification functions for all installation components
- Progressive summarization (Docker-like collapsible output)
- Modular lib/ architecture (core, ui, tasks, verification)
- Exclusive uv for Python package management
- Exclusive fnm for Node.js version management
- Structured dual-format logging (JSON + human-readable)
- Error handling with recovery suggestions
- Idempotency and resume capability
- Performance optimization with parallel execution
- App duplicate detection and cleanup
- Context7 integration for best practices
- Constitutional compliance enforcement

### Out of Scope (Future Enhancements)
- GUI installation interface (TUI only in this spec)
- Remote installation orchestration (single system only)
- Installation via containers/Docker (bare metal Ubuntu only)
- Windows/macOS support (Ubuntu 25.10 only)
- Automated scheduled installations (manual execution only)
- Installation analytics dashboard (logging only)
- Multi-language support (English only)
- Installation via configuration management tools (Ansible, Chef, Puppet)

## Assumptions

1. **Target System**: Ubuntu 25.10 (Questing) fresh installation or existing system
2. **Internet Access**: Stable internet connection required for package downloads
3. **User Permissions**: User has sudo access (passwordless sudo recommended)
4. **Disk Space**: Minimum 10GB free space available
5. **Terminal Support**: Modern terminal emulator (Ghostty, xterm, or better) or SSH client
6. **Shell**: Bash 5.x+ available (for installation script execution)
7. **Package Managers**: apt/dpkg and snap available on system
8. **UTF-8 Locale**: System configured with UTF-8 locale (standard on Ubuntu 25.10)
9. **GitHub CLI**: Available for MCP integration (installed if missing)
10. **Context7 API Key**: Available in .env for best practices queries (optional but recommended)

## Dependencies

### External Dependencies
- **gum**: Charm Bracelet TUI framework (installed via apt/snap)
- **uv**: Astral Python package manager (installed from official source)
- **fnm**: Fast Node Manager (installed from official source)
- **Zig 0.14.0+**: For Ghostty compilation from source
- **Node.js v25.2.0+**: For AI tools and Astro documentation site
- **GitHub CLI**: For MCP integration and repository operations
- **jq/yq**: For JSON/YAML processing in scripts
- **bc**: For duration calculations

### Internal Dependencies
- **Constitutional Compliance**: Adheres to .specify/memory/constitution.md v1.0.0 (10 core principles)
- **Branch Strategy**: Uses constitutional branch workflow (YYYYMMDD-HHMMSS-type-description)
- **Local CI/CD**: Integrates with .runners-local/workflows/gh-workflow-local.sh
- **Documentation**: Updates SPEC-KIT-TUI-INTEGRATION.md and related guides
- **Logging Infrastructure**: Uses existing /tmp/ghostty-start-logs/ and .runners-local/logs/

### Integration Points
- **start.sh**: Main installation script refactored to use new lib/ architecture
- **Context7 MCP**: Queries for best practices via mcp__context7__* tools
- **GitHub MCP**: Repository operations via mcp__github__* tools
- **Performance Monitoring**: Integrates with .runners-local/workflows/performance-monitor.sh
- **App Audit**: New module for duplicate detection (creates /tmp/ubuntu-apps-audit.md)

## Non-Functional Requirements

### Reliability
- **NFR-001**: Installation success rate ≥99% across supported configurations
- **NFR-002**: Verification accuracy ≥99% (no false positives/negatives)
- **NFR-003**: Zero data loss during installation or updates (backup/restore capability)
- **NFR-004**: Graceful degradation when optional components unavailable (e.g., gum)

### Performance
- **NFR-005**: Total installation time <10 minutes on fresh system (constitutional requirement)
- **NFR-006**: fnm startup time <50ms (constitutional requirement)
- **NFR-007**: gum startup time <10ms (verified during installation)
- **NFR-008**: Progress updates every ≤5 seconds during long-running tasks
- **NFR-009**: Log file size <10MB per installation run (with rotation)

### Usability
- **NFR-010**: Professional visual appearance (no broken characters, clean formatting)
- **NFR-011**: Clear error messages with actionable recovery steps
- **NFR-012**: Installation resumable after interruption without user intervention
- **NFR-013**: User customizations preserved during updates (no manual reconfiguration)
- **NFR-014**: Verbose mode toggle for debugging (press 'v' or --verbose flag)

### Maintainability
- **NFR-015**: Modular architecture with single responsibility per lib/ module
- **NFR-016**: Each component independently testable (unit tests pass in isolation)
- **NFR-017**: Comprehensive logging for debugging (JSON + human-readable)
- **NFR-018**: Code coverage ≥80% for lib/core/, lib/ui/, lib/verification/ modules
- **NFR-019**: Documentation updated for all new lib/ modules and functions

### Security
- **NFR-020**: No credentials or API keys logged or displayed
- **NFR-021**: Package downloads verified via checksums (where available)
- **NFR-022**: Sudo usage minimized and scoped (only where necessary)
- **NFR-023**: User data backups encrypted (if containing sensitive information)

### Compatibility
- **NFR-024**: Works on Ubuntu 25.10 (Questing) fresh installation
- **NFR-025**: Works on Ubuntu 25.10 with existing Ghostty installation (idempotency)
- **NFR-026**: Works via SSH (ASCII fallback for box drawing)
- **NFR-027**: Works in TTY console (ASCII fallback)
- **NFR-028**: Works with ZSH, Bash, or other POSIX shells (detection and adaptation)

## Implementation Notes

### Constitutional Compliance Checkpoints
1. **TUI Framework**: Verify gum used exclusively (FR-001), no whiptail/dialog/rich-cli
2. **Box Drawing**: Verify adaptive UTF-8/ASCII (FR-002-005), no hard-coded characters
3. **Verification**: Verify real tests only (FR-007-012), no hard-coded success
4. **Package Managers**: Verify uv exclusive (FR-032-033), fnm exclusive (FR-034-035)
5. **Architecture**: Verify modular lib/ structure (FR-020-031), no monolithic start.sh
6. **Critical Files**: Verify docs/.nojekyll preserved (not in this spec but related infrastructure)
7. **Directory Naming**: Verify .runners-local/ used (not local-infra/)
8. **Component Library**: Verify DaisyUI used in website (not shadcn/ui)
9. **Node.js Version**: Verify latest v25.2.0+ (not LTS/18+)

### Reconciliation Matrix Application
After spec generation, apply these corrections:
- ✅ `local-infra/` → `.runners-local/` (already correct in this spec)
- ✅ `shadcn/ui` → `DaisyUI` (not applicable to this spec)
- ✅ `Node.js 18+` → `Node.js latest (v25.2.0+)` (FR-038 compliant)
- ✅ Verify `gum` mentioned (FR-001 compliant)
- ✅ Verify `uv` for Python (FR-032 compliant)
- ✅ Verify `fnm` for Node.js (FR-034 compliant)
- ✅ Verify modular lib/ architecture (FR-020-031 compliant)

### Reference Documents
All implementation details available in /tmp/:
- `TUI-SYSTEM-IMPLEMENTATION-PLAN.md` - Master plan (43 KB)
- `tui-framework-analysis.md` - gum framework details (19 KB)
- `collapsible-output-design.md` - Docker-like design (25 KB)
- `box-drawing-solution.md` - Adaptive solution (23 KB)
- `verification-framework-design.md` - Real test design (31 KB)
- `package-manager-integration.md` - uv & fnm integration (23 KB)
- `installation-script-architecture.md` - Modular design (24 KB)

Proof-of-concept: `demo-tui-static.sh` validates adaptive box drawing and real verification approach.

App audit findings: `/tmp/ubuntu-apps-audit.md` (28 KB) - 4GB+ duplicate detection.

---

**Next Steps**:
1. Create quality checklist at `specs/001-modern-tui-system/checklists/requirements.md`
2. Validate specification against quality criteria
3. Apply reconciliation matrix (already applied above)
4. Commit with constitutional branch workflow
5. Proceed to `/speckit.plan` for implementation roadmap
