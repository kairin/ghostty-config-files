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
#   - Zero-configuration installation (<10 minutes)
#   - Idempotent (safe re-run)
#   - Performance targets (fnm <50ms, gum <10ms, total <10min)
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

# Source task modules (not yet in init.sh as they are specific to start.sh)
source "${LIB_DIR}/tasks/gum.sh"
source "${LIB_DIR}/tasks/ghostty.sh"
source "${LIB_DIR}/tasks/zsh.sh"
source "${LIB_DIR}/tasks/python_uv.sh"
source "${LIB_DIR}/tasks/nodejs_fnm.sh"
source "${LIB_DIR}/tasks/ai_tools.sh"
source "${LIB_DIR}/tasks/context_menu.sh"
source "${LIB_DIR}/tasks/app_audit.sh"
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
    # Priority 0: Gum TUI Framework (ALWAYS FIRST, ALWAYS REINSTALLED)
    # ═══════════════════════════════════════════════════════════════
    "install-gum||script:lib/installers/gum/install.sh|verify_gum_installed|0|40"

    # ═══════════════════════════════════════════════════════════════
    # Priority 1: Prerequisites
    # ═══════════════════════════════════════════════════════════════
    "verify-prereqs|install-gum|pre_installation_health_check|verify_health|1|10"

    # ═══════════════════════════════════════════════════════════════
    # Priority 2: Component Managers (each orchestrates its own sub-steps)
    # ═══════════════════════════════════════════════════════════════
    # Ghostty Terminal (9 steps: Zig build, Ghostty installation)
    "install-ghostty|verify-prereqs|script:lib/installers/ghostty/install.sh|verify_ghostty_installed|2|185"

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

    # ═══════════════════════════════════════════════════════════════
    # Priority 5: App Audit (Final validation)
    # ═══════════════════════════════════════════════════════════════
    "run-app-audit|install-ai-tools,install-context-menu|task_run_app_audit|verify_app_audit_report|5|20"
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

    # Skip if already completed (idempotency)
    # EXCEPTION: gum is ALWAYS reinstalled (constitutional requirement)
    if [ "$task_id" != "install-gum" ] && is_task_completed "$task_id" && [ "$FORCE_ALL" = false ]; then
        skip_task "$task_id"
        return 0
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
    duration=$(calculate_duration "$task_start" "$task_end")

    # Handle exit codes
    # 0 = success
    # 1 = failure
    # 2 = skipped (idempotent - already done)
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
        complete_task "$task_id" "$duration"
        mark_task_completed "$task_id" "$duration"

        if [ $exit_code -eq 2 ]; then
            log "INFO" "Task $task_id skipped (already completed)"
        fi

        return 0
    else
        fail_task "$task_id" "Installation failed with exit code $exit_code"
        return 1
    fi
}

# ═════════════════════════════════════════════════════════════
# ORCHESTRATION LOGIC (T038)
# ═════════════════════════════════════════════════════════════

main() {
    # Initialize systems
    # Note: Logging and TUI are already initialized by init.sh
    # init_logging
    init_box_drawing "$BOX_STYLE"
    # init_tui
    init_collapsible_output
    init_progress_tracking

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

    # Register all tasks
    local total_tasks=${#TASK_REGISTRY[@]}
    local completed_tasks=0

    for task_entry in "${TASK_REGISTRY[@]}"; do
        IFS='|' read -r task_id deps install_fn verify_fn parallel_group est_seconds <<< "$task_entry"
        register_task "$task_id" "$(echo "$install_fn" | sed 's/_/ /g' | sed 's/task //')"
    done

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

    # Execute tasks by parallel group (0, 1, 2, 3, ...)
    log "INFO" "Starting installation (${total_tasks} tasks, parallel execution enabled)..."

    for group_id in $(printf '%s\n' "${!parallel_groups[@]}" | sort -n); do
        local group_tasks=(${parallel_groups[$group_id]})
        local group_size=${#group_tasks[@]}

        log "INFO" "═══════════════════════════════════════════════════════════════"
        log "INFO" "Parallel Group $group_id: ${group_size} task(s)"
        log "INFO" "═══════════════════════════════════════════════════════════════"

        # TEMPORARY: Disable parallel execution to fix output chaos (TODO: implement output buffering)
        # Execute all tasks sequentially for now
        if true; then
            # Loop through all tasks in this group sequentially
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
        else
            # Multiple tasks - execute in parallel
            log "INFO" "Launching ${group_size} tasks in parallel..."

            local pids=()
            local task_ids=()

            # Launch tasks in background
            for task_id in "${group_tasks[@]}"; do
                # Find task entry
                for task_entry in "${TASK_REGISTRY[@]}"; do
                    IFS='|' read -r entry_id deps install_fn verify_fn pg est <<< "$task_entry"

                    if [ "$entry_id" = "$task_id" ]; then
                        log "INFO" "  → Launching $task_id..."

                        # Execute in background
                        (execute_single_task "$task_id" "$deps" "$install_fn" "$verify_fn") &
                        pids+=($!)
                        task_ids+=("$task_id")
                        break
                    fi
                done
            done

            # Wait for all parallel tasks to complete
            log "INFO" "Waiting for ${#pids[@]} parallel tasks to complete..."

            local failed_count=0
            for i in "${!pids[@]}"; do
                local pid=${pids[$i]}
                local task_id=${task_ids[$i]}

                if wait "$pid"; then
                    log "SUCCESS" "  ✓ $task_id completed"
                    ((completed_tasks += 1))
                else
                    log "ERROR" "  ✗ $task_id failed"
                    ((failed_count += 1))
                fi
            done

            # Check if any parallel tasks failed (blocking)
            if [ "$failed_count" -gt 0 ]; then
                log "ERROR" "Parallel group $group_id: $failed_count task(s) failed"
                exit 1
            fi

            log "SUCCESS" "Parallel group $group_id: All ${group_size} tasks completed"
        fi

        # Show progress after each group (only in verbose mode)
        # In collapsed mode, task rendering shows the progress
        show_progress_bar "$completed_tasks" "$total_tasks"
    done

    # Skip old sequential execution loop (replaced by parallel engine above)
    if false; then
    for task_entry in "${TASK_REGISTRY[@]}"; do
        IFS='|' read -r task_id deps install_fn verify_fn parallel_group est_seconds <<< "$task_entry"

        # Skip if already completed (idempotency)
        if is_task_completed "$task_id" && [ "$FORCE_ALL" = false ]; then
            skip_task "$task_id"
            ((completed_tasks += 1))
            continue
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

    # Post-installation health check
    log "INFO" "Running post-installation health checks..."
    post_installation_health_check

    # Show summary
    local total_duration
    total_duration=$(calculate_elapsed_time)
    show_summary "$completed_tasks" 0 "$total_duration"

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
