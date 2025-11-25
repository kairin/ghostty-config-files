#!/usr/bin/env bash
# lib/installers/common/tui-helpers.sh - TUI helper functions for installer UI
# Extracted from lib/installers/common/manager-runner.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TUI_HELPERS_SOURCED:-}" ]] && return 0
readonly _TUI_HELPERS_SOURCED=1

#######################################
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
#######################################
show_component_header() {
    local component_name="$1"

    # ALWAYS use gum (installed as priority 0, guaranteed available)
    # Use double border for better terminal compatibility
    echo ""
    gum style \
        --border double \
        --border-foreground 212 \
        --align center \
        --width 70 \
        --margin "1 0" \
        --padding "1 2" \
        "Installing ${component_name}"
    echo ""
}

#######################################
# show_component_footer - Display summary footer after installation
#
# Args:
#   $1 - Component name (e.g., "Ghostty")
#   $2 - Total steps completed
#   $3 - Status (SUCCESS, FAILED, PARTIAL)
#   $4 - Total duration in seconds
#   $5 - Component log file path (optional)
#
# Output:
#   Styled footer with installation summary and log file location
#
# Example:
#   show_component_footer "Ghostty" 9 "SUCCESS" 120 "/path/to/log"
#######################################
show_component_footer() {
    local component_name="$1"
    local total_steps="$2"
    local status="$3"
    local total_duration="${4:-0}"
    local component_log="${5:-}"

    local status_symbol
    local status_color

    case "$status" in
        SUCCESS)
            status_symbol="[OK]"
            status_color="green"
            ;;
        FAILED)
            status_symbol="[FAILED]"
            status_color="red"
            ;;
        PARTIAL)
            status_symbol="[PARTIAL]"
            status_color="yellow"
            ;;
        *)
            status_symbol="[?]"
            status_color="white"
            ;;
    esac

    # ALWAYS use gum (installed as priority 0, guaranteed available)
    echo ""
    gum style \
        --border none \
        --foreground "$status_color" \
        --bold \
        --align center \
        --width 60 \
        "$status_symbol ${component_name} installation $status ($total_steps/$total_steps steps, $(format_duration "$total_duration") total)"

    # Show log file location if provided
    if [[ -n "$component_log" ]]; then
        echo ""
        gum style \
            --foreground 240 \
            --align center \
            --width 60 \
            "Detailed logs: $component_log"
    fi
    echo ""
}

#######################################
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
#######################################
validate_step_format() {
    local step_info="$1"

    # Check if step has exactly 3 pipe-delimited fields
    local field_count
    field_count=$(echo "$step_info" | tr -cd '|' | wc -c)

    if [[ "$field_count" -ne 2 ]]; then
        log "ERROR" "Invalid step format: '$step_info' (expected: 'script|name|duration')"
        return 1
    fi

    # Extract fields
    local script display_name duration
    IFS='|' read -r script display_name duration <<< "$step_info"

    # Validate script field
    if [[ -z "$script" ]]; then
        log "ERROR" "Invalid step: empty script name in '$step_info'"
        return 1
    fi

    # Validate display name
    if [[ -z "$display_name" ]]; then
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

#######################################
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
#######################################
calculate_total_duration() {
    local steps=("$@")
    local total=0

    for step_info in "${steps[@]}"; do
        local script display_name duration
        IFS='|' read -r script display_name duration <<< "$step_info"
        total=$((total + duration))
    done

    echo "$total"
}

#######################################
# format_duration - Convert seconds to human-readable format
#
# Args:
#   $1 - Duration in seconds
#
# Returns:
#   Formatted duration string (e.g., "2m 30s")
#######################################
format_duration() {
    local seconds="${1:-0}"

    if [[ "$seconds" -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ "$seconds" -lt 3600 ]]; then
        local minutes=$((seconds / 60))
        local remaining_seconds=$((seconds % 60))
        echo "${minutes}m ${remaining_seconds}s"
    else
        local hours=$((seconds / 3600))
        local remaining_minutes=$(((seconds % 3600) / 60))
        echo "${hours}h ${remaining_minutes}m"
    fi
}

#######################################
# show_progress_bar - Display a progress bar for current step
#
# Args:
#   $1 - Current step number
#   $2 - Total steps
#   $3 - Step description (optional)
#
# Output:
#   Visual progress indicator
#######################################
show_progress_bar() {
    local current="$1"
    local total="$2"
    local description="${3:-}"

    local percentage=$((current * 100 / total))
    local completed=$((current * 40 / total))
    local remaining=$((40 - completed))

    local bar=""
    for ((i=0; i<completed; i++)); do bar+="#"; done
    for ((i=0; i<remaining; i++)); do bar+="-"; done

    printf "\r[%s] %3d%% (%d/%d) %s" "$bar" "$percentage" "$current" "$total" "$description"
}

#######################################
# show_spinner - Display a spinner for long-running operations
#
# Args:
#   $1 - Message to display
#   $2 - PID of background process to wait for
#
# Note: This is a blocking function that waits for the process
#######################################
show_spinner() {
    local message="$1"
    local pid="$2"
    local spin_chars='/-\|'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s %s" "${spin_chars:i++%4:1}" "$message"
        sleep 0.1
    done
    printf "\r"
}

#######################################
# confirm_action - Prompt user for confirmation
#
# Args:
#   $1 - Prompt message
#   $2 - Default value (y/n, optional)
#
# Returns:
#   0 if confirmed, 1 if declined
#######################################
confirm_action() {
    local prompt="$1"
    local default="${2:-n}"

    if command -v gum &>/dev/null; then
        if gum confirm "$prompt"; then
            return 0
        else
            return 1
        fi
    else
        local response
        if [[ "$default" == "y" ]]; then
            read -rp "$prompt [Y/n]: " response
            [[ -z "$response" || "$response" =~ ^[Yy] ]]
        else
            read -rp "$prompt [y/N]: " response
            [[ "$response" =~ ^[Yy] ]]
        fi
    fi
}

#######################################
# select_option - Present a list of options to user
#
# Args:
#   $1 - Prompt message
#   $@ - Options array
#
# Returns:
#   Selected option via stdout
#######################################
select_option() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v gum &>/dev/null; then
        printf '%s\n' "${options[@]}" | gum choose --header="$prompt"
    else
        echo "$prompt" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt" >&2
            ((i++))
        done

        local selection
        read -rp "Enter choice (1-${#options[@]}): " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#options[@]})); then
            echo "${options[$((selection-1))]}"
        else
            echo ""
        fi
    fi
}

# Export functions
export -f show_component_header show_component_footer
export -f validate_step_format calculate_total_duration format_duration
export -f show_progress_bar show_spinner
export -f confirm_action select_option
