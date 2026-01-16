#!/bin/bash
# update_feh.sh - Update feh image viewer
#
# Detects installation method (apt vs source) and updates accordingly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current feh version: $(feh --version 2>/dev/null | head -n 1 || echo 'none')"

# Check if installed via apt or source
if dpkg -l feh &> /dev/null 2>&1; then
    # APT installation
    log "INFO" "Detected apt installation, updating via apt..."

    sudo apt-get update -qq
    if sudo apt-get install -y feh; then
        log "SUCCESS" "feh updated via apt"
    else
        log "ERROR" "apt update failed"
        exit 1
    fi

elif [[ -f /usr/local/bin/feh ]]; then
    # Source installation - delegate to install script
    log "INFO" "Detected source installation, rebuilding..."

    if bash "$SCRIPT_DIR/../004-reinstall/install_feh.sh"; then
        log "SUCCESS" "feh rebuilt from source"
    else
        log "ERROR" "Source build failed"
        exit 1
    fi

else
    log "ERROR" "feh installation not detected"
    exit 1
fi

log "INFO" "New version: $(feh --version 2>/dev/null | head -n 1)"
log "SUCCESS" "feh update complete"
