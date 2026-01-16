#!/bin/bash
# update_vhs.sh - Update vhs via apt (Charm repository)
#
# apt handles version checking and in-place updates automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current vhs version: $(vhs --version 2>/dev/null || echo 'none')"

# Update package lists
log "INFO" "Updating package lists..."
sudo apt-get update -qq

# Install/upgrade vhs (apt handles this gracefully)
log "INFO" "Updating vhs..."
if sudo apt-get install -y vhs; then
    log "SUCCESS" "vhs updated"
    log "INFO" "New version: $(vhs --version 2>/dev/null)"
else
    log "ERROR" "vhs update failed"
    exit 1
fi

log "SUCCESS" "vhs update complete"
