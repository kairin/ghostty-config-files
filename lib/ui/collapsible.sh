#!/usr/bin/env bash
#
# lib/ui/collapsible.sh - Docker-like progressive summarization (Orchestrator)
# Purpose: Collapsible output with real-time task status updates
# Refactored: 2025-11-25 - Modularized to <300 lines (was 735 lines)
# Modules: lib/ui/components/{task_state,spinner,render}.sh

set -euo pipefail

# Source guard
[[ -n "${COLLAPSIBLE_SH_LOADED:-}" ]] && return 0
COLLAPSIBLE_SH_LOADED=1

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE_MODE="${VERBOSE_MODE:-false}"

# ============================================================================
# Source Modular UI Component Libraries
# ============================================================================

source_ui_modules() {
    local components_dir="${SCRIPT_DIR}/components"

    for module in task_state spinner render; do
        if [[ -f "${components_dir}/${module}.sh" ]]; then
            source "${components_dir}/${module}.sh"
        fi
    done
}

# Source modules
source_ui_modules

# Source logging if available
[[ -f "${SCRIPT_DIR}/../core/logging.sh" ]] && source "${SCRIPT_DIR}/../core/logging.sh"
[[ -f "${SCRIPT_DIR}/../core/utils.sh" ]] && source "${SCRIPT_DIR}/../core/utils.sh"

# ============================================================================
# Fallback Implementations (if modules not loaded)
# ============================================================================

# Task state arrays (fallback)
if [[ -z "${TASK_STATUS_INIT:-}" ]]; then
    declare -gA TASK_STATUS TASK_TIMES TASK_ERRORS TASK_DETAILS TASK_OUTPUT
    declare -ga TASK_ORDER
    TASK_STATUS_INIT=1
fi

# ============================================================================
# Public API (Delegates to Modules)
# ============================================================================

init_collapsible_output() {
    if declare -f init_render &>/dev/null; then
        init_render
    else
        TASKS_RENDERED=false
        [[ -t 1 ]] && [[ "$VERBOSE_MODE" == "false" ]] && echo -ne "\033[?25l"
    fi
}

cleanup_collapsible_output() {
    if declare -f cleanup_render &>/dev/null; then
        cleanup_render
    else
        [[ -t 1 ]] && echo -ne "\033[?25h"
    fi
}

register_task() {
    local task_id="$1"
    local task_name="$2"

    TASK_STATUS["$task_id"]="pending"
    TASK_TIMES["$task_id"]=0
    TASK_ERRORS["$task_id"]=""
    TASK_DETAILS["$task_id"]="$task_name"
    TASK_OUTPUT["$task_id"]=""
    TASK_ORDER+=("$task_id")
}

start_task() {
    local task_id="$1"
    TASK_STATUS["$task_id"]="running"
    render_all_tasks
}

complete_task() {
    local task_id="$1"
    local duration="${2:-0}"
    TASK_STATUS["$task_id"]="success"
    TASK_TIMES["$task_id"]="$duration"
    render_all_tasks
}

fail_task() {
    local task_id="$1"
    local error_msg="${2:-Unknown error}"
    TASK_STATUS["$task_id"]="failed"
    TASK_ERRORS["$task_id"]="$error_msg"
    render_all_tasks
}

skip_task() {
    local task_id="$1"
    TASK_STATUS["$task_id"]="skipped"
    render_all_tasks
}

# ============================================================================
# Command Execution with Output Capture
# ============================================================================

run_command_collapsible() {
    local task_id="$1"
    shift
    local cmd=("$@")

    local output_file exit_code=0
    output_file=$(mktemp)

    if [[ "$VERBOSE_MODE" == "true" ]]; then
        if "${cmd[@]}" 2>&1 | tee "$output_file"; then
            exit_code=0
        else
            exit_code=$?
        fi
    else
        "${cmd[@]}" > "$output_file" 2>&1 &
        local cmd_pid=$!

        while kill -0 "$cmd_pid" 2>/dev/null; do
            local line
            line=$(tail -n 1 "$output_file" 2>/dev/null || echo "")
            [[ -n "$line" ]] && echo -ne "\r  ... ${line:0:60}"
            sleep 0.3
        done
        echo -ne "\r\033[K"

        wait "$cmd_pid"
        exit_code=$?
    fi

    TASK_OUTPUT["$task_id"]=$(cat "$output_file")
    rm -f "$output_file"

    return $exit_code
}

show_task_output() {
    local task_id="$1"
    echo "${TASK_OUTPUT[$task_id]:-}"
}

# ============================================================================
# Rendering (Delegate to Module or Fallback)
# ============================================================================

render_all_tasks() {
    # Use module if available
    if declare -f _render_all_tasks &>/dev/null; then
        _render_all_tasks
        return
    fi

    # Skip in verbose mode
    [[ "$VERBOSE_MODE" == "true" ]] && return 0
    [[ ! -t 1 ]] && return 0

    local task_count=${#TASK_ORDER[@]}

    # Move cursor up for in-place update
    if [[ "${TASKS_RENDERED:-false}" == "true" ]]; then
        for (( i=0; i<task_count; i++ )); do
            echo -ne "\033[1A"
        done
    else
        TASKS_RENDERED=true
    fi

    # Render each task
    for task_id in "${TASK_ORDER[@]}"; do
        echo -ne "\033[2K"

        local status="${TASK_STATUS[$task_id]}"
        local name="${TASK_DETAILS[$task_id]}"
        local duration="${TASK_TIMES[$task_id]:-0}"
        local error="${TASK_ERRORS[$task_id]:-}"

        local symbol line
        case "$status" in
            pending)  symbol=""; line="$symbol $name (queued)" ;;
            running)  symbol=""; line="$symbol $name..." ;;
            success)  symbol=""; line="$symbol $name (${duration}s)" ;;
            failed)   symbol=""; line="$symbol $name (FAILED)" ;;
            skipped)  symbol=""; line="$symbol $name (skipped)" ;;
            *)        symbol="?"; line="$symbol $name" ;;
        esac

        echo "$line"

        [[ "$status" == "failed" ]] && [[ -n "$error" ]] && echo "  Error: $error"
    done

    return 0
}

# ============================================================================
# Verbose Mode Control
# ============================================================================

enable_verbose_mode() {
    VERBOSE_MODE=true
    echo -ne "\033[?25h"
}

disable_verbose_mode() {
    VERBOSE_MODE=false
    [[ -t 1 ]] && echo -ne "\033[?25l"
}

toggle_verbose_mode() {
    if [[ "$VERBOSE_MODE" == "true" ]]; then
        disable_verbose_mode
    else
        enable_verbose_mode
    fi
}

is_verbose_mode() {
    [[ "$VERBOSE_MODE" == "true" ]]
}

# ============================================================================
# Spinner Control (Delegate to Module)
# ============================================================================

start_spinner_loop() {
    if declare -f _start_spinner_loop &>/dev/null; then
        _start_spinner_loop "$@"
    fi
}

stop_spinner_loop() {
    if declare -f _stop_spinner_loop &>/dev/null; then
        _stop_spinner_loop "$@"
    fi
}

# ============================================================================
# Export Functions
# ============================================================================

export -f init_collapsible_output
export -f cleanup_collapsible_output
export -f register_task
export -f start_task
export -f complete_task
export -f fail_task
export -f skip_task
export -f run_command_collapsible
export -f show_task_output
export -f render_all_tasks
export -f enable_verbose_mode
export -f disable_verbose_mode
export -f toggle_verbose_mode
export -f is_verbose_mode
