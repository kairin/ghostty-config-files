#!/usr/bin/env bash
#
# start.sh - Modern TUI Installation System Orchestrator
#
# Modular orchestrator for Ghostty terminal infrastructure installation.
# Replaces monolithic start-legacy.sh with clean, maintainable architecture.
#
# Features (T034-T039):
#   - Task registry with dependency resolution (T034)
#   - State management for resume capability (T035)
#   - Parallel task execution engine (T036)
#   - CLI argument parsing (T037)
#   - Modular orchestration logic (T038)
#   - Interrupt handling with cleanup (T039)
#
# Constitutional Compliance:
#   - Principle V: Modular Architecture
#   - <200 lines orchestrator (business logic in lib/)
#   - Zero-configuration installation (target <10 minutes)
#   - Idempotent (safe re-run)
#   - Performance measured and logged (no hard targets)
#
# Usage:
#   ./start.sh                    # Fresh installation (default)
#   ./start.sh --verbose          # Show full output (no collapsing)
#   ./start.sh --resume           # Resume from last checkpoint
#   ./start.sh --force-all        # Force reinstall all components
#   ./start.sh --skip-checks      # Skip pre-installation health checks
#   ./start.sh --box-style ascii  # Force ASCII box drawing
#   ./start.sh --help             # Show help
#

set -euo pipefail

# ═════════════════════════════════════════════════════════════
# INITIALIZATION
# ═════════════════════════════════════════════════════════════

# Source the core bootstrap script
# This handles repo discovery, library sourcing, and initialization
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/lib/init.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/lib/init.sh"
else
    # Fallback for running from random directories if git is available
    source "$(git rev-parse --show-toplevel)/lib/init.sh"
fi

# ═════════════════════════════════════════════════════════════
# VHS AUTO-RECORDING (if available)
# ═════════════════════════════════════════════════════════════
# Enable automatic VHS recording for demo creation
# This must be AFTER lib/init.sh (needs REPO_ROOT) but BEFORE any work
# If VHS available and enabled: execs into VHS (NO RETURN)
# If VHS not available or disabled: continues normally (graceful degradation)
if [[ -f "${LIB_DIR}/ui/vhs-auto-record.sh" ]]; then
    source "${LIB_DIR}/ui/vhs-auto-record.sh"
    maybe_start_vhs_recording "start" "$0" "$@"
fi

# Source installation check module (check ACTUAL status, not state file)
source "${LIB_DIR}/core/installation-check.sh"

# Source task modules (not yet in init.sh as they are specific to start.sh)
source "${LIB_DIR}/tasks/fastfetch.sh"
source "${LIB_DIR}/tasks/go.sh"
source "${LIB_DIR}/tasks/gum.sh"
# ghostty.sh - REMOVED: Using modular installer lib/installers/ghostty/install.sh
source "${LIB_DIR}/tasks/zsh.sh"
source "${LIB_DIR}/tasks/python_uv.sh"
source "${LIB_DIR}/tasks/nodejs_fnm.sh"
source "${LIB_DIR}/tasks/ai_tools.sh"
source "${LIB_DIR}/tasks/context_menu.sh"
source "${LIB_DIR}/tasks/feh.sh"
source "${LIB_DIR}/tasks/glow.sh"
source "${LIB_DIR}/tasks/vhs.sh"
source "${LIB_DIR}/tasks/app_audit.sh"
source "${LIB_DIR}/tasks/system_audit.sh"
source "${LIB_DIR}/verification/duplicate_detection.sh"
source "${LIB_DIR}/verification/unit_tests.sh"
source "${LIB_DIR}/verification/integration_tests.sh"

# For task modules that need it
export SCRIPT_DIR="${REPO_ROOT}"

# ═════════════════════════════════════════════════════════════
# TASK REGISTRY (T034 - Dependency Resolution)
# ═════════════════════════════════════════════════════════════

# Task format: "id|dependencies|install_fn|verify_fn|parallel_group|estimated_seconds"
# install_fn can be either:
#   - A bash function name: "task_install_gum"
#   - A modular script path: "script:lib/tasks/ghostty/00-check-prerequisites.sh"
readonly TASK_REGISTRY=(
    # ═══════════════════════════════════════════════════════════════
    # Priority -1: fastfetch (System Info - BEFORE gum for system audit)
    # ═══════════════════════════════════════════════════════════════
    "install-fastfetch||script:lib/installers/fastfetch/install.sh|verify_fastfetch_installed|-1|25"

    # ═══════════════════════════════════════════════════════════════
    # Priority -0.5: Go Programming Language (Required for Gum)
    # ═══════════════════════════════════════════════════════════════
    "install-go||script:lib/installers/go/install.sh|verify_go_installed|-1|60"

    # ═══════════════════════════════════════════════════════════════
    # Priority 0: Gum TUI Framework (ALWAYS FIRST, ALWAYS REINSTALLED)
    # ═══════════════════════════════════════════════════════════════
    "install-gum|install-fastfetch,install-go|script:lib/installers/gum/install.sh|verify_gum_installed|0|40"

    # ═══════════════════════════════════════════════════════════════
    # Priority 1: Prerequisites
    # ═══════════════════════════════════════════════════════════════
    "verify-prereqs|install-gum|pre_installation_health_check|verify_health|1|10"

    # ═══════════════════════════════════════════════════════════════
    # Priority 2: Component Managers (each orchestrates its own sub-steps)
    # ═══════════════════════════════════════════════════════════════
    # Ghostty Terminal (5 steps: Snap installation, configuration)
    "install-ghostty|verify-prereqs|script:lib/installers/ghostty/install.sh|verify_ghostty_installed|2|55"

    # ZSH + Oh My ZSH (6 steps: OMZ, plugins, zshrc config, security)
    "install-zsh|verify-prereqs|script:lib/installers/zsh/install.sh|verify_zsh_configured|2|70"

    # Python UV Package Manager (5 steps: UV installer, shell config)
    "install-uv|verify-prereqs|script:lib/installers/python_uv/install.sh|verify_python_uv|2|50"

    # Node.js Fast Node Manager (5 steps: fnm, Node.js, shell config)
    "install-fnm|verify-prereqs|script:lib/installers/nodejs_fnm/install.sh|verify_fnm_installed|2|70"

    # AI Tools (5 steps: Claude CLI, Gemini CLI, Copilot CLI)
    "install-ai-tools|install-fnm|script:lib/installers/ai_tools/install.sh|verify_claude_cli|4|105"

    # Context Menu Integration (3 steps: Nautilus right-click menu)
    "install-context-menu|install-ghostty|script:lib/installers/context_menu/install.sh|verify_context_menu|3|20"

    # Feh Image Viewer (5 steps: build from source with ALL features)
    "install-feh|verify-prereqs|script:lib/installers/feh/install.sh|verify_feh_installed|2|130"

    # Glow Markdown Viewer (3 steps: Charm ecosystem, markdown display)
    "install-glow|install-gum|script:lib/installers/glow/install.sh|verify_glow_installed|2|30"

    # VHS Terminal Recorder (5 steps: ffmpeg, ttyd, VHS, demo generation)
    "install-vhs|install-glow|script:lib/installers/vhs/install.sh|verify_vhs_installed|3|85"

    # ═══════════════════════════════════════════════════════════════
    # Priority 5: App Audit (Final validation)
    # ═══════════════════════════════════════════════════════════════
    "run-app-audit|install-ai-tools,install-context-menu,install-vhs|task_run_app_audit|verify_app_audit_report|5|20"
)

# ═════════════════════════════════════════════════════════════
# CLI ARGUMENT PARSING (T037)
# ═════════════════════════════════════════════════════════════

# Default flags
# VERBOSE_MODE defaults to false for Docker-like collapsed terminal output
# Users can enable full terminal output with --verbose flag
# CRITICAL: Full verbose logs ALWAYS captured to log files regardless of mode
VERBOSE_MODE=false
RESUME_MODE=false
FORCE_ALL=false
SKIP_CHECKS=false
BOX_STYLE=""
SHOW_LOGS=false

show_help() {
    cat <<EOF
Modern TUI Installation System

Usage: ./start.sh [OPTIONS]

Options:
  --help                Show this help message
  --verbose             Enable verbose mode (show full output in terminal)
  --show-logs           Display log file locations after installation
  --resume              Resume from last checkpoint
  --force-all           Force reinstall all components (ignore idempotency)
  --skip-checks         Skip pre-installation health checks (not recommended)
  --box-style STYLE     Force box drawing style (ascii|utf8|utf8-double)

Output Modes:
  (default)             Docker-like collapsed output (logs saved to ./logs/)
  --verbose             Show full output in terminal (logs still saved)
  --show-logs           Display log file locations after installation

Logging:
  All installation output is always saved to full verbose logs in:
    ./logs/installation/    - Main installation logs
    ./logs/components/      - Per-component logs
    ./logs/errors.log       - All errors consolidated

  Use logs for debugging even when using collapsed output mode.

Examples:
  ./start.sh                    # Fresh installation (collapsed output)
  ./start.sh --verbose          # Full terminal output + log files
  ./start.sh --show-logs        # Show log locations after installation
  ./start.sh --resume           # Resume interrupted installation
  ./start.sh --force-all        # Force reinstall everything
  ./start.sh --box-style ascii  # Use ASCII box drawing (SSH/legacy terminals)

For more information: https://github.com/yourusername/ghostty-config-files
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --verbose)
            VERBOSE_MODE=true
            shift
            ;;
        --show-logs)
            SHOW_LOGS=true
            shift
            ;;
        --resume)
            RESUME_MODE=true
            shift
            ;;
        --force-all)
            FORCE_ALL=true
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --box-style)
            BOX_STYLE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run './start.sh --help' for usage information"
            exit 1
            ;;
    esac
done

# ═════════════════════════════════════════════════════════════
# INTERRUPT HANDLING (T039)
# ═════════════════════════════════════════════════════════════

cleanup_on_exit() {
    local exit_code=$?

    log "INFO" "Cleaning up on exit (code: $exit_code)..."

    # Stop spinner if running
    if [ -n "${SPINNER_PID:-}" ]; then
        stop_spinner_loop "$SPINNER_PID"
    fi

    # Cleanup collapsible output
    cleanup_collapsible_output

    # Cleanup temporary build files (Global cleanup)
    if [ -d "/tmp/zig-bootstrap" ] || [ -d "/tmp/ghostty-build" ]; then
        log "INFO" "Cleaning up temporary build files..."
        rm -rf "/tmp/zig-bootstrap" 2>/dev/null || true
        rm -rf "/tmp/ghostty-build" 2>/dev/null || true
        rm -f "/tmp/zig-*.tar.xz" 2>/dev/null || true
    fi

    # Save state
    save_state

    if [ $exit_code -ne 0 ]; then
        log "INFO" ""
        log "INFO" "═══════════════════════════════════════"
        log "INFO" "Installation interrupted"
        log "INFO" "═══════════════════════════════════════"
        log "INFO" ""
        log "INFO" "To resume: ./start.sh --resume"
        log "INFO" ""
    fi

    exit $exit_code
}

trap cleanup_on_exit EXIT SIGINT SIGTERM

# ═════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═════════════════════════════════════════════════════════════

#
# Execute a single task (used by both sequential and parallel execution)
#
# Supports both modular scripts and legacy functions:
#   - Modular script: install_fn starts with "script:" (e.g., "script:lib/tasks/ghostty/00-check-prerequisites.sh")
#   - Legacy function: install_fn is a function name (e.g., "task_install_gum")
#
# Args:
#   $1 - Task ID
#   $2 - Dependencies (comma-separated)
#   $3 - Installation function name or script path (prefix with "script:" for modular scripts)
#   $4 - Verification function name
#
# Returns:
#   0 = success
#   1 = failure
#   2 = skipped (already done)
#
execute_single_task() {
    local task_id="$1"
    local deps="$2"
    local install_fn="$3"
    local verify_fn="$4"

    # Check ACTUAL installation status (not state file)
    # EXCEPTION: gum is ALWAYS reinstalled (constitutional requirement)
    if [ "$task_id" != "install-gum" ] && [ "$FORCE_ALL" = false ]; then
        # Map task_id to component name
        local component_name
        case "$task_id" in
            "install-go") component_name="go" ;;
            "install-ghostty") component_name="ghostty" ;;
            "install-zsh") component_name="zsh" ;;
            "install-uv") component_name="uv" ;;
            "install-fnm") component_name="fnm" ;;
            "install-ai-tools") component_name="ai-tools" ;;
            "install-context-menu") component_name="context-menu" ;;
            *) component_name="" ;;
        esac

        # Check if component is actually installed
        if [ -n "$component_name" ] && check_component_installed "$component_name"; then
            log "INFO" "Component $component_name is already installed - skipping"
            skip_task "$task_id"
            return 0
        fi
    fi

    # Check dependencies
    if [ -n "$deps" ]; then
        IFS=',' read -ra dep_array <<< "$deps"
        for dep in "${dep_array[@]}"; do
            if ! is_task_completed "$dep"; then
                log "ERROR" "Dependency not met: $task_id requires $dep"
                fail_task "$task_id" "Dependency not met: $dep"
                return 1
            fi
        done
    fi

    # Execute task
    start_task "$task_id"

    # Show simple progress feedback
    echo ""
    echo "══════════════════════════════════════════════════"
    echo "→ Starting: ${TASK_DETAILS[$task_id]}"
    echo "══════════════════════════════════════════════════"
    echo ""

    local task_start
    task_start=$(get_unix_timestamp)

    local exit_code=0

    # Check if install_fn is a modular script path (starts with "script:")
    if [[ "$install_fn" == script:* ]]; then
        # Extract script path after "script:" prefix
        local script_path="${install_fn#script:}"

        # Make path absolute if relative
        if [[ ! "$script_path" =~ ^/ ]]; then
            script_path="${REPO_ROOT}/${script_path}"
        fi

        # Verify script exists and is executable
        if [[ ! -f "$script_path" ]]; then
            log "ERROR" "Modular script not found: $script_path"
            fail_task "$task_id" "Script not found: $script_path"
            return 1
        fi

        if [[ ! -x "$script_path" ]]; then
            log "ERROR" "Modular script not executable: $script_path"
            fail_task "$task_id" "Script not executable: $script_path"
            return 1
        fi

        # Execute modular script
        if "$script_path"; then
            exit_code=$?
        else
            exit_code=$?
        fi
    else
        # Execute legacy function
        if $install_fn; then
            exit_code=$?
        else
            exit_code=$?
        fi
    fi

    local task_end
    task_end=$(get_unix_timestamp)
    local duration

    echo ""
    duration=$(calculate_duration "$task_start" "$task_end")

    # Handle exit codes
    # 0 = success
    # 1 = failure
    # 2 = skipped (idempotent - already done)
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
        complete_task "$task_id" "$duration"
        mark_task_completed "$task_id" "$duration"

        if [ $exit_code -eq 2 ]; then
            echo "↷ Skipped: ${TASK_DETAILS[$task_id]} (already installed)"
            log "INFO" "Task $task_id skipped (already completed)"
        else
            echo "✓ Completed: ${TASK_DETAILS[$task_id]} ($(format_duration "$duration"))"
        fi
        echo ""

        return 0
    else
        echo "✗ FAILED: ${TASK_DETAILS[$task_id]} (exit code: $exit_code)"
        echo ""
        fail_task "$task_id" "Installation failed with exit code $exit_code"
        return 1
    fi
}

# ═════════════════════════════════════════════════════════════
# ORCHESTRATION LOGIC (T038)
# ═════════════════════════════════════════════════════════════

main() {
    # Initialize systems first (NO sudo yet)
    # Note: Logging and TUI are already initialized by init.sh
    # init_logging
    # init_box_drawing "$BOX_STYLE"  # REMOVED: Now using gum for all boxes (priority 0)
    # init_tui
    init_collapsible_output
    init_progress_tracking

    # Run pre-installation system audit (BEFORE sudo, zero privileges)
    # This shows current state and asks user to confirm
    if ! task_pre_installation_audit; then
        log "WARNING" "Installation cancelled by user"
        exit 0
    fi

    # Setup sudo credentials AFTER user confirms installation
    # This ensures sudo prompts come AFTER the audit table
    setup_sudo

    # Run robust environment verification
    if ! run_environment_checks; then
        log "ERROR" "Environment verification failed."
        exit 1
    fi

    if [ "$VERBOSE_MODE" = true ]; then
        enable_verbose_mode
    fi

    # Show header
    show_header "Modern TUI Installation System" "Ghostty Terminal Infrastructure"

    # Pre-installation health check (unless skipped)
    if [ "$SKIP_CHECKS" = false ]; then
        log "INFO" "Running pre-installation health checks..."
        if ! pre_installation_health_check; then
            log "ERROR" "Pre-installation health checks failed"
            log "ERROR" "Fix issues above or run with --skip-checks (not recommended)"
            exit 1
        fi
    else
        log "WARNING" "Skipping pre-installation health checks (--skip-checks)"
    fi

    # State management (T035)
    if [ "$RESUME_MODE" = true ]; then
        log "INFO" "Resume mode enabled - loading previous state..."
        load_state
    else
        log "INFO" "Fresh installation mode"
        init_state
    fi

    # Register all tasks with user-friendly display names
    local total_tasks=${#TASK_REGISTRY[@]}
    local completed_tasks=0

    for task_entry in "${TASK_REGISTRY[@]}"; do
        IFS='|' read -r task_id deps install_fn verify_fn parallel_group est_seconds <<< "$task_entry"

        # Generate user-friendly display name from task_id
        local display_name
        case "$task_id" in
            install-go)            display_name="Installing Go Programming Language" ;;
            install-gum)           display_name="Installing Gum TUI Framework" ;;
            verify-prereqs)        display_name="Verifying Prerequisites" ;;
            install-ghostty)       display_name="Installing Ghostty Terminal" ;;
            install-zsh)           display_name="Installing ZSH & Oh My ZSH" ;;
            install-uv)            display_name="Installing Python UV Package Manager" ;;
            install-fnm)           display_name="Installing Node.js Fast Node Manager" ;;
            install-ai-tools)      display_name="Installing AI CLI Tools" ;;
            install-context-menu)  display_name="Installing Context Menu Integration" ;;
            install-feh)           display_name="Installing Feh Image Viewer" ;;
            install-glow)          display_name="Installing Glow Markdown Viewer" ;;
            install-vhs)           display_name="Installing VHS Terminal Recorder" ;;
            run-app-audit)         display_name="Running Application Audit" ;;
            *)                     display_name="$(echo "$task_id" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')" ;;
        esac

        register_task "$task_id" "$display_name"
    done

    # Render initial task list (all pending)
    render_all_tasks

    # Start spinner loop for visual feedback (non-verbose mode only)
    # Start spinner loop for visual feedback (non-verbose mode only)
    # Spinner disabled to prevent hanging issues
    local spinner_pid=""
    # if [ "$VERBOSE_MODE" = false ]; then
    #     start_spinner_loop
    #     if [ -f "${TMP_DIR:-/tmp}/ghostty_spinner.pid" ]; then
    #         spinner_pid=$(cat "${TMP_DIR:-/tmp}/ghostty_spinner.pid")
    #     fi
    # fi

    # ═════════════════════════════════════════════════════════════
    # PARALLEL EXECUTION ENGINE (T036)
    # ═════════════════════════════════════════════════════════════

    # Group tasks by parallel_group for execution batching
    declare -A parallel_groups
    for task_entry in "${TASK_REGISTRY[@]}"; do
        IFS='|' read -r task_id deps install_fn verify_fn parallel_group est_seconds <<< "$task_entry"

        if [ -n "${parallel_groups[$parallel_group]:-}" ]; then
            parallel_groups[$parallel_group]+=" $task_id"
        else
            parallel_groups[$parallel_group]="$task_id"
        fi
    done

    # Execute tasks sequentially (Parallel execution disabled for stability)
    log "INFO" "Starting installation (${total_tasks} tasks)..."

    # Sort group IDs (use sort -g to handle negative keys like -1)
    mapfile -t sorted_groups < <(printf '%s\n' "${!parallel_groups[@]}" | sort -g)
    for group_id in "${sorted_groups[@]}"; do
        local group_tasks
        read -ra group_tasks <<< "${parallel_groups[$group_id]}"
        
        # Execute all tasks in this group sequentially
        for task_id in "${group_tasks[@]}"; do
            # Find task entry
            for task_entry in "${TASK_REGISTRY[@]}"; do
                IFS='|' read -r entry_id deps install_fn verify_fn pg est <<< "$task_entry"
                if [ "$entry_id" = "$task_id" ]; then
                    execute_single_task "$task_id" "$deps" "$install_fn" "$verify_fn"
                    if [ $? -eq 0 ]; then
                        ((completed_tasks += 1))
                    fi
                    break
                fi
            done
        done
        
        # Show progress after each group
        show_progress_bar "$completed_tasks" "$total_tasks"
    done

    # Skip old sequential execution loop (replaced by parallel engine above)
    if false; then
    for task_entry in "${TASK_REGISTRY[@]}"; do
        IFS='|' read -r task_id deps install_fn verify_fn parallel_group est_seconds <<< "$task_entry"

        # Check ACTUAL installation status (not state file)
        # EXCEPTION: gum is ALWAYS reinstalled
        if [ "$task_id" != "install-gum" ] && [ "$FORCE_ALL" = false ]; then
            # Map task_id to component name
            local component_name
            case "$task_id" in
                "install-ghostty") component_name="ghostty" ;;
                "install-zsh") component_name="zsh" ;;
                "install-uv") component_name="uv" ;;
                "install-fnm") component_name="fnm" ;;
                "install-ai-tools") component_name="ai-tools" ;;
                "install-context-menu") component_name="context-menu" ;;
                *) component_name="" ;;
            esac

            # Check if component is actually installed
            if [ -n "$component_name" ] && check_component_installed "$component_name"; then
                log "INFO" "Component $component_name is already installed - skipping"
                skip_task "$task_id"
                ((completed_tasks += 1))
                continue
            fi
        fi

        # Check dependencies
        if [ -n "$deps" ]; then
            IFS=',' read -ra dep_array <<< "$deps"
            for dep in "${dep_array[@]}"; do
                if ! is_task_completed "$dep"; then
                    log "ERROR" "Dependency not met: $task_id requires $dep"
                    fail_task "$task_id" "Dependency not met: $dep"
                    exit 1
                fi
            done
        fi

        # Execute task
        start_task "$task_id"

        local task_start
        task_start=$(get_unix_timestamp)

        if $install_fn; then
            local task_end
            task_end=$(get_unix_timestamp)
            local duration
            duration=$(calculate_duration "$task_start" "$task_end")

            complete_task "$task_id" "$duration"
            mark_task_completed "$task_id" "$duration"
            ((completed_tasks += 1))
        else
            fail_task "$task_id" "Installation function failed: $install_fn"
            exit 1
        fi

        # Show progress
        show_progress_bar "$completed_tasks" "$total_tasks"
    done
    fi  # End of disabled sequential loop

    # Stop spinner loop
    if [ -n "$spinner_pid" ]; then
        stop_spinner_loop "$spinner_pid"
    fi

    # Post-installation health check
    log "INFO" "Running post-installation health checks..."
    post_installation_health_check

    # Post-installation verification audit
    log "INFO" ""
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Post-Installation Verification"
    log "INFO" "════════════════════════════════════════"
    log "INFO" ""
    log "INFO" "Running post-installation system audit to verify all installations..."
    log "INFO" ""

    # Run the same audit as pre-installation to show final state
    if source "${REPO_ROOT}/lib/tasks/system_audit.sh" 2>/dev/null; then
        # Run audit but skip the confirmation prompt
        task_post_installation_verification || true
    else
        log "WARNING" "Could not run post-installation verification audit"
    fi

    # Show summary
    local total_duration
    total_duration=$(calculate_elapsed_time)
    show_summary "$completed_tasks" 0 "$total_duration"

    # Cleanup collapsible output
    cleanup_collapsible_output

    log "SUCCESS" "═══════════════════════════════════════"
    log "SUCCESS" "Installation complete!"
    log "SUCCESS" "═══════════════════════════════════════"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Restart your terminal"
    log "INFO" "  2. Launch Ghostty: ghostty"
    log "INFO" "  3. Configure API keys: cp .env.example .env && edit .env"
    log "INFO" ""

    # Display log file locations if requested
    if [ "$SHOW_LOGS" = true ] || [ "$VERBOSE_MODE" = false ]; then
        log "INFO" "═══════════════════════════════════════"
        log "INFO" "Installation Logs"
        log "INFO" "═══════════════════════════════════════"
        log "INFO" ""
        log "INFO" "Main installation log:"
        log "INFO" "  Human-readable: $(get_log_file)"
        log "INFO" "  Verbose debug:  $(get_verbose_log_file)"
        log "INFO" "  Structured JSON: ${LOG_FILE_JSON}"
        log "INFO" ""
        log "INFO" "Component logs:"
        log "INFO" "  Directory: ${REPO_ROOT}/logs/components/"
        if [ -d "${REPO_ROOT}/logs/components/" ]; then
            ls -1t "${REPO_ROOT}/logs/components/" 2>/dev/null | head -5 | while read -r logfile; do
                log "INFO" "    - ${logfile}"
            done
        fi
        log "INFO" ""
        log "INFO" "Error log: ${REPO_ROOT}/logs/errors.log"
        log "INFO" ""
    fi

    return 0
}

# Run orchestrator
main "$@"
