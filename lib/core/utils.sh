#!/usr/bin/env bash
#
# lib/core/utils.sh - Utility functions
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices from bash utilities and ANSI handling 2025
# - ANSI escape sequence stripping
# - Visual width calculation
# - Duration formatting
# - Timestamp generation
#
# Constitutional Compliance: Principle V - Modular Architecture
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${UTILS_SH_LOADED:-}" ] || return 0
UTILS_SH_LOADED=1

#
# Strip ANSI escape sequences from string
#
# Arguments:
#   $1 - String with ANSI codes
#
# Returns:
#   String with ANSI codes removed
#
# Usage:
#   clean_text=$(strip_ansi "$colored_text")
#
strip_ansi() {
    local input="$1"

    # Remove ANSI escape sequences using sed
    # Pattern matches: ESC [ ... m (SGR codes)
    # Also matches: ESC [ ... H, ESC [ ... J (cursor control)
    echo "$input" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g'
}

#
# Get visual width of string (excluding ANSI codes)
#
# Arguments:
#   $1 - String (may contain ANSI codes)
#
# Returns:
#   Integer: number of visible characters
#
# Usage:
#   width=$(get_visual_width "$text_with_colors")
#
get_visual_width() {
    local text="$1"
    local clean_text

    # Strip ANSI codes first
    clean_text=$(strip_ansi "$text")

    # Count characters (wc -m counts multi-byte UTF-8 correctly)
    echo -n "$clean_text" | wc -m
}

#
# Calculate duration between two timestamps
#
# Arguments:
#   $1 - Start timestamp (seconds since epoch)
#   $2 - End timestamp (seconds since epoch)
#
# Returns:
#   Duration in seconds (integer)
#
# Usage:
#   start_time=$(date +%s)
#   # ... do work ...
#   end_time=$(date +%s)
#   duration=$(calculate_duration "$start_time" "$end_time")
#
calculate_duration() {
    local start_time="$1"
    local end_time="$2"

    echo $((end_time - start_time))
}

#
# Calculate duration with nanosecond precision
#
# Arguments:
#   $1 - Start timestamp (nanoseconds)
#   $2 - End timestamp (nanoseconds)
#
# Returns:
#   Duration in milliseconds (integer)
#
# Usage:
#   start_ns=$(date +%s%N)
#   # ... do work ...
#   end_ns=$(date +%s%N)
#   duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")
#
calculate_duration_ns() {
    local start_ns="$1"
    local end_ns="$2"
    local duration_ns

    duration_ns=$((end_ns - start_ns))

    # Convert to milliseconds
    echo $((duration_ns / 1000000))
}

#
# Format duration in human-readable format
#
# Arguments:
#   $1 - Duration in seconds
#
# Returns:
#   Formatted string (e.g., "2m 15s", "45s", "1h 5m 30s")
#
# Usage:
#   formatted=$(format_duration 135)
#   # Output: "2m 15s"
#
format_duration() {
    local total_seconds="$1"
    local hours
    local minutes
    local seconds
    local output=""

    # Calculate hours, minutes, seconds
    hours=$((total_seconds / 3600))
    minutes=$(((total_seconds % 3600) / 60))
    seconds=$((total_seconds % 60))

    # Build output string
    if [ "$hours" -gt 0 ]; then
        output="${hours}h "
    fi

    if [ "$minutes" -gt 0 ]; then
        output="${output}${minutes}m "
    fi

    if [ "$seconds" -gt 0 ] || [ -z "$output" ]; then
        output="${output}${seconds}s"
    fi

    # Trim trailing space
    echo "${output% }"
}

#
# Get current timestamp in ISO8601 format
#
# Returns:
#   ISO8601 timestamp (e.g., "2025-11-18T14:30:45.123Z")
#
# Usage:
#   timestamp=$(get_timestamp)
#
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
}

#
# Get Unix timestamp (seconds since epoch)
#
# Returns:
#   Seconds since 1970-01-01 00:00:00 UTC
#
# Usage:
#   unix_time=$(get_unix_timestamp)
#
get_unix_timestamp() {
    date +%s
}

#
# Get Unix timestamp with nanosecond precision
#
# Returns:
#   Nanoseconds since 1970-01-01 00:00:00 UTC
#
# Usage:
#   unix_ns=$(get_unix_timestamp_ns)
#
get_unix_timestamp_ns() {
    date +%s%N
}

#
# Check if command exists in PATH
#
# Arguments:
#   $1 - Command name
#
# Returns:
#   0 if command exists, 1 if not found
#
# Usage:
#   if command_exists "gum"; then
#       echo "gum is installed"
#   fi
#
command_exists() {
    local command_name="$1"

    # Use type -t to check command type, excluding aliases
    # Returns: file, builtin, function (we want these)
    # Does NOT return: alias (we want to exclude these)
    local cmd_type
    cmd_type=$(type -t "$command_name" 2>/dev/null)

    [[ "$cmd_type" == "file" || "$cmd_type" == "builtin" ]]
}

#
# Get command version (generic)
#
# Arguments:
#   $1 - Command name
#   $2 - Version flag (default: --version)
#
# Returns:
#   Version string from command output
#
# Usage:
#   version=$(get_command_version "gum")
#
get_command_version() {
    local command_name="$1"
    local version_flag="${2:---version}"

    if ! command_exists "$command_name"; then
        echo "NOT_FOUND"
        return 1
    fi

    "$command_name" "$version_flag" 2>&1 | head -n 1
}

#
# Check if running in SSH session
#
# Returns:
#   0 if SSH session, 1 if local
#
# Usage:
#   if is_ssh_session; then
#       echo "Running over SSH"
#   fi
#
is_ssh_session() {
    [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_CLIENT:-}" ] || [ -n "${SSH_TTY:-}" ]
}

#
# Check if terminal supports UTF-8
#
# Returns:
#   0 if UTF-8 supported, 1 if not
#
# Usage:
#   if is_utf8_terminal; then
#       echo "UTF-8 box drawing available"
#   fi
#
is_utf8_terminal() {
    local lang="${LANG:-}"
    local lc_all="${LC_ALL:-}"

    # Check LANG and LC_ALL for UTF-8
    [[ "$lang" == *"UTF-8"* ]] || [[ "$lc_all" == *"UTF-8"* ]]
}

#
# Repeat string N times
#
# Arguments:
#   $1 - String to repeat
#   $2 - Number of repetitions
#
# Returns:
#   Repeated string
#
# Usage:
#   separator=$(repeat_string "─" 50)
#
repeat_string() {
    local string="$1"
    local count="$2"
    local result=""

    for ((i = 0; i < count; i++)); do
        result+="$string"
    done

    echo "$result"
}

#
# Truncate string to max width
#
# Arguments:
#   $1 - String to truncate
#   $2 - Maximum width
#   $3 - Ellipsis (default: "...")
#
# Returns:
#   Truncated string
#
# Usage:
#   short=$(truncate_string "$long_message" 50)
#
truncate_string() {
    local string="$1"
    local max_width="$2"
    local ellipsis="${3:-...}"
    local current_width

    current_width=$(get_visual_width "$string")

    if [ "$current_width" -le "$max_width" ]; then
        echo "$string"
    else
        local ellipsis_width
        ellipsis_width=$(get_visual_width "$ellipsis")
        local target_width=$((max_width - ellipsis_width))

        # Strip ANSI first for accurate substring
        local clean_string
        clean_string=$(strip_ansi "$string")

        echo "${clean_string:0:$target_width}${ellipsis}"
    fi
}

#
# Center text in given width
#
# Arguments:
#   $1 - Text to center
#   $2 - Total width
#   $3 - Padding character (default: space)
#
# Returns:
#   Centered text
#
# Usage:
#   centered=$(center_text "Title" 50 "─")
#
center_text() {
    local text="$1"
    local total_width="$2"
    local pad_char="${3:- }"
    local text_width
    local left_padding
    local right_padding

    text_width=$(get_visual_width "$text")

    # Calculate padding
    left_padding=$(((total_width - text_width) / 2))
    right_padding=$((total_width - text_width - left_padding))

    # Build output
    repeat_string "$pad_char" "$left_padding"
    echo -n "$text"
    repeat_string "$pad_char" "$right_padding"
}

# Export functions for use in other modules
export -f strip_ansi
export -f get_visual_width
export -f calculate_duration
export -f calculate_duration_ns
export -f format_duration
export -f get_timestamp
export -f get_unix_timestamp
export -f get_unix_timestamp_ns
export -f command_exists
export -f get_command_version
export -f is_ssh_session
export -f is_utf8_terminal
export -f repeat_string
export -f truncate_string
export -f center_text
