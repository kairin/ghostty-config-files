# Implementation Plan: Modern TUI Installation System

**Branch**: `001-modern-tui-system` | **Date**: 2025-11-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-modern-tui-system/spec.md`

## Summary

Implement a professional, robust TUI installation system using gum framework (Charm Bracelet) with adaptive UTF-8/ASCII box drawing, real verification tests for all components, Docker-like collapsible output, exclusive uv (Python) and fnm (Node.js) package management, modular lib/ architecture, state persistence for resume capability, and comprehensive error handling with recovery suggestions. Delivers <10 minute fresh installation, <50ms fnm startup, zero broken characters across all terminals (SSH, legacy, modern), and 100% idempotent operations.

## Technical Context

**Language/Version**: Bash 5.x+ (shell scripting for installation system)
**Primary Dependencies**: 
- gum (Charm Bracelet TUI framework) v0.14.3+ - single binary, <10ms startup
- uv (Astral Python package manager) latest - 10-100x faster than pip
- fnm (Fast Node Manager) latest - <50ms startup (constitutional requirement)
- jq (JSON processing) for state management
- bc (calculations) for duration tracking

**Storage**: 
- JSON state files for installation tracking (`/tmp/ghostty-start-logs/installation-state.json`)
- Dual-format logging: structured JSON + human-readable text
- State persistence for resume capability after interruption

**Testing**:
- Bash unit tests for verification functions (`lib/verification/unit_tests.sh`)
- Integration tests for cross-component validation (`lib/verification/integration_tests.sh`)
- Health checks pre/post installation (`lib/verification/health_checks.sh`)
- Real system state verification (no hard-coded success messages)

**Target Platform**: Ubuntu 25.10+ (Questing) - fresh installations and existing systems
**Project Type**: Single-project shell infrastructure (installation orchestrator)

**Performance Goals**:
- Total installation time: <10 minutes on fresh Ubuntu system
- fnm startup time: <50ms (constitutional requirement - AGENTS.md line 55-57)
- gum startup time: <10ms (verified during installation)
- Re-run (idempotency): <30 seconds with all tasks skipped
- Display updates: ≤5 seconds for long-running tasks

**Constraints**:
- Idempotent operations (safe to re-run without side effects)
- Resume capability (interrupt-safe, state persistence)
- SSH-compatible (ASCII fallback for box drawing)
- Passwordless sudo recommended (but not required)
- Zero GitHub Actions consumption (all CI/CD runs locally first)
- Preserve user customizations during updates

**Scale/Scope**:
- 10-15 installation tasks (Ghostty, ZSH, Python/uv, Node.js/fnm, AI tools, etc.)
- Modular lib/ architecture (core, ui, tasks, verification)
- 100% verification coverage (every task has real verification function)
- Multi-layer testing (unit, integration, health checks)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: TUI Framework Standard ✅ COMPLIANT
- **Requirement**: gum (Charm Bracelet) exclusive for all TUI operations
- **Implementation**: gum used for spinners, progress bars, prompts, styling
- **Fallback**: Graceful degradation to plain text if gum unavailable
- **Status**: spec.md FR-001 mandates gum exclusive usage

### Principle II: Adaptive Box Drawing ✅ COMPLIANT
- **Requirement**: UTF-8/ASCII detection with automatic fallback
- **Implementation**: Terminal capability detection via TERM + LANG environment variables
- **Manual Override**: BOX_DRAWING=ascii/utf8 environment variable
- **Status**: spec.md FR-002-FR-005 define adaptive box drawing requirements

### Principle III: Real Verification Tests ✅ COMPLIANT
- **Requirement**: No hard-coded success messages, real system state checks
- **Implementation**: Every installation task has corresponding `verify_<component>()` function
- **Multi-layer**: Unit tests (per-component), integration tests (cross-component), health checks (pre/post)
- **Status**: spec.md FR-007-FR-012 mandate real verification functions

### Principle IV: Docker-Like Collapsible Output ✅ COMPLIANT
- **Requirement**: Progressive summarization (completed tasks collapse to single lines)
- **Implementation**: Active task shows full output with spinner, completed tasks show `✓ Task name (duration)`
- **Verbose Mode**: Press 'v' or --verbose flag to expand all output
- **Status**: spec.md FR-013-FR-019 define progressive summarization

### Principle V: Modular lib/ Architecture ✅ COMPLIANT
- **Requirement**: No monolithic scripts, modular library structure
- **Implementation**: lib/core/, lib/ui/, lib/tasks/, lib/verification/ separation
- **Benefits**: Independent testing, single responsibility, clear interfaces
- **Status**: spec.md FR-020-FR-031 define modular architecture

### Principle VI: Package Manager Exclusivity ✅ COMPLIANT
- **Python**: uv exclusively (spec.md FR-032-FR-033 prohibit pip/poetry/pipenv)
- **Node.js**: fnm exclusively (spec.md FR-034-FR-035 prohibit nvm/n/asdf)
- **Constitutional**: AGENTS.md line 55-57 mandate fnm <50ms startup
- **Status**: Complete compliance with package manager requirements

### Principle VII: Structured Logging ✅ COMPLIANT
- **Requirement**: Dual-format logging (JSON + human-readable)
- **Implementation**: /tmp/ghostty-start-logs/*.log and *.log.json
- **Rotation**: Keep last 10 installations
- **Status**: spec.md FR-039-FR-046 define logging requirements

### Principle VIII: Error Handling & Recovery ✅ COMPLIANT
- **Requirement**: Clear recovery suggestions, not just failure messages
- **Implementation**: Errors include what failed, why, how to fix
- **Recovery**: Continue-or-abort options, rollback capability
- **Status**: spec.md FR-047-FR-052 define error handling

### Principle IX: Idempotency ✅ COMPLIANT
- **Requirement**: Safe to re-run without side effects
- **Implementation**: Check existing state, skip completed tasks, preserve customizations
- **Resume**: State persistence for interrupted installations
- **Status**: spec.md FR-053-FR-058 define idempotency

### Principle X: Performance Standards ✅ COMPLIANT
- **Total time**: <10 minutes fresh installation (spec.md FR-059)
- **fnm startup**: <50ms (spec.md FR-060, AGENTS.md constitutional requirement)
- **gum startup**: <10ms (spec.md FR-061)
- **Parallel**: Independent tasks execute in parallel (spec.md FR-062-063)

### Critical File Preservation ✅ COMPLIANT
- **docs/.nojekyll**: MUST NEVER delete (CRITICAL for GitHub Pages - not in this spec scope)
- **.runners-local/**: Current CI/CD infrastructure directory (not local-infra/)
- **Directory naming**: Verified .runners-local/ used correctly

### Technology Stack Compliance ✅ COMPLIANT
- **TUI Framework**: gum (NOT whiptail/dialog/rich-cli) ✅
- **Python**: uv exclusive (NOT pip/poetry/pipenv) ✅
- **Node.js**: fnm exclusive (NOT nvm/n/asdf) ✅
- **Node.js Version**: Latest v25.2.0+ (NOT LTS/18+) ✅
- **Component Library**: N/A for this spec (website uses DaisyUI) ✅

**CONSTITUTIONAL COMPLIANCE: 10/10 PASSED** ✅

No constitutional violations. No complexity justification required.

## Project Structure

### Documentation (this feature)

```text
specs/001-modern-tui-system/
├── plan.md              # This file (/speckit.plan output)
├── spec.md              # Feature specification (already exists)
├── research.md          # Phase 0 output (gum, collapsible, box drawing, verification, package managers)
├── data-model.md        # Phase 1 output (installation state, task model, verification model)
├── quickstart.md        # Phase 1 output (user guide for new TUI system)
└── contracts/           # Phase 1 output (interface definitions)
    ├── cli-interface.yaml              # start.sh command-line interface
    ├── verification-interface.yaml     # verify_*() function contracts
    ├── tui-interface.yaml              # TUI component contracts
    ├── task-interface.yaml             # Installation task contracts
    └── state-interface.yaml            # State persistence contracts
```

### Source Code (repository root)

This feature implements a modular shell-based installation system following the lib/ architecture pattern:

```text
/home/kkk/Apps/ghostty-config-files/
├── start.sh                          # Main entry point (orchestrator) - REFACTORED
│
├── lib/                              # Reusable library functions (NEW)
│   ├── core/                         # Core functionality
│   │   ├── logging.sh                # Dual-format logging (JSON + human-readable)
│   │   ├── state.sh                  # State management (resume capability)
│   │   ├── errors.sh                 # Error handling with recovery suggestions
│   │   └── utils.sh                  # Utility functions (get_visual_width, etc.)
│   │
│   ├── ui/                           # UI components
│   │   ├── tui.sh                    # gum integration and initialization
│   │   ├── boxes.sh                  # Adaptive box drawing (UTF-8/ASCII)
│   │   ├── collapsible.sh            # Progressive summarization (Docker-like)
│   │   └── progress.sh               # Progress bars and spinners
│   │
│   ├── tasks/                        # Installation tasks (one file per component)
│   │   ├── ghostty.sh                # Ghostty installation + configuration
│   │   ├── zsh.sh                    # ZSH + Oh My ZSH setup
│   │   ├── python_uv.sh              # Python + uv installation
│   │   ├── nodejs_fnm.sh             # Node.js + fnm installation
│   │   ├── ai_tools.sh               # Claude/Gemini/Copilot CLI
│   │   └── context_menu.sh           # Nautilus "Open in Ghostty"
│   │
│   └── verification/                 # Verification tests (real system checks)
│       ├── unit_tests.sh             # Per-component verification functions
│       ├── integration_tests.sh      # Cross-component validation
│       └── health_checks.sh          # Pre/post installation health checks
│
├── .runners-local/                   # Local CI/CD infrastructure (EXISTING)
│   └── workflows/                    # Local workflow scripts
│       ├── gh-workflow-local.sh      # Local GitHub Actions simulation
│       └── performance-monitor.sh    # Performance benchmarks
│
├── configs/                          # Configuration files (EXISTING)
│   └── ghostty/                      # Ghostty configurations
│
└── logs/ or /tmp/ghostty-start-logs/ # Log output (GITIGNORED)
    ├── start-TIMESTAMP.log           # Human-readable log
    ├── start-TIMESTAMP.log.json      # Structured JSON log
    ├── errors.log                    # Critical errors only
    ├── performance.json              # Performance metrics
    ├── system_state_TIMESTAMP.json   # System state snapshots
    └── installation-state.json       # Resume state (task completion tracking)
```

**Structure Decision**: **Single-project** architecture selected

**Rationale**: Installation system is a single cohesive orchestrator with modular library functions. Not a multi-project application, not web/mobile, but rather a shell-based utility with clear separation of concerns via lib/ directories. This matches constitutional Principle V (Modular lib/ Architecture) and enables independent testing of each component.

**Key Principles**:
- **Single Responsibility**: Each lib/ module has one clear purpose
- **Independent Testing**: lib/verification/ can test lib/tasks/ in isolation
- **Clear Interfaces**: contracts/ define expected behavior for each module
- **Maintainability**: Easy to add new tasks, verification functions, or UI components

## Phase 0: Research

**Objective**: Gather technical foundation for gum framework, collapsible output patterns, adaptive box drawing, real verification tests, and package manager integration.

**Research Topics**:
1. **gum (Charm Bracelet) Framework**
   - Installation methods (apt repository, binary download)
   - API for spinners, progress bars, prompts, styling
   - UTF-8/ASCII adaptation mechanisms
   - Performance characteristics (<10ms startup)
   - Integration patterns with bash scripts

2. **Adaptive Box Drawing Techniques**
   - Terminal capability detection (TERM, LANG, SSH_CONNECTION)
   - UTF-8 character sets (light, heavy, double-line)
   - ASCII fallback patterns (+, -, |)
   - Visual width calculation (ANSI escape sequence stripping)
   - Hybrid approaches (gum + custom bash)

3. **Collapsible Output Patterns (Docker-like UX)**
   - Progressive summarization (active task expands, completed collapse)
   - ANSI cursor management for in-place updates
   - Task status tracking (pending, running, success, failed)
   - Duration tracking and time estimation
   - Verbose mode toggle mechanisms

4. **State Persistence for Resume Capability**
   - JSON state file structure (completed tasks, failed tasks, system info)
   - Checkpoint creation and restoration
   - Idempotency detection (skip completed tasks)
   - Interrupt handling (trap SIGINT, SIGTERM)

5. **Parallel Task Execution Patterns**
   - Dependency resolution (topological sort)
   - Background job management (PIDs, wait)
   - Error aggregation from parallel tasks
   - Progress display for concurrent operations

6. **Real Verification Test Design**
   - Multi-layer verification (unit, integration, health)
   - System state checking (command existence, version, functionality)
   - Error diagnostics (what failed, why, how to fix)
   - Performance validation (fnm <50ms, gum <10ms)

7. **uv (Python) and fnm (Node.js) Integration**
   - Installation methods and verification
   - Shell integration (PATH, environment variables)
   - Constitutional compliance (fnm <50ms, latest Node.js)
   - Migration from pip/nvm

**Output**: `research.md` document with:
- gum framework best practices and API reference
- Adaptive box drawing implementation guide
- Collapsible output design patterns
- State persistence architecture
- Parallel execution strategies
- Verification test framework design
- Package manager integration guide

**Success Criteria**:
- All 7 research topics documented with code examples
- Performance benchmarks gathered (gum startup, fnm startup)
- Terminal compatibility matrix completed
- Implementation patterns validated with proof-of-concept code

**Timeline**: Already completed (reference documents in /tmp/)

## Phase 1: Design

**Objective**: Define data models, API contracts, and quick-start user guide.

### 1.1 Data Model Design

**Output**: `data-model.md`

**Core Entities**:

1. **Installation Task**
   - Properties: id, name, description, verify_function, dependencies[], estimated_duration, status, actual_duration, error_message
   - States: pending, running, success, failed, skipped
   - Lifecycle: define → validate dependencies → execute → verify → mark complete/failed

2. **System State Snapshot**
   - Properties: timestamp, hostname, os_info{name,version,kernel,architecture}, installed_packages{}, disk_usage, memory_usage, active_services[]
   - Usage: Captured before/after installation for debugging
   - Storage: `/tmp/ghostty-start-logs/system_state_TIMESTAMP.json`

3. **Verification Result**
   - Properties: task_name, verify_function, exit_code, stdout, stderr, duration, timestamp, success
   - Multi-layer: unit_test_result{}, integration_test_result{}, health_check_result{}
   - Error Diagnostics: what_failed, why_failed, how_to_fix

4. **Installation State (Resume)**
   - Properties: version, last_run, completed_tasks[], failed_tasks[], system_info{}
   - Persistence: JSON file for interrupt recovery
   - Idempotency: Skip tasks in completed_tasks[] on re-run

5. **Performance Metrics**
   - Properties: task_name, start_time, end_time, duration, cpu_usage, memory_usage, disk_io
   - Aggregation: Total time, per-task breakdown, bottleneck identification
   - Validation: fnm <50ms, gum <10ms, total <10min

**Success Criteria**:
- Complete entity-relationship diagram
- JSON schema for each entity
- State transition diagrams for task lifecycle
- Example data instances for testing

### 1.2 Contract Definitions

**Output**: `contracts/` directory with YAML interface definitions

**Files Created**:

1. **cli-interface.yaml** - start.sh command-line interface
   ```yaml
   name: start.sh
   description: Main installation orchestrator
   options:
     - name: --help
       description: Show usage information
     - name: --verbose
       description: Show expanded output (no collapsing)
     - name: --force-all
       description: Reinstall all components
     - name: --resume
       description: Resume interrupted installation
     - name: --skip-checks
       description: Skip pre-installation health checks
     - name: --box-style <ascii|utf8|utf8-double>
       description: Force box drawing style
   ```

2. **verification-interface.yaml** - verify_*() function contracts
   ```yaml
   function_pattern: verify_<component>()
   requirements:
     - Returns 0 on success, 1 on failure
     - Checks actual system state (NOT hard-coded)
     - Logs via log() function (TEST, SUCCESS, ERROR levels)
     - Includes diagnostic output on failure
   examples:
     - verify_ghostty_installed
     - verify_zsh_configured
     - verify_nodejs_fnm
   ```

3. **tui-interface.yaml** - TUI component contracts
   ```yaml
   gum_integration:
     - gum spin: Spinners for long-running tasks
     - gum style: Box drawing and styling
     - gum confirm: User confirmations
   box_drawing:
     - init_box_drawing(): Terminal capability detection
     - draw_box(title, content[]): Adaptive box rendering
   collapsible:
     - render_task(id, name, status): Single task display
     - update_display(): Full display refresh
   ```

4. **task-interface.yaml** - Installation task contracts
   ```yaml
   task_definition:
     id: Unique task identifier
     name: Human-readable name
     install_function: task_install_<component>()
     verify_function: verify_<component>()
     dependencies: [prerequisite_task_ids]
     estimated_duration: Expected seconds
   execution_pattern:
     1. Check if already completed (state file)
     2. Execute dependencies first
     3. Run install_function
     4. Run verify_function
     5. Mark complete or failed in state
   ```

5. **state-interface.yaml** - State persistence contracts
   ```yaml
   state_file: /tmp/ghostty-start-logs/installation-state.json
   operations:
     - is_task_completed(task_id): Check completion
     - mark_task_completed(task_id): Mark success
     - mark_task_failed(task_id, error): Mark failure
     - load_state(): Read from JSON
     - save_state(): Write to JSON
   structure:
     version: "2.0"
     last_run: ISO8601 timestamp
     completed_tasks: [task_ids]
     failed_tasks: [{task_id, error_message}]
     system_info: {os, kernel, architecture}
   ```

**Success Criteria**:
- All 5 contract files created
- Interfaces define clear input/output expectations
- Examples provided for each contract type
- Validation rules specified

### 1.3 Quick Start Guide

**Output**: `quickstart.md`

**Sections**:
1. **One-Command Installation**
   ```bash
   cd /home/kkk/Apps/ghostty-config-files
   ./start.sh
   ```

2. **What to Expect**
   - Progress display (Docker-like collapsible output)
   - Time estimates (installation takes <10 minutes)
   - Automatic verification (real system checks)

3. **Common Options**
   ```bash
   ./start.sh --verbose         # Full output (no collapsing)
   ./start.sh --resume          # Resume interrupted installation
   ./start.sh --box-style ascii # Force ASCII boxes for SSH
   ```

4. **Troubleshooting**
   - Box drawing broken? Use `--box-style ascii`
   - Installation interrupted? Use `--resume`
   - Verification failed? Check logs in `/tmp/ghostty-start-logs/`

5. **Performance Expectations**
   - Total time: <10 minutes on fresh Ubuntu
   - Re-run (idempotency): <30 seconds (all tasks skipped)
   - fnm startup: <50ms (constitutional requirement)

**Success Criteria**:
- Clear step-by-step instructions
- Common issues documented with solutions
- Performance expectations set
- User-friendly formatting

**Timeline**: Phase 1 completion = All data models, contracts, and quickstart documented

## Phase 2: Implementation Waves

### Wave 1: Core Infrastructure (Week 1)

**Objective**: Establish foundation - gum installation, terminal detection, basic lib/ structure

**Tasks**:
1. Install gum as prerequisite (binary download + apt repository)
2. Implement `lib/core/logging.sh` (dual-format: JSON + human-readable)
3. Implement `lib/core/state.sh` (JSON state persistence)
4. Implement `lib/core/errors.sh` (error handling with recovery suggestions)
5. Implement `lib/core/utils.sh` (get_visual_width, duration calculations)
6. Implement `lib/ui/tui.sh` (gum integration wrapper)

**Deliverables**:
- gum installed and verified (<10ms startup)
- lib/core/*.sh modules with comprehensive logging
- Test script: `tests/test-core-infrastructure.sh`

**Validation**:
```bash
# Test gum installation
command -v gum && time gum --version  # <10ms

# Test logging
source lib/core/logging.sh
log "TEST" "Test message"  # Outputs to console + JSON log

# Test state management
source lib/core/state.sh
mark_task_completed "test-task"
is_task_completed "test-task" && echo "SUCCESS"
```

**Success Criteria**:
- gum startup <10ms verified
- Logging produces valid JSON and human-readable output
- State persistence survives script restart

### Wave 2: Adaptive Box Drawing (Week 1)

**Objective**: Implement UTF-8/ASCII adaptive box drawing with terminal detection

**Tasks**:
1. Implement `lib/ui/boxes.sh` - Adaptive box character selection
2. Implement terminal capability detection (TERM, LANG, SSH_CONNECTION)
3. Implement `draw_box()` function with gum fallback
4. Implement `get_visual_width()` with proper ANSI stripping
5. Add manual override via BOX_DRAWING environment variable

**Deliverables**:
- lib/ui/boxes.sh with UTF-8 and ASCII character sets
- Terminal detection logic (UTF-8 vs ASCII)
- Test script: `tests/test-box-drawing.sh`

**Validation**:
```bash
# Test UTF-8 mode
BOX_DRAWING=utf8 ./tests/test-box-drawing.sh
# Should show: ╔═══...═══╗

# Test ASCII mode
BOX_DRAWING=ascii ./tests/test-box-drawing.sh
# Should show: +---...---+

# Test automatic detection
./tests/test-box-drawing.sh
# Should auto-detect based on TERM/LANG

# Test SSH compatibility
ssh localhost ./tests/test-box-drawing.sh
# Should use ASCII automatically
```

**Success Criteria**:
- Zero broken characters in Ghostty, xterm, SSH, TTY
- Automatic detection works correctly
- Manual override functions properly

### Wave 3: Verification Framework (Week 2)

**Objective**: Implement real verification tests for all components (no hard-coded success)

**Tasks**:
1. Implement `lib/verification/unit_tests.sh` - Per-component verification
   - verify_ghostty_installed()
   - verify_zsh_configured()
   - verify_nodejs_fnm()
   - verify_python_uv()
   - verify_claude_cli()
   - verify_gemini_cli()
2. Implement `lib/verification/integration_tests.sh` - Cross-component validation
3. Implement `lib/verification/health_checks.sh` - Pre/post health checks

**Deliverables**:
- 6+ verification functions with real system checks
- Integration test suite
- Health check system (passwordless sudo, disk space, network)

**Validation**:
```bash
# Test individual verification functions
source lib/verification/unit_tests.sh
verify_ghostty_installed && echo "Ghostty OK"
verify_zsh_configured && echo "ZSH OK"

# Test health checks
source lib/verification/health_checks.sh
pre_installation_health_check || echo "Prerequisites missing"
```

**Success Criteria**:
- 100% of verification functions check actual system state
- Verification accuracy ≥99% (no false positives/negatives)
- Error diagnostics include what failed, why, how to fix

### Wave 4: Task Modules (Week 2-3)

**Objective**: Create modular installation task files

**Tasks**:
1. Implement `lib/tasks/ghostty.sh` - Ghostty installation + configuration
2. Implement `lib/tasks/zsh.sh` - ZSH + Oh My ZSH setup
3. Implement `lib/tasks/python_uv.sh` - Python + uv installation
4. Implement `lib/tasks/nodejs_fnm.sh` - Node.js + fnm installation (latest v25.2.0+)
5. Implement `lib/tasks/ai_tools.sh` - Claude/Gemini/Copilot CLI
6. Implement `lib/tasks/context_menu.sh` - Nautilus integration

**Deliverables**:
- 6 task modules with install + verify functions
- Each module follows task-interface.yaml contract
- Task dependency definitions

**Validation**:
```bash
# Test individual task modules
source lib/tasks/python_uv.sh
task_install_uv && verify_uv || echo "uv installation failed"

source lib/tasks/nodejs_fnm.sh
task_install_fnm && verify_fnm || echo "fnm installation failed"

# Verify performance requirements
time fnm env  # Must be <50ms (constitutional requirement)
```

**Success Criteria**:
- All 6 task modules implement required functions
- Verification functions return accurate status
- fnm startup time <50ms validated

### Wave 5: Collapsible Output & Progress (Week 3)

**Objective**: Implement Docker-like progressive summarization

**Tasks**:
1. Implement `lib/ui/collapsible.sh` - Task status tracking and rendering
2. Implement `lib/ui/progress.sh` - Progress bars and spinners
3. Implement `render_task()` - Single task display
4. Implement `update_display()` - Full display refresh with ANSI cursor management
5. Add verbose mode toggle ('v' key or --verbose flag)

**Deliverables**:
- lib/ui/collapsible.sh with Docker-like output
- lib/ui/progress.sh with gum integration
- Keyboard interaction for verbose toggle

**Validation**:
```bash
# Test collapsible output
./start.sh
# Should show:
# ✓ Task 1 (2.1s)
# ✓ Task 2 (3.4s)
# ⠋ Task 3 (running)
# ⏸ Task 4 (queued)

# Test verbose mode
./start.sh --verbose
# All tasks expanded, no collapsing
```

**Success Criteria**:
- Completed tasks collapse to single line
- Active task shows full output with spinner
- Errors auto-expand with recovery suggestions
- Progress updates every ≤5 seconds

### Wave 6: Orchestration & Integration (Week 4)

**Objective**: Refactor start.sh to use modular lib/ architecture

**Tasks**:
1. Backup current start.sh to start-legacy.sh
2. Create new start.sh orchestrator (minimal, loads lib/ modules)
3. Implement task registry with dependency resolution
4. Implement parallel task execution (independent tasks)
5. Integrate all lib/ modules (core, ui, tasks, verification)
6. Add command-line argument parsing (--help, --verbose, --resume, etc.)

**Deliverables**:
- New modular start.sh (<200 lines, orchestrator only)
- start-legacy.sh (backup of original)
- Task registry with topological sort for dependencies
- Parallel execution for independent tasks

**Validation**:
```bash
# Test new modular start.sh
./start.sh --help
# Should show comprehensive usage

# Test dry-run
./start.sh --skip-checks --verbose
# Should load all modules without errors

# Test full installation (Docker)
docker run -it ubuntu:25.10 /bin/bash -c "
    git clone https://github.com/user/ghostty-config-files.git
    cd ghostty-config-files
    git checkout 001-modern-tui-system
    ./start.sh
"
```

**Success Criteria**:
- start.sh loads all lib/ modules successfully
- Task dependencies resolved correctly (topological sort)
- Parallel execution reduces time by 30-40%
- Total installation time <10 minutes

## Phase 3: Testing & Validation

**Objective**: Comprehensive testing across environments and edge cases

### Testing Matrix

| Test | Environment | Expected Outcome | Validation Method |
|------|------------|------------------|-------------------|
| Fresh Install | Ubuntu 25.10 (clean VM) | All components installed, verified | `./start.sh` succeeds, all verify_*() pass |
| Idempotency | After fresh install | All tasks skipped, <30s completion | `./start.sh` detects existing installations |
| Resume | Interrupted install | Resume from checkpoint | Kill mid-install, `./start.sh --resume` continues |
| Box Drawing | Ghostty, xterm, SSH | Proper rendering everywhere | Visual inspection, no broken chars |
| Performance | Fresh system | <10min total, fnm <50ms, gum <10ms | `time ./start.sh`, `time fnm env` |
| Parallel Tasks | uv + fnm install | Both complete successfully | Logs show concurrent execution |
| Error Recovery | Simulated failure | Recovery options offered | Inject failure, verify error handling |
| SSH Install | SSH connection | ASCII box drawing, full functionality | `ssh user@host ./start.sh` |

### Test Scripts

**Created**:
1. `tests/test-fresh-install.sh` - Docker-based fresh installation
2. `tests/test-idempotency.sh` - Re-run safety validation
3. `tests/test-resume.sh` - Interrupt and resume capability
4. `tests/test-cross-terminal.sh` - Terminal compatibility matrix
5. `tests/test-performance.sh` - Performance benchmarks
6. `tests/test-error-recovery.sh` - Error injection and recovery

**Validation Commands**:
```bash
# Run complete test suite
for test in tests/test-*.sh; do
    echo "Running $test..."
    "$test" || echo "FAILED: $test"
done

# Performance benchmarks
tests/test-performance.sh
# Expected output:
# - Total installation: <10 minutes ✓
# - fnm startup: <50ms ✓
# - gum startup: <10ms ✓
# - Idempotent re-run: <30s ✓
```

### Success Criteria

**Functional**:
- ✅ Installation success rate ≥99% across tested configurations
- ✅ Verification accuracy ≥99% (no false positives/negatives)
- ✅ Zero broken box characters in all terminals
- ✅ 100% task verification coverage (no hard-coded success)

**Performance**:
- ✅ Total installation time <10 minutes (fresh Ubuntu 25.10)
- ✅ fnm startup time <50ms (constitutional requirement)
- ✅ gum startup time <10ms
- ✅ Re-run (idempotent) <30 seconds
- ✅ Parallel execution 30-40% faster than sequential

**Quality**:
- ✅ Idempotency: Safe to re-run, all tasks skipped when complete
- ✅ Resume: Interrupted install can resume from checkpoint
- ✅ Error recovery: Clear suggestions for all failure modes
- ✅ User customizations preserved during updates
- ✅ Logs capture full system state for debugging

## Phase 4: Documentation & Deployment

**Objective**: Complete documentation and prepare for main branch merge

### Documentation Tasks

1. **Update README.md**
   - Modern TUI system highlights
   - One-command installation instructions
   - New command-line options (--verbose, --resume, --box-style)
   - Troubleshooting guide (box drawing, SSH, verification failures)

2. **Create ARCHITECTURE.md**
   - lib/ modular architecture explanation
   - Data flow diagrams (spec → plan → implementation)
   - Component interaction diagrams
   - Design decisions and rationale

3. **Update AGENTS.md**
   - Reference new TUI system
   - Update installation instructions
   - Add troubleshooting for TUI-specific issues

4. **Create Migration Guide**
   - Differences between start.sh and start-legacy.sh
   - How to rollback if needed
   - User customization preservation

### Deployment Checklist

**Pre-Merge**:
- [ ] All tests pass (fresh install, idempotency, resume, performance)
- [ ] Constitutional compliance verified (10/10 principles)
- [ ] Local CI/CD workflows pass (`./.runners-local/workflows/gh-workflow-local.sh all`)
- [ ] Performance benchmarks meet targets (<10min, <50ms fnm, <10ms gum)
- [ ] Documentation complete (README, ARCHITECTURE, quickstart)

**Merge Workflow** (Constitutional Branch Strategy):
```bash
# Create timestamped branch (already created: 001-modern-tui-system)
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-modern-tui-system"

# Ensure on correct branch
git checkout 001-modern-tui-system

# Final local CI/CD validation
./.runners-local/workflows/gh-workflow-local.sh all

# Commit final changes
git add .
git commit -m "feat: Implement Modern TUI Installation System

- Add gum (Charm Bracelet) TUI framework with <10ms startup
- Implement adaptive box drawing (UTF-8/ASCII fallback) for all terminals
- Add real verification tests (no hard-coded success messages)
- Create modular lib/ architecture (core, ui, tasks, verification)
- Implement Docker-like collapsible output (progressive summarization)
- Integrate uv (Python) and fnm (Node.js) package managers
- Add state management for resume capability
- Implement parallel task execution (30-40% faster)
- Comprehensive error handling with recovery suggestions

Performance:
- Total installation: <10 minutes (constitutional compliance)
- fnm startup: <50ms (constitutional requirement - AGENTS.md)
- gum startup: <10ms
- Idempotent re-run: <30 seconds

Constitutional Compliance: 10/10 principles
- Principle I: gum exclusive ✓
- Principle II: Adaptive box drawing ✓
- Principle III: Real verification tests ✓
- Principle IV: Docker-like collapsible output ✓
- Principle V: Modular lib/ architecture ✓
- Principle VI: uv/fnm exclusive ✓
- Principle VII: Structured logging ✓
- Principle VIII: Error recovery ✓
- Principle IX: Idempotency ✓
- Principle X: Performance standards ✓

Refs: specs/001-modern-tui-system/spec.md

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push -u origin 001-modern-tui-system

# Merge to main (branch preservation)
git checkout main
git merge 001-modern-tui-system --no-ff --no-edit
git push origin main

# DO NOT DELETE BRANCH (constitutional requirement)
# All branches preserved for historical reference
```

**Post-Merge**:
- [ ] Verify GitHub Pages still works (docs/.nojekyll preserved)
- [ ] Test installation on fresh Ubuntu 25.10 VM
- [ ] Monitor for user-reported issues
- [ ] Create conversation log in `documentations/development/conversation_logs/`

## Risks & Mitigation

### Risk 1: gum Installation Failure
**Impact**: Medium (TUI features unavailable)
**Probability**: Low (gum has binary download + apt repo)
**Mitigation**: Graceful degradation to plain text output, install gum as first prerequisite task

### Risk 2: Terminal Compatibility Issues
**Impact**: Medium (broken characters in some terminals)
**Probability**: Low (adaptive box drawing handles UTF-8/ASCII)
**Mitigation**: Automatic detection with manual override (`--box-style ascii`), comprehensive testing matrix

### Risk 3: Performance Regression
**Impact**: High (fails constitutional requirements)
**Probability**: Low (benchmarks validated)
**Mitigation**: Performance tests in CI/CD, fnm <50ms and gum <10ms verified during installation

### Risk 4: Verification False Positives/Negatives
**Impact**: High (incorrect installation state reporting)
**Probability**: Medium (complex system state checking)
**Mitigation**: Comprehensive test suite, real system state validation, manual verification on first run

### Risk 5: User Customization Loss
**Impact**: High (data loss, user frustration)
**Probability**: Low (idempotency design preserves customizations)
**Mitigation**: Backup critical files before modification, rollback capability, thorough testing

### Risk 6: Migration Complexity
**Impact**: Medium (users need to adapt to new system)
**Probability**: Medium (significant UX changes)
**Mitigation**: Preserve start-legacy.sh for rollback, comprehensive migration guide, user communication

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|---------|------------------|
| Phase 0: Research | Completed | research.md with 7 research topics |
| Phase 1: Design | 2-3 days | data-model.md, contracts/, quickstart.md |
| Phase 2: Implementation | 4 weeks | All lib/ modules, refactored start.sh |
| - Wave 1: Core | Week 1 | lib/core/*, lib/ui/tui.sh, gum installation |
| - Wave 2: Box Drawing | Week 1 | lib/ui/boxes.sh, terminal detection |
| - Wave 3: Verification | Week 2 | lib/verification/*, real system checks |
| - Wave 4: Tasks | Week 2-3 | lib/tasks/*, 6 installation modules |
| - Wave 5: Collapsible | Week 3 | lib/ui/collapsible.sh, progress.sh |
| - Wave 6: Orchestration | Week 4 | New start.sh, task registry, parallel execution |
| Phase 3: Testing | 1 week | Comprehensive test suite, validation |
| Phase 4: Documentation | 2-3 days | README, ARCHITECTURE, migration guide |
| **Total** | **6-7 weeks** | Production-ready Modern TUI System |

**Estimated Effort**: 80-100 hours total development time

## Complexity Tracking

**No constitutional violations detected. No justification required.**

All requirements align with constitutional principles. No complexity budget overruns.

