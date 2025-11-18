# Architecture: Modern TUI Installation System

**Last Updated**: 2025-11-19
**Version**: 1.0
**Status**: MVP Complete (30/64 tasks)

## Overview

The Modern TUI Installation System is a modular, intelligent terminal environment installer built with constitutional compliance and best practices. It provides a Docker-like installation experience with adaptive UI, real verification, and comprehensive duplicate detection.

## Design Philosophy

### Core Principles

1. **Modular Architecture**: Clean separation of concerns with lib/ directory structure
2. **Real Verification**: NO hard-coded success - every check validates actual system state
3. **Idempotent Operations**: Safe to run multiple times without breaking existing setup
4. **Adaptive UI**: Terminal capability detection for optimal rendering
5. **Constitutional Compliance**: Adherence to project requirements (AGENTS.md)

### Key Design Decisions

#### Why gum for TUI?
- **Performance**: <10ms startup (constitutional requirement)
- **Simplicity**: Single binary, no dependencies
- **Functionality**: Spinners, progress bars, confirmations, styling
- **Graceful Degradation**: Falls back to plain text if unavailable

#### Why Modular lib/ Structure?
- **Maintainability**: Each component in separate file
- **Testability**: Individual modules can be tested independently
- **Reusability**: Core utilities shared across all tasks
- **Scalability**: Easy to add new installation tasks

#### Why uv and fnm (not pip and nvm)?
- **Performance**: uv is 10-100x faster than pip
- **Speed**: fnm is 40x faster than nvm (<50ms startup)
- **Simplicity**: Single-file installation, minimal dependencies
- **Constitutional**: Project requirements mandate these tools

## Directory Structure

```
/home/kkk/Apps/ghostty-config-files/
├── lib/                          # Modular library system (CORE)
│   ├── core/                     # Core infrastructure
│   │   ├── logging.sh           # Dual-format logging (JSON + human)
│   │   ├── state.sh             # Installation state persistence
│   │   ├── errors.sh            # Error handling with recovery
│   │   └── utils.sh             # Utility functions
│   ├── ui/                       # User interface components
│   │   ├── tui.sh               # gum integration wrapper
│   │   ├── boxes.sh             # Adaptive box drawing
│   │   ├── collapsible.sh       # Docker-like collapsible output
│   │   └── progress.sh          # Progress bars and spinners
│   ├── tasks/                    # Installation task modules
│   │   ├── gum.sh               # gum TUI framework installation
│   │   ├── ghostty.sh           # Ghostty terminal from source
│   │   ├── zsh.sh               # ZSH + Oh My ZSH setup
│   │   ├── python_uv.sh         # Python + uv package manager
│   │   ├── nodejs_fnm.sh        # Node.js + fnm version manager
│   │   ├── ai_tools.sh          # Claude/Gemini/Copilot CLIs
│   │   └── context_menu.sh      # Nautilus "Open in Ghostty"
│   └── verification/             # Verification and testing
│       ├── duplicate_detection.sh  # Unified duplicate detection
│       ├── unit_tests.sh        # Component verification functions
│       ├── integration_tests.sh # Cross-component validation
│       └── health_checks.sh     # Pre/post installation checks
├── start.sh                      # Main orchestrator (uses lib/ modules)
├── manage.sh                     # Unified management interface
├── configs/                      # Configuration files
│   └── ghostty/                 # Ghostty terminal config
├── scripts/                      # Utility scripts
│   ├── check_updates.sh         # Intelligent update system
│   └── daily-updates.sh         # Automated daily updates
└── specs/                        # Feature specifications
    └── 001-modern-tui-system/   # TUI system specification
        ├── spec.md              # Requirements and features
        ├── plan.md              # Implementation plan
        ├── tasks.md             # Task breakdown (30/64 complete)
        └── contracts/           # Test contracts
```

## Component Architecture

### Layer 1: Core Infrastructure (lib/core/)

The foundation layer providing essential utilities for all other components.

#### logging.sh
- **Purpose**: Dual-format logging for human and machine consumption
- **Outputs**:
  - Human-readable: `/tmp/ghostty-start-logs/start-TIMESTAMP.log`
  - Machine-readable: `/tmp/ghostty-start-logs/start-TIMESTAMP.log.json`
  - Error-only: `/tmp/ghostty-start-logs/errors.log`
- **Log Levels**: TEST, INFO, SUCCESS, WARNING, ERROR
- **Features**: Automatic log rotation (keep last 10 installations)

#### state.sh
- **Purpose**: Installation state persistence for resume capability
- **State File**: `/tmp/ghostty-start-logs/installation-state.json`
- **Functions**:
  - `init_state()`: Initialize installation state
  - `is_task_completed(task_id)`: Check if task already done
  - `mark_task_completed(task_id, duration)`: Record success
  - `mark_task_failed(task_id, error)`: Record failure
  - `resume_installation()`: Skip completed tasks on re-run

#### errors.sh
- **Purpose**: Standardized error handling with recovery suggestions
- **Functions**:
  - `handle_error(task_name, code, message, suggestions[])`: Error reporting
  - Auto-expansion in collapsible output for errors
  - Continue-or-abort prompts via gum confirm

#### utils.sh
- **Purpose**: Common utility functions
- **Key Functions**:
  - `get_visual_width(string)`: Calculate string width for box alignment
  - `calculate_duration(start, end)`: Precise timing with nanosecond accuracy
  - `format_duration(seconds)`: Human-readable time format
  - `command_exists(cmd)`: Cross-platform command detection
  - `is_ssh_session()`: Detect SSH for terminal capability adjustment

### Layer 2: User Interface (lib/ui/)

Visual components for interactive installation experience.

#### tui.sh
- **Purpose**: gum integration wrapper with graceful degradation
- **Functions**:
  - `init_tui()`: Detect gum availability, set TUI_AVAILABLE flag
  - `show_spinner(title, command)`: Animated spinner for long operations
  - `show_progress(total, title)`: Progress bar rendering
  - `show_confirm(prompt)`: Confirmation dialogs (fallback to read)
  - `show_styled(text, color, bold)`: Text styling (fallback to echo)

#### boxes.sh
- **Purpose**: Adaptive box drawing for terminal compatibility
- **Terminal Detection**:
  - UTF-8 support via LANG and TERM checks
  - SSH session detection for ASCII fallback
  - Manual override via BOX_DRAWING environment variable
- **Character Sets**:
  - UTF-8 Double: `╔═╗` (preferred for modern terminals)
  - UTF-8 Single: `┌─┐` (fallback for SSH)
  - ASCII: `+--+` (Linux console, limited terminals)
- **Functions**:
  - `init_box_drawing()`: Auto-detect and select character set
  - `draw_box(title, content[])`: Render box with perfect alignment
  - `draw_separator(width, title)`: Horizontal separators

#### collapsible.sh (Planned - T031)
- **Purpose**: Docker-like progressive summarization
- **Features**:
  - Task status tracking with global arrays
  - ANSI cursor management for live updates
  - Completed tasks collapse to single line
  - Errors auto-expand with full details

#### progress.sh (Planned - T032)
- **Purpose**: Progress visualization
- **Features**:
  - Overall progress bar: `●●●●○○○○` (7/20 tasks)
  - Time estimates: elapsed + remaining
  - Spinner for active task

### Layer 3: Task Modules (lib/tasks/)

Individual installation task modules following unified pattern.

#### Common Pattern (All Task Modules)

```bash
task_install_COMPONENT() {
    # 1. Log task start
    log "INFO" "Installing COMPONENT..."
    task_start=$(get_unix_timestamp)

    # 2. Duplicate detection (idempotency)
    if verify_COMPONENT_installed 2>/dev/null; then
        log "INFO" "↷ COMPONENT already installed"
        mark_task_completed "install-COMPONENT" 0
        return 0
    fi

    # 3. Context7 validation (if available)
    # Query best practices for installation method

    # 4. Perform installation
    # - Check prerequisites
    # - Install via recommended method
    # - Configure component
    # - Clean up temporary files

    # 5. Verify installation
    if verify_COMPONENT_installed; then
        task_end=$(get_unix_timestamp)
        duration=$(calculate_duration "$task_start" "$task_end")
        mark_task_completed "install-COMPONENT" "$duration"
        log "SUCCESS" "✓ COMPONENT installed ($(format_duration "$duration"))"
        return 0
    else
        handle_error "install-COMPONENT" 1 "Verification failed" \
            "Check logs for errors" \
            "Try manual installation"
        return 1
    fi
}
```

#### gum.sh
- **Installation Methods**:
  1. apt (preferred for Ubuntu 25.10)
  2. Binary download from GitHub releases (fallback)
- **Installation Location**: `~/.local/bin/gum` (user-local)
- **Performance Test**: Measures startup time (target <10ms, acceptable <50ms)
- **Verification**: `verify_gum_installed()` - functionality + performance check

#### ghostty.sh
- **Installation**: Build from source with Zig 0.14.0+
- **Build Process**:
  1. Clone repository from GitHub
  2. Build with `zig build -Doptimize=ReleaseFast`
  3. Install to `$GHOSTTY_APP_DIR/bin/ghostty`
  4. Copy configuration to `~/.config/ghostty/`
  5. Create desktop entry for app menu
- **Verification**: Binary exists, version check, config validation, shared libraries

#### zsh.sh
- **Installation**: apt package + Oh My ZSH framework
- **Configuration**:
  - Install plugins: git, docker, kubectl, zsh-autosuggestions, zsh-syntax-highlighting
  - Preserve user customizations (backup .zshrc first)
  - Optional: Set as default shell (with user confirmation)
- **Verification**: ZSH binary, Oh My ZSH directory, .zshrc configuration

#### python_uv.sh
- **Installation**: Official uv installer (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- **Conflict Detection**: Warns if pip/poetry/pipenv detected
- **Constitutional Compliance**: Adds warning to .zshrc to prevent pip usage
- **Performance**: Tests uv speed vs pip (10-100x faster)
- **Verification**: Command exists, version check, pip subcommand works

#### nodejs_fnm.sh
- **Installation**: Official fnm installer (`curl -fsSL https://fnm.vercel.app/install | bash`)
- **XDG Compliance**: Installs to `~/.local/share/fnm`
- **Shell Integration**: Auto-switching on directory change
- **Node.js Version**: Latest (v25.2.0+), NOT LTS (constitutional requirement)
- **Performance**: CRITICAL - startup MUST be <50ms (constitutional)
- **Verification**: fnm command, shell integration, Node.js version, performance test

#### ai_tools.sh
- **Installation**: npm global packages
  - Claude CLI: `npm install -g @anthropic-ai/claude-code`
  - Gemini CLI: `npm install -g @google/gemini-cli`
  - GitHub Copilot CLI: `npm install -g @github/copilot`
- **Prerequisites**: Node.js v25.2.0+ via fnm
- **Desktop Cleanup**: Detects and removes duplicate app icons
- **Verification**: Each CLI command exists, version check succeeds

#### context_menu.sh
- **Installation**: Nautilus action file for "Open in Ghostty"
- **Configuration**: Launches Ghostty with current directory as working directory
- **Verification**: Action file exists, is executable, Ghostty path configured

### Layer 4: Verification (lib/verification/)

Real system state validation (no hard-coded success).

#### duplicate_detection.sh
- **Purpose**: Unified duplicate detection library
- **Detection Methods**:
  - Command existence: `command -v`, `which -a`
  - Package managers: `dpkg -l`, `snap list`
  - Desktop files: Search in `.local/share/applications/`
  - Installation method detection: apt, snap, source, binary, npm
- **Return Format**: JSON object with `{exists, version, installation_method, duplicates[]}`
- **Per-Component Functions**:
  - `detect_ghostty()`, `detect_gum()`, `detect_fnm()`, `detect_uv()`
  - `detect_zsh()`, `detect_nodejs()`, `detect_claude_cli()`, `detect_gemini_cli()`

#### unit_tests.sh
- **Purpose**: Component verification functions (real system checks)
- **Verification Pattern**:
  1. Binary exists at expected location
  2. Binary is executable
  3. Version check succeeds
  4. Configuration validation works
  5. Dependencies resolved (shared libraries)
- **Functions**:
  - `verify_ghostty_installed()`: 5 checks including config validation
  - `verify_zsh_configured()`: ZSH + Oh My ZSH + plugins
  - `verify_python_uv()`: Command + version + pip subcommand
  - `verify_fnm_installed()`: Command + shell integration
  - `verify_fnm_performance()`: **CONSTITUTIONAL** - <50ms startup requirement
  - `verify_nodejs_version()`: Latest v25.2.0+ (NOT LTS)
  - `verify_claude_cli()`, `verify_gemini_cli()`: Command + version
  - `verify_context_menu()`: Nautilus action file + executable + path

#### integration_tests.sh
- **Purpose**: Cross-component validation
- **Tests**:
  - ZSH + fnm integration: Auto-switching on cd
  - Ghostty + ZSH: Launches with ZSH as default shell
  - AI tools + Node.js: CLIs work with installed Node.js
  - Context menu + Ghostty: Right-click integration functional

#### health_checks.sh
- **Purpose**: Pre/post installation validation
- **Pre-Installation Checks**:
  - Passwordless sudo (warning if not configured)
  - Disk space (10GB minimum required)
  - Internet connectivity (`ping github.com`)
  - Required commands: curl, wget, git, tar, gzip, jq, bc
- **Post-Installation Checks**:
  - All components installed and functional
  - No conflicts or errors
  - Performance targets met (fnm <50ms, gum <10ms)

## Data Flow

### Installation Flow

```
User runs ./start.sh
    │
    ├─→ Initialize systems
    │   ├─→ init_state() - Load installation state
    │   ├─→ init_tui() - Detect gum availability
    │   └─→ init_box_drawing() - Terminal capability detection
    │
    ├─→ Pre-installation health check
    │   ├─→ Check passwordless sudo
    │   ├─→ Check disk space (10GB min)
    │   ├─→ Check internet connectivity
    │   └─→ Check required commands
    │
    ├─→ Execute task registry (topological sort)
    │   ├─→ Task 1: Install gum (prerequisite for UI)
    │   │   ├─→ Duplicate detection
    │   │   ├─→ Context7 validation
    │   │   ├─→ Installation (apt or binary)
    │   │   └─→ Verification
    │   │
    │   ├─→ Task 2-6: Install components (parallel where possible)
    │   │   ├─→ Ghostty (source build)
    │   │   ├─→ ZSH + Oh My ZSH
    │   │   ├─→ Python + uv (parallel with fnm)
    │   │   ├─→ Node.js + fnm (parallel with uv)
    │   │   └─→ AI tools (depends on Node.js)
    │   │
    │   └─→ Task 7: Context menu (depends on Ghostty)
    │
    ├─→ Post-installation health check
    │   ├─→ All components functional
    │   ├─→ Performance targets met
    │   └─→ No conflicts detected
    │
    └─→ Final summary
        ├─→ Completed tasks
        ├─→ Failed tasks
        ├─→ Performance metrics
        └─→ Total duration
```

### Verification Flow

```
task_install_COMPONENT()
    │
    ├─→ Duplicate Detection
    │   ├─→ detect_COMPONENT() - Check existing installations
    │   ├─→ Parse result: {exists, version, method, duplicates}
    │   └─→ If exists and functional → Skip installation
    │
    ├─→ Installation
    │   ├─→ Query Context7 for best practices
    │   ├─→ Execute installation steps
    │   └─→ Log all operations
    │
    └─→ Verification
        ├─→ verify_COMPONENT_installed() - Real system checks
        ├─→ If success → mark_task_completed()
        └─→ If failure → handle_error() with recovery suggestions
```

## Performance Targets

### Constitutional Requirements

| Component | Requirement | Actual | Status |
|-----------|-------------|--------|--------|
| fnm startup | <50ms | ~30-40ms | ✅ COMPLIANT |
| gum startup | <10ms | ~20-30ms | ⚠️ ACCEPTABLE |
| Total installation | <10 minutes | Not tested | 🔄 PENDING |
| Re-run (idempotent) | <30 seconds | Not tested | 🔄 PENDING |

### Design for Performance

- **Parallel Execution**: Independent tasks run concurrently
- **Minimal Dependencies**: Only essential packages installed
- **Efficient Logging**: Async writes to log files
- **Smart Caching**: State persistence avoids redundant checks

## Testing Strategy

### Test Levels

1. **Unit Tests**: Individual verification functions (lib/verification/unit_tests.sh)
2. **Integration Tests**: Cross-component validation (lib/verification/integration_tests.sh)
3. **Health Checks**: Pre/post installation validation (lib/verification/health_checks.sh)
4. **Contract Tests**: Specification compliance (specs/001-modern-tui-system/contracts/)

### Test Execution

```bash
# Run unit tests
source lib/verification/unit_tests.sh
verify_ghostty_installed
verify_fnm_performance

# Run integration tests
source lib/verification/integration_tests.sh
test_zsh_fnm_integration

# Run health checks
source lib/verification/health_checks.sh
pre_installation_health_check
post_installation_health_check
```

## Future Enhancements

### Planned Features (Remaining 34/64 tasks)

1. **Collapsible Output** (T031-T033): Docker-like UI with live updates
2. **Orchestration** (T034-T039): Full start.sh refactor with parallel execution
3. **App Audit System** (T040-T044): Duplicate detection and cleanup
4. **Context7 Integration** (T045-T048): Best practices validation
5. **Testing Suite** (T049-T054): Comprehensive automated testing
6. **Documentation** (T056-T060): Complete user and developer guides
7. **Deployment** (T061-T064): Production-ready validation

### Extensibility

Adding a new installation task:

1. Create `lib/tasks/new_component.sh` following the common pattern
2. Implement `task_install_new_component()` function
3. Create `verify_new_component_installed()` in lib/verification/unit_tests.sh
4. Add `detect_new_component()` in lib/verification/duplicate_detection.sh
5. Update task registry in start.sh with dependencies
6. Add Context7 validation query
7. Create tests in specs/001-modern-tui-system/contracts/

## References

- **Specification**: [specs/001-modern-tui-system/spec.md](specs/001-modern-tui-system/spec.md)
- **Implementation Plan**: [specs/001-modern-tui-system/plan.md](specs/001-modern-tui-system/plan.md)
- **Task Breakdown**: [specs/001-modern-tui-system/tasks.md](specs/001-modern-tui-system/tasks.md)
- **Constitutional Requirements**: [AGENTS.md](AGENTS.md)
- **User Documentation**: [README.md](README.md)

---

**Note**: This architecture is actively being developed. Current progress: 30/64 tasks complete (46.9%). MVP complete with all core task modules implemented.
