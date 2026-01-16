#!/bin/bash
# update_fastfetch.sh - Update fastfetch system info tool
#
# Uses apt for in-place update

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current fastfetch version: $(fastfetch --version 2>/dev/null || echo 'none')"

# Update package lists
log "INFO" "Updating package lists..."
sudo apt-get update -qq

# Install/upgrade fastfetch
log "INFO" "Updating fastfetch..."
if sudo apt-get install -y fastfetch; then
    log "SUCCESS" "fastfetch updated"
    log "INFO" "New version: $(fastfetch --version 2>/dev/null)"
else
    log "ERROR" "fastfetch update failed"
    exit 1
fi

log "SUCCESS" "fastfetch update complete"
