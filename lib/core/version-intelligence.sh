#!/usr/bin/env bash
#
# lib/core/version-intelligence.sh - Smart Version Comparison & Installation Strategy
#
# Purpose: Determine the best installation method for each tool based on:
#   - Current OS state and version
#   - APT package version availability
#   - GitHub/upstream latest version
#   - Source build viability and benefits
#
# Constitutional Compliance: Principle I - TUI Framework Standard (gum exclusive)
#

set -euo pipefail

# Source guard
[ -z "${VERSION_INTELLIGENCE_SH_LOADED:-}" ] || return 0
VERSION_INTELLIGENCE_SH_LOADED=1

#
# Compare two semantic versions
#
# Args:
#   $1 - Version 1 (e.g., "1.2.3")
#   $2 - Version 2 (e.g., "1.2.4")
#
# Returns:
#   0 = version1 < version2
#   1 = version1 == version2
#   2 = version1 > version2
#
compare_versions() {
    local ver1="$1"
    local ver2="$2"

    # Normalize versions (remove 'v' prefix, handle non-semver)
    ver1="${ver1#v}"
    ver2="${ver2#v}"

    # Split versions into components
    IFS='.' read -ra v1_parts <<< "$ver1"
    IFS='.' read -ra v2_parts <<< "$ver2"

    # Compare each component
    local max_parts=${#v1_parts[@]}
    [ ${#v2_parts[@]} -gt "$max_parts" ] && max_parts=${#v2_parts[@]}

    for ((i=0; i<max_parts; i++)); do
        local part1=${v1_parts[i]:-0}
        local part2=${v2_parts[i]:-0}

        # Remove non-numeric suffixes (e.g., "2.0-rc1" -> "2.0")
        part1=$(echo "$part1" | grep -oE '^[0-9]+' || echo 0)
        part2=$(echo "$part2" | grep -oE '^[0-9]+' || echo 0)

        if [ "$part1" -lt "$part2" ]; then
            return 0  # version1 < version2
        elif [ "$part1" -gt "$part2" ]; then
            return 2  # version1 > version2
        fi
    done

    return 1  # version1 == version2
}

#
# Get APT package version
#
# Args:
#   $1 - Package name
#
# Returns:
#   Version string or "N/A" if not available
#
get_apt_version() {
    local package="$1"

    if ! command -v apt-cache >/dev/null 2>&1; then
        echo "N/A"
        return 1
    fi

    local version
    version=$(apt-cache policy "$package" 2>/dev/null | grep -oP 'Candidate: \K[^ ]+' || echo "N/A")
    echo "$version"
}

#
# Get GitHub latest release version
#
# Args:
#   $1 - GitHub repo (e.g., "charmbracelet/gum")
#
# Returns:
#   Version string or "N/A" if unavailable
#
get_github_latest_version() {
    local repo="$1"

    if ! command -v curl >/dev/null 2>&1; then
        echo "N/A"
        return 1
    fi

    local version
    version=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | \
              grep -oP '"tag_name": "\K[^"]+' || echo "N/A")
    echo "$version"
}

#
# Determine best installation method for a tool
#
# Args:
#   $1 - Tool name
#   $2 - APT package name (or "N/A")
#   $3 - GitHub repo (or "N/A")
#   $4 - npm package name (or "N/A")
#   $5 - Current OS (detected automatically if not provided)
#
# Returns:
#   JSON object with installation strategy:
#   {
#     "method": "apt|npm|github_binary|source",
#     "reason": "explanation",
#     "version_target": "X.Y.Z",
#     "requires_build": true|false
#   }
#
determine_installation_strategy() {
    local tool_name="$1"
    local apt_package="${2:-N/A}"
    local github_repo="${3:-N/A}"
    local npm_package="${4:-N/A}"
    local os_version="${5:-$(lsb_release -rs 2>/dev/null || echo "unknown")}"

    # Get available versions
    local apt_version="N/A"
    local github_version="N/A"
    local current_version="N/A"

    [ "$apt_package" != "N/A" ] && apt_version=$(get_apt_version "$apt_package")
    [ "$github_repo" != "N/A" ] && github_version=$(get_github_latest_version "$github_repo")

    # Detect current installed version
    if command -v "$tool_name" >/dev/null 2>&1; then
        current_version=$("$tool_name" --version 2>/dev/null | grep -oP 'v?\d+\.\d+(\.\d+)?' | head -1 || echo "unknown")
    fi

    # Decision tree for installation method
    local method="apt"
    local reason="Default to apt (stable)"
    local version_target="$apt_version"
    local requires_build=false

    # Priority 1: npm packages (for Node.js ecosystem tools)
    if [ "$npm_package" != "N/A" ] && command -v npm >/dev/null 2>&1; then
        method="npm"
        reason="npm global package (Node.js ecosystem)"
        version_target="latest"
        requires_build=false

    # Priority 2: APT packages (stable, system-managed)
    elif [ "$apt_version" != "N/A" ] && [ "$apt_version" != "(none)" ]; then
        # Check if GitHub version is significantly newer
        if [ "$github_version" != "N/A" ]; then
            if compare_versions "$apt_version" "$github_version"; then
                # APT version is older - decide if worth building from source
                local major_diff=false

                # Extract major version numbers
                local apt_major gh_major
                apt_major=$(echo "$apt_version" | cut -d. -f1)
                gh_major=$(echo "$github_version" | cut -d. -f1)

                if [ "$apt_major" -lt "$gh_major" ]; then
                    major_diff=true
                fi

                if [ "$major_diff" = true ]; then
                    method="source"
                    reason="GitHub version ($github_version) has major improvements over apt ($apt_version)"
                    version_target="$github_version"
                    requires_build=true
                else
                    method="apt"
                    reason="apt version ($apt_version) is recent enough vs GitHub ($github_version)"
                    version_target="$apt_version"
                    requires_build=false
                fi
            fi
        else
            method="apt"
            reason="apt available and GitHub version unknown"
            version_target="$apt_version"
            requires_build=false
        fi

    # Priority 3: GitHub binary download (if no apt available)
    elif [ "$github_repo" != "N/A" ]; then
        method="github_binary"
        reason="No apt package available, using GitHub binary"
        version_target="$github_version"
        requires_build=false

    # Priority 4: Source build (last resort)
    else
        method="source"
        reason="No other installation method available"
        version_target="$github_version"
        requires_build=true
    fi

    # Output JSON
    cat <<EOF
{
  "tool": "$tool_name",
  "method": "$method",
  "reason": "$reason",
  "version_target": "$version_target",
  "version_apt": "$apt_version",
  "version_github": "$github_version",
  "version_current": "$current_version",
  "requires_build": $requires_build,
  "os_version": "$os_version"
}
EOF
}

#
# Check if source build will provide significant benefits
#
# Args:
#   $1 - Tool name
#   $2 - APT version
#   $3 - GitHub version
#
# Returns:
#   0 = source build recommended
#   1 = apt version sufficient
#
recommend_source_build() {
    local tool_name="$1"
    local apt_version="$2"
    local github_version="$3"

    # If no apt version available, always recommend source
    [ "$apt_version" = "N/A" ] && return 0

    # If no GitHub version available, stick with apt
    [ "$github_version" = "N/A" ] && return 1

    # Compare versions
    if compare_versions "$apt_version" "$github_version"; then
        # APT is older - check if difference is significant
        local apt_major gh_major
        apt_major=$(echo "$apt_version" | cut -d. -f1)
        gh_major=$(echo "$github_version" | cut -d. -f1)

        # Major version difference = recommend source
        [ "$apt_major" -lt "$gh_major" ] && return 0
    fi

    # APT version is sufficient
    return 1
}

# Export functions
export -f compare_versions
export -f get_apt_version
export -f get_github_latest_version
export -f determine_installation_strategy
export -f recommend_source_build
