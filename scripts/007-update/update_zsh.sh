#!/bin/bash
# update_zsh.sh - Update ZSH shell
#
# Uses apt for in-place update (preserves .zshrc and configs)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current zsh version: $(zsh --version 2>/dev/null || echo 'none')"

# Update package lists
log "INFO" "Updating package lists..."
sudo apt-get update -qq

# Install/upgrade zsh (apt preserves user configs)
log "INFO" "Updating zsh..."
if sudo apt-get install -y zsh; then
    log "SUCCESS" "zsh updated"
    log "INFO" "New version: $(zsh --version 2>/dev/null)"
else
    log "ERROR" "zsh update failed"
    exit 1
fi

log "SUCCESS" "zsh update complete"
