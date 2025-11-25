#!/usr/bin/env bash
#
# lib/ui/components/task_state.sh - Task state management for collapsible UI
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Task States:
#   pending   - Task not yet started
#   running   - Task currently executing
#   success   - Task completed successfully
#   failed    - Task failed with error
#   skipped   - Task skipped (already installed)
#
# Functions:
#   - register_task(): Register new task
#   - update_task_status(): Update task status
#   - start_task(): Mark task as running
#   - complete_task(): Mark task as success
#   - fail_task(): Mark task as failed
#   - skip_task(): Mark task as skipped
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_UI_COMPONENTS_TASK_STATE_SH:-}" ]] && return 0
readonly _LIB_UI_COMPONENTS_TASK_STATE_SH=1

# ============================================================================
# GLOBAL STATE TRACKING
# ============================================================================

# Task state associative arrays (initialized if not already)
if [[ -z "${TASK_STATUS_INIT:-}" ]]; then
    declare -gA TASK_STATUS       # task_id => status
    declare -gA TASK_TIMES        # task_id => duration in seconds
    declare -gA TASK_ERRORS       # task_id => error message
    declare -gA TASK_DETAILS      # task_id => task name
    declare -gA TASK_OUTPUT       # task_id => buffered output
    declare -ga TASK_ORDER        # Array of task IDs in order
    TASK_STATUS_INIT=1
fi

# ============================================================================
# TASK REGISTRATION
# ============================================================================

# Function: register_task
register_task() {
    local task_id="$1"
    local task_name="$2"

    TASK_STATUS["$task_id"]="pending"
    TASK_TIMES["$task_id"]=0
    TASK_ERRORS["$task_id"]=""
    TASK_DETAILS["$task_id"]="$task_name"
    TASK_OUTPUT["$task_id"]=""
    TASK_ORDER+=("$task_id")

    return 0
}

# Function: get_task_count
#   Task count (stdout)
get_task_count() {
    echo "${#TASK_ORDER[@]}"
}

# Function: get_task_ids
#   Task IDs, one per line (stdout)
get_task_ids() {
    for task_id in "${TASK_ORDER[@]}"; do
        echo "$task_id"
    done
}

# ============================================================================
# STATUS UPDATES
# ============================================================================

# Function: update_task_status
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    local optional_data="${3:-}"

    # Verify task exists
    if [[ -z "${TASK_STATUS[$task_id]:-}" ]]; then
        echo "ERROR: Unknown task: $task_id" >&2
        return 1
    fi

    TASK_STATUS["$task_id"]="$new_status"

    case "$new_status" in
        success)
            TASK_TIMES["$task_id"]="$optional_data"
            ;;
        failed)
            TASK_ERRORS["$task_id"]="$optional_data"
            ;;
    esac

    return 0
}

# Function: start_task
start_task() {
    local task_id="$1"
    update_task_status "$task_id" "running"
}

# Function: complete_task
complete_task() {
    local task_id="$1"
    local duration="${2:-0}"
    update_task_status "$task_id" "success" "$duration"
}

# Function: fail_task
fail_task() {
    local task_id="$1"
    local error_msg="${2:-Unknown error}"
    update_task_status "$task_id" "failed" "$error_msg"
}

# Function: skip_task
skip_task() {
    local task_id="$1"
    local reason="${2:-already installed}"
    update_task_status "$task_id" "skipped"
}

# ============================================================================
# STATE QUERIES
# ============================================================================

# Function: get_task_status
#   Status string (stdout)
get_task_status() {
    local task_id="$1"
    echo "${TASK_STATUS[$task_id]:-unknown}"
}

# Function: get_task_name
#   Task name (stdout)
get_task_name() {
    local task_id="$1"
    echo "${TASK_DETAILS[$task_id]:-$task_id}"
}

# Function: get_task_duration
#   Duration in seconds (stdout)
get_task_duration() {
    local task_id="$1"
    echo "${TASK_TIMES[$task_id]:-0}"
}

# Function: get_task_error
#   Error message (stdout)
get_task_error() {
    local task_id="$1"
    echo "${TASK_ERRORS[$task_id]:-}"
}

# Function: get_task_output
#   Buffered output (stdout)
get_task_output() {
    local task_id="$1"
    echo "${TASK_OUTPUT[$task_id]:-}"
}

# Function: set_task_output
set_task_output() {
    local task_id="$1"
    local output="$2"
    TASK_OUTPUT["$task_id"]="$output"
}

# ============================================================================
# SUMMARY FUNCTIONS
# ============================================================================

# Function: get_status_counts
#   JSON-formatted counts (stdout)
get_status_counts() {
    local pending=0 running=0 success=0 failed=0 skipped=0

    for task_id in "${TASK_ORDER[@]}"; do
        case "${TASK_STATUS[$task_id]}" in
            pending) ((pending++)) ;;
            running) ((running++)) ;;
            success) ((success++)) ;;
            failed)  ((failed++)) ;;
            skipped) ((skipped++)) ;;
        esac
    done

    cat <<EOF
{
  "pending": $pending,
  "running": $running,
  "success": $success,
  "failed": $failed,
  "skipped": $skipped,
  "total": ${#TASK_ORDER[@]}
}
EOF
}

# Function: all_tasks_complete
all_tasks_complete() {
    for task_id in "${TASK_ORDER[@]}"; do
        case "${TASK_STATUS[$task_id]}" in
            pending|running) return 1 ;;
        esac
    done
    return 0
}

# Function: any_tasks_failed
any_tasks_failed() {
    for task_id in "${TASK_ORDER[@]}"; do
        [[ "${TASK_STATUS[$task_id]}" == "failed" ]] && return 0
    done
    return 1
}

# Function: reset_task_state
reset_task_state() {
    TASK_STATUS=()
    TASK_TIMES=()
    TASK_ERRORS=()
    TASK_DETAILS=()
    TASK_OUTPUT=()
    TASK_ORDER=()
    return 0
}
