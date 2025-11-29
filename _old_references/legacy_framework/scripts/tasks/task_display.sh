#!/bin/bash
# Module: task_display.sh
# Purpose: Parallel task UI with collapsible verbose output
# Dependencies: common.sh, progress.sh
# Exit Codes: 0=success, 1=display failed

set -euo pipefail

# Prevent multiple sourcing
[[ -n "${TASK_DISPLAY_SH_LOADED:-}" ]] && return 0
readonly TASK_DISPLAY_SH_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/progress.sh"

# ============================================================
# CONFIGURATION
# ============================================================

# Terminal capability detection
TERM_WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
TERM_ANSI_SUPPORT=1

# Detect ANSI support
if [[ ! -t 1 ]] || [[ "${TERM:-}" == "dumb" ]] || [[ "${NO_COLOR:-0}" == "1" ]]; then
    TERM_ANSI_SUPPORT=0
fi

# ANSI escape codes (only if supported)
if [[ $TERM_ANSI_SUPPORT -eq 1 ]]; then
    readonly ANSI_CLEAR_LINE="\033[2K"
    readonly ANSI_MOVE_UP="\033[1A"
    readonly ANSI_SAVE_CURSOR="\033[s"
    readonly ANSI_RESTORE_CURSOR="\033[u"
    readonly ANSI_HIDE_CURSOR="\033[?25l"
    readonly ANSI_SHOW_CURSOR="\033[?25h"
else
    readonly ANSI_CLEAR_LINE=""
    readonly ANSI_MOVE_UP=""
    readonly ANSI_SAVE_CURSOR=""
    readonly ANSI_RESTORE_CURSOR=""
    readonly ANSI_HIDE_CURSOR=""
    readonly ANSI_SHOW_CURSOR=""
fi

# Display symbols (ANSI vs ASCII fallback)
if [[ $TERM_ANSI_SUPPORT -eq 1 ]]; then
    readonly SYMBOL_PENDING="○"
    readonly SYMBOL_RUNNING="⠋"
    readonly SYMBOL_SUCCESS="✓"
    readonly SYMBOL_FAILED="✗"
    readonly SYMBOL_COLLAPSED="[+]"
    readonly SYMBOL_EXPANDED="[-]"
else
    readonly SYMBOL_PENDING="[ ]"
    readonly SYMBOL_RUNNING="[~]"
    readonly SYMBOL_SUCCESS="[✓]"
    readonly SYMBOL_FAILED="[X]"
    readonly SYMBOL_COLLAPSED="[+]"
    readonly SYMBOL_EXPANDED="[-]"
fi

# Auto-collapse delay (seconds) - disable for testing with TASK_DISPLAY_NO_AUTO_COLLAPSE=1
readonly AUTO_COLLAPSE_DELAY="${TASK_DISPLAY_AUTO_COLLAPSE_DELAY:-10}"

# Maximum concurrent tasks displayed
readonly MAX_PARALLEL_TASKS=4

# ============================================================
# STATE MANAGEMENT
# ============================================================

# Task state storage
declare -A TASK_IDS=()          # task_id -> display order
declare -A TASK_STATUS=()       # task_id -> status (pending|running|completed|failed)
declare -A TASK_DESCRIPTION=()  # task_id -> description text
declare -A TASK_START_TIME=()   # task_id -> start timestamp (nanoseconds)
declare -A TASK_END_TIME=()     # task_id -> end timestamp (nanoseconds)
declare -A TASK_COLLAPSED=()    # task_id -> collapsed state (0=expanded, 1=collapsed)
declare -A TASK_OUTPUT=()       # task_id -> verbose output buffer
declare -A TASK_RENDER_COUNT=() # task_id -> number of times rendered

# Global display state
DISPLAY_ENABLED=1
TOTAL_TASKS=0
LAST_RENDER_TIME=0

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: init_task_display
# Purpose: Initialize task display system
# Args: None
# Returns: 0 on success
# Side Effects: Sets up terminal for task display
init_task_display() {
    log_debug "Initializing task display system"

    # Detect terminal width
    TERM_WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}

    # Hide cursor for cleaner display
    if [[ $TERM_ANSI_SUPPORT -eq 1 ]]; then
        echo -ne "${ANSI_HIDE_CURSOR}"
    fi

    # Set up cleanup trap
    trap 'cleanup_task_display' EXIT INT TERM

    return 0
}

# Function: cleanup_task_display
# Purpose: Clean up task display on exit
# Args: None
# Returns: 0 always
# Side Effects: Restores cursor, cleans up state
cleanup_task_display() {
    # Show cursor
    if [[ $TERM_ANSI_SUPPORT -eq 1 ]]; then
        echo -ne "${ANSI_SHOW_CURSOR}"
    fi

    return 0
}

# Function: register_task
# Purpose: Register a new task for display
# Args: $1=task_id, $2=description
# Returns: 0 on success, 1 if task exists
# Side Effects: Adds task to tracking arrays
register_task() {
    local task_id="$1"
    local description="$2"

    if [[ -z "$task_id" ]] || [[ -z "$description" ]]; then
        log_error "register_task: task_id and description required"
        return 1
    fi

    if [[ -n "${TASK_STATUS[$task_id]:-}" ]]; then
        log_warn "Task '$task_id' already registered"
        return 1
    fi

    # Initialize task state
    TOTAL_TASKS=$((TOTAL_TASKS + 1))
    TASK_IDS[$task_id]=$TOTAL_TASKS
    TASK_STATUS[$task_id]="pending"
    TASK_DESCRIPTION[$task_id]="$description"
    TASK_COLLAPSED[$task_id]=1  # Start collapsed
    TASK_OUTPUT[$task_id]=""
    TASK_RENDER_COUNT[$task_id]=0

    log_debug "Registered task: $task_id ($description)"
    return 0
}

# Function: start_task
# Purpose: Mark task as running
# Args: $1=task_id
# Returns: 0 on success, 1 if task not found
# Side Effects: Updates task status, records start time
start_task() {
    local task_id="$1"

    if [[ -z "${TASK_STATUS[$task_id]:-}" ]]; then
        log_error "Task '$task_id' not registered"
        return 1
    fi

    TASK_STATUS[$task_id]="running"
    TASK_START_TIME[$task_id]=$(date +%s%N)
    TASK_COLLAPSED[$task_id]=0  # Expand when running

    log_debug "Started task: $task_id"
    render_display

    return 0
}

# Function: complete_task
# Purpose: Mark task as completed
# Args: $1=task_id, $2=status (success|failed), $3=output (optional)
# Returns: 0 on success, 1 if task not found
# Side Effects: Updates task status, schedules auto-collapse
complete_task() {
    local task_id="$1"
    local status="$2"
    local output="${3:-}"

    if [[ -z "${TASK_STATUS[$task_id]:-}" ]]; then
        log_error "Task '$task_id' not registered"
        return 1
    fi

    # Validate status
    if [[ "$status" != "success" ]] && [[ "$status" != "failed" ]]; then
        log_error "Invalid status: $status (must be 'success' or 'failed')"
        return 1
    fi

    # Update task state
    if [[ "$status" == "success" ]]; then
        TASK_STATUS[$task_id]="completed"
        TASK_COLLAPSED[$task_id]=1  # Auto-collapse on success
    else
        TASK_STATUS[$task_id]="failed"
        TASK_COLLAPSED[$task_id]=0  # Expand on failure
    fi

    TASK_END_TIME[$task_id]=$(date +%s%N)
    TASK_OUTPUT[$task_id]="$output"

    log_debug "Completed task: $task_id (status=$status)"
    render_display

    # Schedule auto-collapse for successful tasks (unless disabled)
    if [[ "$status" == "success" ]] && [[ "${TASK_DISPLAY_NO_AUTO_COLLAPSE:-0}" != "1" ]]; then
        (
            sleep "$AUTO_COLLAPSE_DELAY"
            if [[ "${TASK_STATUS[$task_id]:-}" == "completed" ]]; then
                TASK_COLLAPSED[$task_id]=1
                render_display
            fi
        ) &
    fi

    return 0
}

# Function: get_task_duration
# Purpose: Calculate task duration
# Args: $1=task_id
# Returns: Duration string (e.g., "2.5s", "1m 30s")
# Side Effects: None
get_task_duration() {
    local task_id="$1"

    local start_time="${TASK_START_TIME[$task_id]:-}"
    local end_time="${TASK_END_TIME[$task_id]:-}"

    if [[ -z "$start_time" ]]; then
        echo "N/A"
        return 0
    fi

    # Use current time if still running
    if [[ -z "$end_time" ]]; then
        end_time=$(date +%s%N)
    fi

    # Calculate duration in milliseconds
    local duration_ns=$((end_time - start_time))
    local duration_ms=$((duration_ns / 1000000))

    # Format based on magnitude
    if [[ $duration_ms -lt 1000 ]]; then
        echo "${duration_ms}ms"
    elif [[ $duration_ms -lt 60000 ]]; then
        local seconds=$((duration_ms / 1000))
        local ms=$((duration_ms % 1000))
        printf "%d.%01ds" "$seconds" "$((ms / 100))"
    else
        local total_seconds=$((duration_ms / 1000))
        local minutes=$((total_seconds / 60))
        local seconds=$((total_seconds % 60))
        printf "%dm %02ds" "$minutes" "$seconds"
    fi
}

# Function: render_task_line
# Purpose: Render single task status line
# Args: $1=task_id
# Returns: Formatted task line (stdout)
# Side Effects: None
render_task_line() {
    local task_id="$1"

    local status="${TASK_STATUS[$task_id]}"
    local description="${TASK_DESCRIPTION[$task_id]}"
    local duration
    duration=$(get_task_duration "$task_id")

    # Select symbol and color based on status
    local symbol color_code
    case "$status" in
        pending)
            symbol="$SYMBOL_PENDING"
            color_code="${COLOR_BLUE:-}"
            ;;
        running)
            symbol="$SYMBOL_RUNNING"
            color_code="${COLOR_CYAN:-}"
            ;;
        completed)
            symbol="$SYMBOL_SUCCESS"
            color_code="${COLOR_GREEN:-}"
            ;;
        failed)
            symbol="$SYMBOL_FAILED"
            color_code="${COLOR_RED:-}"
            ;;
        *)
            symbol="?"
            color_code=""
            ;;
    esac

    # Collapse indicator
    local collapse_indicator=""
    if [[ -n "${TASK_OUTPUT[$task_id]:-}" ]]; then
        if [[ ${TASK_COLLAPSED[$task_id]} -eq 1 ]]; then
            collapse_indicator="$SYMBOL_COLLAPSED "
        else
            collapse_indicator="$SYMBOL_EXPANDED "
        fi
    fi

    # Truncate description based on terminal width
    local max_desc_width=$((TERM_WIDTH - 25))  # Reserve space for symbol, time
    if [[ ${#description} -gt $max_desc_width ]]; then
        description="${description:0:$max_desc_width}..."
    fi

    # Format: [symbol] [+/-] Description (duration)
    if [[ $TERM_ANSI_SUPPORT -eq 1 ]]; then
        printf "${color_code}%s${COLOR_RESET:-} %s%s ${COLOR_BLUE:-}(%s)${COLOR_RESET:-}\n" \
            "$symbol" "$collapse_indicator" "$description" "$duration"
    else
        printf "%s %s%s (%s)\n" \
            "$symbol" "$collapse_indicator" "$description" "$duration"
    fi
}

# Function: render_display
# Purpose: Render complete task display
# Args: None
# Returns: 0 on success
# Side Effects: Updates terminal display
render_display() {
    if [[ $DISPLAY_ENABLED -eq 0 ]]; then
        return 0
    fi

    # Performance throttling: max 20 renders per second (50ms)
    local current_time
    current_time=$(date +%s%N)
    local time_since_last_render=$(( (current_time - LAST_RENDER_TIME) / 1000000 ))

    if [[ $time_since_last_render -lt 50 ]]; then
        return 0  # Skip render if too soon
    fi

    LAST_RENDER_TIME=$current_time

    # Render all tasks (sorted by ID)
    local -a sorted_ids
    mapfile -t sorted_ids < <(for id in "${!TASK_IDS[@]}"; do echo "${TASK_IDS[$id]} $id"; done | sort -n | cut -d' ' -f2)

    for task_id in "${sorted_ids[@]}"; do
        render_task_line "$task_id"

        # Render verbose output if expanded
        if [[ ${TASK_COLLAPSED[$task_id]} -eq 0 ]] && [[ -n "${TASK_OUTPUT[$task_id]:-}" ]]; then
            local output="${TASK_OUTPUT[$task_id]}"

            # Indent output
            while IFS= read -r line; do
                printf "  ${COLOR_BLUE:-}│${COLOR_RESET:-} %s\n" "$line"
            done <<< "$output"
        fi

        TASK_RENDER_COUNT[$task_id]=$((TASK_RENDER_COUNT[$task_id] + 1))
    done

    return 0
}

# Function: detect_terminal_width
# Purpose: Detect current terminal width
# Args: None
# Returns: Terminal width (columns)
# Side Effects: None
detect_terminal_width() {
    local width=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    echo "$width"
}

# Function: detect_ansi_support
# Purpose: Check if terminal supports ANSI escape codes
# Args: None
# Returns: 0 if ANSI supported, 1 otherwise
# Side Effects: None
detect_ansi_support() {
    if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]] && [[ "${NO_COLOR:-0}" != "1" ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================
# GRACEFUL DEGRADATION
# ============================================================

# Function: get_display_mode
# Purpose: Determine display mode based on terminal width
# Args: None
# Returns: Display mode (full|truncated|minimal)
# Side Effects: None
get_display_mode() {
    local width
    width=$(detect_terminal_width)

    if [[ $width -ge 100 ]]; then
        echo "full"
    elif [[ $width -ge 80 ]]; then
        echo "truncated"
    else
        echo "minimal"
    fi
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat << 'EOF'
This module provides parallel task display functionality and should be sourced, not executed directly.

Usage:
    source scripts/task_display.sh

Available functions:
    - init_task_display
    - cleanup_task_display
    - register_task <task_id> <description>
    - start_task <task_id>
    - complete_task <task_id> <status> [output]
    - get_task_duration <task_id>
    - render_task_line <task_id>
    - render_display
    - detect_terminal_width
    - detect_ansi_support
    - get_display_mode

Example:
    source scripts/task_display.sh
    init_task_display
    register_task "task1" "Installing Node.js"
    start_task "task1"
    # ... perform work ...
    complete_task "task1" "success" "Node.js v25.2.0 installed"
    cleanup_task_display
EOF
    exit 0
fi
