#!/bin/bash
# update_gum.sh - Update gum via apt (Charm repository)
#
# apt handles version checking and in-place updates automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current gum version: $(gum --version 2>/dev/null || echo 'none')"

# Update package lists
log "INFO" "Updating package lists..."
sudo apt-get update -qq

# Install/upgrade gum (apt handles this gracefully)
log "INFO" "Updating gum..."
if sudo apt-get install -y gum; then
    log "SUCCESS" "gum updated"
    log "INFO" "New version: $(gum --version 2>/dev/null)"
else
    log "ERROR" "gum update failed"
    exit 1
fi

log "SUCCESS" "gum update complete"
