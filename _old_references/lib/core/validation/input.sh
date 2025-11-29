#!/usr/bin/env bash
# lib/core/validation/input.sh - Input and data validation utilities
# Extracted from lib/core/validation.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_VALIDATION_INPUT_SOURCED:-}" ]] && return 0
readonly _VALIDATION_INPUT_SOURCED=1

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
# Validate non-negative integer value
# Arguments:
#   $1 - Value to check
# Returns:
#   0 if non-negative integer, 1 if not
#######################################
is_non_negative_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
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

#######################################
# Validate IP address format (IPv4)
# Arguments:
#   $1 - IP address to check
# Returns:
#   0 if valid IPv4, 1 if not
#######################################
is_valid_ipv4() {
    local ip="$1"
    local IFS='.'
    read -ra octets <<< "$ip"

    if [[ ${#octets[@]} -ne 4 ]]; then
        return 1
    fi

    for octet in "${octets[@]}"; do
        if ! [[ "$octet" =~ ^[0-9]+$ ]] || ((octet < 0 || octet > 255)); then
            return 1
        fi
    done

    return 0
}

#######################################
# Validate string is not empty
# Arguments:
#   $1 - String to check
# Returns:
#   0 if not empty, 1 if empty
#######################################
is_not_empty() {
    local value="$1"
    [[ -n "$value" ]]
}

#######################################
# Validate string matches pattern
# Arguments:
#   $1 - String to check
#   $2 - Regex pattern
# Returns:
#   0 if matches, 1 if not
#######################################
matches_pattern() {
    local value="$1"
    local pattern="$2"
    [[ "$value" =~ $pattern ]]
}

# Export functions
export -f command_exists require_command validate_dependencies
export -f validate_json validate_yaml
export -f is_integer is_positive_integer is_non_negative_integer is_boolean
export -f is_valid_url is_valid_email is_valid_semver is_valid_ipv4
export -f is_not_empty matches_pattern
