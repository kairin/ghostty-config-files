#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL Node.js installations..."

removed_count=0

# 1. Remove APT packages if installed
if dpkg -l nodejs 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found nodejs apt package, removing..."
    if sudo apt-get remove -y nodejs; then
        ((removed_count++))
        log "SUCCESS" "nodejs APT package removed"
    else
        log "WARNING" "Failed to remove nodejs apt package"
    fi
fi

if dpkg -l npm 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found npm apt package, removing..."
    if sudo apt-get remove -y npm; then
        ((removed_count++))
        log "SUCCESS" "npm APT package removed"
    else
        log "WARNING" "Failed to remove npm apt package"
    fi
fi

# 2. Remove Snap if installed
if snap list node 2>/dev/null | grep -q node; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove node; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 3. Remove fnm (Fast Node Manager)
if [ -d "$HOME/.local/share/fnm" ]; then
    log "INFO" "Found fnm at ~/.local/share/fnm, removing..."
    if rm -rf "$HOME/.local/share/fnm"; then
        ((removed_count++))
        log "SUCCESS" "Removed ~/.local/share/fnm"
    else
        log "WARNING" "Failed to remove fnm directory"
    fi
fi

# Legacy fnm location
if [ -d "$HOME/.fnm" ]; then
    log "INFO" "Found legacy fnm at ~/.fnm, removing..."
    if rm -rf "$HOME/.fnm"; then
        ((removed_count++))
        log "SUCCESS" "Removed ~/.fnm"
    else
        log "WARNING" "Failed to remove legacy fnm directory"
    fi
fi

# fnm binary
if [ -f "$HOME/.local/bin/fnm" ]; then
    log "INFO" "Removing fnm binary..."
    rm -f "$HOME/.local/bin/fnm"
fi

# 4. Remove nvm if installed
if [ -d "$HOME/.nvm" ]; then
    log "INFO" "Found nvm at ~/.nvm, removing..."
    if rm -rf "$HOME/.nvm"; then
        ((removed_count++))
        log "SUCCESS" "Removed ~/.nvm"
    else
        log "WARNING" "Failed to remove nvm directory"
    fi
fi

# 5. Check for any other node binaries in PATH
if command -v node &>/dev/null; then
    remaining=$(which node)
    log "WARNING" "node still found at: $remaining"
    log "WARNING" "Manual cleanup may be required"
fi

# 6. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v node &>/dev/null; then
        log "INFO" "Node.js is not installed, nothing to do"
    else
        log "WARNING" "Could not remove Node.js - still found in PATH"
        log "WARNING" "Please manually remove fnm/nvm configuration from shell rc files"
    fi
else
    if ! command -v node &>/dev/null; then
        log "SUCCESS" "All Node.js installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which node)
        log "WARNING" "Removed $removed_count installations, but node still found at: $remaining"
    fi
    log "INFO" "Please manually remove fnm/nvm configuration from shell rc files (.zshrc, .bashrc)"
fi
