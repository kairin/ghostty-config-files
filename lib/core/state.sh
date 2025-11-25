#!/usr/bin/env bash
#
# lib/core/state.sh - State persistence for resume capability
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices from bash JSON state management patterns 2025
# - JSON state file for installation tracking
# - Resume capability after interruption
# - Idempotency detection (skip completed tasks)
# - System information capture
# - jq for JSON processing
#
# Constitutional Compliance: Principle IX - Idempotency
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${STATE_SH_LOADED:-}" ] || return 0
STATE_SH_LOADED=1

# Source logging module (SCRIPT_DIR set by orchestrator)
# NOTE: SCRIPT_DIR points to repository root, not lib/core/
STATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${STATE_LIB_DIR}/logging.sh"

# State file path
STATE_FILE="/tmp/ghostty-start-logs/installation-state.json"

# Current state (loaded into memory)
# Initialize associative arrays (required for set -u with empty arrays)
declare -A STATE_COMPLETED_TASKS=()
declare -A STATE_FAILED_TASKS=()
STATE_VERSION="2.0"
STATE_LAST_RUN=""

#
# Initialize state management system
#
# Creates state file if missing, loads existing state
#
# Usage: init_state
#
init_state() {
    local log_dir
    log_dir=$(dirname "$STATE_FILE")

    # Create directory if missing
    mkdir -p "$log_dir"

    # If state file exists, load it
    if [ -f "$STATE_FILE" ]; then
        log "INFO" "Loading existing installation state from $STATE_FILE"
        load_state
    else
        log "INFO" "Initializing new installation state"
        create_initial_state
    fi
}

#
# Create initial state file
#
create_initial_state() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Capture system information
    local hostname
    local os_name
    local os_version
    local kernel
    local architecture

    hostname=$(hostname)
    os_name=$(lsb_release -si 2>/dev/null || echo "Unknown")
    os_version=$(lsb_release -sr 2>/dev/null || echo "Unknown")
    kernel=$(uname -r)
    architecture=$(uname -m)

    # Create initial state JSON
    cat > "$STATE_FILE" <<EOF
{
  "version": "$STATE_VERSION",
  "last_run": "$timestamp",
  "completed_tasks": [],
  "failed_tasks": [],
  "system_info": {
    "hostname": "$hostname",
    "os_name": "$os_name",
    "os_version": "$os_version",
    "kernel": "$kernel",
    "architecture": "$architecture"
  },
  "performance": {
    "total_duration": 0,
    "task_durations": {}
  }
}
EOF

    log "SUCCESS" "Created initial state file: $STATE_FILE"
}

#
# Load state from JSON file into memory
#
load_state() {
    if [ ! -f "$STATE_FILE" ]; then
        log "WARNING" "State file not found: $STATE_FILE"
        return 1
    fi

    # Validate JSON
    if ! jq empty "$STATE_FILE" 2>/dev/null; then
        log "ERROR" "Invalid JSON in state file: $STATE_FILE"
        return 1
    fi

    # Temporarily disable strict mode for array operations
    set +u

    # Load completed tasks into associative array
    while IFS= read -r task_id; do
        STATE_COMPLETED_TASKS["$task_id"]=1
    done < <(jq -r '.completed_tasks[]' "$STATE_FILE")

    # Load failed tasks with error messages
    while IFS='|' read -r task_id error_message; do
        STATE_FAILED_TASKS["$task_id"]="$error_message"
    done < <(jq -r '.failed_tasks[] | "\(.task_id)|\(.error_message)"' "$STATE_FILE" 2>/dev/null || true)

    set -u

    # Load last run timestamp
    STATE_LAST_RUN=$(jq -r '.last_run' "$STATE_FILE")

    # Count tasks (safe for empty arrays with set -u)
    local completed_count=0
    local failed_count=0
    # Only count if arrays exist and have elements
    if [ -v STATE_COMPLETED_TASKS ]; then
        completed_count="${#STATE_COMPLETED_TASKS[@]}"
    fi
    if [ -v STATE_FAILED_TASKS ]; then
        failed_count="${#STATE_FAILED_TASKS[@]}"
    fi

    log "SUCCESS" "Loaded state: $completed_count completed, $failed_count failed"
}

#
# Save current state to JSON file
#
save_state() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Temporarily disable strict mode for array operations
    set +u

    # Build completed tasks array
    local completed_json
    completed_json="["
    for task_id in "${!STATE_COMPLETED_TASKS[@]}"; do
        completed_json+="\"$task_id\","
    done
    completed_json="${completed_json%,}]"  # Remove trailing comma

    # Build failed tasks array
    local failed_json
    failed_json="["
    for task_id in "${!STATE_FAILED_TASKS[@]}"; do
        local error_message="${STATE_FAILED_TASKS[$task_id]}"
        # Escape for JSON
        local escaped_error
        escaped_error=$(printf '%s' "$error_message" | jq -Rs .)
        failed_json+="{\"task_id\":\"$task_id\",\"error_message\":$escaped_error},"
    done
    failed_json="${failed_json%,}]"  # Remove trailing comma

    set -u

    # Preserve system info and performance from existing state
    local system_info
    local performance
    system_info=$(jq -c '.system_info' "$STATE_FILE" 2>/dev/null || echo '{}')
    performance=$(jq -c '.performance' "$STATE_FILE" 2>/dev/null || echo '{"total_duration":0,"task_durations":{}}')

    # Write updated state
    cat > "$STATE_FILE" <<EOF
{
  "version": "$STATE_VERSION",
  "last_run": "$timestamp",
  "completed_tasks": $completed_json,
  "failed_tasks": $failed_json,
  "system_info": $system_info,
  "performance": $performance
}
EOF

    # Count tasks (safe for empty arrays with set -u)
    local completed_count=0
    local failed_count=0
    # Only count if arrays exist and have elements
    if [ -v STATE_COMPLETED_TASKS ]; then
        completed_count="${#STATE_COMPLETED_TASKS[@]}"
    fi
    if [ -v STATE_FAILED_TASKS ]; then
        failed_count="${#STATE_FAILED_TASKS[@]}"
    fi

    log "INFO" "State saved: $completed_count completed, $failed_count failed"
}

#
# Check if a task has been completed
#
# Arguments:
#   $1 - Task ID
#
# Returns:
#   0 if task completed, 1 if not completed
#
# Usage:
#   if is_task_completed "install-ghostty"; then
#       echo "Ghostty already installed"
#   fi
#
is_task_completed() {
    local task_id="${1:-}"

    # Return false if no task ID provided
    [ -z "$task_id" ] && return 1

    # Temporarily disable strict mode for this check (set -u causes issues with unset array keys)
    set +u
    local result=1
    if [[ -n "${STATE_COMPLETED_TASKS[$task_id]:-}" ]]; then
        result=0
    fi
    set -u

    return $result
}

#
# Mark a task as completed
#
# Arguments:
#   $1 - Task ID
#   $2 - Duration in seconds (optional)
#
# Usage:
#   mark_task_completed "install-ghostty" 45
#
mark_task_completed() {
    local task_id="$1"
    local duration="${2:-0}"

    # Temporarily disable strict mode for array operations
    set +u

    # Add to completed tasks
    STATE_COMPLETED_TASKS["$task_id"]=1

    # Remove from failed tasks if present
    unset "STATE_FAILED_TASKS[$task_id]"

    set -u

    # Update performance metrics
    update_task_duration "$task_id" "$duration"

    # Save state
    save_state

    log "SUCCESS" "Marked task '$task_id' as completed (duration: ${duration}s)"
}

#
# Mark a task as failed
#
# Arguments:
#   $1 - Task ID
#   $2 - Error message
#
# Usage:
#   mark_task_failed "install-ghostty" "Build failed: Zig compiler not found"
#
mark_task_failed() {
    local task_id="$1"
    local error_message="$2"

    # Temporarily disable strict mode for array operations
    set +u

    # Add to failed tasks
    STATE_FAILED_TASKS["$task_id"]="$error_message"

    # Remove from completed tasks if present
    unset "STATE_COMPLETED_TASKS[$task_id]"

    set -u

    # Save state
    save_state

    log "ERROR" "Marked task '$task_id' as failed: $error_message"
}

#
# Update task duration in performance metrics
#
# Arguments:
#   $1 - Task ID
#   $2 - Duration in seconds
#
update_task_duration() {
    local task_id="$1"
    local duration="$2"

    # Update task duration using jq
    jq --arg task_id "$task_id" --argjson duration "$duration" \
        '.performance.task_durations[$task_id] = $duration' \
        "$STATE_FILE" > "${STATE_FILE}.tmp"

    mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

#
# Resume installation from last checkpoint
#
# Loads state and returns list of tasks to skip
#
# Returns:
#   List of completed task IDs (one per line)
#
# Usage:
#   while IFS= read -r completed_task; do
#       echo "Skipping: $completed_task"
#   done < <(resume_installation)
#
resume_installation() {
    load_state

    # Temporarily disable strict mode for array operations
    set +u

    log "INFO" "Resume mode: ${#STATE_COMPLETED_TASKS[@]} tasks already completed"

    # Output completed task IDs
    for task_id in "${!STATE_COMPLETED_TASKS[@]}"; do
        echo "$task_id"
    done

    set -u
}

#
# Clear all state (fresh start)
#
# Usage: clear_state
#
clear_state() {
    log "WARNING" "Clearing installation state"

    STATE_COMPLETED_TASKS=()
    STATE_FAILED_TASKS=()

    create_initial_state

    log "SUCCESS" "State cleared - fresh installation mode"
}

#
# Get state summary
#
# Returns JSON summary of current state
#
get_state_summary() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "{}"
        return
    fi

    jq -c '{
        version: .version,
        last_run: .last_run,
        completed_count: (.completed_tasks | length),
        failed_count: (.failed_tasks | length),
        total_duration: .performance.total_duration
    }' "$STATE_FILE"
}

# Export functions for use in other modules
export -f init_state
export -f create_initial_state
export -f load_state
export -f save_state
export -f is_task_completed
export -f mark_task_completed
export -f mark_task_failed
export -f update_task_duration
export -f resume_installation
export -f clear_state
export -f get_state_summary
