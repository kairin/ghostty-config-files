#!/usr/bin/env bash
# manager-runner.sh - TUI wrapper for component installation managers
# Orchestrates step-by-step installation with TUI feedback using modular components

set -euo pipefail

# Source guard - prevent redundant loading
[[ -z "${MANAGER_RUNNER_SH_LOADED:-}" ]] || return 0
MANAGER_RUNNER_SH_LOADED=1

# Determine script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

# Source required libraries
source "${REPO_ROOT}/lib/core/utils.sh"
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/ui/tui.sh"
source "${REPO_ROOT}/lib/ui/collapsible.sh"
source "${REPO_ROOT}/lib/installers/common/tui-helpers.sh"

# Manager runner state
declare -g MR_COMPONENT_NAME=""
declare -g MR_TOTAL_STEPS=0
declare -g MR_CURRENT_STEP=0
declare -g MR_TOTAL_DURATION=0
declare -g MR_START_TIME=0

#
# run_install_steps - Execute installation steps with full TUI integration
#
# This is the main entry point for component managers. It handles:
#   - TUI system initialization
#   - Component header display
#   - Step-by-step execution with progress tracking
#   - Task status updates (pending -> running -> success/failed)
#   - Collapsible output rendering
#   - Error handling with auto-expand
#   - Component footer display
#
# Args:
#   $1 - Component name (e.g., "Ghostty", "ZSH", "Python UV")
#   $2 - Steps directory path (absolute path to steps/ directory)
#   $@ - Installation steps array (format: "script.sh|Display Name|Duration")
#
# Returns:
#   0 = all steps succeeded
#   1 = at least one step failed
#   2 = configuration error (invalid step format)
#
run_install_steps() {
    # Validate minimum arguments
    if [[ $# -lt 3 ]]; then
        log "ERROR" "run_install_steps: insufficient arguments"
        log "ERROR" "Usage: run_install_steps 'ComponentName' '/path/to/steps' 'script|name|duration' ..."
        return 2
    fi

    local component_name="$1"
    local steps_dir="$2"
    shift 2
    local steps=("$@")

    # Store component name for helper functions
    MR_COMPONENT_NAME="$component_name"
    MR_TOTAL_STEPS=${#steps[@]}
    MR_CURRENT_STEP=0
    MR_START_TIME=$(date +%s)

    # Create component-specific log file
    local timestamp component_log_dir component_log
    timestamp=$(date +"%Y%m%d-%H%M%S")
    component_log_dir="${LOGGING_REPO_ROOT:-$REPO_ROOT}/logs/components"
    mkdir -p "$component_log_dir"
    component_log="${component_log_dir}/${component_name,,}-${timestamp}.log"
    touch "$component_log"

    log "INFO" "Component log: $component_log"

    # Validate steps directory exists
    if [[ ! -d "$steps_dir" ]]; then
        log "ERROR" "Steps directory does not exist: $steps_dir"
        return 2
    fi

    # Validate all step formats before execution
    log "INFO" "Validating ${MR_TOTAL_STEPS} installation steps for ${component_name}..."
    for step_info in "${steps[@]}"; do
        if ! validate_step_format "$step_info"; then
            log "ERROR" "Step validation failed for: $step_info"
            return 2
        fi
    done

    # Calculate total estimated duration
    local total_estimated
    total_estimated=$(calculate_total_duration "${steps[@]}")
    log "INFO" "Total estimated duration: $(format_duration "$total_estimated")"

    # Initialize TUI system
    init_tui
    init_collapsible_output

    # Show component header
    show_component_header "$component_name"

    # Register all tasks first (for collapsible UI)
    local step_num=1
    for step_info in "${steps[@]}"; do
        local script display_name duration
        IFS='|' read -r script display_name duration <<< "$step_info"
        local task_id="${component_name,,}-step-${step_num}"
        register_task "$task_id" "$display_name"
        ((step_num++))
    done

    # Execute steps sequentially
    step_num=1
    local failed_steps=0

    for step_info in "${steps[@]}"; do
        local script display_name duration
        IFS='|' read -r script display_name duration <<< "$step_info"
        local task_id="${component_name,,}-step-${step_num}"
        local step_path="${steps_dir}/${script}"

        MR_CURRENT_STEP=$step_num

        # Verify step script exists and is executable
        if [[ ! -f "$step_path" ]]; then
            log "ERROR" "Step script not found: $step_path"
            fail_task "$task_id" "Step script not found: $script"
            ((failed_steps++))
            ((step_num++))
            continue
        fi

        if [[ ! -x "$step_path" ]]; then
            log "WARNING" "Step script not executable, attempting to fix: $step_path"
            chmod +x "$step_path" || {
                log "ERROR" "Failed to make script executable: $step_path"
                fail_task "$task_id" "Script not executable: $script"
                ((failed_steps++))
                ((step_num++))
                continue
            }
        fi

        # Log step start and update task state
        log "INFO" "Step ${step_num}/${MR_TOTAL_STEPS}: ${display_name} (estimated: $(format_duration "$duration"))"
        start_task "$task_id"

        # Execute step with timing
        local step_start step_end step_duration step_exit_code
        step_start=$(date +%s)
        log "INFO" "-> Step ${step_num}/${MR_TOTAL_STEPS}: ${display_name}..."

        # Execute and capture exit code properly
        "$step_path" && step_exit_code=0 || step_exit_code=$?
        step_end=$(date +%s)
        step_duration=$((step_end - step_start))

        # Handle exit codes:
        #   0 = success
        #   1 = failure
        #   2 = skipped (idempotent - already installed)
        if [ $step_exit_code -eq 0 ]; then
            complete_task "$task_id" "$step_duration"
            log "SUCCESS" "Completed: ${display_name} ($(format_duration "$step_duration"))"
        elif [ $step_exit_code -eq 2 ]; then
            # Exit code 2 = skipped (already done, idempotent behavior)
            # Mark remaining tasks as skipped and exit early with success
            complete_task "$task_id" 0
            log "INFO" "Skipped: ${display_name} (already installed)"

            # Mark remaining steps as skipped and return success
            local remaining_step=$((step_num + 1))
            while [ $remaining_step -le $MR_TOTAL_STEPS ]; do
                local remaining_task_id="${component_name,,}-step-${remaining_step}"
                skip_task "$remaining_task_id" 2>/dev/null || true
                ((remaining_step++))
            done

            # Show component footer with SKIPPED status
            local skip_end_time
            skip_end_time=$(date +%s)
            MR_TOTAL_DURATION=$((skip_end_time - MR_START_TIME))
            show_component_footer "$component_name" "$MR_TOTAL_STEPS" "SKIPPED" "$MR_TOTAL_DURATION" "$component_log"
            log "INFO" "${component_name} already installed - skipping remaining steps"
            cleanup_collapsible_output
            return 2  # Return 2 to indicate skipped (idempotent)
        else
            log "ERROR" "FAILED: ${display_name} (exit code: $step_exit_code)"
            fail_task "$task_id" "Exit code: $step_exit_code - Check logs for details"
            ((failed_steps++))
        fi

        ((step_num++))
    done

    # Calculate total duration
    local end_time
    end_time=$(date +%s)
    MR_TOTAL_DURATION=$((end_time - MR_START_TIME))

    # Show component footer with results
    if [[ $failed_steps -eq 0 ]]; then
        show_component_footer "$component_name" "$MR_TOTAL_STEPS" "SUCCESS" "$MR_TOTAL_DURATION" "$component_log"
        log "SUCCESS" "${component_name} installation complete: ${MR_TOTAL_STEPS}/${MR_TOTAL_STEPS} steps succeeded"
        cleanup_collapsible_output
        return 0
    elif [[ $failed_steps -eq "$MR_TOTAL_STEPS" ]]; then
        show_component_footer "$component_name" "$MR_TOTAL_STEPS" "FAILED" "$MR_TOTAL_DURATION" "$component_log"
        log "ERROR" "${component_name} installation FAILED: ${failed_steps}/${MR_TOTAL_STEPS} steps failed"
    else
        show_component_footer "$component_name" "$MR_TOTAL_STEPS" "PARTIAL" "$MR_TOTAL_DURATION" "$component_log"
        log "WARNING" "${component_name} installation PARTIAL: ${failed_steps}/${MR_TOTAL_STEPS} steps failed"
    fi

    cleanup_collapsible_output
    return 1
}

# Export functions for use in component managers
export -f run_install_steps

# Export state variables
export MR_COMPONENT_NAME
export MR_TOTAL_STEPS
export MR_CURRENT_STEP
export MR_TOTAL_DURATION
export MR_START_TIME

log "INFO" "manager-runner.sh loaded successfully"
