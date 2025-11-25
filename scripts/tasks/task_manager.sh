#!/bin/bash
# task_manager.sh - Parallel task orchestration with max 4 concurrent tasks


# Prevent multiple sourcing
[[ -n "${TASK_MANAGER_SH_LOADED:-}" ]] && return 0
readonly TASK_MANAGER_SH_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/task_display.sh"

# ============================================================
# CONFIGURATION
# ============================================================

# Maximum concurrent tasks
readonly MAX_CONCURRENT_TASKS=4

# Task queue management
declare -a TASK_QUEUE=()        # Queue of pending task IDs
declare -A RUNNING_TASKS=()     # task_id -> PID
declare -A TASK_COMMANDS=()     # task_id -> command to execute
declare -A TASK_EXIT_CODES=()   # task_id -> exit code after completion

# Global orchestration state
ORCHESTRATOR_RUNNING=0

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: init_task_manager
# Purpose: Initialize task orchestration system
# Args: None
# Returns: 0 on success
# Side Effects: Sets up task queue and display
init_task_manager() {
    log_debug "Initializing task manager"

    # Initialize task display
    init_task_display

    ORCHESTRATOR_RUNNING=1

    return 0
}

# Function: cleanup_task_manager
# Purpose: Clean up task orchestration on exit
# Args: None
# Returns: 0 always
# Side Effects: Terminates running tasks, cleans up display
cleanup_task_manager() {
    log_debug "Cleaning up task manager"

    # Terminate any running tasks
    for task_id in "${!RUNNING_TASKS[@]}"; do
        local pid="${RUNNING_TASKS[$task_id]}"
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Terminating running task: $task_id (PID $pid)"
            kill "$pid" 2>/dev/null || true
        fi
    done

    # Clean up display
    cleanup_task_display

    ORCHESTRATOR_RUNNING=0

    return 0
}

# Function: queue_task
# Purpose: Add task to execution queue
# Args: $1=task_id, $2=description, $3=command
# Returns: 0 on success
# Side Effects: Registers task, adds to queue
queue_task() {
    local task_id="$1"
    local description="$2"
    local command="$3"

    if [[ -z "$task_id" ]] || [[ -z "$description" ]] || [[ -z "$command" ]]; then
        log_error "queue_task: task_id, description, and command required"
        return 1
    fi

    # Register task for display
    register_task "$task_id" "$description"

    # Store command
    TASK_COMMANDS[$task_id]="$command"

    # Add to queue
    TASK_QUEUE+=("$task_id")

    log_debug "Queued task: $task_id"

    return 0
}

# Function: execute_task_async
# Purpose: Execute task in background
# Args: $1=task_id
# Returns: 0 on success, 1 on failure
# Side Effects: Starts background process, updates state
execute_task_async() {
    local task_id="$1"

    if [[ -z "${TASK_COMMANDS[$task_id]:-}" ]]; then
        log_error "Task command not found: $task_id"
        return 1
    fi

    local command="${TASK_COMMANDS[$task_id]}"

    # Mark task as running
    start_task "$task_id"

    # Execute in background
    (
        set +e  # Allow command to fail

        # Capture output and exit code
        local output
        local exit_code

        output=$(eval "$command" 2>&1)
        exit_code=$?

        # Store results in temp file (for parent process)
        local result_file="/tmp/task_${task_id}_$$"
        echo "$exit_code" > "$result_file"
        echo "$output" >> "$result_file"

        exit $exit_code
    ) &

    local pid=$!
    RUNNING_TASKS[$task_id]=$pid

    log_debug "Started background task: $task_id (PID $pid)"

    return 0
}

# Function: wait_for_task_slot
# Purpose: Wait until a task slot is available
# Args: None
# Returns: 0 when slot available
# Side Effects: Blocks until running tasks < MAX_CONCURRENT_TASKS
wait_for_task_slot() {
    while [[ ${#RUNNING_TASKS[@]} -ge $MAX_CONCURRENT_TASKS ]]; do
        # Check running tasks
        for task_id in "${!RUNNING_TASKS[@]}"; do
            local pid="${RUNNING_TASKS[$task_id]}"

            if ! kill -0 "$pid" 2>/dev/null; then
                # Task completed
                wait "$pid" 2>/dev/null || true

                # Read results
                local result_file="/tmp/task_${task_id}_$$"
                if [[ -f "$result_file" ]]; then
                    local exit_code
                    exit_code=$(head -n1 "$result_file")
                    local output
                    output=$(tail -n +2 "$result_file")

                    TASK_EXIT_CODES[$task_id]=$exit_code

                    # Complete task
                    if [[ $exit_code -eq 0 ]]; then
                        complete_task "$task_id" "success" "$output"
                    else
                        complete_task "$task_id" "failed" "$output"
                    fi

                    rm -f "$result_file"
                fi

                # Remove from running tasks
                unset RUNNING_TASKS["$task_id"]
            fi
        done

        # Brief sleep to avoid busy-waiting
        sleep 0.1
    done

    return 0
}

# Function: run_all_tasks
# Purpose: Execute all queued tasks with max concurrency
# Args: None
# Returns: 0 if all tasks succeeded, 1 if any failed
# Side Effects: Processes entire task queue
run_all_tasks() {
    log_debug "Running all queued tasks (max concurrency: $MAX_CONCURRENT_TASKS)"

    local total_tasks=${#TASK_QUEUE[@]}
    local failed_tasks=0

    # Process queue
    for task_id in "${TASK_QUEUE[@]}"; do
        # Wait for available slot
        wait_for_task_slot

        # Execute task
        execute_task_async "$task_id"
    done

    # Wait for all remaining tasks
    while [[ ${#RUNNING_TASKS[@]} -gt 0 ]]; do
        wait_for_task_slot
    done

    # Count failures
    for task_id in "${TASK_QUEUE[@]}"; do
        local exit_code="${TASK_EXIT_CODES[$task_id]:-0}"
        if [[ $exit_code -ne 0 ]]; then
            failed_tasks=$((failed_tasks + 1))
        fi
    done

    if [[ $failed_tasks -gt 0 ]]; then
        log_error "Task execution completed with $failed_tasks failures"
        return 1
    else
        log_info "All tasks completed successfully"
        return 0
    fi
}

# Function: run_task_sync
# Purpose: Execute single task synchronously (for testing)
# Args: $1=task_id, $2=description, $3=command
# Returns: Task exit code
# Side Effects: Registers, executes, and completes task
run_task_sync() {
    local task_id="$1"
    local description="$2"
    local command="$3"

    # Register task
    register_task "$task_id" "$description"

    # Mark as running
    start_task "$task_id"

    # Execute command
    set +e
    local output
    local exit_code

    output=$(eval "$command" 2>&1)
    exit_code=$?
    set -e

    # Complete task
    if [[ $exit_code -eq 0 ]]; then
        complete_task "$task_id" "success" "$output"
    else
        complete_task "$task_id" "failed" "$output"
    fi

    return $exit_code
}

# Function: get_task_summary
# Purpose: Get summary of task execution results
# Args: None
# Returns: Summary string (stdout)
# Side Effects: None
get_task_summary() {
    local total=0
    local succeeded=0
    local failed=0

    for task_id in "${!TASK_EXIT_CODES[@]}"; do
        total=$((total + 1))
        if [[ ${TASK_EXIT_CODES[$task_id]} -eq 0 ]]; then
            succeeded=$((succeeded + 1))
        else
            failed=$((failed + 1))
        fi
    done

    echo "Tasks: $total total, $succeeded succeeded, $failed failed"
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat << 'EOF'
This module provides parallel task orchestration and should be sourced, not executed directly.

Usage:
    source scripts/task_manager.sh

Available functions:
    - init_task_manager
    - cleanup_task_manager
    - queue_task <task_id> <description> <command>
    - execute_task_async <task_id>
    - wait_for_task_slot
    - run_all_tasks
    - run_task_sync <task_id> <description> <command>
    - get_task_summary

Example:
    source scripts/task_manager.sh
    init_task_manager
    queue_task "task1" "Installing Node.js" "install_node.sh"
    queue_task "task2" "Installing Ghostty" "install_ghostty.sh"
    run_all_tasks
    get_task_summary
    cleanup_task_manager
EOF
    exit 0
fi
