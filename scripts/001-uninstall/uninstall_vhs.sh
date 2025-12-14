#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL vhs installations..."

removed_count=0

# 1. Remove APT package if installed
if dpkg -l vhs 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found apt package, removing..."
    if sudo apt-get remove -y vhs; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# 2. Remove Snap if installed
if snap list vhs 2>/dev/null | grep -q vhs; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove vhs; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 3. Remove go-installed binary
GO_BIN="${GOPATH:-$HOME/go}/bin/vhs"
if [ -f "$GO_BIN" ]; then
    log "INFO" "Found go binary at $GO_BIN, removing..."
    if rm -f "$GO_BIN"; then
        ((removed_count++))
        log "SUCCESS" "Go binary removed"
    else
        log "WARNING" "Failed to remove go binary"
    fi
fi

# 4. Remove from /usr/local/bin if exists
if [ -f "/usr/local/bin/vhs" ]; then
    log "INFO" "Found binary at /usr/local/bin/vhs, removing..."
    if sudo rm -f "/usr/local/bin/vhs"; then
        ((removed_count++))
        log "SUCCESS" "Binary removed from /usr/local/bin"
    else
        log "WARNING" "Failed to remove binary"
    fi
fi

# 5. Check for any other vhs binaries in PATH
if command -v vhs &>/dev/null; then
    remaining=$(which vhs)
    log "WARNING" "vhs still found at: $remaining"
    log "WARNING" "Manual cleanup may be required"
fi

# 6. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v vhs &>/dev/null; then
        log "INFO" "vhs is not installed, nothing to do"
    else
        log "ERROR" "Could not remove vhs - still found in PATH"
        exit 1
    fi
else
    if ! command -v vhs &>/dev/null; then
        log "SUCCESS" "All vhs installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which vhs)
        log "WARNING" "Removed $removed_count installations, but vhs still found at: $remaining"
    fi
fi
