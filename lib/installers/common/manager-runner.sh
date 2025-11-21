#!/usr/bin/env bash
#
# lib/installers/common/manager-runner.sh - Reusable TUI wrapper for component installation managers
#
# Purpose:
#   Provides a modular, reusable wrapper that adds full TUI integration to any component
#   installation manager. This eliminates the need for hard-coded TUI logic in individual
#   component managers, keeping them simple, data-driven, and focused on defining installation steps.
#
# Design Philosophy:
#   - ONE PLACE for all TUI integration logic (DRY principle)
#   - Component managers define steps as DATA (not code)
#   - Consistent UX across all component installers
#   - Docker-like progressive summarization with collapsible output
#   - Professional styling with gum framework
#
# Features:
#   - Automatic TUI system initialization (gum detection, box drawing)
#   - Collapsible task output with Docker-style rendering
#   - Real-time progress indicators (Step X/Y)
#   - Professional component headers/footers with gum styling
#   - Error handling with auto-expand on failure
#   - Verbose mode toggle (--verbose flag)
#   - Spinner animations for long-running tasks
#   - Duration tracking and display
#
# Usage Pattern (Component Manager):
#   ```bash
#   #!/usr/bin/env bash
#   set -euo pipefail
#
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   STEPS_DIR="${SCRIPT_DIR}/steps"
#
#   source "${SCRIPT_DIR}/common.sh"
#   source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"
#
#   main() {
#       # Define installation steps as data (not loops)
#       declare -a INSTALL_STEPS=(
#           "00-check-prerequisites.sh|Check Prerequisites|5"
#           "01-download-package.sh|Download Package|30"
#           "02-extract-package.sh|Extract Package|10"
#           "03-install-binary.sh|Install Binary|10"
#           "04-configure.sh|Configure Component|10"
#           "05-verify.sh|Verify Installation|5"
#       )
#
#       # One function call runs everything with full TUI integration
#       run_install_steps "MyComponent" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
#   }
#
#   main "$@"
#   ```
#
# Step Array Format:
#   Each step is a pipe-delimited string: "SCRIPT|DISPLAY_NAME|DURATION"
#   - SCRIPT: Script filename in steps directory (e.g., "00-check-prerequisites.sh")
#   - DISPLAY_NAME: Human-readable task name (e.g., "Check Prerequisites")
#   - DURATION: Estimated duration in seconds (for progress tracking)
#
# Visual Output Example:
#   ```
#   ╔═══════════════════════════════════════════════════════════╗
#   ║              Installing Ghostty Terminal                  ║
#   ╚═══════════════════════════════════════════════════════════╝
#
#   ✓ Check Prerequisites (5s)
#   ⠋ Downloading Zig Compiler... (30s estimated)
#   ⏸ Extract Zig Tarball (queued)
#   ⏸ Clone Ghostty Repository (queued)
#   ⏸ Build Ghostty (queued)
#   ⏸ Install Binary (queued)
#   ⏸ Configure Ghostty (queued)
#   ⏸ Create Desktop Entry (queued)
#   ⏸ Verify Installation (queued)
#
#   ═══════════════════════════════════════════════════════════
#   ✅ Ghostty installation complete (9/9 steps, 185s total)
#   ═══════════════════════════════════════════════════════════
#   ```
#
# Constitutional Compliance:
#   - Principle I: Modular Architecture (TUI logic centralized)
#   - Principle V: Reusability (one wrapper for all installers)
#   - Clean, professional output like Docker build
#
# Dependencies:
#   - lib/ui/tui.sh - gum integration wrapper
#   - lib/ui/collapsible.sh - Docker-like collapsible output
#   - lib/core/logging.sh - Logging infrastructure
#   - lib/core/utils.sh - Utility functions
#
# Exit Codes:
#   0 = all steps completed successfully
#   1 = one or more steps failed
#   2 = invalid step format or configuration error
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${MANAGER_RUNNER_SH_LOADED:-}" ] || return 0
MANAGER_RUNNER_SH_LOADED=1

# Determine script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"

# Source required libraries
source "${REPO_ROOT}/lib/core/utils.sh"
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/ui/tui.sh"
source "${REPO_ROOT}/lib/ui/collapsible.sh"

# Manager runner state
declare -g MR_COMPONENT_NAME=""
declare -g MR_TOTAL_STEPS=0
declare -g MR_CURRENT_STEP=0
declare -g MR_TOTAL_DURATION=0
declare -g MR_START_TIME=0

#
# show_component_header - Display styled header for component installation
#
# Args:
#   $1 - Component name (e.g., "Ghostty", "ZSH", "Python UV")
#
# Output:
#   Styled header box with component name
#
# Example:
#   show_component_header "Ghostty Terminal"
#
show_component_header() {
    local component_name="$1"

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum for professional styling
        echo ""
        gum style \
            --border double \
            --border-foreground 212 \
            --align center \
            --width 60 \
            --margin "0 2" \
            --padding "1 2" \
            "Installing ${component_name}"
        echo ""
    else
        # Fallback: ASCII box
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        printf "║%*s%*s║\n" $(( (59 + ${#component_name} + 12) / 2 )) "Installing ${component_name}" $(( (59 - ${#component_name} - 12) / 2 )) ""
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""
    fi
}

#
# show_component_footer - Display summary footer after installation
#
# Args:
#   $1 - Component name (e.g., "Ghostty")
#   $2 - Total steps completed
#   $3 - Status (SUCCESS, FAILED, PARTIAL)
#
# Output:
#   Styled footer with installation summary
#
# Example:
#   show_component_footer "Ghostty" 9 "SUCCESS"
#
show_component_footer() {
    local component_name="$1"
    local total_steps="$2"
    local status="$3"

    local status_symbol
    local status_color

    case "$status" in
        SUCCESS)
            status_symbol="✅"
            status_color="green"
            ;;
        FAILED)
            status_symbol="❌"
            status_color="red"
            ;;
        PARTIAL)
            status_symbol="⚠️"
            status_color="yellow"
            ;;
        *)
            status_symbol="?"
            status_color="white"
            ;;
    esac

    if [ "$TUI_AVAILABLE" = true ]; then
        echo ""
        gum style \
            --border none \
            --foreground "$status_color" \
            --bold \
            --align center \
            --width 60 \
            "$status_symbol ${component_name} installation $status ($total_steps/$total_steps steps, $(format_duration "$MR_TOTAL_DURATION") total)"
        echo ""
    else
        # Fallback: ASCII separator
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "$status_symbol ${component_name} installation $status ($total_steps/$total_steps steps, $(format_duration "$MR_TOTAL_DURATION") total)"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
    fi
}

#
# validate_step_format - Validate step array format
#
# Args:
#   $1 - Step info string (format: "script.sh|Display Name|Duration")
#
# Returns:
#   0 = valid format
#   1 = invalid format
#
# Example:
#   if validate_step_format "00-check.sh|Check Prerequisites|5"; then
#       echo "Valid"
#   fi
#
validate_step_format() {
    local step_info="$1"

    # Check if step has exactly 3 pipe-delimited fields
    local field_count
    field_count=$(echo "$step_info" | tr -cd '|' | wc -c)

    if [ "$field_count" -ne 2 ]; then
        log "ERROR" "Invalid step format: '$step_info' (expected: 'script|name|duration')"
        return 1
    fi

    # Extract fields
    IFS='|' read -r script display_name duration <<< "$step_info"

    # Validate script field
    if [ -z "$script" ]; then
        log "ERROR" "Invalid step: empty script name in '$step_info'"
        return 1
    fi

    # Validate display name
    if [ -z "$display_name" ]; then
        log "ERROR" "Invalid step: empty display name in '$step_info'"
        return 1
    fi

    # Validate duration (must be a positive integer)
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid step: duration must be a positive integer in '$step_info' (got: '$duration')"
        return 1
    fi

    return 0
}

#
# calculate_total_duration - Sum up estimated durations from all steps
#
# Args:
#   $@ - Step info array
#
# Returns:
#   Total estimated duration in seconds
#
# Example:
#   total_duration=$(calculate_total_duration "${INSTALL_STEPS[@]}")
#
calculate_total_duration() {
    local steps=("$@")
    local total=0

    for step_info in "${steps[@]}"; do
        IFS='|' read -r script display_name duration <<< "$step_info"
        total=$((total + duration))
    done

    echo "$total"
}

#
# run_install_steps - Execute installation steps with full TUI integration
#
# This is the main entry point for component managers. It handles:
#   - TUI system initialization
#   - Component header display
#   - Step-by-step execution with progress tracking
#   - Task status updates (pending → running → success/failed)
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
# Example:
#   declare -a INSTALL_STEPS=(
#       "00-check.sh|Check Prerequisites|5"
#       "01-download.sh|Download Package|30"
#       "02-install.sh|Install Package|10"
#   )
#   run_install_steps "Ghostty" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
#
run_install_steps() {
    # Validate minimum arguments
    if [ $# -lt 3 ]; then
        log "ERROR" "run_install_steps: insufficient arguments (expected: component_name steps_dir step1 [step2 ...])"
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

    # Validate steps directory exists
    if [ ! -d "$steps_dir" ]; then
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
        IFS='|' read -r script display_name duration <<< "$step_info"
        local task_id="${component_name,,}-step-${step_num}"

        register_task "$task_id" "$display_name"
        ((step_num++))
    done

    # Start spinner loop for collapsible UI
    local spinner_pid=""
    if [ "$VERBOSE_MODE" = false ]; then
        spinner_pid=$(start_spinner_loop)
    fi

    # Execute steps sequentially
    step_num=1
    local failed_steps=0

    for step_info in "${steps[@]}"; do
        IFS='|' read -r script display_name duration <<< "$step_info"
        local task_id="${component_name,,}-step-${step_num}"
        local step_path="${steps_dir}/${script}"

        MR_CURRENT_STEP=$step_num

        # Verify step script exists
        if [ ! -f "$step_path" ]; then
            log "ERROR" "Step script not found: $step_path"
            fail_task "$task_id" "Step script not found: $script"
            ((failed_steps++))
            ((step_num++))
            continue
        fi

        # Verify step script is executable
        if [ ! -x "$step_path" ]; then
            log "WARNING" "Step script not executable, attempting to fix: $step_path"
            chmod +x "$step_path" || {
                log "ERROR" "Failed to make script executable: $step_path"
                fail_task "$task_id" "Script not executable: $script"
                ((failed_steps++))
                ((step_num++))
                continue
            }
        fi

        # Log step start
        log "INFO" "Step ${step_num}/${MR_TOTAL_STEPS}: ${display_name} (estimated: $(format_duration "$duration"))"

        # Start task
        start_task "$task_id"

        # Execute step with timing
        local step_start
        step_start=$(date +%s)

        if run_command_collapsible "$task_id" "$step_path"; then
            local step_end
            step_end=$(date +%s)
            local step_duration=$((step_end - step_start))

            complete_task "$task_id" "$step_duration"
            log "SUCCESS" "Step ${step_num}/${MR_TOTAL_STEPS} complete: ${display_name} ($(format_duration "$step_duration"))"
        else
            local exit_code=$?
            log "ERROR" "Step ${step_num}/${MR_TOTAL_STEPS} FAILED: ${display_name} (exit code: $exit_code)"
            fail_task "$task_id" "Exit code: $exit_code - Check logs for details"
            ((failed_steps++))

            # Show task output on failure (if not in verbose mode)
            if [ "$VERBOSE_MODE" = false ]; then
                show_task_output "$task_id"
            fi
        fi

        ((step_num++))
    done

    # Stop spinner loop
    if [ -n "$spinner_pid" ]; then
        stop_spinner_loop "$spinner_pid"
    fi

    # Calculate total duration
    local end_time
    end_time=$(date +%s)
    MR_TOTAL_DURATION=$((end_time - MR_START_TIME))

    # Show component footer
    if [ $failed_steps -eq 0 ]; then
        show_component_footer "$component_name" "$MR_TOTAL_STEPS" "SUCCESS"
        log "SUCCESS" "${component_name} installation complete: ${MR_TOTAL_STEPS}/${MR_TOTAL_STEPS} steps succeeded ($(format_duration "$MR_TOTAL_DURATION"))"
        cleanup_collapsible_output
        return 0
    else
        if [ $failed_steps -eq "$MR_TOTAL_STEPS" ]; then
            show_component_footer "$component_name" "$MR_TOTAL_STEPS" "FAILED"
            log "ERROR" "${component_name} installation FAILED: ${failed_steps}/${MR_TOTAL_STEPS} steps failed"
        else
            show_component_footer "$component_name" "$MR_TOTAL_STEPS" "PARTIAL"
            log "WARNING" "${component_name} installation PARTIAL: ${failed_steps}/${MR_TOTAL_STEPS} steps failed, $((MR_TOTAL_STEPS - failed_steps)) succeeded"
        fi
        cleanup_collapsible_output
        return 1
    fi
}

# Export functions for use in component managers
export -f show_component_header
export -f show_component_footer
export -f validate_step_format
export -f calculate_total_duration
export -f run_install_steps

# Export state variables
export MR_COMPONENT_NAME
export MR_TOTAL_STEPS
export MR_CURRENT_STEP
export MR_TOTAL_DURATION
export MR_START_TIME

log "INFO" "manager-runner.sh loaded successfully"
