#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL feh installations..."

removed_count=0

# 1. Remove APT package if installed
if dpkg -l feh 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found apt package, removing..."
    if sudo apt-get remove -y feh; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# 2. Remove Snap if installed
if snap list feh 2>/dev/null | grep -q feh; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove feh; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 3. Remove source/manual binary if exists at /usr/local/bin
if [ -f "/usr/local/bin/feh" ]; then
    log "INFO" "Found source binary at /usr/local/bin/feh, removing..."
    if sudo rm -f "/usr/local/bin/feh"; then
        ((removed_count++))
        log "SUCCESS" "Source binary removed from /usr/local/bin"
    else
        log "WARNING" "Failed to remove source binary"
    fi
fi

# 4. Check for any other feh binaries in PATH
if command -v feh &>/dev/null; then
    remaining=$(which feh)
    log "WARNING" "feh still found at: $remaining"
    log "WARNING" "This may be a system package or another installation method"
    log "WARNING" "Manual cleanup may be required"
    # Don't exit with error - we did our best
fi

# 5. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v feh &>/dev/null; then
        log "INFO" "feh is not installed, nothing to do"
    else
        log "ERROR" "Could not remove feh - still found in PATH"
        exit 1
    fi
else
    if ! command -v feh &>/dev/null; then
        log "SUCCESS" "All feh installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which feh)
        log "WARNING" "Removed $removed_count installations, but feh still found at: $remaining"
    fi
fi
