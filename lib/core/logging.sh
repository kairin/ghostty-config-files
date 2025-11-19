#!/usr/bin/env bash
#
# lib/core/logging.sh - Dual-format logging system (JSON + human-readable)
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices from bash logging patterns 2025
# - Structured logging with JSON output
# - Human-readable console output with color coding
# - Log levels: TEST, INFO, SUCCESS, WARNING, ERROR
# - Dual output: /tmp/ghostty-start-logs/start-TIMESTAMP.log (human)
#              /tmp/ghostty-start-logs/start-TIMESTAMP.log.json (structured)
# - Critical errors append to /tmp/ghostty-start-logs/errors.log
# - Log rotation: keep last 10 installations
#
# Constitutional Compliance: Principle VII - Structured Logging
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${LOGGING_SH_LOADED:-}" ] || return 0
LOGGING_SH_LOADED=1

# Global log file paths (initialized in init_logging)
LOG_DIR="/tmp/ghostty-start-logs"
LOG_FILE=""
LOG_FILE_JSON=""
ERROR_LOG="${LOG_DIR}/errors.log"

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

    # Create log directory if missing
    mkdir -p "$LOG_DIR"

    # Set log file paths
    LOG_FILE="${LOG_DIR}/start-${timestamp}.log"
    LOG_FILE_JSON="${LOG_DIR}/start-${timestamp}.log.json"

    # Initialize log files
    touch "$LOG_FILE"
    echo "[" > "$LOG_FILE_JSON"  # Start JSON array

    # Rotate old logs (keep last 10)
    rotate_logs

    # Log initialization
    log "INFO" "Logging system initialized"
    log "INFO" "Human-readable log: $LOG_FILE"
    log "INFO" "Structured JSON log: $LOG_FILE_JSON"
}

#
# Rotate old log files (keep last 10 installations)
#
rotate_logs() {
    local log_count

    # Count existing log files
    log_count=$(find "$LOG_DIR" -name "start-*.log" -type f | wc -l)

    # If more than 10, remove oldest
    if [ "$log_count" -gt 10 ]; then
        find "$LOG_DIR" -name "start-*.log" -type f -printf '%T+ %p\n' | \
            sort | \
            head -n -10 | \
            cut -d' ' -f2- | \
            xargs rm -f

        # Also remove corresponding JSON files
        find "$LOG_DIR" -name "start-*.log.json" -type f -printf '%T+ %p\n' | \
            sort | \
            head -n -10 | \
            cut -d' ' -f2- | \
            xargs rm -f
    fi
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

export -f get_level_num

# Export functions for use in other modules
export -f init_logging
export -f rotate_logs
export -f get_timestamp
export -f get_log_file
export -f log
export -f finalize_logging
export -f set_log_level
