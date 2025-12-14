#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking for existing feh installation..."

# Cache configuration for GitHub API (avoid rate limiting)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-checks"
CACHE_FILE="${CACHE_DIR}/feh_latest.txt"
CACHE_TTL=3600  # 1 hour

# Get latest version with caching and timeout
get_feh_latest() {
    # Check if cache exists and is fresh
    if [[ -f "$CACHE_FILE" ]]; then
        local age=$(($(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [[ $age -lt $CACHE_TTL ]]; then
            cat "$CACHE_FILE"
            return
        fi
    fi

    # Fetch from GitHub API with timeout
    mkdir -p "$CACHE_DIR" 2>/dev/null
    local result
    result=$(curl -s --connect-timeout 3 --max-time 5 \
        "https://api.github.com/repos/derf/feh/tags" 2>/dev/null | \
        grep -oP '"name": "\K[^"]+' | head -1)

    if [[ -n "$result" ]]; then
        echo "$result" > "$CACHE_FILE"
        echo "$result"
    elif [[ -f "$CACHE_FILE" ]]; then
        # API failed, return stale cache
        cat "$CACHE_FILE"
    else
        echo "-"
    fi
}

if command -v feh &> /dev/null; then
    # Extract just the version number (e.g., "3.11.2" not "feh version 3.11.2")
    VERSION=$(feh --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    LOCATION=$(command -v feh)

    METHOD="Unknown"
    if [[ "$LOCATION" == "/usr/local/bin/feh" ]]; then
        METHOD="Source"
    elif dpkg -s feh &> /dev/null; then
        METHOD="Apt"
    fi

    LATEST=$(get_feh_latest)

    log "SUCCESS" "feh is installed: $VERSION"
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    log "WARNING" "feh is NOT installed"
    LATEST=$(get_feh_latest)
    echo "NOT_INSTALLED|-|-|-|$LATEST"
fi
