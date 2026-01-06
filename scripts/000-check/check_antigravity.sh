#!/bin/bash
# check_antigravity.sh - Check if Google Antigravity is installed
#
# Output format: STATUS|VERSION|METHOD|LOCATION|LATEST
# This format is required by the TUI parser (cache.go ParseCheckOutput)

source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking for Google Antigravity installation..."

# Get latest available version from APT (with caching)
get_antigravity_latest() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-checks"
    local cache_file="${cache_dir}/antigravity_latest.txt"
    local cache_ttl=3600  # 1 hour

    # Check if cache exists and is fresh
    if [[ -f "$cache_file" ]]; then
        local age=$(($(date +%s) - $(stat -c%Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $age -lt $cache_ttl ]]; then
            cat "$cache_file"
            return
        fi
    fi

    # Fetch from apt-cache (requires apt update to have been run)
    mkdir -p "$cache_dir" 2>/dev/null
    local result
    result=$(apt-cache policy antigravity 2>/dev/null | grep "Candidate:" | awk '{print $2}' | grep -oP '\d+(\.\d+)+(-\d+)?' | head -1)

    if [[ -n "$result" ]]; then
        echo "$result" > "$cache_file"
        echo "$result"
    elif [[ -f "$cache_file" ]]; then
        # apt-cache failed, return stale cache
        cat "$cache_file"
    else
        echo "-"
    fi
}

# Detection: Check if Antigravity is installed
detect_antigravity() {
    local binary_path=""
    local method=""
    local version=""

    # Method 1: Check dpkg (APT installation - preferred)
    if dpkg -l antigravity 2>/dev/null | grep -q "^ii"; then
        binary_path=$(command -v antigravity 2>/dev/null || echo "/usr/bin/antigravity")
        version=$(dpkg -l antigravity 2>/dev/null | grep "^ii" | awk '{print $3}')
        method="apt"
        echo "$binary_path|$method|$version"
        return 0
    fi

    # Method 2: Binary in PATH
    if command -v antigravity &> /dev/null; then
        binary_path=$(command -v antigravity)
        method="PATH"
        # Try to get version from command
        version=$(antigravity --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "-")
        echo "$binary_path|$method|$version"
        return 0
    fi

    # Method 3: Check common locations
    if [ -x "/usr/bin/antigravity" ]; then
        binary_path="/usr/bin/antigravity"
        method="System"
        version=$("$binary_path" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "-")
        echo "$binary_path|$method|$version"
        return 0
    fi

    if [ -x "$HOME/.local/bin/antigravity" ]; then
        binary_path="$HOME/.local/bin/antigravity"
        method="Local"
        version=$("$binary_path" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "-")
        echo "$binary_path|$method|$version"
        return 0
    fi

    # Method 4: Snap
    if command -v snap &> /dev/null && snap list antigravity 2>/dev/null | grep -q antigravity; then
        binary_path=$(command -v antigravity)
        method="snap"
        version=$(snap list antigravity 2>/dev/null | grep antigravity | awk '{print $2}')
        echo "$binary_path|$method|$version"
        return 0
    fi

    # Not found
    echo "||"
    return 1
}

# Main execution
DETECTION=$(detect_antigravity)

if [ -n "$DETECTION" ] && [ "$DETECTION" != "||" ]; then
    BINARY_PATH=$(echo "$DETECTION" | cut -d'|' -f1)
    METHOD=$(echo "$DETECTION" | cut -d'|' -f2)
    VERSION=$(echo "$DETECTION" | cut -d'|' -f3)

    # Ensure we have a version
    [ -z "$VERSION" ] && VERSION="-"

    LATEST=$(get_antigravity_latest)
    log "SUCCESS" "Google Antigravity is installed (method: $METHOD, version: $VERSION)"
    # Output format: STATUS|VERSION|METHOD|LOCATION|LATEST
    echo "INSTALLED|$VERSION|$METHOD|$BINARY_PATH|$LATEST"
else
    LATEST=$(get_antigravity_latest)
    log "WARNING" "Google Antigravity is NOT installed"
    echo "NOT_INSTALLED|-|-|-|$LATEST"
fi
