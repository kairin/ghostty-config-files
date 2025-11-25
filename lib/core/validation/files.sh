#!/usr/bin/env bash
# lib/core/validation/files.sh - File and directory validation utilities
# Extracted from lib/core/validation.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_VALIDATION_FILES_SOURCED:-}" ]] && return 0
readonly _VALIDATION_FILES_SOURCED=1

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
# Check if path exists (file or directory)
# Arguments:
#   $1 - Path to check
# Returns:
#   0 if exists, 1 if not
#######################################
path_exists() {
    local path="$1"
    [[ -e "$path" ]]
}

#######################################
# Check if path is a symbolic link
# Arguments:
#   $1 - Path to check
# Returns:
#   0 if symlink, 1 if not
#######################################
is_symlink() {
    local path="$1"
    [[ -L "$path" ]]
}

#######################################
# Get file size in bytes
# Arguments:
#   $1 - File path
# Outputs:
#   File size in bytes
# Returns:
#   0 on success, 1 if file not found
#######################################
get_file_size() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "0"
        return 1
    fi

    stat -c%s "$file_path" 2>/dev/null || wc -c < "$file_path"
}

#######################################
# Get file modification time
# Arguments:
#   $1 - File path
# Outputs:
#   Modification time in seconds since epoch
# Returns:
#   0 on success, 1 if file not found
#######################################
get_file_mtime() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "0"
        return 1
    fi

    stat -c%Y "$file_path" 2>/dev/null || date -r "$file_path" +%s 2>/dev/null || echo "0"
}

#######################################
# Check if file is newer than another
# Arguments:
#   $1 - File to check
#   $2 - Reference file
# Returns:
#   0 if $1 is newer than $2, 1 otherwise
#######################################
is_file_newer() {
    local file1="$1"
    local file2="$2"

    [[ "$file1" -nt "$file2" ]]
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

# Export functions
export -f require_file require_dir ensure_dir
export -f is_writable is_readable is_executable
export -f path_exists is_symlink
export -f get_file_size get_file_mtime is_file_newer
export -f validate_shell_syntax
