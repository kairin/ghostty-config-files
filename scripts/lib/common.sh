#!/bin/bash
# common.sh - Common utility functions for path resolution, logging, error handling
# Orchestrates modular components from lib/core/ for backward compatibility

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

# Determine paths
_COMMON_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_COMMON_REPO_ROOT="$(cd "$_COMMON_SCRIPT_DIR/../.." && pwd)"

# Source modular components
source "$_COMMON_REPO_ROOT/lib/core/paths.sh"
source "$_COMMON_REPO_ROOT/lib/core/validation.sh"

# ============================================================
# LOGGING FUNCTIONS (Consolidated from original)
# ============================================================

# Function: log_info - Log informational message with timestamp
log_info() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[INFO] [$timestamp] $message"
    return 0
}

# Function: log_warn - Log warning message with timestamp
log_warn() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[WARN] [$timestamp] $message" >&2
    return 0
}

# Function: log_error - Log error message with timestamp
log_error() {
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[ERROR] [$timestamp] $message" >&2
    return 0
}

# Function: log_debug - Log debug message (only if DEBUG=1)
log_debug() {
    local message="$1"
    if [[ "${DEBUG:-0}" == "1" ]] || [[ "${MANAGE_DEBUG:-0}" == "1" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        echo "[DEBUG] [$timestamp] $message" >&2
    fi
    return 0
}

# Function: log_event - Structured logging with severity levels
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

    # Skip DEBUG unless enabled
    if [[ "$severity" == "DEBUG" ]] && [[ "${DEBUG:-0}" != "1" ]] && [[ "${MANAGE_DEBUG:-0}" != "1" ]]; then
        return 0
    fi

    # Structured JSON logging (if enabled)
    if [[ "${LOG_JSON:-0}" == "1" ]]; then
        local json_log="{\"timestamp\":\"$timestamp\",\"severity\":\"$severity\",\"message\":\"$message\""
        [[ -n "$context" ]] && json_log="$json_log,\"context\":$context"
        json_log="$json_log}"

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

        if [[ "$severity" == "ERROR" ]] || [[ "$severity" == "CRITICAL" ]]; then
            echo "$prefix [$formatted_time] $message" >&2
        else
            echo "$prefix [$formatted_time] $message"
        fi
    fi
    return 0
}

# Function: die - Print error message and exit
die() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    exit "$exit_code"
}

# Function: get_timestamp - Generate timestamp string
get_timestamp() {
    local format="${1:-iso}"
    case "$format" in
        "file") date '+%Y%m%d-%H%M%S' ;;
        "log")  date '+%Y-%m-%d %H:%M:%S' ;;
        "iso")  date '+%Y-%m-%dT%H:%M:%S%z' ;;
        *)      date '+%Y-%m-%dT%H:%M:%S%z' ;;
    esac
    return 0
}

# ============================================================
# PACKAGE MIGRATION UTILITIES (Preserved for backward compatibility)
# ============================================================

# Error codes
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

# JSON utilities
json_parse() {
    local json_file="$1"
    local jq_filter="$2"
    [[ ! -f "$json_file" ]] && { log_error "JSON file not found: $json_file"; return 1; }
    jq -r "$jq_filter" "$json_file" 2>/dev/null || { log_error "Failed to parse JSON file: $json_file"; return 1; }
}

json_validate() {
    local json_string="$1"
    echo "$json_string" | jq empty >/dev/null 2>&1
}

json_get_field() {
    local json_string="$1"
    local field_path="$2"
    echo "$json_string" | jq -r "$field_path" 2>/dev/null
}

# Configuration loader
load_config() {
    local config_file="${1:-$HOME/.config/package-migration/config.json}"
    [[ ! -f "$config_file" ]] && { log_warn "Config file not found: $config_file, using defaults"; return 1; }

    MIGRATION_BACKUP_DIR=$(json_parse "$config_file" '.backup.directory' 2>/dev/null || echo "$HOME/.config/package-migration/backups")
    export MIGRATION_BACKUP_DIR
    MIGRATION_RETENTION_DAYS=$(json_parse "$config_file" '.backup.retention_days' 2>/dev/null || echo "30")
    export MIGRATION_RETENTION_DAYS
    MIGRATION_CACHE_ENABLED=$(json_parse "$config_file" '.cache.enabled' 2>/dev/null || echo "true")
    export MIGRATION_CACHE_ENABLED
    MIGRATION_CACHE_TTL=$(json_parse "$config_file" '.cache.ttl_seconds' 2>/dev/null || echo "3600")
    export MIGRATION_CACHE_TTL
    MIGRATION_BATCH_SIZE=$(json_parse "$config_file" '.migration.batch_size' 2>/dev/null || echo "10")
    export MIGRATION_BATCH_SIZE
    MIGRATION_PRIORITY_THRESHOLD=$(json_parse "$config_file" '.migration.priority_threshold' 2>/dev/null || echo "500")
    export MIGRATION_PRIORITY_THRESHOLD
    MIGRATION_DISK_MIN_GB=$(json_parse "$config_file" '.health_checks.disk_space_minimum_gb' 2>/dev/null || echo "10")
    export MIGRATION_DISK_MIN_GB
    MIGRATION_NETWORK_TIMEOUT=$(json_parse "$config_file" '.health_checks.network_timeout_seconds' 2>/dev/null || echo "30")
    export MIGRATION_NETWORK_TIMEOUT
    MIGRATION_LOG_DIR=$(json_parse "$config_file" '.logging.directory' 2>/dev/null || echo "/tmp/ghostty-start-logs")
    export MIGRATION_LOG_DIR

    log_info "Configuration loaded from $config_file"
    return 0
}

# Validate required tools for migration
validate_migration_dependencies() {
    local missing_tools=()

    for tool in jq dpkg-query apt-cache systemctl snap; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error_exit "E006" "Missing required tools: ${missing_tools[*]}" 1
    fi

    log_info "All required tools are available"
}

# ============================================================
# MAIN EXECUTION (Show usage when run directly)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    cat << 'EOF'
This module provides common utility functions and should be sourced, not executed directly.

Usage:
    source scripts/lib/common.sh

Available functions (from lib/core/paths.sh):
    - resolve_absolute_path <path>
    - get_script_dir
    - get_project_root [starting_path]
    - expand_path <path>
    - normalize_path <path>
    - create_temp_dir [prefix]

Available functions (from lib/core/validation.sh):
    - command_exists <command>
    - require_command <command> [error_message]
    - require_file <file_path> [error_message]
    - require_dir <dir_path> [error_message]
    - ensure_dir <dir_path>
    - validate_dependencies <tool1> [tool2] ...
    - validate_json <input> [type]
    - validate_yaml <file_path>
    - validate_shell_syntax <script_path>

Available functions (logging):
    - log_info <message>
    - log_warn <message>
    - log_error <message>
    - log_debug <message>
    - log_event <severity> <message> [context]
    - die <message> [exit_code]
    - get_timestamp [format]

Example:
    source scripts/lib/common.sh
    log_info "Starting installation"
    require_command "git" || die "Git is required"
    PROJECT_ROOT=$(get_project_root)
EOF
    exit 0
fi
