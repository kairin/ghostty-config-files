#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL fastfetch installations..."

removed_count=0

# 1. Remove APT package if installed
if dpkg -l fastfetch 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found apt package, removing..."
    if sudo apt-get remove -y fastfetch; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# 2. Remove Snap if installed
if snap list fastfetch 2>/dev/null | grep -q fastfetch; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove fastfetch; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 3. Remove from /usr/local/bin (manual/source install)
if [ -f "/usr/local/bin/fastfetch" ]; then
    log "INFO" "Found binary at /usr/local/bin/fastfetch, removing..."
    if sudo rm -f "/usr/local/bin/fastfetch"; then
        ((removed_count++))
        log "SUCCESS" "Binary removed from /usr/local/bin"
    else
        log "WARNING" "Failed to remove binary"
    fi
fi

# Also remove flashfetch symlink if exists
if [ -f "/usr/local/bin/flashfetch" ] || [ -L "/usr/local/bin/flashfetch" ]; then
    log "INFO" "Removing flashfetch symlink..."
    sudo rm -f "/usr/local/bin/flashfetch"
fi

# 4. Remove from ~/.local/bin
if [ -f "$HOME/.local/bin/fastfetch" ]; then
    log "INFO" "Found binary at ~/.local/bin/fastfetch, removing..."
    if rm -f "$HOME/.local/bin/fastfetch"; then
        ((removed_count++))
        log "SUCCESS" "Binary removed from ~/.local/bin"
    else
        log "WARNING" "Failed to remove binary"
    fi
fi

# 5. Check for any other fastfetch binaries in PATH
if command -v fastfetch &>/dev/null; then
    remaining=$(which fastfetch)
    log "WARNING" "fastfetch still found at: $remaining"
    log "WARNING" "Manual cleanup may be required"
fi

# 6. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v fastfetch &>/dev/null; then
        log "INFO" "fastfetch is not installed, nothing to do"
    else
        log "ERROR" "Could not remove fastfetch - still found in PATH"
        exit 1
    fi
else
    if ! command -v fastfetch &>/dev/null; then
        log "SUCCESS" "All fastfetch installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which fastfetch)
        log "WARNING" "Removed $removed_count installations, but fastfetch still found at: $remaining"
    fi
fi
