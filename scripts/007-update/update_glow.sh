#!/bin/bash
# update_glow.sh - Update glow via apt (Charm repository)
#
# apt handles version checking and in-place updates automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current glow version: $(glow --version 2>/dev/null || echo 'none')"

# Update package lists
log "INFO" "Updating package lists..."
sudo apt-get update -qq

# Install/upgrade glow (apt handles this gracefully)
log "INFO" "Updating glow..."
if sudo apt-get install -y glow; then
    log "SUCCESS" "glow updated"
    log "INFO" "New version: $(glow --version 2>/dev/null)"
else
    log "ERROR" "glow update failed"
    exit 1
fi

log "SUCCESS" "glow update complete"
