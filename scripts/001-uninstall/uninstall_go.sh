#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL Go installations..."

removed_count=0

# 1. Remove APT package if installed
if dpkg -l golang 2>/dev/null | grep -q '^ii' || dpkg -l golang-go 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found apt package, removing..."
    if sudo apt-get remove -y golang golang-go 2>/dev/null; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# 2. Remove Snap if installed
if snap list go 2>/dev/null | grep -q go; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove go; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 3. Remove tarball installation at /usr/local/go
if [ -d "/usr/local/go" ]; then
    log "INFO" "Found tarball installation at /usr/local/go, removing..."
    if sudo rm -rf /usr/local/go; then
        ((removed_count++))
        log "SUCCESS" "Removed /usr/local/go"
    else
        log "WARNING" "Failed to remove /usr/local/go"
    fi
fi

# 4. Remove symlinks in /usr/local/bin
for bin in go gofmt; do
    if [ -f "/usr/local/bin/$bin" ] || [ -L "/usr/local/bin/$bin" ]; then
        log "INFO" "Removing /usr/local/bin/$bin..."
        sudo rm -f "/usr/local/bin/$bin"
    fi
done

# 5. Check for any other go binaries in PATH
if command -v go &>/dev/null; then
    remaining=$(which go)
    log "WARNING" "go still found at: $remaining"
    log "WARNING" "Manual cleanup may be required"
fi

# 6. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v go &>/dev/null; then
        log "INFO" "Go is not installed, nothing to do"
    else
        log "ERROR" "Could not remove Go - still found in PATH"
        exit 1
    fi
else
    if ! command -v go &>/dev/null; then
        log "SUCCESS" "All Go installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which go)
        log "WARNING" "Removed $removed_count installations, but go still found at: $remaining"
    fi
fi
