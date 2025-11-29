#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming Nerd Fonts installation..."

# Check for one of the key fonts
if fc-list : family | grep -q "JetBrainsMonoNL Nerd Font"; then
    log "SUCCESS" "Nerd Fonts detected in system"
    exit 0
else
    log "ERROR" "Nerd Fonts not found in system"
    exit 1
fi
