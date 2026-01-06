#!/bin/bash
# check_fastfetch.sh

# Cache configuration for GitHub API (avoid rate limiting)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-checks"
CACHE_FILE="${CACHE_DIR}/fastfetch_latest.txt"
CACHE_TTL=3600  # 1 hour

get_fastfetch_latest() {
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
    result=$(timeout 5 curl -sL --connect-timeout 3 --max-time 5 \
        "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" 2>/dev/null | \
        grep -oP '"tag_name": "\K[^"]+')

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

if command -v fastfetch &> /dev/null; then
    VERSION=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "Unknown")
    LOCATION=$(command -v fastfetch)

    # Determine method
    if [[ "$LOCATION" == *"/usr/bin/"* ]] && dpkg -l fastfetch &>/dev/null; then
        METHOD="APT"
    elif [[ "$LOCATION" == *"/usr/local/bin/"* ]]; then
        METHOD="Source"
    else
        METHOD="Other"
    fi

    LATEST=$(get_fastfetch_latest)
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    LATEST=$(get_fastfetch_latest)
    echo "NOT_INSTALLED|-|-|-|$LATEST"
fi
