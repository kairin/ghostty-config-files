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

# Detect script directory
readonly ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all lib modules (order matters - dependencies first)
source "${ORCHESTRATOR_DIR}/lib/core/logging.sh"
source "${ORCHESTRATOR_DIR}/lib/core/utils.sh"
source "${ORCHESTRATOR_DIR}/lib/core/state.sh"
source "${ORCHESTRATOR_DIR}/lib/core/errors.sh"
source "${ORCHESTRATOR_DIR}/lib/ui/tui.sh"
source "${ORCHESTRATOR_DIR}/lib/ui/boxes.sh"
source "${ORCHESTRATOR_DIR}/lib/ui/collapsible.sh"
source "${ORCHESTRATOR_DIR}/lib/ui/progress.sh"
source "${ORCHESTRATOR_DIR}/lib/verification/health_checks.sh"
source "${ORCHESTRATOR_DIR}/lib/verification/duplicate_detection.sh"
source "${ORCHESTRATOR_DIR}/lib/verification/unit_tests.sh"
source "${ORCHESTRATOR_DIR}/lib/verification/integration_tests.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/gum.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/ghostty.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/zsh.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/python_uv.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/nodejs_fnm.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/ai_tools.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/context_menu.sh"
source "${ORCHESTRATOR_DIR}/lib/tasks/app_audit.sh"

# For task modules that need it
export SCRIPT_DIR="${ORCHESTRATOR_DIR}"

# ═════════════════════════════════════════════════════════════
# TASK REGISTRY (T034 - Dependency Resolution)
# ═════════════════════════════════════════════════════════════

# Task format: "id|dependencies|install_fn|verify_fn|parallel_group|estimated_seconds"
readonly TASK_REGISTRY=(
    "verify-prereqs||pre_installation_health_check|verify_health|0|10"
    "install-gum|verify-prereqs|task_install_gum|verify_gum_installed|1|30"
    "install-ghostty|verify-prereqs|task_install_ghostty|verify_ghostty_installed|1|180"
    "install-zsh|verify-prereqs|task_install_zsh|verify_zsh_configured|1|60"
    "install-uv|verify-prereqs|task_install_uv|verify_python_uv|1|45"
    "install-fnm|verify-prereqs|task_install_fnm|verify_fnm_installed|1|30"
    "install-nodejs|install-fnm|task_install_nodejs|verify_nodejs_version|2|120"
    "install-ai-tools|install-nodejs|task_install_ai_tools|verify_claude_cli|3|90"
    "install-context-menu|install-ghostty|task_install_context_menu|verify_context_menu|2|15"
    "run-app-audit|install-ai-tools,install-context-menu|task_run_app_audit|verify_app_audit_report|4|20"
)

# ═════════════════════════════════════════════════════════════
# CLI ARGUMENT PARSING (T037)
# ═════════════════════════════════════════════════════════════

# Default flags
VERBOSE_MODE=false
RESUME_MODE=false
FORCE_ALL=false
SKIP_CHECKS=false
BOX_STYLE=""

show_help() {
    cat <<EOF
Modern TUI Installation System

Usage: ./start.sh [OPTIONS]

Options:
  --help                Show this help message
  --verbose             Enable verbose mode (show full output, no collapsing)
  --resume              Resume from last checkpoint
  --force-all           Force reinstall all components (ignore idempotency)
  --skip-checks         Skip pre-installation health checks (not recommended)
  --box-style STYLE     Force box drawing style (ascii|utf8|utf8-double)

Examples:
  ./start.sh                    # Fresh installation (default)
  ./start.sh --verbose          # Full output, no collapsing
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
    save_installation_state

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
# Args:
#   $1 - Task ID
#   $2 - Dependencies (comma-separated)
#   $3 - Installation function name
#   $4 - Verification function name
#
# Returns:
#   0 = success
#   1 = failure
#
execute_single_task() {
    local task_id="$1"
    local deps="$2"
    local install_fn="$3"
    local verify_fn="$4"

    # Skip if already completed (idempotency)
    if is_task_completed "$task_id" && [ "$FORCE_ALL" = false ]; then
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

    if $install_fn; then
        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        complete_task "$task_id" "$duration"
        mark_task_completed "$task_id" "$duration"
        return 0
    else
        fail_task "$task_id" "Installation function failed: $install_fn"
        return 1
    fi
}

# ═════════════════════════════════════════════════════════════
# ORCHESTRATION LOGIC (T038)
# ═════════════════════════════════════════════════════════════

main() {
    # Initialize systems
    init_logging
    init_box_drawing "$BOX_STYLE"
    init_tui
    init_collapsible_output
    init_progress_tracking

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

        # If only one task in group, execute sequentially (no background)
        if [ "$group_size" -eq 1 ]; then
            local task_id="${group_tasks[0]}"

            # Find task entry
            for task_entry in "${TASK_REGISTRY[@]}"; do
                IFS='|' read -r entry_id deps install_fn verify_fn pg est <<< "$task_entry"
                if [ "$entry_id" = "$task_id" ]; then
                    execute_single_task "$task_id" "$deps" "$install_fn" "$verify_fn"
                    if [ $? -eq 0 ]; then
                        ((completed_tasks++))
                    fi
                    break
                fi
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
                    ((completed_tasks++))
                else
                    log "ERROR" "  ✗ $task_id failed"
                    ((failed_count++))
                fi
            done

            # Check if any parallel tasks failed (blocking)
            if [ "$failed_count" -gt 0 ]; then
                log "ERROR" "Parallel group $group_id: $failed_count task(s) failed"
                exit 1
            fi

            log "SUCCESS" "Parallel group $group_id: All ${group_size} tasks completed"
        fi

        # Show progress after each group
        show_progress_bar "$completed_tasks" "$total_tasks"
    done

    # Skip old sequential execution loop (replaced by parallel engine above)
    if false; then
    for task_entry in "${TASK_REGISTRY[@]}"; do
        IFS='|' read -r task_id deps install_fn verify_fn parallel_group est_seconds <<< "$task_entry"

        # Skip if already completed (idempotency)
        if is_task_completed "$task_id" && [ "$FORCE_ALL" = false ]; then
            skip_task "$task_id"
            ((completed_tasks++))
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
            ((completed_tasks++))
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

    return 0
}

# Run orchestrator
main "$@"
