# Requirements Validation Checklist - Modern TUI Installation System

**Feature**: 001-modern-tui-system
**Created**: 2025-11-18
**Status**: Draft

## Purpose

This checklist ensures all functional requirements (FR-001 through FR-075), non-functional requirements (NFR-001 through NFR-028), and success criteria (SC-001 through SC-015) are properly implemented and tested.

---

## TUI Framework & Box Drawing (FR-001 to FR-006)

- [ ] **FR-001**: gum used exclusively for all TUI elements (spinners, progress bars, prompts, styled output)
  - Test: Grep lib/ for whiptail/dialog/rich-cli usage → should be zero
  - Verify: All TUI calls use gum commands

- [ ] **FR-002**: Terminal capability detection via TERM and SSH_CONNECTION implemented
  - Test: Run with TERM=xterm → UTF-8 boxes
  - Test: Run with SSH_CONNECTION set → ASCII boxes
  - Verify: `detect_terminal_capability()` function exists in lib/ui/boxes.sh

- [ ] **FR-003**: UTF-8 double-line boxes rendered for modern terminals
  - Test: Visual inspection on Ghostty terminal → ╔═╗ ║ ╚═╝
  - Test: Visual inspection on xterm → UTF-8 boxes
  - Verify: UTF-8 box characters in lib/ui/boxes.sh

- [ ] **FR-004**: ASCII boxes rendered for SSH and legacy terminals
  - Test: SSH connection → +=-| boxes
  - Test: TERM=linux → ASCII boxes
  - Verify: ASCII fallback logic in lib/ui/boxes.sh

- [ ] **FR-005**: Manual override via BOX_DRAWING environment variable
  - Test: `BOX_DRAWING=utf8 ./start.sh` → forces UTF-8
  - Test: `BOX_DRAWING=ascii ./start.sh` → forces ASCII
  - Verify: Environment variable check in detection logic

- [ ] **FR-006**: Graceful degradation when gum unavailable
  - Test: Rename gum binary, run installation → plain text output
  - Test: Verify gum installed as first priority task
  - Verify: Fallback implementation exists

---

## Verification & Testing (FR-007 to FR-012)

- [ ] **FR-007**: Real verification functions (no hard-coded success)
  - Code review: All verify_* functions check actual system state
  - Test: Verification fails when component not installed
  - Test: Verification passes only when component actually installed

- [ ] **FR-008**: Every task has corresponding verify_<component>() function
  - Inventory: List all tasks in lib/tasks/
  - Verify: Matching verify_* function exists for each task
  - Test: Run verification suite independently

- [ ] **FR-009**: Verification checks command existence, versions, files, services
  - Test: `verify_ghostty()` → checks `command -v ghostty`, version, config file
  - Test: `verify_zsh()` → checks shell, Oh My ZSH, plugins
  - Code review: All verify functions use `command -v`, version parsing, file checks

- [ ] **FR-010**: Verification returns proper exit codes (0/1)
  - Test: All verify_* functions → return 0 on success, 1 on failure
  - Test: No silent failures (missing return statements)
  - Verify: Error handling captures exit codes

- [ ] **FR-011**: Multi-layer verification (unit, integration, health checks)
  - Test: lib/verification/unit_tests.sh → per-component tests pass
  - Test: lib/verification/integration_tests.sh → cross-component tests pass
  - Test: lib/verification/health_checks.sh → pre/post validation pass

- [ ] **FR-012**: Verification results in structured JSON logs
  - Test: Check /tmp/ghostty-start-logs/*.json → verification results present
  - Verify: JSON schema includes task_name, exit_code, stdout, stderr, timestamp
  - Test: JSON is valid and parseable

---

## Progressive Summarization (FR-013 to FR-019)

- [ ] **FR-013**: Completed tasks collapse to `✓ Task name (duration)`
  - Test: Visual inspection → completed tasks show single line
  - Test: No verbose output for completed tasks (unless verbose mode)
  - Verify: Collapsible output implementation in lib/ui/collapsible.sh

- [ ] **FR-014**: Active task shows full output with spinner
  - Test: Visual inspection → active task has animated spinner
  - Test: Full output visible during execution
  - Verify: gum spin integration for active tasks

- [ ] **FR-015**: Queued tasks show pending indicator (⏸)
  - Test: Visual inspection → queued tasks have ⏸ symbol
  - Verify: Pending status implementation

- [ ] **FR-016**: Errors auto-expand with recovery suggestions
  - Test: Inject error → verify auto-expansion
  - Test: Recovery suggestions present and actionable
  - Test: Continue-or-abort prompt appears

- [ ] **FR-017**: Verbose mode toggle (press 'v' or --verbose)
  - Test: Press 'v' during execution → all output expands
  - Test: `./start.sh --verbose` → no collapsing
  - Test: Toggle 'v' again → collapse restored

- [ ] **FR-018**: Overall progress percentage and time estimates
  - Test: Visual inspection → progress shown (e.g., "5/10 tasks, 50%, ~5 min remaining")
  - Verify: Progress calculation logic in lib/ui/progress.sh

- [ ] **FR-019**: Color-coded output (green/yellow/red/blue)
  - Test: Visual inspection → green=success, yellow=warning, red=error, blue=info
  - Verify: Color constants defined and used consistently

---

## Modular Architecture (FR-020 to FR-031)

- [ ] **FR-020**: lib/ structure with core/, ui/, tasks/, verification/
  - Verify: Directory structure exists
  - Test: `tree lib/` → shows all required subdirectories

- [ ] **FR-021**: lib/core/logging.sh implemented
  - Test: Source lib/core/logging.sh → functions available
  - Verify: Dual-format logging (console + JSON)
  - Test: Log rotation logic works

- [ ] **FR-022**: lib/core/state.sh for state management
  - Test: State persistence to JSON files
  - Test: Resume capability after interruption
  - Verify: State load/save functions exist

- [ ] **FR-023**: lib/core/errors.sh for error handling
  - Test: Error functions provide recovery suggestions
  - Verify: Error aggregation at end of installation
  - Test: Rollback capability for failed tasks

- [ ] **FR-024**: lib/ui/tui.sh for gum integration
  - Test: Source lib/ui/tui.sh → gum wrapper functions available
  - Verify: Spinner, progress bar, prompt functions

- [ ] **FR-025**: lib/ui/boxes.sh for adaptive box drawing
  - Test: Source lib/ui/boxes.sh → box drawing functions available
  - Verify: UTF-8/ASCII detection and rendering

- [ ] **FR-026**: lib/ui/collapsible.sh for progressive summarization
  - Test: Task collapse/expand functionality
  - Verify: Docker-like output management

- [ ] **FR-027**: lib/ui/progress.sh for progress indicators
  - Test: Progress percentage calculation
  - Test: Time estimation logic
  - Verify: Spinner animations

- [ ] **FR-028**: lib/tasks/*.sh for each component
  - Verify: ghostty.sh, zsh.sh, python_uv.sh, nodejs_fnm.sh, ai_tools.sh exist
  - Test: Each task file sources properly
  - Test: Task functions executable independently

- [ ] **FR-029**: lib/verification/unit_tests.sh implemented
  - Test: Run unit tests → per-component verification passes
  - Verify: Coverage for all components

- [ ] **FR-030**: lib/verification/integration_tests.sh implemented
  - Test: Run integration tests → cross-component validation passes
  - Verify: Dependency checks work

- [ ] **FR-031**: lib/verification/health_checks.sh implemented
  - Test: Pre-installation health check passes
  - Test: Post-installation health check validates all components
  - Verify: System state capture

---

## Package Management (FR-032 to FR-038)

- [ ] **FR-032**: uv used exclusively for Python packages
  - Code review: Grep for `pip`, `pip3`, `python -m pip` → should be zero
  - Verify: All Python operations use `uv pip`, `uv run`, `uv venv`

- [ ] **FR-033**: pip/poetry/pipenv prohibited
  - Test: Installation doesn't install or use pip, poetry, pipenv
  - Code review: No references to prohibited tools

- [ ] **FR-034**: fnm used exclusively for Node.js
  - Code review: Grep for `nvm`, `n`, `asdf` → should be zero
  - Verify: All Node.js operations use `fnm install`, `fnm use`, `fnm default`

- [ ] **FR-035**: nvm/n/asdf prohibited
  - Test: Installation doesn't install or use nvm, n, asdf
  - Code review: No references to prohibited tools

- [ ] **FR-036**: uv verification with real version check
  - Test: `verify_uv()` → checks `uv --version`
  - Test: Fails when uv not installed
  - Test: Passes when uv installed with valid version

- [ ] **FR-037**: fnm startup time <50ms verified
  - Test: Measure `time fnm --version` → <50ms
  - Verify: Startup time check in installation
  - Performance benchmark: Constitutional requirement met

- [ ] **FR-038**: Latest Node.js (v25.2.0+) installed via fnm
  - Test: `node --version` → v25.2.0 or higher
  - Verify: fnm installs latest, not LTS
  - Test: AI tools and Astro work with latest Node.js

---

## Structured Logging (FR-039 to FR-046)

- [ ] **FR-039**: Dual-format logging (console + JSON)
  - Test: Check /tmp/ghostty-start-logs/ → both .log and .log.json files
  - Verify: Console output human-readable, JSON structured

- [ ] **FR-040**: Human-readable logs to start-TIMESTAMP.log
  - Test: File exists after installation
  - Test: Content is human-readable with timestamps, colors
  - Verify: Log format consistent

- [ ] **FR-041**: Structured JSON to start-TIMESTAMP.log.json
  - Test: JSON file exists and is valid
  - Test: JSON schema includes required fields
  - Verify: Parseable with jq

- [ ] **FR-042**: Critical errors to errors.log
  - Test: Inject error → appears in errors.log
  - Test: Only critical errors logged (not warnings/info)

- [ ] **FR-043**: Performance metrics to performance.json
  - Test: File contains task timing data
  - Verify: Schema includes start_time, end_time, duration
  - Test: Metrics accurate

- [ ] **FR-044**: System state snapshots to system_state_TIMESTAMP.json
  - Test: Snapshot captured before and after installation
  - Verify: Includes hostname, kernel, packages, disk, memory
  - Test: JSON valid and complete

- [ ] **FR-045**: Log rotation keeps last 10 installations
  - Test: Run installation 12 times → only last 10 logs remain
  - Verify: Rotation logic in lib/core/logging.sh

- [ ] **FR-046**: Task timing logged (start, end, duration)
  - Test: All tasks have timing data in JSON logs
  - Verify: Duration calculation accurate
  - Test: Performance analysis possible from logs

---

## Error Handling & Recovery (FR-047 to FR-052)

- [ ] **FR-047**: Error messages include what/why/how
  - Test: Inject various errors → verify message format
  - Test: Recovery suggestions present and actionable
  - Code review: All error messages follow format

- [ ] **FR-048**: Errors auto-expand in collapsible output
  - Test: Error occurs → output auto-expands
  - Test: Full diagnostic information visible
  - Verify: Error expansion in lib/ui/collapsible.sh

- [ ] **FR-049**: Continue-or-abort option for non-critical errors
  - Test: Non-critical error → prompt appears
  - Test: User can choose continue or abort
  - Test: Critical errors abort immediately (no prompt)

- [ ] **FR-050**: Rollback capability for failed tasks
  - Test: Task fails → rollback restores previous state
  - Test: Backups used for rollback
  - Verify: Rollback logic in lib/core/errors.sh

- [ ] **FR-051**: Error aggregation at end
  - Test: Multiple errors → summary at end
  - Test: All errors listed with context
  - Verify: Error collection and reporting

- [ ] **FR-052**: Recovery suggestions specific to error type
  - Test: Network error → suggests checking connection
  - Test: Permission error → suggests sudo/permissions fix
  - Test: Dependency error → suggests installing dependencies
  - Code review: Error type detection and suggestion mapping

---

## Idempotency & Resume (FR-053 to FR-058)

- [ ] **FR-053**: Existing state checked, skip if installed
  - Test: Run installation twice → second run skips completed tasks
  - Test: Verification functions detect existing installations
  - Performance: Second run completes in <30 seconds

- [ ] **FR-054**: User customizations preserved
  - Test: Modify ZSH config, re-run installation → customizations intact
  - Test: Modify Ghostty theme, update → theme preserved
  - Test: Shell aliases, functions preserved

- [ ] **FR-055**: Critical files backed up with timestamps
  - Test: Check backup directory → timestamped backups exist
  - Verify: Backup before modification in all tasks
  - Test: Backup rotation (keep reasonable number)

- [ ] **FR-056**: Restore capability for failed modifications
  - Test: Inject failure → restore from backup
  - Test: Restored file matches original
  - Verify: Restore logic in lib/core/errors.sh

- [ ] **FR-057**: Installation state persisted to JSON
  - Test: Interrupt installation → state file exists
  - Test: JSON contains task status, checkpoints
  - Verify: State save on each task completion

- [ ] **FR-058**: Resume from checkpoint after interruption
  - Test: Kill installation at task 5 → resume completes tasks 6-10
  - Test: No duplicate work (tasks 1-5 skipped)
  - Verify: State load and resume logic

---

## Performance Standards (FR-059 to FR-063)

- [ ] **FR-059**: Total installation <10 minutes (fresh system)
  - Benchmark: Fresh Ubuntu VM → measure total time
  - Constitutional requirement: MUST be <10 minutes
  - Test: Multiple runs, average time

- [ ] **FR-060**: fnm startup time <50ms
  - Benchmark: `time fnm --version` → measure
  - Constitutional requirement: MUST be <50ms
  - Test: Multiple measurements, verify consistency

- [ ] **FR-061**: gum startup time <10ms
  - Benchmark: `time gum --version` → measure
  - Performance target: <10ms
  - Test: Multiple measurements

- [ ] **FR-062**: Parallel execution for independent tasks
  - Test: Monitor task execution → verify parallel runs
  - Test: Task dependencies respected (sequential when required)
  - Performance: 30-40% faster than sequential baseline

- [ ] **FR-063**: Progress feedback every ≤5 seconds
  - Test: Time between progress updates → verify ≤5s
  - Test: No long silent periods
  - Verify: Update frequency in long-running tasks

---

## App Duplicate Detection (FR-064 to FR-070)

- [ ] **FR-064**: Scan for duplicates (snap/apt, disabled, browsers)
  - Test: Run audit → detects snap+apt duplicates
  - Test: Detects disabled snap versions
  - Test: Identifies multiple browsers
  - Verify: Audit logic comprehensive

- [ ] **FR-065**: Categorize duplicates by type
  - Test: Audit report → categories clear (enabled duplicates, disabled snaps, browsers)
  - Verify: Categorization logic accurate

- [ ] **FR-066**: Calculate disk usage per category
  - Test: Audit report → disk usage shown for each duplicate
  - Test: Total recoverable space calculated
  - Verify: Disk usage calculation accurate

- [ ] **FR-067**: Generate audit report in /tmp/ubuntu-apps-audit.md
  - Test: File exists after audit
  - Test: Report format readable and actionable
  - Verify: Markdown formatting correct

- [ ] **FR-068**: Safe cleanup commands preserve user data
  - Test: Cleanup removes duplicates without data loss
  - Test: User preferences preserved (bookmarks, settings)
  - Code review: Data preservation logic

- [ ] **FR-069**: Verify app icon clarity after cleanup
  - Test: Ubuntu "Show Apps" → no duplicate icons
  - Manual inspection: Icon drawer clean
  - Test: Single icon per application

- [ ] **FR-070**: Selective cleanup (user chooses)
  - Test: User prompted to select which duplicates to remove
  - Test: User can skip certain removals
  - Verify: Interactive selection UI

---

## Context7 Integration (FR-071 to FR-075)

- [ ] **FR-071**: Query Context7 before installing apps
  - Test: Installation queries Context7 MCP for recommendations
  - Verify: mcp__context7__* tools used
  - Test: Recommendations retrieved successfully

- [ ] **FR-072**: Follow Context7 snap/apt/source recommendations
  - Test: Installation method matches Context7 recommendation
  - Code review: Decision logic based on Context7 response

- [ ] **FR-073**: Validate existing installations against Context7
  - Test: Audit flags non-compliant installations
  - Test: Compliance report accurate
  - Verify: Validation logic comprehensive

- [ ] **FR-074**: Generate compliance report
  - Test: Report includes non-compliant apps
  - Test: Recommendations provided for each issue
  - Verify: Report format actionable

- [ ] **FR-075**: Suggest migration paths for non-compliance
  - Test: Non-compliant app → migration steps provided
  - Test: Migration preserves functionality
  - Verify: Migration suggestions safe and tested

---

## Non-Functional Requirements

### Reliability (NFR-001 to NFR-004)

- [ ] **NFR-001**: Installation success rate ≥99%
  - CI/CD: Run 100+ installations across configurations → measure success rate
  - Target: ≥99% success
  - Test: Fresh install, existing system, SSH, VM

- [ ] **NFR-002**: Verification accuracy ≥99%
  - Test: No false positives (verification passes when component missing)
  - Test: No false negatives (verification fails when component installed)
  - Benchmark: ≥99% accuracy

- [ ] **NFR-003**: Zero data loss
  - Test: Backups created before modifications
  - Test: Restore capability tested
  - Test: User data preserved across installations

- [ ] **NFR-004**: Graceful degradation without gum
  - Test: Remove gum → installation continues with plain text
  - Test: Functionality intact (no crashes)
  - Verify: Fallback implementation

### Performance (NFR-005 to NFR-009)

- [ ] **NFR-005**: Total time <10 minutes
  - Benchmark: Fresh system average time
  - Constitutional requirement: MUST meet
  - Test: Multiple runs, measure variance

- [ ] **NFR-006**: fnm startup <50ms
  - Benchmark: `time fnm --version`
  - Constitutional requirement: MUST meet
  - Test: Consistent across runs

- [ ] **NFR-007**: gum startup <10ms
  - Benchmark: `time gum --version`
  - Target: <10ms
  - Test: Measure during installation

- [ ] **NFR-008**: Progress updates every ≤5s
  - Test: Time between updates
  - Verify: No long silent periods

- [ ] **NFR-009**: Log file size <10MB per run
  - Test: Check log file sizes
  - Verify: Rotation prevents unbounded growth

### Usability (NFR-010 to NFR-014)

- [ ] **NFR-010**: Professional visual appearance
  - Manual inspection: No broken characters
  - Test: Clean formatting across terminals
  - User feedback: Professional rating

- [ ] **NFR-011**: Clear error messages
  - Test: All errors have actionable steps
  - Code review: Error message quality

- [ ] **NFR-012**: Resumable after interruption
  - Test: Kill and resume → completes successfully
  - Test: No manual intervention required

- [ ] **NFR-013**: User customizations preserved
  - Test: Re-run doesn't overwrite customizations
  - Test: Manual configs intact

- [ ] **NFR-014**: Verbose mode toggle
  - Test: 'v' key expands/collapses
  - Test: --verbose flag works

### Maintainability (NFR-015 to NFR-019)

- [ ] **NFR-015**: Modular architecture, single responsibility
  - Code review: Each lib/ module has clear purpose
  - Test: Modules independently testable

- [ ] **NFR-016**: Independent component testing
  - Test: Unit tests pass in isolation
  - Verify: No tight coupling

- [ ] **NFR-017**: Comprehensive logging
  - Code review: All critical operations logged
  - Test: Logs sufficient for debugging

- [ ] **NFR-018**: Code coverage ≥80%
  - Benchmark: Run coverage tools on lib/core/, lib/ui/, lib/verification/
  - Target: ≥80% coverage

- [ ] **NFR-019**: Documentation updated
  - Verify: All lib/ modules documented
  - Test: Function headers complete

### Security (NFR-020 to NFR-023)

- [ ] **NFR-020**: No credentials logged
  - Code review: Grep for API keys, passwords → none in logs
  - Test: Log files don't contain sensitive data

- [ ] **NFR-021**: Package downloads verified
  - Test: Checksums validated where available
  - Verify: Download verification logic

- [ ] **NFR-022**: Sudo usage minimized
  - Code review: Sudo only where necessary
  - Test: Installation works with scoped sudo

- [ ] **NFR-023**: User data backups encrypted
  - Test: Backups with sensitive data encrypted
  - Verify: Encryption implementation (if applicable)

### Compatibility (NFR-024 to NFR-028)

- [ ] **NFR-024**: Works on Ubuntu 25.10 fresh
  - Test: Fresh VM installation
  - Verify: All components install correctly

- [ ] **NFR-025**: Works with existing Ghostty
  - Test: System with Ghostty → idempotent run
  - Test: No conflicts, preserves settings

- [ ] **NFR-026**: Works via SSH
  - Test: SSH connection → ASCII boxes
  - Test: Full functionality via SSH

- [ ] **NFR-027**: Works in TTY console
  - Test: TTY console → ASCII fallback
  - Test: Installation completes

- [ ] **NFR-028**: Works with ZSH/Bash/POSIX
  - Test: ZSH shell → works
  - Test: Bash shell → works
  - Test: Detection logic accurate

---

## Success Criteria Validation

- [ ] **SC-001**: Installation <10 min (fresh Ubuntu 25.10)
  - Benchmark: Multiple fresh VM runs
  - Target: <10 minutes consistently

- [ ] **SC-002**: Zero broken box characters
  - Visual testing: Ghostty, xterm, SSH, legacy
  - Manual inspection: All terminals render correctly

- [ ] **SC-003**: 100% real verification functions
  - Code audit: All tasks have verify_* functions
  - Test: No hard-coded success messages

- [ ] **SC-004**: Verification accuracy ≥99%
  - Integration tests: Measure true positive/negative rates
  - Benchmark: ≥99% accuracy

- [ ] **SC-005**: Re-run completes in <30s
  - Test: Second run time measurement
  - Idempotency validation

- [ ] **SC-006**: 100% errors have recovery suggestions
  - Error injection testing: All error types
  - Code review: All error handlers provide suggestions

- [ ] **SC-007**: Cleanup recovers ≥4GB
  - Test: Typical system before/after
  - Disk usage measurement

- [ ] **SC-008**: Zero duplicate icons
  - Manual inspection: Ubuntu "Show Apps"
  - Test: Post-cleanup icon clarity

- [ ] **SC-009**: Success rate ≥99%
  - CI/CD: 100+ runs across configs
  - Statistical measurement

- [ ] **SC-010**: Parallel execution 30-40% faster
  - Benchmark: Sequential vs parallel
  - Performance comparison

- [ ] **SC-011**: 90% user satisfaction
  - User surveys (future)
  - Professional rating

- [ ] **SC-012**: fnm startup <50ms
  - Benchmark: Startup time measurement
  - Constitutional requirement

- [ ] **SC-013**: gum startup <10ms
  - Benchmark: Startup time measurement
  - Performance target

- [ ] **SC-014**: 100% Context7 compliance
  - Audit: All apps follow recommendations
  - Compliance report validation

- [ ] **SC-015**: 100% customization preservation
  - Diff testing: Before/after comparison
  - User configs intact

---

## Constitutional Compliance Validation

- [ ] **TUI Framework**: gum exclusive (no whiptail/dialog/rich-cli)
- [ ] **Box Drawing**: Adaptive UTF-8/ASCII (no hard-coded)
- [ ] **Verification**: Real tests only (no hard-coded success)
- [ ] **Package Managers**: uv (Python), fnm (Node.js) exclusive
- [ ] **Architecture**: Modular lib/ structure (not monolithic)
- [ ] **Critical Files**: docs/.nojekyll preserved
- [ ] **Directory Naming**: .runners-local/ (not .runners-local/)
- [ ] **Component Library**: DaisyUI (not shadcn/ui)
- [ ] **Node.js Version**: Latest v25.2.0+ (not LTS/18+)

---

## Final Sign-Off

**Specification Author**: Claude
**Review Date**: _____________
**Approval Status**: ☐ Approved ☐ Needs Revision ☐ Rejected

**Notes**:
_______________________________________
_______________________________________
_______________________________________

**Next Steps**:
1. [ ] Proceed to `/speckit.plan` for implementation roadmap
2. [ ] Create dependency graph for task ordering
3. [ ] Estimate implementation timeline (6-week roadmap)
4. [ ] Assign implementation waves and agent coordination
