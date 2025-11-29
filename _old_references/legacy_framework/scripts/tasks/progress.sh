#!/bin/bash
# Module: progress.sh
# Purpose: Standardized progress reporting functions for user-facing operations
# Dependencies: None
# Modules Required: None
# Exit Codes: 0=success, 1=invalid argument

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# ============================================================
# CONFIGURATION
# ============================================================

# Progress symbols (can be overridden by environment variables)
PROGRESS_SYMBOL_START="${PROGRESS_SYMBOL_START:-🔄}"
PROGRESS_SYMBOL_SUCCESS="${PROGRESS_SYMBOL_SUCCESS:-✅}"
PROGRESS_SYMBOL_ERROR="${PROGRESS_SYMBOL_ERROR:-❌}"
PROGRESS_SYMBOL_WARNING="${PROGRESS_SYMBOL_WARNING:-⚠️}"
PROGRESS_SYMBOL_INFO="${PROGRESS_SYMBOL_INFO:-ℹ️}"

# Color support detection
if [[ "${MANAGE_NO_COLOR:-0}" == "1" ]] || [[ "${NO_COLOR:-}" == "1" ]]; then
    COLOR_ENABLED=0
else
    COLOR_ENABLED=1
fi

# ANSI color codes
if [[ "$COLOR_ENABLED" -eq 1 ]]; then
    COLOR_RESET='\033[0m'
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_CYAN='\033[0;36m'
    COLOR_BOLD='\033[1m'
else
    COLOR_RESET=''
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_CYAN=''
    COLOR_BOLD=''
fi

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: show_progress
# Purpose: Display progress message with symbol and optional color
# Args: $1=status ("start"|"success"|"error"|"warning"|"info"), $2=message
# Returns: 0 always
# Side Effects: Prints formatted progress message to stdout (or stderr for errors)
show_progress() {
    local status="$1"
    local message="$2"

    case "$status" in
        "start")
            echo -e "${COLOR_CYAN}${PROGRESS_SYMBOL_START} ${COLOR_BOLD}${message}${COLOR_RESET}"
            ;;
        "success")
            echo -e "${COLOR_GREEN}${PROGRESS_SYMBOL_SUCCESS} ${message}${COLOR_RESET}"
            ;;
        "error")
            echo -e "${COLOR_RED}${PROGRESS_SYMBOL_ERROR} ${message}${COLOR_RESET}" >&2
            ;;
        "warning")
            echo -e "${COLOR_YELLOW}${PROGRESS_SYMBOL_WARNING} ${message}${COLOR_RESET}" >&2
            ;;
        "info")
            echo -e "${COLOR_BLUE}${PROGRESS_SYMBOL_INFO} ${message}${COLOR_RESET}"
            ;;
        *)
            # Fallback: no symbol
            echo "$message"
            ;;
    esac

    return 0
}

# Function: show_step
# Purpose: Display numbered step in a multi-step process
# Args: $1=current_step, $2=total_steps, $3=description
# Returns: 0 always
# Side Effects: Prints formatted step message to stdout
show_step() {
    local current_step="$1"
    local total_steps="$2"
    local description="$3"

    echo -e "${COLOR_BOLD}[${current_step}/${total_steps}]${COLOR_RESET} ${description}"
    return 0
}

# Function: show_header
# Purpose: Display section header for visual separation
# Args: $1=title
# Returns: 0 always
# Side Effects: Prints formatted header to stdout
show_header() {
    local title="$1"
    local width=60
    local separator
    separator=$(printf '=%.0s' $(seq 1 $width))

    echo ""
    echo -e "${COLOR_BOLD}${separator}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  ${title}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${separator}${COLOR_RESET}"
    echo ""

    return 0
}

# Function: show_subheader
# Purpose: Display subsection header
# Args: $1=title
# Returns: 0 always
# Side Effects: Prints formatted subheader to stdout
show_subheader() {
    local title="$1"

    echo ""
    echo -e "${COLOR_BOLD}## ${title}${COLOR_RESET}"
    echo ""

    return 0
}

# Function: start_spinner
# Purpose: Start a spinner for long-running operations (background process)
# Args: $1=message (optional)
# Returns: 0 on success, 1 if spinner already running
# Side Effects: Sets SPINNER_PID global variable, prints spinner animation
start_spinner() {
    local message="${1:-Processing...}"

    # Check if spinner already running
    if [[ -n "${SPINNER_PID:-}" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        return 1
    fi

    # Disable spinner if NO_COLOR or not a terminal
    if [[ "$COLOR_ENABLED" -eq 0 ]] || [[ ! -t 1 ]]; then
        echo "$message"
        return 0
    fi

    # Start spinner in background
    {
        local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0

        while true; do
            i=$(( (i+1) % ${#spin_chars} ))
            printf "\r${COLOR_CYAN}${spin_chars:$i:1}${COLOR_RESET} %s" "$message" >&2
            sleep 0.1
        done
    } &

    SPINNER_PID=$!
    return 0
}

# Function: stop_spinner
# Purpose: Stop the spinner started by start_spinner
# Args: $1=status ("success"|"error"|"warning", optional), $2=final_message (optional)
# Returns: 0 always
# Side Effects: Kills spinner process, clears spinner line, shows final status
stop_spinner() {
    local status="${1:-success}"
    local final_message="${2:-Done}"

    # If spinner not running, just return
    if [[ -z "${SPINNER_PID:-}" ]]; then
        return 0
    fi

    # Kill spinner process
    if kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
    fi

    unset SPINNER_PID

    # Clear spinner line and show final status
    printf "\r\033[K" >&2  # Clear line

    case "$status" in
        "success")
            echo -e "${COLOR_GREEN}${PROGRESS_SYMBOL_SUCCESS} ${final_message}${COLOR_RESET}"
            ;;
        "error")
            echo -e "${COLOR_RED}${PROGRESS_SYMBOL_ERROR} ${final_message}${COLOR_RESET}" >&2
            ;;
        "warning")
            echo -e "${COLOR_YELLOW}${PROGRESS_SYMBOL_WARNING} ${final_message}${COLOR_RESET}" >&2
            ;;
        *)
            echo "$final_message"
            ;;
    esac

    return 0
}

# Function: show_progress_bar
# Purpose: Display a simple progress bar
# Args: $1=current, $2=total, $3=description (optional)
# Returns: 0 always
# Side Effects: Prints progress bar to stdout
show_progress_bar() {
    local current="$1"
    local total="$2"
    local description="${3:-}"

    local percentage=$((current * 100 / total))
    local completed=$((current * 50 / total))
    local remaining=$((50 - completed))

    local bar
    bar=$(printf '█%.0s' $(seq 1 $completed))
    bar="${bar}$(printf '░%.0s' $(seq 1 $remaining))"

    if [[ -n "$description" ]]; then
        printf "\r[%s] %3d%% - %s" "$bar" "$percentage" "$description"
    else
        printf "\r[%s] %3d%%" "$bar" "$percentage"
    fi

    # Print newline if complete
    if [[ "$current" -eq "$total" ]]; then
        echo ""
    fi

    return 0
}

# Function: show_timing
# Purpose: Display operation timing information
# Args: $1=start_time (from $(date +%s)), $2=operation_name
# Returns: 0 always
# Side Effects: Prints formatted timing message to stdout
show_timing() {
    local start_time="$1"
    local operation_name="$2"
    local end_time
    end_time="$(date +%s)"

    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    if [[ $minutes -gt 0 ]]; then
        echo -e "${COLOR_CYAN}⏱ ${operation_name} completed in ${minutes}m ${seconds}s${COLOR_RESET}"
    else
        echo -e "${COLOR_CYAN}⏱ ${operation_name} completed in ${seconds}s${COLOR_RESET}"
    fi

    return 0
}

# Function: confirm
# Purpose: Prompt user for yes/no confirmation
# Args: $1=prompt_message, $2=default (optional: "y" or "n", defaults to "n")
# Returns: 0 for yes, 1 for no
# Side Effects: Prints prompt to stdout, reads from stdin
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    # Show prompt with default indicator
    if [[ "$default" == "y" ]]; then
        printf "%s [Y/n]: " "$prompt"
    else
        printf "%s [y/N]: " "$prompt"
    fi

    read -r response

    # Use default if empty
    if [[ -z "$response" ]]; then
        response="$default"
    fi

    # Check response
    case "${response,,}" in  # Convert to lowercase
        y|yes)
            return 0
            ;;
        n|no)
            return 1
            ;;
        *)
            # Invalid response, use default
            if [[ "$default" == "y" ]]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Function: show_summary
# Purpose: Display summary of operation results
# Args: $1=success_count, $2=failure_count, $3=operation_type (optional)
# Returns: 0 if all successful, 1 if any failures
# Side Effects: Prints formatted summary to stdout
show_summary() {
    local success_count="$1"
    local failure_count="$2"
    local operation_type="${3:-operations}"

    local total_count=$((success_count + failure_count))

    echo ""
    echo -e "${COLOR_BOLD}=== Summary ===${COLOR_RESET}"
    echo -e "Total ${operation_type}: ${COLOR_BOLD}${total_count}${COLOR_RESET}"
    echo -e "${COLOR_GREEN}Successful: ${success_count}${COLOR_RESET}"

    if [[ "$failure_count" -gt 0 ]]; then
        echo -e "${COLOR_RED}Failed: ${failure_count}${COLOR_RESET}"
        return 1
    else
        echo -e "${COLOR_GREEN}All ${operation_type} completed successfully${COLOR_RESET}"
        return 0
    fi
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # If run directly, show demo of progress functions
    cat << 'EOF'
This module provides progress reporting functions and should be sourced, not executed directly.

Usage:
    source scripts/progress.sh

Available functions:
    - show_progress <status> <message>
    - show_step <current> <total> <description>
    - show_header <title>
    - show_subheader <title>
    - start_spinner [message]
    - stop_spinner [status] [final_message]
    - show_progress_bar <current> <total> [description]
    - show_timing <start_time> <operation_name>
    - confirm <prompt> [default]
    - show_summary <success_count> <failure_count> [operation_type]

Example:
    source scripts/progress.sh
    show_header "Installation"
    show_step 1 3 "Installing Node.js"
    show_progress "start" "Downloading Node.js..."
    # ... operation ...
    show_progress "success" "Node.js installed"
EOF
    exit 0
fi
