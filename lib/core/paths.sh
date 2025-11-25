#!/usr/bin/env bash
# lib/core/paths.sh - Path manipulation and resolution utilities
# Extracted from scripts/lib/common.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_CORE_PATHS_SOURCED:-}" ]] && return 0
readonly _CORE_PATHS_SOURCED=1

#######################################
# Resolve relative path to absolute path
# Arguments:
#   $1 - Path (relative or absolute)
# Outputs:
#   Absolute path to stdout
# Returns:
#   0 on success, 1 if path doesn't exist, 2 if empty argument
#######################################
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

#######################################
# Get the directory containing the calling script
# Arguments:
#   None (uses BASH_SOURCE from caller context)
# Outputs:
#   Script directory to stdout
# Returns:
#   0 always
#######################################
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

#######################################
# Find the repository root directory (contains .git/)
# Arguments:
#   $1 - Starting path (optional, defaults to current directory)
# Outputs:
#   Project root path to stdout
# Returns:
#   0 on success, 1 if not in git repository
#######################################
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

#######################################
# Expand tilde in paths to full home directory
# Arguments:
#   $1 - Path potentially containing tilde
# Outputs:
#   Expanded path to stdout
#######################################
expand_path() {
    local path="$1"
    path="${path/#\~/$HOME}"
    echo "$path"
}

#######################################
# Normalize path (remove double slashes, resolve . and ..)
# Arguments:
#   $1 - Path to normalize
# Outputs:
#   Normalized path to stdout
#######################################
normalize_path() {
    local path="$1"

    # Remove trailing slash
    path="${path%/}"

    # Replace multiple slashes with single
    path=$(echo "$path" | sed 's|/\+|/|g')

    # If path exists, use realpath for proper normalization
    if [[ -e "$path" ]]; then
        realpath "$path" 2>/dev/null || echo "$path"
    else
        echo "$path"
    fi
}

#######################################
# Get relative path from one path to another
# Arguments:
#   $1 - Source path
#   $2 - Target path
# Outputs:
#   Relative path to stdout
#######################################
get_relative_path() {
    local source="$1"
    local target="$2"

    # Use realpath if available
    if command -v realpath &>/dev/null; then
        realpath --relative-to="$source" "$target" 2>/dev/null || echo "$target"
    else
        # Fallback: return absolute path
        echo "$target"
    fi
}

#######################################
# Check if path is inside a directory
# Arguments:
#   $1 - Path to check
#   $2 - Parent directory
# Returns:
#   0 if path is inside parent, 1 otherwise
#######################################
is_path_inside() {
    local path="$1"
    local parent="$2"

    # Normalize both paths
    local norm_path norm_parent
    norm_path=$(normalize_path "$path")
    norm_parent=$(normalize_path "$parent")

    [[ "$norm_path" == "$norm_parent"* ]]
}

#######################################
# Get file extension from path
# Arguments:
#   $1 - File path
# Outputs:
#   File extension (without dot) or empty string
#######################################
get_file_extension() {
    local path="$1"
    local filename
    filename=$(basename "$path")

    if [[ "$filename" == *.* ]]; then
        echo "${filename##*.}"
    else
        echo ""
    fi
}

#######################################
# Get filename without extension
# Arguments:
#   $1 - File path
# Outputs:
#   Filename without extension
#######################################
get_filename_without_extension() {
    local path="$1"
    local filename
    filename=$(basename "$path")

    if [[ "$filename" == *.* ]]; then
        echo "${filename%.*}"
    else
        echo "$filename"
    fi
}

#######################################
# Create temporary directory with optional prefix
# Arguments:
#   $1 - Prefix (optional, defaults to "tmp")
# Outputs:
#   Path to created temporary directory
# Returns:
#   0 on success, 1 on failure
#######################################
create_temp_dir() {
    local prefix="${1:-tmp}"
    local temp_dir

    temp_dir=$(mktemp -d "/tmp/${prefix}.XXXXXX") || {
        echo "ERROR: Failed to create temporary directory" >&2
        return 1
    }

    echo "$temp_dir"
    return 0
}

#######################################
# Safely remove directory with confirmation
# Arguments:
#   $1 - Directory path
#   $2 - Force flag (optional, "force" to skip confirmation)
# Returns:
#   0 on success, 1 on failure
#######################################
safe_remove_dir() {
    local dir="$1"
    local force="${2:-}"

    if [[ ! -d "$dir" ]]; then
        echo "WARNING: Directory does not exist: $dir" >&2
        return 0
    fi

    # Safety check: don't remove root or home
    if [[ "$dir" == "/" ]] || [[ "$dir" == "$HOME" ]]; then
        echo "ERROR: Refusing to remove critical directory: $dir" >&2
        return 1
    fi

    if [[ "$force" != "force" ]]; then
        echo "Would remove: $dir"
        return 0
    fi

    rm -rf "$dir" || {
        echo "ERROR: Failed to remove directory: $dir" >&2
        return 1
    }

    return 0
}

# Export functions
export -f resolve_absolute_path get_script_dir get_project_root
export -f expand_path normalize_path get_relative_path is_path_inside
export -f get_file_extension get_filename_without_extension
export -f create_temp_dir safe_remove_dir
