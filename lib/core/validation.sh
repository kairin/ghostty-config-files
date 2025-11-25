#!/usr/bin/env bash
# lib/core/validation.sh - Common validation utilities
# Extracted from scripts/lib/common.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_CORE_VALIDATION_SOURCED:-}" ]] && return 0
readonly _CORE_VALIDATION_SOURCED=1

#######################################
# Check if a command exists
# Arguments:
#   $1 - Command name
# Returns:
#   0 if exists, 1 if not
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Require a command to be available
# Arguments:
#   $1 - Command name
#   $2 - Error message (optional)
# Returns:
#   0 if command exists, 1 if not (logs error)
#######################################
require_command() {
    local command_name="$1"
    local error_message="${2:-Command '$command_name' is required but not found}"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: $error_message" >&2
        return 1
    fi

    return 0
}

#######################################
# Require a file to exist
# Arguments:
#   $1 - File path
#   $2 - Error message (optional)
# Returns:
#   0 if file exists, 1 if not (logs error)
#######################################
require_file() {
    local file_path="$1"
    local error_message="${2:-Required file not found: $file_path}"

    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: $error_message" >&2
        return 1
    fi

    return 0
}

#######################################
# Require a directory to exist
# Arguments:
#   $1 - Directory path
#   $2 - Error message (optional)
# Returns:
#   0 if directory exists, 1 if not (logs error)
#######################################
require_dir() {
    local dir_path="$1"
    local error_message="${2:-Required directory not found: $dir_path}"

    if [[ ! -d "$dir_path" ]]; then
        echo "ERROR: $error_message" >&2
        return 1
    fi

    return 0
}

#######################################
# Ensure directory exists, create if not
# Arguments:
#   $1 - Directory path
# Returns:
#   0 on success, 1 on failure
#######################################
ensure_dir() {
    local dir_path="$1"

    if [[ -z "$dir_path" ]]; then
        echo "ERROR: Directory path argument is required" >&2
        return 2
    fi

    if [[ ! -d "$dir_path" ]]; then
        if ! mkdir -p "$dir_path"; then
            echo "ERROR: Failed to create directory: $dir_path" >&2
            return 1
        fi
    fi

    return 0
}

#######################################
# Check if a path is writable
# Arguments:
#   $1 - Path to check
# Returns:
#   0 if writable, 1 if not
#######################################
is_writable() {
    local path="$1"
    [[ -w "$path" ]]
}

#######################################
# Check if a path is readable
# Arguments:
#   $1 - Path to check
# Returns:
#   0 if readable, 1 if not
#######################################
is_readable() {
    local path="$1"
    [[ -r "$path" ]]
}

#######################################
# Check if a path is executable
# Arguments:
#   $1 - Path to check
# Returns:
#   0 if executable, 1 if not
#######################################
is_executable() {
    local path="$1"
    [[ -x "$path" ]]
}

#######################################
# Validate required tools for a script
# Arguments:
#   $@ - List of required tool names
# Returns:
#   0 if all tools present, 1 if any missing
#######################################
validate_dependencies() {
    local missing_tools=()

    for tool in "$@"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "ERROR: Missing required tools: ${missing_tools[*]}" >&2
        return 1
    fi

    return 0
}

#######################################
# Validate JSON syntax
# Arguments:
#   $1 - JSON string or file path
#   $2 - Type ("string" or "file", default "string")
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_json() {
    local input="$1"
    local type="${2:-string}"

    if ! command -v jq &>/dev/null; then
        echo "WARNING: jq not available for JSON validation" >&2
        return 0
    fi

    if [[ "$type" == "file" ]]; then
        jq empty "$input" 2>/dev/null
    else
        echo "$input" | jq empty 2>/dev/null
    fi
}

#######################################
# Validate YAML syntax
# Arguments:
#   $1 - YAML file path
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_yaml() {
    local yaml_file="$1"

    if command -v yq &>/dev/null; then
        yq eval '.' "$yaml_file" >/dev/null 2>&1
    elif command -v python3 &>/dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null
    else
        echo "WARNING: No YAML validator available" >&2
        return 0
    fi
}

#######################################
# Validate shell script syntax
# Arguments:
#   $1 - Script file path
# Returns:
#   0 if valid, 1 if syntax error
#######################################
validate_shell_syntax() {
    local script_file="$1"

    if [[ ! -f "$script_file" ]]; then
        echo "ERROR: Script file not found: $script_file" >&2
        return 1
    fi

    bash -n "$script_file" 2>&1
}

#######################################
# Validate integer value
# Arguments:
#   $1 - Value to check
# Returns:
#   0 if integer, 1 if not
#######################################
is_integer() {
    local value="$1"
    [[ "$value" =~ ^-?[0-9]+$ ]]
}

#######################################
# Validate positive integer value
# Arguments:
#   $1 - Value to check
# Returns:
#   0 if positive integer, 1 if not
#######################################
is_positive_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]] && [[ "$value" -gt 0 ]]
}

#######################################
# Validate boolean value (true/false, yes/no, 1/0)
# Arguments:
#   $1 - Value to check
# Returns:
#   0 if boolean, 1 if not
#######################################
is_boolean() {
    local value="$1"
    case "${value,,}" in
        true|false|yes|no|1|0|on|off) return 0 ;;
        *) return 1 ;;
    esac
}

#######################################
# Validate URL format
# Arguments:
#   $1 - URL to check
# Returns:
#   0 if valid URL format, 1 if not
#######################################
is_valid_url() {
    local url="$1"
    [[ "$url" =~ ^https?://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+.*$ ]]
}

#######################################
# Validate email format
# Arguments:
#   $1 - Email to check
# Returns:
#   0 if valid email format, 1 if not
#######################################
is_valid_email() {
    local email="$1"
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

#######################################
# Validate semantic version format
# Arguments:
#   $1 - Version string to check
# Returns:
#   0 if valid semver, 1 if not
#######################################
is_valid_semver() {
    local version="$1"
    [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$ ]]
}

# Export functions
export -f command_exists require_command require_file require_dir ensure_dir
export -f is_writable is_readable is_executable
export -f validate_dependencies validate_json validate_yaml validate_shell_syntax
export -f is_integer is_positive_integer is_boolean
export -f is_valid_url is_valid_email is_valid_semver
