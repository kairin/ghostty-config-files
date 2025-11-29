#!/usr/bin/env bash
#
# lib/verification/duplicate_detection.sh - Unified duplicate detection library
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices from package management and duplicate detection 2025
# - Command existence checks
# - Version verification
# - Multiple installation detection (snap vs apt vs source)
# - Desktop file scanning
# - Standardized detection result format
#
# Constitutional Compliance: User Story 3 (Re-run Safety), User Story 4 (Duplicate Detection)
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${DUPLICATE_DETECTION_SH_LOADED:-}" ] || return 0
DUPLICATE_DETECTION_SH_LOADED=1

# Source utility module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/logging.sh"

#
# Detect existing installation of a component
#
# This is a generic detection function that checks multiple installation methods
#
# Arguments:
#   $1 - Component name (e.g., "ghostty", "gum", "fnm")
#   $2 - Minimum required version (optional, e.g., "1.1.4")
#
# Returns:
#   JSON object with detection result:
#   {
#     "exists": true|false,
#     "version": "x.y.z" | "unknown" | "",
#     "installation_method": "apt" | "snap" | "source" | "binary" | "unknown" | "",
#     "command_path": "/path/to/command" | "",
#     "duplicates": [
#       {"method": "snap", "path": "/snap/bin/command"},
#       {"method": "apt", "path": "/usr/bin/command"}
#     ]
#   }
#
# Usage:
#   detection_result=$(detect_installation "gum" "0.14.0")
#   exists=$(echo "$detection_result" | jq -r '.exists')
#
detect_installation() {
    local component="$1"
    local min_version="${2:-}"
    local command_path
    local version="unknown"
    local method="unknown"
    local exists=false
    local duplicates_json="[]"

    # Check if command exists
    if command_exists "$component"; then
        exists=true
        command_path=$(command -v "$component" 2>/dev/null || echo "")

        # Get version if possible
        version=$(get_command_version "$component" 2>/dev/null || echo "unknown")

        # Detect installation method based on path
        method=$(detect_installation_method "$command_path")

        # Check for duplicates
        duplicates_json=$(detect_duplicates "$component")
    else
        command_path=""
        version=""
        method=""
    fi

    # Build JSON result
    cat <<EOF
{
  "exists": $exists,
  "version": "$version",
  "installation_method": "$method",
  "command_path": "$command_path",
  "duplicates": $duplicates_json
}
EOF
}

#
# Detect installation method based on command path
#
# Arguments:
#   $1 - Full path to command
#
# Returns:
#   Installation method: "apt", "snap", "source", "binary", "npm", "unknown"
#
detect_installation_method() {
    local path="$1"

    case "$path" in
        /snap/*)
            echo "snap"
            ;;
        /usr/bin/*|/bin/*)
            # Check if installed via apt/dpkg
            local basename
            basename=$(basename "$path")
            if dpkg -S "$path" &>/dev/null; then
                echo "apt"
            else
                echo "binary"
            fi
            ;;
        /usr/local/bin/*)
            echo "source"
            ;;
        $HOME/.local/bin/*|$HOME/bin/*)
            echo "binary"
            ;;
        /usr/lib/node_modules/*|*/node_modules/.bin/*)
            echo "npm"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#
# Detect duplicate installations of a component
#
# Arguments:
#   $1 - Component name
#
# Returns:
#   JSON array of duplicate installations
#
detect_duplicates() {
    local component="$1"
    local duplicates=()
    local duplicates_json="["

    # Find all instances using which -a
    local all_paths
    if command -v which &>/dev/null; then
        mapfile -t all_paths < <(which -a "$component" 2>/dev/null || true)
    else
        all_paths=()
    fi

    # Check if multiple installations exist
    if [ "${#all_paths[@]}" -gt 1 ]; then
        for path in "${all_paths[@]}"; do
            local method
            method=$(detect_installation_method "$path")

            duplicates_json+="{\"method\":\"$method\",\"path\":\"$path\"},"
        done

        # Remove trailing comma
        duplicates_json="${duplicates_json%,}"
    fi

    duplicates_json+="]"
    echo "$duplicates_json"
}

#
# Check if version meets minimum requirement
#
# Arguments:
#   $1 - Current version (e.g., "1.2.3")
#   $2 - Minimum required version (e.g., "1.1.0")
#
# Returns:
#   0 if version meets requirement, 1 if not
#
# Usage:
#   if version_meets_requirements "1.2.3" "1.1.0"; then
#       echo "Version is sufficient"
#   fi
#
version_meets_requirements() {
    local current="$1"
    local required="$2"

    # If version is unknown, assume it doesn't meet requirements
    if [ "$current" = "unknown" ] || [ -z "$current" ]; then
        return 1
    fi

    # Extract major, minor, patch from current version
    local current_major current_minor current_patch
    current_major=$(echo "$current" | grep -oP '^\d+' || echo "0")
    current_minor=$(echo "$current" | grep -oP '^\d+\.\K\d+' || echo "0")
    current_patch=$(echo "$current" | grep -oP '^\d+\.\d+\.\K\d+' || echo "0")

    # Extract major, minor, patch from required version
    local required_major required_minor required_patch
    required_major=$(echo "$required" | grep -oP '^\d+' || echo "0")
    required_minor=$(echo "$required" | grep -oP '^\d+\.\K\d+' || echo "0")
    required_patch=$(echo "$required" | grep -oP '^\d+\.\d+\.\K\d+' || echo "0")

    # Compare versions
    if [ "$current_major" -gt "$required_major" ]; then
        return 0
    elif [ "$current_major" -eq "$required_major" ]; then
        if [ "$current_minor" -gt "$required_minor" ]; then
            return 0
        elif [ "$current_minor" -eq "$required_minor" ]; then
            if [ "$current_patch" -ge "$required_patch" ]; then
                return 0
            fi
        fi
    fi

    return 1
}

#
# Detect package installation method (apt vs snap)
#
# Arguments:
#   $1 - Package name
#
# Returns:
#   JSON array of installation methods found
#
detect_package_duplicates() {
    local package_name="$1"
    local installations_json="["

    # Check apt/dpkg
    if dpkg -l "$package_name" 2>/dev/null | grep -q "^ii"; then
        local version
        version=$(dpkg -l "$package_name" 2>/dev/null | grep "^ii" | awk '{print $3}')
        installations_json+="{\"method\":\"apt\",\"version\":\"$version\"},"
    fi

    # Check snap
    if command -v snap &>/dev/null && snap list "$package_name" 2>/dev/null | grep -q "^${package_name}"; then
        local version
        version=$(snap list "$package_name" 2>/dev/null | grep "^${package_name}" | awk '{print $2}')
        installations_json+="{\"method\":\"snap\",\"version\":\"$version\"},"
    fi

    # Remove trailing comma
    installations_json="${installations_json%,}"
    installations_json+="]"

    echo "$installations_json"
}

#
# Detect disabled snap packages
#
# Returns:
#   JSON array of disabled snap packages
#
detect_disabled_snaps() {
    local disabled_json="["

    if ! command -v snap &>/dev/null; then
        echo "[]"
        return
    fi

    # List all snaps including disabled ones
    local disabled_snaps
    mapfile -t disabled_snaps < <(snap list --all 2>/dev/null | grep "disabled" | awk '{print $1}' || true)

    for snap_name in "${disabled_snaps[@]}"; do
        local version revision
        version=$(snap list --all "$snap_name" 2>/dev/null | grep "disabled" | awk '{print $2}' | head -n 1)
        revision=$(snap list --all "$snap_name" 2>/dev/null | grep "disabled" | awk '{print $3}' | head -n 1)

        disabled_json+="{\"name\":\"$snap_name\",\"version\":\"$version\",\"revision\":\"$revision\"},"
    done

    # Remove trailing comma
    disabled_json="${disabled_json%,}"
    disabled_json+="]"

    echo "$disabled_json"
}

#
# Scan for duplicate desktop files (GNOME app drawer icons)
#
# Arguments:
#   $1 - Application name (case-insensitive)
#
# Returns:
#   JSON array of desktop file paths
#
detect_duplicate_desktop_files() {
    local app_name="$1"
    local desktop_files_json="["
    local desktop_dirs=(
        "/usr/share/applications"
        "$HOME/.local/share/applications"
        "/var/lib/snapd/desktop/applications"
    )

    for dir in "${desktop_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        # Find desktop files matching app name (case-insensitive)
        local files
        mapfile -t files < <(find "$dir" -iname "*${app_name}*.desktop" 2>/dev/null || true)

        for file in "${files[@]}"; do
            desktop_files_json+="{\"path\":\"$file\"},"
        done
    done

    # Remove trailing comma
    desktop_files_json="${desktop_files_json%,}"
    desktop_files_json+="]"

    echo "$desktop_files_json"
}

#
# High-level detection for specific components
#

#
# Detect Ghostty installation
#
detect_ghostty() {
    detect_installation "ghostty" "1.1.4"
}

#
# Detect gum installation
#
detect_gum() {
    detect_installation "gum" "0.14.0"
}

#
# Detect fnm installation
#
detect_fnm() {
    detect_installation "fnm"
}

#
# Detect uv installation
#
detect_uv() {
    detect_installation "uv"
}

#
# Detect ZSH installation
#
detect_zsh() {
    local result
    result=$(detect_installation "zsh")

    # Also check for Oh My ZSH
    local oh_my_zsh_installed=false
    if [ -d "$HOME/.oh-my-zsh" ]; then
        oh_my_zsh_installed=true
    fi

    # Add Oh My ZSH status to result
    result=$(echo "$result" | jq --argjson omz "$oh_my_zsh_installed" '. + {oh_my_zsh_installed: $omz}')

    echo "$result"
}

#
# Detect Node.js installation
#
detect_nodejs() {
    detect_installation "node" "25.0.0"
}

#
# Detect Claude CLI installation
#
detect_claude_cli() {
    detect_installation "claude"
}

#
# Detect Gemini CLI installation
#
detect_gemini_cli() {
    detect_installation "gemini"
}

# Export functions for use in other modules
export -f detect_installation
export -f detect_installation_method
export -f detect_duplicates
export -f version_meets_requirements
export -f detect_package_duplicates
export -f detect_disabled_snaps
export -f detect_duplicate_desktop_files
export -f detect_ghostty
export -f detect_gum
export -f detect_fnm
export -f detect_uv
export -f detect_zsh
export -f detect_nodejs
export -f detect_claude_cli
export -f detect_gemini_cli
