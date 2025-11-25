#!/bin/bash
# common.sh - Common utility functions for path resolution, logging, error handling

set -euo pipefail

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${COMMON_SH_LOADED:-}" ]] && return 0
readonly COMMON_SH_LOADED=1

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: resolve_absolute_path
# Purpose: Convert relative path to absolute path, resolving symlinks
# Args: $1=path (relative or absolute)
# Returns: 0 on success, 1 on failure (path doesn't exist)
# Side Effects: Prints absolute path to stdout
resolve_absolute_path() {
    local path="$1"

    if [[ -z "$path" ]]; then
        echo "ERROR: Path argument is required" >&2
        return 2
    fi

    if [[ ! -e "$path" ]]; then
        echo "ERROR: Path does not exist: $path" >&2
        return 1
    fi

    # Resolve to absolute path
    local absolute_path
    absolute_path="$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"

    echo "$absolute_path"
    return 0
}

# Function: get_script_dir
# Purpose: Get the directory containing the calling script
# Args: None (uses BASH_SOURCE from caller context)
# Returns: 0 on success
# Side Effects: Prints script directory to stdout
get_script_dir() {
    local script_dir

    # Get directory of the calling script (one level up in call stack)
    if [[ "${#BASH_SOURCE[@]}" -gt 1 ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    else
        # Fallback: current working directory
        script_dir="$(pwd)"
    fi

    echo "$script_dir"
    return 0
}

# Function: get_project_root
# Purpose: Find the repository root directory (contains .git/)
# Args: $1=starting_path (optional, defaults to current directory)
# Returns: 0 on success, 1 if not in git repository
# Side Effects: Prints project root path to stdout
get_project_root() {
    local current_dir="${1:-$(pwd)}"

    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.git" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    echo "ERROR: Not in a git repository" >&2
    return 1
}

# Function: log_info
# Purpose: Log informational message with timestamp
# Args: $1=message
# Returns: 0 always
# Side Effects: Prints formatted log message to stdout
log_info() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[INFO] [$timestamp] $message"
    return 0
}

# Function: log_warn
# Purpose: Log warning message with timestamp
# Args: $1=message
# Returns: 0 always
# Side Effects: Prints formatted warning to stderr
log_warn() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[WARN] [$timestamp] $message" >&2
    return 0
}

# Function: log_error
# Purpose: Log error message with timestamp
# Args: $1=message
# Returns: 0 always (doesn't exit, caller decides)
# Side Effects: Prints formatted error to stderr
log_error() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[ERROR] [$timestamp] $message" >&2
    return 0
}

# Function: log_debug
# Purpose: Log debug message with timestamp (only if DEBUG=1)
# Args: $1=message
# Returns: 0 always
# Side Effects: Prints formatted debug message to stderr if DEBUG is enabled
log_debug() {
    local message="$1"

    # Only log if DEBUG environment variable is set
    if [[ "${DEBUG:-0}" == "1" ]] || [[ "${MANAGE_DEBUG:-0}" == "1" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        echo "[DEBUG] [$timestamp] $message" >&2
    fi

    return 0
}

# Function: log_event
# Purpose: Structured logging with severity levels (DEBUG|INFO|WARNING|ERROR|CRITICAL)
# Args: $1=severity (DEBUG|INFO|WARNING|ERROR|CRITICAL), $2=message, $3=context (optional JSON)
# Returns: 0 always
# Side Effects: Prints structured JSON log to stderr (if LOG_JSON=1) or formatted text
log_event() {
    local severity="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp
    timestamp="$(date -Iseconds)"

    # Validate severity level
    case "$severity" in
        DEBUG|INFO|WARNING|ERROR|CRITICAL) ;;
        *)
            echo "[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] Invalid severity level: $severity" >&2
            return 1
            ;;
    esac

    # Skip DEBUG messages unless debug mode enabled
    if [[ "$severity" == "DEBUG" ]] && [[ "${DEBUG:-0}" != "1" ]] && [[ "${MANAGE_DEBUG:-0}" != "1" ]]; then
        return 0
    fi

    # Structured JSON logging (if enabled)
    if [[ "${LOG_JSON:-0}" == "1" ]]; then
        local json_log="{\"timestamp\":\"$timestamp\",\"severity\":\"$severity\",\"message\":\"$message\""

        # Add context if provided
        if [[ -n "$context" ]]; then
            json_log="$json_log,\"context\":$context"
        fi

        json_log="$json_log}"

        # Log to JSON file if LOG_FILE is set
        if [[ -n "${LOG_FILE:-}" ]]; then
            echo "$json_log" >> "$LOG_FILE"
        else
            echo "$json_log" >&2
        fi
    else
        # Human-readable text logging
        local prefix
        case "$severity" in
            DEBUG)    prefix="[DEBUG]   " ;;
            INFO)     prefix="[INFO]    " ;;
            WARNING)  prefix="[WARNING] " ;;
            ERROR)    prefix="[ERROR]   " ;;
            CRITICAL) prefix="[CRITICAL]" ;;
        esac

        local formatted_time
        formatted_time="$(date '+%Y-%m-%d %H:%M:%S')"

        # ERROR and CRITICAL go to stderr, others to stdout
        if [[ "$severity" == "ERROR" ]] || [[ "$severity" == "CRITICAL" ]]; then
            echo "$prefix [$formatted_time] $message" >&2
        else
            echo "$prefix [$formatted_time] $message"
        fi
    fi

    return 0
}

# Function: die
# Purpose: Print error message and exit with specified code
# Args: $1=error_message, $2=exit_code (optional, defaults to 1)
# Returns: Never returns (calls exit)
# Side Effects: Prints error message to stderr and exits script
die() {
    local message="$1"
    local exit_code="${2:-1}"

    log_error "$message"
    exit "$exit_code"
}

# Function: require_command
# Purpose: Verify that a required command is available
# Args: $1=command_name, $2=error_message (optional)
# Returns: 0 if command exists, 1 if not
# Side Effects: Logs error if command not found
require_command() {
    local command_name="$1"
    local error_message="${2:-Command '$command_name' is required but not found}"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        log_error "$error_message"
        return 1
    fi

    return 0
}

# Function: require_file
# Purpose: Verify that a required file exists
# Args: $1=file_path, $2=error_message (optional)
# Returns: 0 if file exists, 1 if not
# Side Effects: Logs error if file not found
require_file() {
    local file_path="$1"
    local error_message="${2:-Required file not found: $file_path}"

    if [[ ! -f "$file_path" ]]; then
        log_error "$error_message"
        return 1
    fi

    return 0
}

# Function: require_dir
# Purpose: Verify that a required directory exists
# Args: $1=dir_path, $2=error_message (optional)
# Returns: 0 if directory exists, 1 if not
# Side Effects: Logs error if directory not found
require_dir() {
    local dir_path="$1"
    local error_message="${2:-Required directory not found: $dir_path}"

    if [[ ! -d "$dir_path" ]]; then
        log_error "$error_message"
        return 1
    fi

    return 0
}

# Function: ensure_dir
# Purpose: Create directory if it doesn't exist
# Args: $1=dir_path
# Returns: 0 on success, 1 on failure
# Side Effects: Creates directory (and parents if needed)
ensure_dir() {
    local dir_path="$1"

    if [[ -z "$dir_path" ]]; then
        log_error "Directory path argument is required"
        return 2
    fi

    if [[ ! -d "$dir_path" ]]; then
        log_debug "Creating directory: $dir_path"
        if ! mkdir -p "$dir_path"; then
            log_error "Failed to create directory: $dir_path"
            return 1
        fi
    fi

    return 0
}

# Function: is_writable
# Purpose: Check if a path is writable
# Args: $1=path
# Returns: 0 if writable, 1 if not
# Side Effects: None
is_writable() {
    local path="$1"

    if [[ -w "$path" ]]; then
        return 0
    else
        return 1
    fi
}

# Function: get_timestamp
# Purpose: Generate timestamp string for file naming
# Args: $1=format (optional: "file" for filenames, "log" for logs, default is ISO8601)
# Returns: 0 always
# Side Effects: Prints timestamp to stdout
get_timestamp() {
    local format="${1:-iso}"

    case "$format" in
        "file")
            # Safe for filenames: YYYYMMDD-HHMMSS
            date '+%Y%m%d-%H%M%S'
            ;;
        "log")
            # Human-readable for logs: YYYY-MM-DD HH:MM:SS
            date '+%Y-%m-%d %H:%M:%S'
            ;;
        "iso")
            # ISO 8601 format
            date '+%Y-%m-%dT%H:%M:%S%z'
            ;;
        *)
            # Default to ISO
            date '+%Y-%m-%dT%H:%M:%S%z'
            ;;
    esac

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # If run directly, show usage
    cat << 'EOF'
This module provides common utility functions and should be sourced, not executed directly.

Usage:
    source scripts/common.sh

Available functions:
    - resolve_absolute_path <path>
    - get_script_dir
    - get_project_root [starting_path]
    - log_info <message>
    - log_warn <message>
    - log_error <message>
    - log_debug <message>
    - die <message> [exit_code]
    - require_command <command_name> [error_message]
    - require_file <file_path> [error_message]
    - require_dir <dir_path> [error_message]
    - ensure_dir <dir_path>
    - is_writable <path>
    - get_timestamp [format]

Example:
    source scripts/common.sh
    log_info "Starting installation"
    require_command "git" || die "Git is required"
    PROJECT_ROOT=$(get_project_root)
EOF
    exit 0
fi

# ============================================================
# PACKAGE MIGRATION SPECIFIC UTILITIES
# ============================================================

# Error codes (per contracts/cli-interface.md)
readonly E001="snapd daemon not running"
readonly E002="Insufficient disk space"
readonly E003="Network timeout (snap store)"
readonly E004="Package not found"
readonly E005="Backup corrupted"
readonly E006="Permission denied"
readonly E007="Dependency conflict"
readonly E008="No snap alternative found"

# Error handling for migration
error_exit() {
    local error_code="$1"
    local error_message="$2"
    local exit_code="${3:-1}"

    log_error "[$error_code] $error_message"
    exit "$exit_code"
}

error_warn() {
    local error_code="$1"
    local error_message="$2"

    log_warn "[$error_code] $error_message"
}

# JSON utilities (using jq)
json_parse() {
    local json_file="$1"
    local jq_filter="$2"

    if [ ! -f "$json_file" ]; then
        log_error "JSON file not found: $json_file"
        return 1
    fi

    jq -r "$jq_filter" "$json_file" 2>/dev/null || {
        log_error "Failed to parse JSON file: $json_file"
        return 1
    }
}

json_validate() {
    local json_string="$1"

    echo "$json_string" | jq empty >/dev/null 2>&1
    return $?
}

json_get_field() {
    local json_string="$1"
    local field_path="$2"

    echo "$json_string" | jq -r "$field_path" 2>/dev/null
}

# Configuration loader
load_config() {
    local config_file="${1:-$HOME/.config/package-migration/config.json}"

    if [ ! -f "$config_file" ]; then
        log_warn "Config file not found: $config_file, using defaults"
        return 1
    fi

    # Export configuration as environment variables with MIGRATION_ prefix
    export MIGRATION_BACKUP_DIR=$(json_parse "$config_file" '.backup.directory' 2>/dev/null || echo "$HOME/.config/package-migration/backups")
    export MIGRATION_RETENTION_DAYS=$(json_parse "$config_file" '.backup.retention_days' 2>/dev/null || echo "30")
    export MIGRATION_CACHE_ENABLED=$(json_parse "$config_file" '.cache.enabled' 2>/dev/null || echo "true")
    export MIGRATION_CACHE_TTL=$(json_parse "$config_file" '.cache.ttl_seconds' 2>/dev/null || echo "3600")
    export MIGRATION_BATCH_SIZE=$(json_parse "$config_file" '.migration.batch_size' 2>/dev/null || echo "10")
    export MIGRATION_PRIORITY_THRESHOLD=$(json_parse "$config_file" '.migration.priority_threshold' 2>/dev/null || echo "500")
    export MIGRATION_DISK_MIN_GB=$(json_parse "$config_file" '.health_checks.disk_space_minimum_gb' 2>/dev/null || echo "10")
    export MIGRATION_NETWORK_TIMEOUT=$(json_parse "$config_file" '.health_checks.network_timeout_seconds' 2>/dev/null || echo "30")
    export MIGRATION_LOG_DIR=$(json_parse "$config_file" '.logging.directory' 2>/dev/null || echo "/tmp/ghostty-start-logs")

    log_info "Configuration loaded from $config_file"
    return 0
}

# Expand tilde in paths
expand_path() {
    local path="$1"
    path="${path/#\~/$HOME}"
    echo "$path"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate required tools
validate_dependencies() {
    local missing_tools=()

    for tool in jq dpkg-query apt-cache systemctl snap; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        error_exit "E006" "Missing required tools: ${missing_tools[*]}" 1
    fi

    log_info "All required tools are available"
}
