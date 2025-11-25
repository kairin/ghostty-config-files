#!/usr/bin/env bash
# lib/ui/tui/render.sh - TUI visual rendering utilities
# Extracted from lib/installers/common/tui-helpers.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TUI_RENDER_SOURCED:-}" ]] && return 0
readonly _TUI_RENDER_SOURCED=1

#######################################
# show_component_header - Display styled header for component installation
#
# Args:
#   $1 - Component name (e.g., "Ghostty", "ZSH", "Python UV")
#
# Output:
#   Styled header box with component name
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
        SKIPPED)
            status_symbol="[SKIPPED]"
            status_color="cyan"
            ;;
        *)
            status_symbol="[?]"
            status_color="white"
            ;;
    esac

    # Format duration
    local duration_str
    duration_str=$(format_duration "$total_duration")

    # ALWAYS use gum (installed as priority 0, guaranteed available)
    echo ""
    gum style \
        --border none \
        --foreground "$status_color" \
        --bold \
        --align center \
        --width 60 \
        "$status_symbol ${component_name} installation $status ($total_steps/$total_steps steps, $duration_str total)"

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
# print_header - Print a styled section header
#
# Args:
#   $1 - Header text
#   $2 - Width (optional, default 60)
#######################################
print_header() {
    local text="$1"
    local width="${2:-60}"
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '=')

    echo ""
    echo "$line"
    echo "  $text"
    echo "$line"
    echo ""
}

#######################################
# print_status_line - Print a status line with alignment
#
# Args:
#   $1 - Label
#   $2 - Value
#   $3 - Status indicator (optional: OK, FAIL, WARN)
#######################################
print_status_line() {
    local label="$1"
    local value="$2"
    local status="${3:-}"

    local indicator=""
    case "$status" in
        OK)   indicator="[OK]" ;;
        FAIL) indicator="[FAIL]" ;;
        WARN) indicator="[WARN]" ;;
    esac

    printf "%-30s %s %s\n" "$label:" "$value" "$indicator"
}

# Export functions
export -f show_component_header show_component_footer
export -f format_duration show_progress_bar show_spinner
export -f print_header print_status_line
