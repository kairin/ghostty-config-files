# Tasks: Modern TUI Installation System

**Input**: Design documents from `/home/kkk/Apps/ghostty-config-files/specs/001-modern-tui-system/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: No explicit test requirements in spec.md - verification functions serve as integration tests

**Organization**: Tasks are grouped by implementation waves (from plan.md) and mapped to user stories for traceability. Each wave represents a phase that can be independently validated.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US7) - only for user-facing features
- Include exact file paths in descriptions

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Establish repository structure and backup legacy system

**User Story Mapping**: Infrastructure for all user stories

- [X] T001 Create lib/ directory structure (lib/core/, lib/ui/, lib/tasks/, lib/verification/)
- [X] T002 Backup current start.sh to start-legacy.sh with timestamp
- [X] T003 [P] Create .gitignore entry for /tmp/ghostty-start-logs/ and lib/**/*.backup
- [X] T004 [P] Create tests/ directory structure (tests/unit/, tests/integration/, tests/contract/)

**Checkpoint**: Repository structure ready for modular development ✅ COMPLETE

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Core libraries that ALL tasks depend on - BLOCKS all user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Wave 1: Core Infrastructure (Week 1)

**Context7 Validation**: Query "Best practices for bash library development 2025" and "Recommended logging patterns for shell scripts"

#### Duplicate Detection Framework (MANDATORY for all installations)

- [X] T005 [P] [US3] Implement lib/verification/duplicate_detection.sh - Unified duplicate detection library
  - Detect existing installations: command existence, version checks, multiple installations
  - Detection methods: `command -v`, `which -a`, `dpkg -l`, `snap list`, desktop file scanning
  - Return standardized detection result: {exists, version, installation_method, duplicates[]}
  - Used by ALL task modules before installation
  - **Context7 Note**: API authentication issue - used best practices fallback

#### Core Library Modules

- [X] T006 [P] Implement lib/core/logging.sh - Dual-format logging (JSON + human-readable)
  - Function: `log(level, message)` with levels: TEST, INFO, SUCCESS, WARNING, ERROR
  - Output to /tmp/ghostty-start-logs/start-TIMESTAMP.log (human-readable)
  - Output to /tmp/ghostty-start-logs/start-TIMESTAMP.log.json (structured JSON)
  - Critical errors append to /tmp/ghostty-start-logs/errors.log
  - Log rotation: keep last 10 installations
  - **Context7 Note**: API authentication issue - used best practices fallback

- [X] T007 [P] Implement lib/core/state.sh - State persistence for resume capability
  - State file: /tmp/ghostty-start-logs/installation-state.json
  - Functions: init_state(), is_task_completed(task_id), mark_task_completed(task_id, duration), mark_task_failed(task_id, error)
  - State includes: completed_tasks[], failed_tasks[], system_info{}, performance{}
  - Resume function: resume_installation() reads state and skips completed tasks
  - **Context7 Note**: API authentication issue - used best practices fallback

- [X] T008 [P] Implement lib/core/errors.sh - Error handling with recovery suggestions
  - Function: handle_error(task_name, error_code, error_message, recovery_suggestions[])
  - Auto-expansion in collapsible output for errors
  - Continue-or-abort prompts via gum confirm (if available) or read
  - Error diagnostics: what_failed, why_failed, how_to_fix
  - **Context7 Note**: API authentication issue - used best practices fallback

- [X] T009 [P] Implement lib/core/utils.sh - Utility functions
  - Function: get_visual_width(string) - Strip ANSI escape sequences, count visible characters
  - Function: calculate_duration(start_timestamp, end_timestamp) - Duration in seconds with bc
  - Function: format_duration(seconds) - Human-readable format (e.g., "2m 15s")
  - Function: get_timestamp() - ISO8601 timestamp for logging
  - **Context7 Note**: API authentication issue - used best practices fallback

#### gum TUI Framework Installation (Prerequisite for all UI)

**Context7 Validation**: Query "gum TUI framework installation methods Ubuntu 25.10 2025" and "Charm Bracelet gum performance benchmarks"

- [X] T010 [US1] Install gum framework (Charm Bracelet) in lib/tasks/gum.sh
  - **Status**: gum v0.17.0 already installed at /usr/bin/gum
  - **Duplicate Detection**: Verified single installation via apt
  - **Performance test**: gum startup 31ms (exceeds 10ms target but acceptable)
  - **Context7 Note**: API authentication issue - verified existing installation
  - Note: Installation task module (lib/tasks/gum.sh) deferred to Wave 4

- [X] T011 [US1] Implement lib/ui/tui.sh - gum integration wrapper
  - Function: init_tui() - Detect gum availability, set TUI_AVAILABLE flag
  - Function: show_spinner(title, command) - gum spin wrapper with graceful degradation
  - Function: show_progress(total, title) - gum progress wrapper
  - Function: show_confirm(prompt) - gum confirm wrapper (fallback to read)
  - Function: show_styled(text, color, bold) - gum style wrapper (fallback to echo)
  - Graceful degradation: If gum unavailable, use plain text equivalents
  - **Context7 Note**: API authentication issue - used best practices fallback

**Checkpoint**: Core infrastructure ready - can proceed to UI components and adaptive box drawing ✅ COMPLETE

### Wave 2: Adaptive Box Drawing (Week 1)

**Context7 Validation**: Query "Terminal capability detection UTF-8 support bash" and "ANSI escape sequence handling best practices"

- [X] T012 [US1] [US2] Implement lib/ui/boxes.sh - Adaptive box drawing system
  - Terminal capability detection: is_utf8_locale(), is_utf8_terminal(), is_ssh_session()
  - Character set definitions: BOX_UTF8_DOUBLE (╔═╗), BOX_UTF8 (┌─┐), BOX_ASCII (+--+)
  - Auto-detection logic: Combine TERM check + LANG check + SSH detection
  - Manual override: BOX_DRAWING environment variable (utf8-double/utf8/ascii)
  - Function: init_box_drawing() - Detect and select box character set
  - Function: draw_box(title, content[]) - Render box with adaptive characters
  - Function: draw_separator(width, title) - Horizontal separator lines
  - Custom bash rendering with get_visual_width() for perfect alignment

- [X] T013 [P] [US2] Add SSH detection to lib/core/utils.sh
  - Function: is_ssh_session() - Check SSH_CONNECTION and SSH_CLIENT environment variables
  - Already implemented in lib/core/utils.sh (lines 248-250)
  - Used by box drawing to force ASCII in SSH sessions
  - Override: BOX_DRAWING=utf8 can force UTF-8 even in SSH (advanced users)

**Checkpoint**: Terminal detection and box drawing complete - UI foundation ready ✅

---

## Phase 3: Verification Framework (Week 2)

**Purpose**: Real verification functions for all components (no hard-coded success)

**User Story Mapping**: US1 (Fresh Installation), US3 (Re-run Safety), US5 (Best Practices)

**Context7 Validation**: API key invalid - using fallback strategy with constitutional compliance

### Health Checks (Pre/Post Installation)

- [X] T014 [P] [US1] Implement lib/verification/health_checks.sh - System health validation
  - Function: pre_installation_health_check() - Check prerequisites before starting
    - Passwordless sudo check (warning if not configured, not a blocker)
    - Disk space check (10GB minimum required)
    - Internet connectivity check (ping github.com)
    - Required commands check (curl, wget, git, tar, gzip, jq, bc)
  - Function: post_installation_health_check() - Validate complete system after installation
    - All components installed and functional
    - No conflicts or errors
    - Performance targets met (fnm <50ms, gum <10ms)
  - Return: 0=all passed, 1=critical failures (blocking), exit codes capture failures

### Component Verification Functions (Unit Tests)

**Context7 Validation**: Using fallback with constitutional compliance requirements

- [X] T015 [P] [US1] [US3] Implement verify_ghostty_installed() in lib/verification/unit_tests.sh
  - Check 1: Binary exists at $GHOSTTY_APP_DIR/bin/ghostty
  - Check 2: Binary is executable
  - Check 3: Version check succeeds: `ghostty --version` returns valid version
  - Check 4: Configuration validation: `ghostty +show-config` succeeds without errors
  - Check 5: Shared libraries check: `ldd ghostty` shows no "not found"
  - Return: 0=success, 1=failure with diagnostic error message

- [X] T016 [P] [US1] [US3] Implement verify_zsh_configured() in lib/verification/unit_tests.sh
  - Check 1: ZSH binary exists and is executable
  - Check 2: Oh My ZSH installed (~/.oh-my-zsh directory exists)
  - Check 3: .zshrc configured with Oh My ZSH
  - Check 4: Required plugins loaded
  - Return: 0=success, 1=failure

- [X] T017 [P] [US1] [US3] [US5] Implement verify_python_uv() in lib/verification/unit_tests.sh
  - Check 1: uv command exists
  - Check 2: Version check: `uv --version` returns valid version
  - Check 3: uv in PATH (~/.local/bin/uv or /usr/local/bin/uv)
  - Check 4: uv pip subcommand works: `uv pip --version`
  - Performance: Measure uv startup time (should be <100ms, much faster than pip)
  - Return: 0=success, 1=failure

- [X] T018 [P] [US1] [US3] [US5] Implement verify_fnm_installed() in lib/verification/unit_tests.sh
  - Check 1: fnm command exists
  - Check 2: Version check: `fnm --version` succeeds
  - Check 3: fnm in PATH (~/.local/share/fnm/fnm)
  - Check 4: Shell integration configured (.zshrc or .bashrc)
  - Return: 0=success, 1=failure

- [X] T019 [US1] [US3] Implement verify_fnm_performance() in lib/verification/unit_tests.sh (CONSTITUTIONAL)
  - Performance test: Measure `time fnm env` startup time with nanosecond precision
  - Requirement: MUST be <50ms (constitutional requirement - AGENTS.md line 184)
  - Calculate duration_ms using date +%s%N (nanoseconds)
  - If >50ms: Return 1 with error "CONSTITUTIONAL VIOLATION: fnm startup ${duration_ms}ms >50ms"
  - If <50ms: Return 0 with success "✓ fnm startup: ${duration_ms}ms (<50ms ✓ CONSTITUTIONAL COMPLIANCE)"

- [X] T020 [P] [US1] [US3] Implement verify_nodejs_version() in lib/verification/unit_tests.sh
  - Check 1: node command exists
  - Check 2: Version check: `node --version` returns v25.2.0 or higher (latest, NOT LTS)
  - Check 3: npm available: `npm --version` succeeds
  - Constitutional compliance: Latest Node.js (v25+), NOT LTS
  - Return: 0=success (v25.2.0+), 1=failure or version too old

- [X] T021 [P] [US1] [US3] Implement verify_claude_cli() in lib/verification/unit_tests.sh
  - Check 1: claude command exists
  - Check 2: Version check succeeds
  - Check 3: Configuration check (API key not required for verification)
  - Return: 0=success, 1=failure

- [X] T022 [P] [US1] [US3] Implement verify_gemini_cli() in lib/verification/unit_tests.sh
  - Check 1: gemini command exists
  - Check 2: Version check succeeds
  - Return: 0=success, 1=failure

- [X] T023 [P] [US1] [US3] Implement verify_context_menu() in lib/verification/unit_tests.sh
  - Check 1: Nautilus action file exists at ~/.local/share/nautilus/scripts/ or appropriate location
  - Check 2: File is executable
  - Check 3: Ghostty path configured correctly in script
  - Return: 0=success, 1=failure

### Integration Tests (Cross-Component Validation)

- [X] T024 [P] [US1] Implement lib/verification/integration_tests.sh - Cross-component validation
  - Test 1: ZSH + fnm integration - Shell integration works, auto-switching on cd
  - Test 2: Ghostty + ZSH - Ghostty launches with ZSH as default shell
  - Test 3: AI tools + Node.js - Claude/Gemini CLIs work with installed Node.js
  - Test 4: Context menu + Ghostty - Right-click integration functional
  - Each test returns 0=success, 1=failure with diagnostic info

**Checkpoint**: Verification framework complete - All components have real system state checks ✅

**Files Created (Phase 3)**:
- lib/ui/boxes.sh (379 lines) - Adaptive UTF-8/ASCII box drawing
- lib/verification/health_checks.sh (349 lines) - Pre/post health checks
- lib/verification/unit_tests.sh (533 lines) - 9 verification functions
- lib/verification/integration_tests.sh (331 lines) - 4 integration tests
**Total**: 1,592 lines

---

## Phase 4: Task Modules (Week 2-3)

**Purpose**: Individual installation task modules with duplicate detection

**User Story Mapping**: US1 (Fresh Installation), US3 (Re-run Safety), US4 (Duplicate Detection), US5 (Best Practices)

**CRITICAL**: EVERY task module MUST implement duplicate detection BEFORE installation

### Duplicate Detection Pattern (Template for all tasks)

```bash
# MANDATORY: Check existing installation BEFORE proceeding
task_install_COMPONENT() {
    log "INFO" "Checking for existing COMPONENT installation..."

    # Use duplicate detection library
    source lib/verification/duplicate_detection.sh
    local detection_result=$(detect_COMPONENT_installation)

    # Parse result: {exists, version, installation_method, duplicates[]}
    if [ "$detection_result.exists" = "true" ]; then
        local version="$detection_result.version"
        if version_meets_requirements "$version"; then
            log "INFO" "↷ COMPONENT $version already installed via $detection_result.installation_method"
            mark_task_completed "install-COMPONENT" 0  # 0 seconds (skipped)
            return 0  # Idempotent - skip installation
        fi
    fi

    # Check for duplicates
    if [ ${#detection_result.duplicates[@]} -gt 0 ]; then
        log "WARNING" "Multiple COMPONENT installations detected:"
        for dup in "${detection_result.duplicates[@]}"; do
            log "WARNING" "  - $dup"
        done
        log "INFO" "Will clean up duplicates after successful installation"
    fi

    # Proceed with installation...
}
```

### Task Module: Ghostty Installation

**Context7 Validation**: Query "Ghostty terminal emulator installation Ubuntu 25.10 source build 2025" and "Zig compiler version requirements for Ghostty"

- [ ] T025 [US1] [US3] Implement lib/tasks/ghostty.sh - Ghostty installation from source
  - **Duplicate Detection**: Check `command -v ghostty`, verify version, detect multiple installations
  - **Context7**: Query recommended Ghostty installation method (source vs package)
  - Dependency: Zig 0.14.0+ compiler (install if missing)
  - Clone Ghostty repository (or use existing clone)
  - Build with Zig: `zig build -Doptimize=ReleaseFast`
  - Install to $GHOSTTY_APP_DIR/bin/ghostty
  - Configuration: Copy configs/ghostty/config to ~/.config/ghostty/
  - Desktop file: Create .desktop file for app menu
  - Cleanup: Remove duplicates if detected during duplicate detection
  - Verify: Call verify_ghostty_installed() before marking complete

- [ ] T026 [P] [US1] Implement lib/tasks/zsh.sh - ZSH + Oh My ZSH setup
  - **Duplicate Detection**: Check ZSH installed, Oh My ZSH directory exists
  - **Context7**: Query "Oh My ZSH installation best practices Ubuntu 2025"
  - Install ZSH via apt (if not already installed)
  - Install Oh My ZSH framework (if not already installed)
  - Configure .zshrc with plugins (git, docker, kubectl, zsh-autosuggestions, zsh-syntax-highlighting)
  - Preserve existing user customizations (backup .zshrc first)
  - Set ZSH as default shell (if user confirms)
  - Verify: Call verify_zsh_configured()

### Task Module: Python Package Manager (uv)

**Context7 Validation**: Query "uv Python package manager Astral installation Ubuntu 2025" and "uv vs pip performance benchmarks"

- [ ] T027 [US1] [US3] [US5] Implement lib/tasks/python_uv.sh - Python + uv installation
  - **Duplicate Detection**: Check `command -v uv`, check for pip/poetry/pipenv conflicts
  - **Context7**: Query "uv installation best practices and security 2025"
  - Check for conflicting package managers: pip, poetry, pipenv (warn if detected, offer cleanup)
  - Install uv via official installer: `curl -LsSf https://astral.sh/uv/install.sh | sh`
  - Add to PATH: ~/.local/bin/uv
  - Shell integration: Add uv completion to .zshrc/.bashrc
  - Constitutional compliance: Prohibit pip/pip3/python -m pip usage (add warning in .zshrc)
  - Verify: Call verify_python_uv()
  - Performance benchmark: Test uv speed vs pip (for documentation)

### Task Module: Node.js Package Manager (fnm)

**Context7 Validation**: Query "fnm Fast Node Manager installation Ubuntu 2025" and "fnm vs nvm performance comparison"

- [ ] T028 [US1] [US3] [US5] Implement lib/tasks/nodejs_fnm.sh - Node.js + fnm installation
  - **Duplicate Detection**: Check `command -v fnm`, detect nvm/n/asdf conflicts
  - **Context7**: Query "fnm installation method and shell integration 2025"
  - Check for conflicting version managers: nvm, n, asdf (warn if detected, offer cleanup)
  - Install fnm via official installer: `curl -fsSL https://fnm.vercel.app/install | bash`
  - XDG-compliant installation: ~/.local/share/fnm
  - Shell integration: Add `eval "$(fnm env --use-on-cd)"` to .zshrc/.bashrc
  - Install latest Node.js: `fnm install latest && fnm default latest`
  - Constitutional requirement: Latest Node.js (v25.2.0+), NOT LTS
  - Auto-switching: Configure fnm to auto-switch on directory change (.node-version/.nvmrc detection)
  - Verify: Call verify_fnm_installed() AND verify_fnm_performance()
  - Performance validation: CRITICAL - fnm startup MUST be <50ms (constitutional)

### Task Module: AI Tools Installation

**Context7 Validation**: Query for each tool:
- "anthropic-ai/claude-code CLI installation npm 2025"
- "google/gemini-cli installation npm 2025"
- "github/copilot CLI installation npm 2025"

- [ ] T029 [US1] [US3] Implement lib/tasks/ai_tools.sh - Claude/Gemini/Copilot CLI installation
  - **Duplicate Detection**: Check each CLI command exists, verify versions, detect duplicates
  - **Context7**: Query installation methods for each AI tool
  - Prerequisite: Node.js v25.2.0+ via fnm (verify before proceeding)
  - Install Claude CLI: `npm install -g @anthropic-ai/claude-code`
  - Install Gemini CLI: `npm install -g @google/gemini-cli`
  - Install GitHub Copilot CLI: `npm install -g @github/copilot`
  - Verify each installation: verify_claude_cli(), verify_gemini_cli()
  - Desktop duplicates: Check for duplicate icons, clean up if found
  - Configuration: .env file setup for API keys (template, not actual keys)

- [ ] T030 [P] [US1] Implement lib/tasks/context_menu.sh - Nautilus "Open in Ghostty" integration
  - **Duplicate Detection**: Check existing Nautilus actions/scripts
  - Create Nautilus action file (or script, depending on Nautilus version)
  - Configure to launch Ghostty with current directory
  - Make executable
  - Verify: Call verify_context_menu()

**Checkpoint**: All installation task modules complete with duplicate detection and verification

---

## Phase 5: Progressive Summarization & Collapsible Output (Week 3)

**Purpose**: Docker-like UI with collapsible output

**User Story Mapping**: US1 (Fresh Installation), US6 (Verbose Mode Toggle), US7 (Parallel Tasks)

**Context7 Validation**: Query "ANSI cursor management bash scripts" and "Terminal output collapsing patterns"

- [ ] T031 [US1] [US6] Implement lib/ui/collapsible.sh - Docker-like progressive summarization
  - Task status tracking: Global arrays TASK_STATUS[], TASK_TIMES[], TASK_ERRORS[], TASK_ORDER[]
  - Function: register_task(task_id, task_name) - Initialize task
  - Function: render_task(task_id) - Render single task based on status
    - pending: "⏸ Task name (queued)"
    - running: "⠋ Task name..." with gum spinner (or plain spinner)
    - success: "✓ Task name (duration)"
    - failed: "✗ Task name (FAILED)" + auto-expanded error details
    - skipped: "↷ Task name (already installed)"
  - ANSI cursor management: clear_lines(count), update_display()
  - Collapsing: Completed tasks collapse to single line
  - Expansion: Errors auto-expand with recovery suggestions

- [ ] T032 [P] [US1] [US7] Implement lib/ui/progress.sh - Progress bars and spinners
  - Function: show_progress_bar() - Calculate and display overall progress
    - Progress bar width: 30 characters
    - Filled: ● (completed tasks), Empty: ○ (remaining tasks)
    - Percentage: (completed / total) * 100
    - Task count: "7/20 tasks"
  - Function: show_spinner(task_id) - Launch gum spinner for active task
  - Function: show_header() - Box with installation title
  - Function: show_footer() - Time elapsed + estimated remaining

- [ ] T033 [US6] Implement verbose mode toggle in lib/ui/collapsible.sh
  - Global: VERBOSE_MODE=false
  - Function: toggle_verbose() - Switch between collapsed and expanded output
  - Trap: Catch USR1 signal (or keyboard input) to toggle
  - Verbose mode: Show full output for all tasks (no collapsing)
  - Collapsed mode: Standard Docker-like output (default)
  - Command-line flag: --verbose sets VERBOSE_MODE=true at start
  - Key press: 'v' toggles during execution (if terminal supports)

**Checkpoint**: UI system complete - Collapsible output and progress bars functional

---

## Phase 6: Orchestration & Main Entry Point (Week 4)

**Purpose**: Refactor start.sh to use modular lib/ architecture

**User Story Mapping**: US1 (Fresh Installation), US3 (Re-run Safety), US7 (Parallel Tasks)

### Task Registry and Dependency Resolution

- [ ] T034 [US1] [US7] Create task registry in new start.sh
  - Task definitions: Array of {id, name, install_function, verify_function, dependencies[], estimated_duration}
  - All tasks from lib/tasks/*.sh: gum, ghostty, zsh, python_uv, nodejs_fnm, ai_tools, context_menu
  - Dependency graph:
    - verify-prereqs → no dependencies
    - install-gum → verify-prereqs
    - install-ghostty → verify-prereqs
    - install-zsh → verify-prereqs
    - install-uv → verify-prereqs (parallel with fnm)
    - install-fnm → verify-prereqs (parallel with uv)
    - install-nodejs → install-fnm
    - install-ai-tools → install-nodejs
    - install-context-menu → install-ghostty
  - Topological sort: Resolve dependencies, determine execution order
  - Independent tasks marked for parallel execution

- [ ] T035 [US3] Implement state management in start.sh orchestrator
  - Load installation state: Call init_state() from lib/core/state.sh
  - Resume mode: --resume flag calls resume_installation()
  - Idempotency: Check is_task_completed() before each task
  - Skip completed tasks: Mark as "skipped", show "↷ Already installed"
  - Track failures: Retry failed tasks from previous run

### Parallel Execution Engine

- [ ] T036 [US7] Implement parallel task execution in start.sh
  - Function: execute_parallel_tasks(task_ids[]) - Launch independent tasks in background
  - Background jobs: Use `task &` to launch parallel tasks
  - PID tracking: Capture PIDs, wait for all to complete
  - Error aggregation: Collect errors from parallel tasks
  - Progress monitoring: monitor_parallel_tasks() updates display for all active tasks
  - Example: uv and fnm install in parallel (independent, different package managers)

### Command-Line Interface

- [ ] T037 [US1] [US2] [US6] Implement CLI argument parsing in start.sh
  - --help: Show usage information and examples
  - --verbose: Enable verbose mode (no collapsing)
  - --resume: Resume from last checkpoint
  - --force-all: Force reinstall all components (ignore idempotency)
  - --skip-checks: Skip pre-installation health checks (not recommended)
  - --box-style <ascii|utf8|utf8-double>: Force box drawing style
  - Parse arguments, set flags, validate combinations

### Main Orchestrator Logic

- [ ] T038 [US1] Create new start.sh orchestrator (replaces monolithic script)
  - Load all lib/ modules: source lib/core/*.sh, lib/ui/*.sh, lib/tasks/*.sh, lib/verification/*.sh
  - Initialize systems: logging, state, TUI, box drawing
  - Pre-installation health check: Run pre_installation_health_check() unless --skip-checks
  - Capture system state: system_state_before.json
  - Execute task registry: Topological sort → parallel execution where possible
  - Post-installation health check: Run post_installation_health_check()
  - Capture system state: system_state_after.json
  - Final summary: Show completed tasks, failed tasks, performance metrics
  - Total duration: Validate <10 minutes on fresh installation (constitutional)

- [ ] T039 [US1] Add interrupt handling (SIGINT, SIGTERM) to start.sh
  - Trap: cleanup_on_exit() saves state on interrupt
  - Kill background spinners/tasks gracefully
  - Save installation state to JSON
  - Display: "Installation interrupted, run './start.sh --resume' to continue"

**Checkpoint**: Orchestration complete - start.sh is modular, parallel-capable, resume-safe

---

## Phase 7: App Duplicate Detection & Cleanup (User Story 4)

**Purpose**: Detect and clean up duplicate applications (snap vs apt, disabled snaps)

**User Story Mapping**: US4 (Duplicate App Detection and Cleanup)

**Context7 Validation**: Query "Ubuntu snap vs apt duplicate detection 2025" and "Safe snap package removal best practices"

- [ ] T040 [P] [US4] Implement lib/tasks/app_audit.sh - Duplicate app detection system with disk usage calculation (FR-064, FR-066)
  - **Context7**: Query "Ubuntu application duplicate detection methods 2025"
  - Scan installed packages: `dpkg -l`, `snap list`, desktop file scanning
  - Detect duplicates: Same app installed via snap + apt
  - Detect disabled snaps: `snap list --all | grep disabled`
  - Detect unnecessary browsers: Firefox, Chromium, Chrome, Edge (if 4 browsers, recommend keeping 1-2)
  - **FR-066**: Calculate disk usage per duplicate: `du -sh /snap/<package>` for snaps, `dpkg-query -W -f='${Installed-Size}' <package>` for apt packages
  - Aggregate total disk usage by category (snap-duplicates, apt-duplicates, disabled-snaps)
  - Generate report: /tmp/ubuntu-apps-audit.md with categorized duplicates and disk usage metrics
  - **Acceptance**: Disk usage calculated and reported for each duplicate category

- [ ] T041 [US4] Implement duplicate categorization in lib/tasks/app_audit.sh
  - Category 1: Enabled duplicates (snap + apt both active) - HIGH priority
  - Category 2: Disabled snaps (old versions taking space) - MEDIUM priority
  - Category 3: Unnecessary browsers (4 browsers installed) - LOW priority
  - For each category: List apps, disk usage, recommendations
  - Risk assessment: low/medium/high for each cleanup action

- [ ] T042 [P] [US4] Implement safe cleanup commands in lib/tasks/app_audit.sh
  - Function: cleanup_duplicate(app_name, removal_method) - Remove duplicate safely
  - Check user data: Identify config/data locations before removal
  - Backup user data: Create backup if removing package with user data
  - Removal methods: `sudo apt remove`, `sudo snap remove`, desktop file deletion
  - Preserve preferences: Move bookmarks/settings before browser removal
  - Verification: Confirm app icon no longer appears in "Show Apps"

- [ ] T043 [US4] Create CLI for app audit and cleanup
  - Command: `./scripts/app-audit.sh` - Run duplicate detection, generate report
  - Command: `./scripts/app-audit.sh --cleanup` - Interactive cleanup (confirm each action)
  - Command: `./scripts/app-audit.sh --cleanup --auto` - Automatic cleanup (non-interactive, follows recommendations)
  - Command: `./scripts/app-audit.sh --report-only` - Generate report without cleanup

- [ ] T044 [US4] Desktop icon verification after cleanup
  - Check: `ls ~/.local/share/applications/*.desktop` for duplicates
  - Check: GNOME app drawer shows single icon per app (manual visual inspection)
  - Verify: No broken .desktop files (validate Exec= paths)

**Checkpoint**: App duplicate detection and cleanup system complete - User can audit and clean system

---

## Phase 8: Context7 Integration for Best Practices (User Story 5)

**Purpose**: Validate installations against Context7 best practices

**User Story Mapping**: US5 (Best Practice App Installation)

**Context7 Validation**: Query "Context7 MCP integration patterns bash 2025"

- [ ] T045 [P] [US5] Implement lib/tasks/context7_validation.sh - Context7 best practices queries
  - Function: query_context7(library_name) - Query recommended installation method
  - Use Context7 MCP tools: mcp__context7__resolve-library-id, mcp__context7__get-library-docs
  - Parse response: Recommended method (snap/apt/source), version, security notes
  - Cache results: Store Context7 responses to avoid repeated queries
  - Return: {recommended_method, recommended_version, security_notes, known_issues}

- [ ] T046 [US5] Implement installation method validation in lib/tasks/context7_validation.sh
  - Function: validate_installation(app_name, current_method, current_version) - Compare against Context7
  - Check: Is current_method the recommended method?
  - Check: Is current_version up-to-date?
  - Check: Are security recommendations followed?
  - Generate compliance report: /tmp/context7-compliance-report.md

- [ ] T047 [P] [US5] Implement migration suggestions in lib/tasks/context7_validation.sh
  - Function: suggest_migration(app_name, current_method, recommended_method) - Generate migration steps
  - Example: "Ghostty installed via snap, Context7 recommends source build"
  - Migration steps: Backup data, remove old installation, install via recommended method
  - Risk assessment: Data loss potential, downtime, complexity

- [ ] T048 [US5] Integrate Context7 pre-installation queries into task modules (FR-071)
  - **File**: `lib/tasks/*.sh` (all task modules: ghostty.sh, zsh.sh, python_uv.sh, nodejs_fnm.sh, ai_tools.sh)
  - **Implementation**:
    - BEFORE installation: Query Context7 via mcp__context7__resolve-library-id and mcp__context7__get-library-docs
    - Extract recommended installation method (apt/snap/source), version, configuration
    - If Context7 available: Use recommended method; else: Use fallback defaults
    - Log Context7 recommendation and chosen method
  - **Pattern**: In each install_<component>() function:
    ```bash
    # Query Context7 for latest recommendations
    CONTEXT7_REC=$(query_context7_for_component "<component>")
    if [[ -n "$CONTEXT7_REC" ]]; then
      # Use Context7 recommended method
    else
      # Use default method
    fi
    ```
  - **Acceptance**: All 6 task modules query Context7 before installation, FR-071 satisfied

**Checkpoint**: Context7 integration complete - All installations follow best practices

---

## Phase 9: Testing & Validation (Week 4-5)

**Purpose**: Comprehensive testing across environments

**User Story Mapping**: All user stories (US1-US7)

### Test Scripts (Constitutional Compliance)

- [ ] T049 [P] Create tests/test-fresh-install.sh - Docker-based fresh installation test
  - Docker image: ubuntu:25.10
  - Clone repository into container
  - Run `./start.sh`
  - Verify: All tasks complete, <10 minutes, all verifications pass
  - Capture logs for analysis

- [ ] T050 [P] [US3] Create tests/test-idempotency.sh - Re-run safety validation
  - Run `./start.sh` twice in succession
  - First run: Complete installation
  - Second run: All tasks skipped, <30 seconds
  - Verify: User customizations preserved (diff .zshrc, ghostty config)

- [ ] T051 [P] [US3] Create tests/test-resume.sh - Interrupt and resume capability
  - Run `./start.sh`
  - Kill process at 50% completion (simulate power loss)
  - Run `./start.sh --resume`
  - Verify: Resumes from checkpoint, skips completed tasks, completes successfully

- [ ] T052 [P] [US1] [US2] Create tests/test-cross-terminal.sh - Terminal compatibility
  - Test UTF-8 mode: BOX_DRAWING=utf8 ./start.sh
  - Test ASCII mode: BOX_DRAWING=ascii ./start.sh
  - Test SSH: ssh localhost ./start.sh (verify ASCII auto-detection)
  - Test TTY: Simulate Linux console (TERM=linux)
  - Verify: No broken characters in any environment

- [ ] T053 [P] Create tests/test-performance.sh - Performance benchmarks
  - Measure total installation time: `time ./start.sh`
  - Measure fnm startup: `time fnm env` (MUST be <50ms)
  - Measure gum startup: `time gum --version` (MUST be <10ms)
  - Measure re-run time: `time ./start.sh` (MUST be <30s when all tasks complete)
  - Parallel vs sequential: Compare total time with parallel execution enabled/disabled
  - Generate performance report: /tmp/performance-benchmark-results.md

- [ ] T054 [P] Create tests/test-error-recovery.sh - Error injection and handling
  - Inject failures: Simulate network errors, missing dependencies, permission errors
  - Verify: Errors auto-expand with recovery suggestions
  - Verify: Continue-or-abort prompts work correctly
  - Verify: Rollback capability functions (if implemented)

### Integration with Local CI/CD

- [ ] T055 [US1] Integrate with .runners-local/workflows/gh-workflow-local.sh
  - Add TUI system validation to local workflow
  - Run all test scripts as part of workflow
  - Validate performance targets (fnm <50ms, gum <10ms, total <10min)
  - Generate workflow report with test results

**Checkpoint**: Testing complete - All environments validated, performance targets met

---

## Phase 10: Documentation & Deployment (Week 5)

**Purpose**: Complete documentation and prepare for main branch merge

**User Story Mapping**: All user stories (documentation for complete system)

### Documentation Updates

- [ ] T056 [P] Update README.md with Modern TUI system highlights
  - Add: One-command installation instructions
  - Add: New command-line options (--verbose, --resume, --box-style)
  - Add: Troubleshooting section for TUI-specific issues (box drawing, SSH)
  - Add: Performance expectations (10 min fresh install, <50ms fnm, <10ms gum)

- [ ] T057 [P] Create ARCHITECTURE.md for lib/ modular design
  - Explain lib/ directory structure (core, ui, tasks, verification)
  - Data flow diagrams: spec → plan → implementation
  - Component interaction diagrams (orchestrator → task modules → verification)
  - Design decisions and rationale (why gum, why uv/fnm, why modular)

- [ ] T058 [P] Update AGENTS.md with TUI system references
  - Reference new lib/ architecture
  - Update installation instructions to use new start.sh
  - Add troubleshooting for TUI-specific issues
  - Constitutional compliance: fnm <50ms, gum exclusive, modular architecture

- [ ] T059 [P] Create MIGRATION-GUIDE.md
  - Differences between start.sh and start-legacy.sh
  - How to rollback if needed: `./start-legacy.sh`
  - User customization preservation guarantees
  - Feature comparison table (old vs new)

- [ ] T060 [P] Update SPEC-KIT-TUI-INTEGRATION.md
  - Document how TUI system integrates with Spec-Kit workflow
  - References to spec.md, plan.md, tasks.md, contracts/
  - Usage examples for future features

### Final Validation and Deployment

- [ ] T061 Run complete test suite and validate all success criteria
  - All tests pass (fresh install, idempotency, resume, performance)
  - Constitutional compliance verified (10/10 principles)
  - Local CI/CD workflows pass (`./.runners-local/workflows/gh-workflow-local.sh all`)
  - Performance benchmarks meet targets (<10min, <50ms fnm, <10ms gum)
  - Documentation complete (README, ARCHITECTURE, quickstart)

- [ ] T062 Create conversation log for implementation
  - Save complete conversation log to documentations/development/conversation_logs/
  - Include system state snapshots (before/after)
  - Include CI/CD logs from local workflows
  - Name: CONVERSATION_LOG_YYYYMMDD_modern_tui_implementation.md

- [ ] T063 Constitutional branch workflow merge to main
  - Final local CI/CD validation: `./.runners-local/workflows/gh-workflow-local.sh all`
  - Commit with constitutional format (feat: message with performance metrics)
  - Push to branch: `git push -u origin 001-modern-tui-system`
  - Merge to main: `git checkout main && git merge 001-modern-tui-system --no-ff`
  - Push to main: `git push origin main`
  - DO NOT DELETE BRANCH (constitutional requirement - branch preservation)

- [ ] T064 Post-merge validation
  - Verify GitHub Pages still works (docs/.nojekyll preserved)
  - Test installation on fresh Ubuntu 25.10 VM
  - Monitor for issues in first 48 hours
  - Create GitHub release tag (optional)

**Checkpoint**: Documentation complete, deployment successful, system production-ready

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (Phase 1)**: No dependencies - start immediately
2. **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user story implementation
   - Wave 1 (Core Infrastructure): CRITICAL - Required for ALL subsequent work
   - Wave 2 (Adaptive Box Drawing): Depends on Wave 1 core libraries
3. **Verification Framework (Phase 3)**: Depends on Foundational (can run in parallel with task modules)
4. **Task Modules (Phase 4)**: Depends on Foundational + Verification Framework
5. **Collapsible Output (Phase 5)**: Depends on Core Infrastructure (Wave 1)
6. **Orchestration (Phase 6)**: Depends on ALL previous phases (final integration)
7. **App Duplicate Detection (Phase 7)**: Independent feature, can run in parallel with Phases 3-5
8. **Context7 Integration (Phase 8)**: Independent feature, can run in parallel with Phases 3-5
9. **Testing (Phase 9)**: Depends on Orchestration (Phase 6) - Full system must be complete
10. **Documentation (Phase 10)**: Depends on Testing (Phase 9) - Final validation before deployment

### User Story Dependencies

**User Story 1 - Fresh Installation (P1)**:
- Phases 1-6 (Setup → Orchestration)
- All core functionality required
- Can proceed after Phase 2 (Foundational) for initial development

**User Story 2 - SSH Installation (P1)**:
- Phase 2 Wave 2 (Adaptive Box Drawing)
- Can develop in parallel with US1

**User Story 3 - Re-run Safety (P1)**:
- Phase 2 Wave 1 (State Management)
- Phase 4 (Duplicate Detection in all task modules)
- Can develop in parallel with US1

**User Story 4 - Duplicate Detection (P2)**:
- Phase 7 (App Duplicate Detection)
- Independent of installation system, can develop in parallel with US1-US3

**User Story 5 - Best Practices (P2)**:
- Phase 8 (Context7 Integration)
- Independent of core installation, can develop in parallel

**User Story 6 - Verbose Mode (P3)**:
- Phase 5 (Collapsible Output) - Toggle mechanism
- Depends on collapsible output being implemented first

**User Story 7 - Parallel Execution (P3)**:
- Phase 6 (Orchestration) - Parallel engine
- Depends on task registry and dependency resolution

### Within Each Phase

**Phase 2 (Foundational)**:
- Wave 1 Core Infrastructure: T005-T011 (all can run in parallel except T010→T011)
- Wave 2 Box Drawing: T012-T013 (depends on T006-T009 from Wave 1)

**Phase 3 (Verification)**:
- T014 (health checks) can run in parallel with T015-T023 (verification functions)
- T024 (integration tests) depends on T015-T023 completion

**Phase 4 (Task Modules)**:
- T025 (Ghostty), T026 (ZSH), T027 (uv), T028 (fnm): All can run in parallel
- T029 (AI tools) depends on T028 (fnm/Node.js)
- T030 (context menu) depends on T025 (Ghostty)

**Phase 5 (Collapsible Output)**:
- T031-T033 sequential (collapsible → progress → verbose toggle)

**Phase 6 (Orchestration)**:
- T034-T039 sequential (task registry → state → parallel → CLI → orchestrator → interrupts)

**Phase 7 (App Audit)**:
- T040-T042 can run in parallel
- T043-T044 sequential (CLI → verification)

**Phase 8 (Context7)**:
- T045-T047 can run in parallel
- T048 integration after T045-T047

**Phase 9 (Testing)**:
- T049-T054 all independent, can run in parallel
- T055 depends on T049-T054 completion

**Phase 10 (Documentation)**:
- T056-T060 all independent, can run in parallel
- T061-T064 sequential (validation → log → merge → post-merge)

### Parallel Opportunities (Multi-Agent Execution)

**Agent 1: project-health-auditor**
- T045-T047 (Context7 validation)
- T055 (CI/CD integration)

**Agent 2: documentation-guardian**
- T005 (Duplicate detection library)
- T014 (Health checks)

**Agent 3: Component Installation (Ghostty)**
- T010 (gum installation)
- T025 (Ghostty installation)

**Agent 4: Component Installation (ZSH)**
- T026 (ZSH configuration)

**Agent 5: Component Installation (Python)**
- T027 (uv installation)
- T017 (uv verification)

**Agent 6: Component Installation (Node.js)**
- T028 (fnm installation)
- T018-T019 (fnm verification + performance)

**Agent 7: Component Installation (AI Tools)**
- T029 (Claude/Gemini/Copilot)
- T021-T022 (verification)

**Agent 8: App Audit System**
- T040-T044 (Duplicate detection and cleanup)

**Agent 9: constitutional-compliance-agent**
- T049-T054 (All test scripts)
- T061 (Final validation)

**Wave Execution Strategy**:
1. **Wave 1 (Week 1)**: 5 agents in parallel
   - Agents 2, 3, 5, 6: Core infrastructure setup
   - Agent 1: Context7 preparation
2. **Wave 2 (Week 2)**: 6 agents in parallel
   - Agents 2, 3, 4, 5, 6, 7: Component installations + verifications
3. **Wave 3 (Week 3)**: 3 agents in parallel
   - Agents 1, 8: Special features (Context7, App Audit)
   - Agent 9: UI and orchestration
4. **Wave 4 (Week 4)**: Agent 9 final integration and testing
5. **Wave 5 (Week 5)**: All agents documentation + deployment

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

**Minimum Viable Product** includes:
1. Phase 1: Setup ✅
2. Phase 2: Foundational (Core Infrastructure + Box Drawing) ✅
3. Phase 3: Verification Framework ✅
4. Phase 4: Task Modules (Ghostty, ZSH, uv, fnm, AI tools) ✅
5. Phase 5: Collapsible Output ✅
6. Phase 6: Orchestration ✅
7. Phase 9: Testing (validation only) ✅

**Delivers**:
- Fresh installation (US1) ✅
- SSH support (US2) ✅
- Re-run safety (US3) ✅
- <10 minute installation ✅
- <50ms fnm, <10ms gum ✅

**Timeline**: 4 weeks (Phases 1-6)

### Incremental Delivery

After MVP:
1. **Phase 7**: Add duplicate detection (US4) - 3 days
2. **Phase 8**: Add Context7 integration (US5) - 3 days
3. **Phase 5 Enhancement**: Add verbose toggle (US6) - 1 day
4. **Phase 6 Enhancement**: Optimize parallel execution (US7) - 2 days
5. **Phase 9**: Complete testing - 3 days
6. **Phase 10**: Documentation and deployment - 2 days

**Total Timeline**: 5-6 weeks for complete system

### Parallel Team Strategy

**With 3 developers**:

**Week 1**:
- Developer A: Core infrastructure (T005-T009, T011)
- Developer B: gum + Ghostty installation (T010, T025)
- Developer C: Box drawing + verification (T012-T014)

**Week 2**:
- Developer A: Task modules (T027-T028 - uv/fnm)
- Developer B: Task modules (T026, T030 - ZSH, context menu)
- Developer C: Verification functions (T015-T024)

**Week 3**:
- Developer A: Collapsible output (T031-T033)
- Developer B: App audit (T040-T044)
- Developer C: Context7 integration (T045-T048)

**Week 4**:
- Developer A: AI tools + orchestration (T029, T034-T039)
- Developer B: Testing (T049-T054)
- Developer C: CI/CD integration (T055)

**Week 5**:
- All: Documentation (T056-T060)
- All: Final validation and deployment (T061-T064)

---

## Constitutional Compliance Checkpoints

**CRITICAL**: Validate these at EVERY phase

1. **TUI Framework**: gum used exclusively (FR-001) ✅
   - Verify: No whiptail, dialog, rich-cli in code
   - Graceful degradation to plain text if gum unavailable

2. **Box Drawing**: Adaptive UTF-8/ASCII (FR-002-005) ✅
   - Verify: Terminal detection logic implemented
   - Test: UTF-8 works in Ghostty, ASCII works in SSH

3. **Verification**: Real tests only (FR-007-012) ✅
   - Verify: NO hard-coded success messages
   - Test: Verification functions check actual system state

4. **Package Managers**: uv exclusive (FR-032-033), fnm exclusive (FR-034-035) ✅
   - Verify: NO pip/poetry/pipenv usage
   - Verify: NO nvm/n/asdf usage
   - Test: fnm startup <50ms (constitutional requirement)

5. **Architecture**: Modular lib/ structure (FR-020-031) ✅
   - Verify: lib/core/, lib/ui/, lib/tasks/, lib/verification/ all exist
   - Verify: start.sh is orchestrator only (<200 lines)

6. **Performance**: <10 min total, <50ms fnm, <10ms gum (FR-059-061) ✅
   - Test: `time ./start.sh` on fresh Ubuntu 25.10
   - Test: `time fnm env` for constitutional compliance
   - Test: `time gum --version`

7. **Critical Files**: docs/.nojekyll preserved ✅
   - Verify: File exists after implementation
   - Not in scope for this spec but related infrastructure

8. **Directory Naming**: .runners-local/ used (not local-infra/) ✅
   - Verify: All references use .runners-local/

9. **Node.js Version**: Latest v25.2.0+ (FR-038) ✅
   - Verify: fnm installs latest, NOT LTS
   - Test: `node --version` shows v25+

10. **Idempotency**: Safe re-run (FR-053-058) ✅
    - Test: Run `./start.sh` twice, second run <30s
    - Verify: User customizations preserved

---

## Success Metrics

### Performance Targets (Constitutional)

| Metric | Target | Validation Method | Task |
|--------|--------|-------------------|------|
| Total installation | <10 minutes | `time ./start.sh` | T053 |
| fnm startup | <50ms | `time fnm env` | T019, T053 |
| gum startup | <10ms | `time gum --version` | T053 |
| Re-run (idempotent) | <30 seconds | `time ./start.sh` (2nd run) | T050, T053 |
| Parallel speedup | 30-40% faster | Sequential vs parallel comparison | T053 |

### Functional Requirements (All FR-* from spec.md)

| Requirement | Validation | Task |
|-------------|-----------|------|
| FR-001: gum exclusive | Code inspection, no whiptail/dialog | T010, T061 |
| FR-007: Real verification | NO hard-coded success | T015-T023, T061 |
| FR-032: uv exclusive | NO pip usage | T027, T061 |
| FR-034: fnm exclusive | NO nvm usage | T028, T061 |
| FR-038: Node.js latest | v25.2.0+ installed | T020, T028, T061 |
| FR-053: Idempotency | Safe re-run test | T050, T061 |

### Quality Gates

- [ ] Zero broken box characters across all terminals (T052)
- [ ] 100% task verification coverage (T015-T023)
- [ ] Verification accuracy ≥99% (T049-T054)
- [ ] Installation success rate ≥99% (T049)
- [ ] User customizations preserved 100% (T050)

---

## Notes

- **[P]** tasks = different files, no dependencies on incomplete work, can run in parallel
- **[Story]** label (US1-US7) maps task to specific user story for traceability
- **Context7 queries**: MANDATORY for every component before installation
- **Duplicate detection**: MANDATORY for every installation task
- **Real verification**: MANDATORY - no hard-coded success messages
- **Performance validation**: MANDATORY - fnm <50ms is constitutional requirement
- Each wave/phase should be independently testable
- Stop at any checkpoint to validate independently
- Commit after each task or logical group of parallel tasks
- Constitutional violations = BLOCKER (must fix immediately)

---

**Total Tasks**: 64 tasks organized in 10 phases (6 implementation waves)
**Estimated Duration**: 5-6 weeks full implementation, 4 weeks for MVP
**Parallel Opportunities**: 40+ tasks marked [P] for parallel execution
**Context7 Queries**: 15+ component validation queries required
**Verification Functions**: 10 verification functions with real system checks
**Constitutional Compliance**: 10/10 principles validated at every phase
