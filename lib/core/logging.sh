#!/usr/bin/env bash
#
# lib/core/logging.sh - Dual-format logging system (JSON + human-readable) with dual-mode output
#
# CONTEXT7 REFERENCE: Bash logging best practices 2025
# - Dual-mode output: Terminal (collapsed) + Log files (full verbose)
# - Structured logging with JSON output
# - Human-readable console output with color coding
# - Log levels: TEST, INFO, SUCCESS, WARNING, ERROR
# - Permanent logs: ${REPO_ROOT}/logs/ (NOT /tmp)
# - Three log files per session:
#   * start-TIMESTAMP.log (human-readable summary)
#   * start-TIMESTAMP.log.json (structured JSON)
#   * start-TIMESTAMP-verbose.log (FULL command output for debugging)
# - Critical errors append to ${REPO_ROOT}/logs/errors.log
# - Log rotation: keep last 10 installations or files >50MB
#
# Constitutional Compliance: Principle VII - Structured Logging
# User Requirement: "all logs captured in full, extremely verbose regardless"
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${LOGGING_SH_LOADED:-}" ] || return 0
LOGGING_SH_LOADED=1

# Determine repository root for permanent log directory
# This ensures logs persist across reboots (unlike /tmp)
LOGGING_REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Global log file paths (initialized in init_logging)
# CHANGED: Use permanent directory instead of /tmp
LOG_DIR="${LOGGING_REPO_ROOT}/logs/installation"
LOG_FILE=""
LOG_FILE_JSON=""
VERBOSE_LOG_FILE=""  # NEW: Full verbose log for debugging
ERROR_LOG="${LOGGING_REPO_ROOT}/logs/errors.log"

# ANSI color codes for console output
COLOR_RESET="\033[0m"
COLOR_TEST="\033[0;36m"      # Cyan
COLOR_INFO="\033[0;34m"      # Blue
COLOR_SUCCESS="\033[0;32m"   # Green
COLOR_WARNING="\033[0;33m"   # Yellow
COLOR_ERROR="\033[0;31m"     # Red
COLOR_BOLD="\033[1m"

# Helper to get numeric log level
get_level_num() {
    case "$1" in
        DEBUG)   echo 0 ;;
        TEST)    echo 0 ;;
        INFO)    echo 1 ;;
        SUCCESS) echo 2 ;;
        WARNING) echo 3 ;;
        ERROR)   echo 4 ;;
        *)       echo -1 ;;
    esac
}

# Current log level threshold (default: TEST - show all)
LOG_LEVEL_THRESHOLD=0

#
# Initialize logging system
#
# Creates log directory, sets up log file paths, rotates old logs
#
# Usage: init_logging
#
init_logging() {
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")

    # Create log directory if missing (plus component subdirectory)
    mkdir -p "$LOG_DIR"
    mkdir -p "${LOGGING_REPO_ROOT}/logs/components"

    # Set log file paths
    LOG_FILE="${LOG_DIR}/start-${timestamp}.log"
    LOG_FILE_JSON="${LOG_DIR}/start-${timestamp}.log.json"
    VERBOSE_LOG_FILE="${LOG_DIR}/start-${timestamp}-verbose.log"  # NEW: Full verbose log

    # Initialize log files
    touch "$LOG_FILE"
    touch "$VERBOSE_LOG_FILE"  # NEW: Initialize verbose log
    echo "[" > "$LOG_FILE_JSON"  # Start JSON array

    # Rotate old logs (keep last 10)
    rotate_logs

    # Log initialization
    log "INFO" "Logging system initialized (dual-mode output)"
    log "INFO" "Human-readable log: $LOG_FILE"
    log "INFO" "Structured JSON log: $LOG_FILE_JSON"
    log "INFO" "Full verbose log: $VERBOSE_LOG_FILE"
    log "INFO" "Error log: $ERROR_LOG"
}

#
# Rotate old log files (keep last 10 installations or remove files >50MB)
#
rotate_logs() {
    local log_count

    # Ensure log directory exists
    [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"

    # Count existing log files
    log_count=$(find "$LOG_DIR" -name "start-*.log" -type f 2>/dev/null | wc -l)

    # If more than 10, remove oldest
    if [ "$log_count" -gt 10 ]; then
        find "$LOG_DIR" -name "start-*.log" -type f -printf '%T+ %p\n' 2>/dev/null | \
            sort | \
            head -n -10 | \
            cut -d' ' -f2- | \
            xargs rm -f 2>/dev/null || true

        # Also remove corresponding JSON and verbose files
        find "$LOG_DIR" -name "start-*.log.json" -type f -printf '%T+ %p\n' 2>/dev/null | \
            sort | \
            head -n -10 | \
            cut -d' ' -f2- | \
            xargs rm -f 2>/dev/null || true

        find "$LOG_DIR" -name "start-*-verbose.log" -type f -printf '%T+ %p\n' 2>/dev/null | \
            sort | \
            head -n -10 | \
            cut -d' ' -f2- | \
            xargs rm -f 2>/dev/null || true
    fi

    # Remove log files >50MB (protection against runaway logging)
    find "$LOG_DIR" -name "*.log" -type f -size +50M -delete 2>/dev/null || true
}

#
# Get timestamp in ISO8601 format
#
# Returns: ISO8601 timestamp string
#
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
}

#
# Get current log file path
#
# Returns: Path to current human-readable log file
#
# Usage:
#   command 2>&1 | tee -a "$(get_log_file)"
#
get_log_file() {
    echo "$LOG_FILE"
}

#
# Get current verbose log file path
#
# Returns: Path to current verbose log file (full command output)
#
# Usage:
#   log_command_output "Task description" "$(command 2>&1)"
#
get_verbose_log_file() {
    echo "$VERBOSE_LOG_FILE"
}

#
# Log command output to verbose log file
#
# This function ALWAYS logs to the verbose log file regardless of VERBOSE_MODE.
# It captures FULL command output for debugging purposes while keeping terminal
# output collapsed (Docker-like) when VERBOSE_MODE=false.
#
# Arguments:
#   $1 - Command description (e.g., "Downloading Zig Compiler")
#   $2 - Command output (from captured variable or command substitution)
#
# Behavior:
#   - Always writes to verbose log file (regardless of VERBOSE_MODE)
#   - Appends timestamp and command description as separator
#   - Never displays to terminal (handled by run_command_collapsible)
#   - Creates log file if missing
#
# Usage:
#   output=$(curl -fsSL https://example.com/file.tar.gz 2>&1)
#   log_command_output "Downloading file" "$output"
#
# Constitutional Compliance:
#   - User Requirement: "all logs captured in full, extremely verbose regardless"
#   - Dual-mode output: Terminal (collapsed) + Log files (full verbose)
#
log_command_output() {
    local description="$1"
    local output="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Ensure verbose log file exists
    if [ -z "$VERBOSE_LOG_FILE" ]; then
        # Fallback: create verbose log file if not initialized
        VERBOSE_LOG_FILE="${LOG_DIR}/start-$(date +"%Y%m%d-%H%M%S")-verbose.log"
        touch "$VERBOSE_LOG_FILE"
    fi

    # Write to verbose log (ALWAYS, regardless of VERBOSE_MODE)
    {
        echo "================================"
        echo "[$timestamp] $description"
        echo "================================"
        echo "$output"
        echo ""
    } >> "$VERBOSE_LOG_FILE"
}

#
# Log a message with specified level
#
# Arguments:
#   $1 - Log level (TEST|INFO|SUCCESS|WARNING|ERROR)
#   $2 - Message to log
#
# Output:
#   - Console output with color coding
#   - Human-readable log file
#   - Structured JSON log file
#   - Error log (if level is ERROR)
#
# Usage:
#   log "INFO" "Starting installation"
#   log "ERROR" "Failed to install component: $error_message"
#
log() {
    local level="$1"
    local message="$2"
    local timestamp
    local color
    local level_num

    # Validate log level and get number
    level_num=$(get_level_num "$level")
    if [ "$level_num" -eq -1 ]; then
        echo "ERROR: Invalid log level '$level'" >&2
        return 1
    fi

    # Check if message should be logged based on threshold
    if [ "$level_num" -lt "$LOG_LEVEL_THRESHOLD" ]; then
        return 0
    fi

    # Get timestamp
    timestamp=$(get_timestamp)

    # Select color based on level
    case "$level" in
        DEBUG)   color="$COLOR_TEST" ;;
        TEST)    color="$COLOR_TEST" ;;
        INFO)    color="$COLOR_INFO" ;;
        SUCCESS) color="$COLOR_SUCCESS" ;;
        WARNING) color="$COLOR_WARNING" ;;
        ERROR)   color="$COLOR_ERROR" ;;
        *)       color="$COLOR_RESET" ;;
    esac

    # Console output (with color)
    printf "${COLOR_BOLD}[%s]${COLOR_RESET} ${color}%s${COLOR_RESET} %s\n" \
        "$timestamp" "$level" "$message"

    # Human-readable log file output (no color codes)
    if [ -n "${LOG_FILE:-}" ] && [ -f "$LOG_FILE" ]; then
        printf "[%s] %s %s\n" "$timestamp" "$level" "$message" >> "$LOG_FILE"
    fi

    # Structured JSON log output
    if [ -n "${LOG_FILE_JSON:-}" ] && [ -f "$LOG_FILE_JSON" ]; then
        # Escape special characters in message for JSON
        local escaped_message
        escaped_message=$(printf '%s' "$message" | jq -Rs .)

        # Append JSON entry (comma-separated, array format)
        cat >> "$LOG_FILE_JSON" <<EOF
{
  "timestamp": "$timestamp",
  "level": "$level",
  "message": $escaped_message
},
EOF
    fi

    # Critical errors also go to error log
    if [ "$level" = "ERROR" ] && [ -f "$ERROR_LOG" ]; then
        printf "[%s] ERROR: %s\n" "$timestamp" "$message" >> "$ERROR_LOG"
    fi
}

#
# Finalize logging (close JSON array)
#
# Call this at the end of script execution to properly close JSON log file
#
finalize_logging() {
    if [ -n "${LOG_FILE_JSON:-}" ] && [ -f "$LOG_FILE_JSON" ]; then
        # Remove trailing comma and close JSON array
        sed -i '$ s/,$//' "$LOG_FILE_JSON"
        echo "]" >> "$LOG_FILE_JSON"

        log "INFO" "Logging finalized"
    fi
}

#
# Set log level threshold
#
# Arguments:
#   $1 - Log level (TEST|INFO|SUCCESS|WARNING|ERROR)
#
# Usage:
#   set_log_level "WARNING"  # Only show WARNING and ERROR
#
set_log_level() {
    local level="$1"
    local level_num
    
    level_num=$(get_level_num "$level")
    if [ "$level_num" -eq -1 ]; then
        echo "ERROR: Invalid log level '$level'" >&2
        return 1
    fi

    LOG_LEVEL_THRESHOLD="$level_num"
    log "INFO" "Log level threshold set to $level"
}

#
# Compare two semantic version strings
#
# Arguments:
#   $1 - First version (e.g., "1.2.3")
#   $2 - Second version (e.g., "1.2.4")
#
# Returns:
#   0 if versions are equal
#   1 if first version is greater
#   2 if second version is greater
#
# Usage:
#   version_compare "1.2.3" "1.2.4"
#   result=$?
#   if [ $result -eq 2 ]; then echo "Update available"; fi
#
version_compare() {
    local ver1="$1"
    local ver2="$2"

    # Strip leading 'v' if present
    ver1="${ver1#v}"
    ver2="${ver2#v}"

    # Handle empty versions
    if [ -z "$ver1" ] || [ "$ver1" = "unknown" ]; then
        [ -z "$ver2" ] || [ "$ver2" = "unknown" ] && return 0 || return 2
    fi
    if [ -z "$ver2" ] || [ "$ver2" = "unknown" ]; then
        return 1
    fi

    # If versions are identical, return equal
    if [ "$ver1" = "$ver2" ]; then
        return 0
    fi

    # Split versions into components and compare
    local IFS='.'
    local i ver1_arr ver2_arr
    read -ra ver1_arr <<< "$ver1"
    read -ra ver2_arr <<< "$ver2"

    # Compare each component
    for ((i=0; i<${#ver1_arr[@]} || i<${#ver2_arr[@]}; i++)); do
        local v1=${ver1_arr[i]:-0}
        local v2=${ver2_arr[i]:-0}

        # Remove non-numeric suffixes (e.g., "1.2.3-beta" -> "1.2.3")
        # Use parameter expansion to handle non-numeric characters
        v1=${v1%%[^0-9]*}
        v2=${v2%%[^0-9]*}
        v1=${v1:-0}
        v2=${v2:-0}

        if [ "$v1" -gt "$v2" ]; then
            return 1  # First version is greater
        elif [ "$v1" -lt "$v2" ]; then
            return 2  # Second version is greater
        fi
    done

    return 0  # Versions are equal
}

#
# Check if first version is greater than second version
#
# Arguments:
#   $1 - First version (e.g., "1.2.4")
#   $2 - Second version (e.g., "1.2.3")
#
# Returns:
#   0 (true) if first version is greater
#   1 (false) otherwise
#
# Usage:
#   if version_greater "1.2.4" "1.2.3"; then
#       echo "Update available"
#   fi
#
version_greater() {
    version_compare "$1" "$2"
    [ $? -eq 1 ]
}

#
# Check if versions are equal
#
# Arguments:
#   $1 - First version
#   $2 - Second version
#
# Returns:
#   0 (true) if versions are equal
#   1 (false) otherwise
#
# Usage:
#   if version_equal "1.2.3" "1.2.3"; then
#       echo "Already up-to-date"
#   fi
#
version_equal() {
    version_compare "$1" "$2"
    [ $? -eq 0 ]
}

export -f get_level_num

# Export functions for use in other modules
export -f init_logging
export -f rotate_logs
export -f get_timestamp
export -f get_log_file
export -f get_verbose_log_file  # NEW: Get verbose log file path
export -f log_command_output    # NEW: Log command output to verbose log
export -f log
export -f finalize_logging
export -f set_log_level
export -f version_compare       # NEW: Semantic version comparison
export -f version_greater       # NEW: Check if version is greater
export -f version_equal         # NEW: Check if versions are equal
