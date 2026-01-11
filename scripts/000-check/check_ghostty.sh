#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking for existing ghostty installation..."

# Cache configuration for GitHub API (avoid rate limiting)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-checks"
CACHE_FILE="${CACHE_DIR}/ghostty_latest.txt"
CACHE_TTL=3600  # 1 hour

# Get latest version with caching and timeout
get_ghostty_latest() {
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
        "https://api.github.com/repos/ghostty-org/ghostty/tags" 2>/dev/null | \
        grep -oP '"name": "v?\K[^"]+' | head -1)

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

if command -v ghostty &> /dev/null; then
    # Extract just the version number (e.g., "1.1.4" not "Ghostty 1.1.4" or "1.1.4-main+abc")
    VERSION=$(ghostty --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    LOCATION=$(command -v ghostty)

    # Detect installation method
    METHOD="Unknown"
    if snap list ghostty &>/dev/null 2>&1; then
        METHOD="Snap"
    elif dpkg -l ghostty 2>/dev/null | grep -q '^ii'; then
        METHOD="apt"
    elif [[ "$LOCATION" == "/usr/bin/ghostty" ]]; then
        # If at /usr/bin but not from apt, it's a source build
        METHOD="Source"
    elif [[ "$LOCATION" == "/usr/local/bin/ghostty" ]]; then
        METHOD="Source"
    elif [[ "$LOCATION" == "$HOME/.local/bin/ghostty" ]]; then
        METHOD="Local"
    fi

    LATEST=$(get_ghostty_latest)

    log "SUCCESS" "ghostty is installed: $VERSION"

    # Check context menu integration (nautilus-open-any-terminal extension)
    CONTEXT_MENU_STATUS="NO_CONTEXT_MENU"

    # Check for nautilus-open-any-terminal extension (preferred modern approach)
    EXT_FILE="${HOME}/.local/share/nautilus-python/extensions/nautilus_open_any_terminal.py"
    if [[ -f "$EXT_FILE" ]]; then
        CONFIGURED_TERMINAL=$(gsettings get com.github.stunkymonkey.nautilus-open-any-terminal terminal 2>/dev/null | tr -d "'")
        if [[ "$CONFIGURED_TERMINAL" == "ghostty" ]]; then
            log "SUCCESS" "Context menu: Extension installed (Ghostty)"
            CONTEXT_MENU_STATUS="CONTEXT_MENU_EXTENSION"
        else
            log "INFO" "Context menu: Extension installed (not configured for Ghostty)"
            CONTEXT_MENU_STATUS="CONTEXT_MENU_OTHER"
        fi
    # Fallback: check legacy script (deprecated in Nautilus 49+)
    elif [[ -x "${HOME}/.local/share/nautilus/scripts/Open in Ghostty" ]]; then
        log "WARNING" "Context menu: Legacy script (hidden in Scripts submenu)"
        CONTEXT_MENU_STATUS="CONTEXT_MENU_LEGACY"
    else
        log "INFO" "Context menu: Not installed (run Reinstall to add)"
    fi

    # Append context menu status to location field
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION^$CONTEXT_MENU_STATUS|$LATEST"
else
    log "WARNING" "ghostty is NOT installed"
    LATEST=$(get_ghostty_latest)
    echo "NOT_INSTALLED|-|-|-|$LATEST"
fi
