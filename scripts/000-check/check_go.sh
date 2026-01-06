#!/bin/bash
# check_go.sh

# Cache configuration for go.dev API
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-checks"
CACHE_FILE="${CACHE_DIR}/go_latest.txt"
CACHE_TTL=3600  # 1 hour

get_go_latest() {
    # Check if cache exists and is fresh
    if [[ -f "$CACHE_FILE" ]]; then
        local age=$(($(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [[ $age -lt $CACHE_TTL ]]; then
            cat "$CACHE_FILE"
            return
        fi
    fi

    # Fetch from go.dev with timeout
    mkdir -p "$CACHE_DIR" 2>/dev/null
    local result
    result=$(timeout 5 curl -sL --connect-timeout 3 --max-time 5 \
        "https://go.dev/VERSION?m=text" 2>/dev/null | head -n 1 | sed 's/go//')

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

if command -v go &> /dev/null; then
    VERSION=$(go version | grep -oP 'go\d+\.\d+\.\d+' | sed 's/go//' || echo "Unknown")
    LOCATION=$(command -v go)

    if [[ "$LOCATION" == *"/usr/local/go/bin/"* ]]; then
        METHOD="Official"
    elif [[ "$LOCATION" == *"/usr/bin/"* ]]; then
        METHOD="APT"
    else
        METHOD="Other"
    fi

    LATEST=$(get_go_latest)
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|$LATEST"
else
    LATEST=$(get_go_latest)
    echo "NOT_INSTALLED|-|-|-|$LATEST"
fi
