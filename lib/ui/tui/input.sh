#!/usr/bin/env bash
# lib/ui/tui/input.sh - TUI user input utilities
# Extracted from lib/installers/common/tui-helpers.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TUI_INPUT_SOURCED:-}" ]] && return 0
readonly _TUI_INPUT_SOURCED=1

#######################################
# validate_step_format - Validate step array format
#
# Args:
#   $1 - Step info string (format: "script.sh|Display Name|Duration")
#
# Returns:
#   0 = valid format
#   1 = invalid format
#######################################
validate_step_format() {
    local step_info="$1"

    # Check if step has exactly 3 pipe-delimited fields
    local field_count
    field_count=$(echo "$step_info" | tr -cd '|' | wc -c)

    if [[ "$field_count" -ne 2 ]]; then
        echo "ERROR: Invalid step format: '$step_info' (expected: 'script|name|duration')" >&2
        return 1
    fi

    # Extract fields
    local script display_name duration
    IFS='|' read -r script display_name duration <<< "$step_info"

    # Validate script field
    if [[ -z "$script" ]]; then
        echo "ERROR: Invalid step: empty script name in '$step_info'" >&2
        return 1
    fi

    # Validate display name
    if [[ -z "$display_name" ]]; then
        echo "ERROR: Invalid step: empty display name in '$step_info'" >&2
        return 1
    fi

    # Validate duration (must be a positive integer)
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid step: duration must be a positive integer in '$step_info' (got: '$duration')" >&2
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

#######################################
# get_text_input - Get text input from user
#
# Args:
#   $1 - Prompt message
#   $2 - Default value (optional)
#   $3 - Placeholder text (optional)
#
# Returns:
#   User input via stdout
#######################################
get_text_input() {
    local prompt="$1"
    local default="${2:-}"
    local placeholder="${3:-}"

    if command -v gum &>/dev/null; then
        local result
        if [[ -n "$default" ]]; then
            result=$(gum input --placeholder="$placeholder" --value="$default" --header="$prompt")
        else
            result=$(gum input --placeholder="$placeholder" --header="$prompt")
        fi
        echo "$result"
    else
        local input
        if [[ -n "$default" ]]; then
            read -rp "$prompt [$default]: " input
            echo "${input:-$default}"
        else
            read -rp "$prompt: " input
            echo "$input"
        fi
    fi
}

#######################################
# get_password_input - Get password input from user (hidden)
#
# Args:
#   $1 - Prompt message
#
# Returns:
#   Password via stdout
#######################################
get_password_input() {
    local prompt="$1"

    if command -v gum &>/dev/null; then
        gum input --password --header="$prompt"
    else
        local password
        read -rsp "$prompt: " password
        echo ""  # Newline after hidden input
        echo "$password"
    fi
}

#######################################
# select_multiple - Allow user to select multiple options
#
# Args:
#   $1 - Prompt message
#   $@ - Options array
#
# Returns:
#   Selected options via stdout (newline separated)
#######################################
select_multiple() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v gum &>/dev/null; then
        printf '%s\n' "${options[@]}" | gum choose --no-limit --header="$prompt"
    else
        echo "$prompt (comma-separated numbers)" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt" >&2
            ((i++))
        done

        local selections
        read -rp "Enter choices: " selections

        IFS=',' read -ra selected_indices <<< "$selections"
        for idx in "${selected_indices[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            if [[ "$idx" =~ ^[0-9]+$ ]] && ((idx >= 1 && idx <= ${#options[@]})); then
                echo "${options[$((idx-1))]}"
            fi
        done
    fi
}

#######################################
# wait_for_key - Wait for user to press any key
#
# Args:
#   $1 - Message (optional, default: "Press any key to continue...")
#######################################
wait_for_key() {
    local message="${1:-Press any key to continue...}"
    echo "$message"
    read -rsn1
}

# Export functions
export -f validate_step_format calculate_total_duration
export -f confirm_action select_option
export -f get_text_input get_password_input select_multiple
export -f wait_for_key
