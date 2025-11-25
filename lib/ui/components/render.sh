#!/usr/bin/env bash
#
# lib/ui/components/render.sh - Task rendering for collapsible UI
#
# Dependencies: task_state.sh, spinner.sh
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - render_task_line(): Render single task line
#   - render_all_tasks(): Render all tasks with status
#   - init_render(): Initialize rendering system
#   - cleanup_render(): Clean up rendering state
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_UI_COMPONENTS_RENDER_SH:-}" ]] && return 0
readonly _LIB_UI_COMPONENTS_RENDER_SH=1

# ============================================================================
# ANSI ESCAPE CODES
# ============================================================================

readonly ANSI_SAVE_CURSOR="\033[s"
readonly ANSI_RESTORE_CURSOR="\033[u"
readonly ANSI_CLEAR_LINE="\033[2K"
readonly ANSI_MOVE_UP="\033[1A"
readonly ANSI_MOVE_DOWN="\033[1B"
readonly ANSI_HIDE_CURSOR="\033[?25l"
readonly ANSI_SHOW_CURSOR="\033[?25h"
readonly ANSI_RESET="\033[0m"

# Colors
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_RED="\033[0;31m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_BLUE="\033[0;34m"
readonly COLOR_CYAN="\033[0;36m"
readonly COLOR_DIM="\033[2m"

# ============================================================================
# RENDER STATE
# ============================================================================

TASKS_RENDERED=false
VERBOSE_MODE="${VERBOSE_MODE:-false}"

# ============================================================================
# INITIALIZATION
# ============================================================================

# Function: init_render
init_render() {
    TASKS_RENDERED=false

    # Hide cursor in non-verbose mode
    if [[ -t 1 ]] && [[ "$VERBOSE_MODE" == "false" ]]; then
        echo -ne "$ANSI_HIDE_CURSOR"
    fi

    return 0
}

# Function: cleanup_render
cleanup_render() {
    # Show cursor
    if [[ -t 1 ]]; then
        echo -ne "$ANSI_SHOW_CURSOR"
    fi

    TASKS_RENDERED=false
    return 0
}

# ============================================================================
# TASK LINE RENDERING
# ============================================================================

# Function: render_task_line
#   Formatted task line (stdout)
render_task_line() {
    local task_id="$1"
    local status="$2"
    local task_name="$3"
    local duration="${4:-0}"
    local error="${5:-}"

    local symbol color suffix=""

    case "$status" in
        pending)
            symbol=""
            color="$COLOR_DIM"
            suffix=" (queued)"
            ;;
        running)
            # Use spinner character from spinner.sh if loaded
            if declare -f get_spinner_char &>/dev/null; then
                symbol=$(get_spinner_char)
            else
                symbol=""
            fi
            color="$COLOR_CYAN"
            suffix="..."
            ;;
        success)
            symbol=""
            color="$COLOR_GREEN"
            if [[ "$duration" -gt 0 ]]; then
                if declare -f format_duration &>/dev/null; then
                    suffix=" ($(format_duration "$duration"))"
                else
                    suffix=" (${duration}s)"
                fi
            fi
            ;;
        failed)
            symbol=""
            color="$COLOR_RED"
            suffix=" (FAILED)"
            ;;
        skipped)
            symbol=""
            color="$COLOR_YELLOW"
            suffix=" (skipped)"
            ;;
        *)
            symbol="?"
            color="$ANSI_RESET"
            ;;
    esac

    echo -e "${color}${symbol} ${task_name}${suffix}${ANSI_RESET}"
}

# ============================================================================
# FULL RENDER
# ============================================================================

# Function: render_all_tasks
render_all_tasks() {
    # Skip in verbose mode
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        return 0
    fi

    # Skip if not interactive terminal
    if [[ ! -t 1 ]]; then
        return 0
    fi

    # Check if task arrays exist
    if [[ -z "${TASK_ORDER:-}" ]]; then
        return 0
    fi

    local task_count=${#TASK_ORDER[@]}

    # Move cursor up to replace previous render
    if [[ "$TASKS_RENDERED" == "true" ]]; then
        for (( i=0; i<task_count; i++ )); do
            echo -ne "$ANSI_MOVE_UP"
        done
    else
        TASKS_RENDERED=true
    fi

    # Render each task
    for task_id in "${TASK_ORDER[@]}"; do
        echo -ne "$ANSI_CLEAR_LINE"

        local status="${TASK_STATUS[$task_id]:-pending}"
        local name="${TASK_DETAILS[$task_id]:-$task_id}"
        local duration="${TASK_TIMES[$task_id]:-0}"
        local error="${TASK_ERRORS[$task_id]:-}"

        render_task_line "$task_id" "$status" "$name" "$duration" "$error"

        # Show error details for failed tasks
        if [[ "$status" == "failed" ]] && [[ -n "$error" ]]; then
            echo "  ${COLOR_RED}Error: ${error}${ANSI_RESET}"
        fi
    done

    return 0
}

# ============================================================================
# VERBOSE MODE CONTROL
# ============================================================================

# Function: enable_verbose
enable_verbose() {
    VERBOSE_MODE=true
    echo -ne "$ANSI_SHOW_CURSOR"
    return 0
}

# Function: disable_verbose
disable_verbose() {
    VERBOSE_MODE=false
    if [[ -t 1 ]]; then
        echo -ne "$ANSI_HIDE_CURSOR"
    fi
    return 0
}

# Function: toggle_verbose
toggle_verbose() {
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        disable_verbose
    else
        enable_verbose
    fi
    return 0
}

# Function: is_verbose
is_verbose() {
    [[ "$VERBOSE_MODE" == "true" ]]
}

# ============================================================================
# PROGRESS BAR
# ============================================================================

# Function: render_progress_bar
#   Progress bar string (stdout)
render_progress_bar() {
    local progress="$1"
    local width="${2:-40}"

    local filled=$(( progress * width / 100 ))
    local empty=$(( width - filled ))

    local bar=""
    for (( i=0; i<filled; i++ )); do bar+=""; done
    for (( i=0; i<empty; i++ )); do bar+=""; done

    echo -e "${COLOR_GREEN}${bar}${ANSI_RESET} ${progress}%"
}

# Function: calculate_progress
#   Progress percentage (stdout)
calculate_progress() {
    if [[ -z "${TASK_ORDER:-}" ]] || [[ ${#TASK_ORDER[@]} -eq 0 ]]; then
        echo "0"
        return 0
    fi

    local completed=0
    for task_id in "${TASK_ORDER[@]}"; do
        case "${TASK_STATUS[$task_id]:-pending}" in
            success|failed|skipped) ((completed++)) ;;
        esac
    done

    local total=${#TASK_ORDER[@]}
    echo $(( completed * 100 / total ))
}

# ============================================================================
# SUMMARY RENDERING
# ============================================================================

# Function: render_summary
render_summary() {
    echo
    echo "========================================"
    echo "Task Summary"
    echo "========================================"

    local success=0 failed=0 skipped=0

    for task_id in "${TASK_ORDER[@]}"; do
        case "${TASK_STATUS[$task_id]:-pending}" in
            success) ((success++)) ;;
            failed)  ((failed++)) ;;
            skipped) ((skipped++)) ;;
        esac
    done

    local total=${#TASK_ORDER[@]}

    echo -e "${COLOR_GREEN}Completed: $success${ANSI_RESET}"
    [[ $failed -gt 0 ]] && echo -e "${COLOR_RED}Failed: $failed${ANSI_RESET}"
    [[ $skipped -gt 0 ]] && echo -e "${COLOR_YELLOW}Skipped: $skipped${ANSI_RESET}"
    echo "Total: $total"
    echo "========================================"

    return 0
}
