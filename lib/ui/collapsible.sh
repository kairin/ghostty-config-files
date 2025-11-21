#!/usr/bin/env bash
#
# lib/ui/collapsible.sh - Docker-like progressive summarization with collapsible output
#
# Provides Docker-style installation output with collapsible task display:
# - Tasks collapse to single line when complete
# - Errors auto-expand with recovery suggestions
# - Real-time task status updates (pending, running, success, failed, skipped)
# - ANSI cursor management for in-place updates
# - Verbose mode toggle (T033 integrated)
#
# CURRENT STATUS (2025-11-20):
# - Output capture functions added: run_command_collapsible(), show_task_output()
# - Collapsible rendering re-enabled (was temporarily disabled)
# - VERBOSE_MODE=true by default (shows all output in real-time)
#
# TODO FOR FULL COLLAPSIBLE UI:
# 1. Update all lib/tasks/*.sh modules to use run_command_collapsible()
#    - ghostty.sh: git clone, zig build, tar extraction
#    - python_uv.sh: curl downloads, tar extraction
#    - nodejs_fnm.sh: downloads and extractions
#    - zsh.sh: oh-my-zsh installation, plugin downloads
#    - ai_tools.sh: npm install commands
# 2. Add proper output buffering for parallel tasks
# 3. Implement task output expansion on failure
# 4. Test with VERBOSE_MODE=false for Docker-like collapsed output
# 5. Add keyboard shortcut to toggle verbose mode during installation
#
# Task States:
#   pending   → "⏸ Task name (queued)"
#   running   → "⠋ Task name..." (with spinner animation)
#   success   → "✓ Task name (duration)"
#   failed    → "✗ Task name (FAILED)" + expanded error details
#   skipped   → "↷ Task name (already installed)"
#
# Verbose Mode (T033):
#   - Default: Collapsed output (Docker-like)
#   - --verbose flag: Show full output for all tasks
#   - 'v' key toggle during execution (if terminal supports input)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Clean, professional output like Docker build
# - Graceful degradation if ANSI not supported
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${COLLAPSIBLE_SH_LOADED:-}" ] || return 0
COLLAPSIBLE_SH_LOADED=1

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

# Global state tracking
# Global state tracking
declare -gA TASK_STATUS      # task_id => status (pending/running/success/failed/skipped)
declare -gA TASK_TIMES       # task_id => duration in seconds
declare -gA TASK_ERRORS      # task_id => error message
declare -gA TASK_DETAILS     # task_id => task name
declare -gA TASK_OUTPUT      # task_id => buffered command output
declare -ga TASK_ORDER       # Array of task IDs in execution order

# Verbose mode (T033)
# DEFAULT: VERBOSE_MODE=false for Docker-like collapsed terminal output
# CRITICAL: Full verbose logs ALWAYS captured to log files regardless of this setting
# Users can enable full terminal output with --verbose flag
VERBOSE_MODE=${VERBOSE_MODE:-false}  # Can be set via --verbose flag

# ANSI cursor control
readonly ANSI_SAVE_CURSOR="\033[s"
readonly ANSI_RESTORE_CURSOR="\033[u"
readonly ANSI_CLEAR_LINE="\033[2K"
readonly ANSI_MOVE_UP="\033[1A"
readonly ANSI_MOVE_DOWN="\033[1B"
readonly ANSI_HIDE_CURSOR="\033[?25l"
readonly ANSI_SHOW_CURSOR="\033[?25h"

# Spinner characters (for running tasks)
readonly SPINNER_CHARS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_INDEX=0

# Display constants
readonly STATUS_PENDING="⏸"
readonly STATUS_RUNNING="⠋"
readonly STATUS_SUCCESS="✓"
readonly STATUS_FAILED="✗"
readonly STATUS_SKIPPED="↷"

#
# Initialize collapsible output system
#
# Sets up terminal for collapsible display
#
init_collapsible_output() {
    # Hide cursor for cleaner output
    if [ -t 1 ] && [ "$VERBOSE_MODE" = false ]; then
        echo -ne "$ANSI_HIDE_CURSOR"
    fi

    log "INFO" "Initialized collapsible output system (verbose: $VERBOSE_MODE)"
}

#
# Cleanup collapsible output system
#
# Restores terminal state
#
cleanup_collapsible_output() {
    # Show cursor
    if [ -t 1 ]; then
        echo -ne "$ANSI_SHOW_CURSOR"
    fi
}

#
# Register a new task
#
# Args:
#   $1 - Task ID (unique identifier, e.g., "install-ghostty")
#   $2 - Task name (display name, e.g., "Installing Ghostty Terminal")
#
register_task() {
    local task_id="$1"
    local task_name="$2"

    TASK_STATUS["$task_id"]="pending"
    TASK_TIMES["$task_id"]=0
    TASK_ERRORS["$task_id"]=""
    TASK_DETAILS["$task_id"]="$task_name"
    TASK_OUTPUT["$task_id"]=""
    TASK_ORDER+=("$task_id")

    log "INFO" "Registered task: $task_id ($task_name)"
}

#
# Run command with collapsible output
#
# Executes a command while capturing output for the collapsible UI.
# CRITICAL: ALWAYS logs full output to verbose log file regardless of VERBOSE_MODE.
# In verbose mode, shows output in real-time. In collapsed mode, shows only status.
#
# Args:
#   $1 - Task ID
#   $2+ - Command and arguments to execute
#
# Returns:
#   Command exit code
#
# Dual-Mode Behavior:
#   - VERBOSE_MODE=true: Show full output to terminal + log to files
#   - VERBOSE_MODE=false: Show collapsed status + log full output to files
#
# Constitutional Compliance:
#   - User Requirement: "all logs captured in full, extremely verbose regardless"
#   - Dual-mode output: Terminal (collapsed) + Log files (full verbose)
#
# Example:
#   run_command_collapsible "install-ghostty" git clone https://github.com/ghostty-org/ghostty
#
run_command_collapsible() {
    local task_id="$1"
    shift
    local cmd=("$@")

    # Capture output to variable (for both terminal and logs)
    local output
    local exit_code=0
    local output_file
    output_file=$(mktemp)

    # Execute command with output capture
    if "${cmd[@]}" > "$output_file" 2>&1; then
        exit_code=0
    else
        exit_code=$?
    fi

    # Read captured output
    output=$(cat "$output_file")

    # ALWAYS log full output to verbose log file (regardless of VERBOSE_MODE)
    log_command_output "$task_id: ${cmd[*]}" "$output"

    # Terminal display depends on VERBOSE_MODE
    if [ "$VERBOSE_MODE" = true ]; then
        # Show full output to terminal
        echo "$output"
    else
        # Show only collapsed summary (Docker-like)
        # Output already logged to verbose file, just show status via task rendering
        :
    fi

    # Store output in task buffer (for expansion on failure)
    TASK_OUTPUT["$task_id"]="$output"

    # Also append to human-readable log file
    echo "$output" >> "$(get_log_file)"

    # Cleanup
    rm -f "$output_file"

    return $exit_code
}

#
# Show task output (expand collapsed task)
#
# Args:
#   $1 - Task ID
#
show_task_output() {
    local task_id="$1"

    if [ -n "${TASK_OUTPUT[$task_id]:-}" ]; then
        echo "${TASK_OUTPUT[$task_id]}"
    fi
}

#
# Update task status
#
# Args:
#   $1 - Task ID
#   $2 - New status (pending/running/success/failed/skipped)
#   $3 - Optional: duration (for success) or error message (for failed)
#
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    local optional_data="${3:-}"

    TASK_STATUS["$task_id"]="$new_status"

    case "$new_status" in
        success)
            TASK_TIMES["$task_id"]="$optional_data"
            ;;
        failed)
            TASK_ERRORS["$task_id"]="$optional_data"
            ;;
    esac

    # Refresh display
    render_all_tasks
}

#
# Get status symbol for task
#
# Args:
#   $1 - Task status
#
# Returns:
#   Status symbol (⏸/⠋/✓/✗/↷)
#
get_status_symbol() {
    local status="$1"

    case "$status" in
        pending)  echo "$STATUS_PENDING" ;;
        running)  echo "${SPINNER_CHARS[$SPINNER_INDEX]}" ;;
        success)  echo "$STATUS_SUCCESS" ;;
        failed)   echo "$STATUS_FAILED" ;;
        skipped)  echo "$STATUS_SKIPPED" ;;
        *)        echo "?" ;;
    esac
}

#
# Render single task line
#
# Args:
#   $1 - Task ID
#
# Returns:
#   Formatted task line
#
render_task_line() {
    # Skip in verbose mode (safety check - should be caught by render_all_tasks)
    if [ "$VERBOSE_MODE" = true ]; then
        return 0
    fi

    local task_id="$1"
    local status="${TASK_STATUS[$task_id]}"
    local task_name="${TASK_DETAILS[$task_id]}"
    local duration="${TASK_TIMES[$task_id]}"
    local error="${TASK_ERRORS[$task_id]}"

    local symbol
    symbol=$(get_status_symbol "$status")

    local line="$symbol $task_name"

    case "$status" in
        pending)
            line="$line (queued)"
            ;;
        running)
            line="$line..."
            ;;
        success)
            if [ "$duration" -gt 0 ]; then
                line="$line ($(format_duration "$duration"))"
            else
                line="$line (skipped)"
            fi
            ;;
        failed)
            line="$line (FAILED)"
            ;;
        skipped)
            line="$line (already installed)"
            ;;
    esac

    echo "$line"
}

#
# Render all tasks (collapsible view)
#
# Displays all registered tasks with their current status
# - Completed tasks: Single collapsed line
# - Running task: Single line with spinner
# - Failed task: Expanded with error details
#
render_all_tasks() {
    # Skip rendering in verbose mode (full output shown)
    if [ "$VERBOSE_MODE" = true ]; then
        return 0
    fi

    # Skip if not interactive terminal
    if [ ! -t 1 ]; then
        return 0
    fi

    # Clear screen area for tasks
    local task_count=${#TASK_ORDER[@]}

    # Move cursor up to start of task list
    for (( i=0; i<task_count; i++ )); do
        echo -ne "$ANSI_MOVE_UP"
    done

    # Render each task
    for task_id in "${TASK_ORDER[@]}"; do
        echo -ne "$ANSI_CLEAR_LINE"
        render_task_line "$task_id"
        echo ""  # Newline

        # Auto-expand failed tasks with error details
        if [ "${TASK_STATUS[$task_id]}" = "failed" ] && [ -n "${TASK_ERRORS[$task_id]}" ]; then
            echo "  Error: ${TASK_ERRORS[$task_id]}"
            echo ""
        fi
    done
}

#
# Start task (set to running state)
#
# Args:
#   $1 - Task ID
#
start_task() {
    local task_id="$1"

    update_task_status "$task_id" "running"
    log "INFO" "Started task: $task_id"
}

#
# Complete task successfully
#
# Args:
#   $1 - Task ID
#   $2 - Duration in seconds
#
complete_task() {
    local task_id="$1"
    local duration="${2:-0}"

    update_task_status "$task_id" "success" "$duration"
    log "INFO" "Completed task: $task_id ($(format_duration "$duration"))"
}

#
# Mark task as failed
#
# Args:
#   $1 - Task ID
#   $2 - Error message
#
fail_task() {
    local task_id="$1"
    local error_msg="${2:-Unknown error}"

    update_task_status "$task_id" "failed" "$error_msg"
    log "ERROR" "Failed task: $task_id - $error_msg"
}

#
# Mark task as skipped
#
# Args:
#   $1 - Task ID
#
skip_task() {
    local task_id="$1"

    update_task_status "$task_id" "skipped"
    log "INFO" "Skipped task: $task_id (already installed)"
}

#
# Spinner animation update
#
# Updates spinner character for running tasks
#
update_spinner() {
    SPINNER_INDEX=$(( (SPINNER_INDEX + 1) % ${#SPINNER_CHARS[@]} ))

    # Re-render tasks to update spinner
    render_all_tasks
}

#
# Start spinner loop (background)
#
# Starts background process to update spinner every 100ms
#
# Returns:
#   PID of spinner process
#
start_spinner_loop() {
    if [ "$VERBOSE_MODE" = true ]; then
        return 0
    fi

    (
        while true; do
            update_spinner
            sleep 0.1
        done
    ) &

    echo $!  # Return PID
}

#
# Stop spinner loop
#
# Args:
#   $1 - Spinner PID
#
stop_spinner_loop() {
    local spinner_pid="$1"

    if [ -n "$spinner_pid" ] && kill -0 "$spinner_pid" 2>/dev/null; then
        kill "$spinner_pid" 2>/dev/null || true
    fi
}

#
# Toggle verbose mode (T033)
#
# Switches between collapsed and expanded output
#
toggle_verbose_mode() {
    if [ "$VERBOSE_MODE" = true ]; then
        VERBOSE_MODE=false
        log "INFO" "Verbose mode: OFF (collapsed output)"
        echo -ne "$ANSI_HIDE_CURSOR"
    else
        VERBOSE_MODE=true
        log "INFO" "Verbose mode: ON (full output)"
        echo -ne "$ANSI_SHOW_CURSOR"
    fi
}

#
# Enable verbose mode
#
# Sets VERBOSE_MODE=true (typically from --verbose flag)
#
enable_verbose_mode() {
    VERBOSE_MODE=true
    log "INFO" "Verbose mode enabled (full output)"
}

#
# Disable verbose mode
#
# Sets VERBOSE_MODE=false (collapsed Docker-like output)
#
disable_verbose_mode() {
    VERBOSE_MODE=false
    log "INFO" "Verbose mode disabled (collapsed output)"
}

#
# Check if verbose mode is enabled
#
# Returns:
#   0 = verbose mode ON
#   1 = verbose mode OFF
#
is_verbose_mode() {
    [ "$VERBOSE_MODE" = true ]
}

#
# Example usage demonstration
#
# Shows how to use collapsible output system
#
demo_collapsible_output() {
    init_collapsible_output

    # Register tasks
    register_task "task-1" "Installing component A"
    register_task "task-2" "Installing component B"
    register_task "task-3" "Installing component C"
    register_task "task-4" "Installing component D (will fail)"
    register_task "task-5" "Installing component E"

    # Initial render (all pending)
    render_all_tasks

    # Start spinner
    local spinner_pid
    spinner_pid=$(start_spinner_loop)

    # Simulate task execution
    sleep 1
    start_task "task-1"
    sleep 2
    complete_task "task-1" 2

    sleep 1
    start_task "task-2"
    sleep 1
    skip_task "task-2"

    sleep 1
    start_task "task-3"
    sleep 2
    complete_task "task-3" 2

    sleep 1
    start_task "task-4"
    sleep 1
    fail_task "task-4" "Network timeout - check internet connection"

    sleep 1
    start_task "task-5"
    sleep 2
    complete_task "task-5" 2

    # Stop spinner
    stop_spinner_loop "$spinner_pid"

    # Cleanup
    cleanup_collapsible_output

    log "INFO" "Demo complete"
}

# Export functions
export -f init_collapsible_output
export -f cleanup_collapsible_output
export -f register_task
export -f run_command_collapsible
export -f show_task_output
export -f update_task_status
export -f get_status_symbol
export -f render_task_line
export -f render_all_tasks
export -f start_task
export -f complete_task
export -f fail_task
export -f skip_task
export -f update_spinner
export -f start_spinner_loop
export -f stop_spinner_loop
export -f toggle_verbose_mode
export -f enable_verbose_mode
export -f disable_verbose_mode
export -f is_verbose_mode
export -f demo_collapsible_output
