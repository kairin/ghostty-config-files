#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming feh installation..."

if command -v feh &> /dev/null; then
    VERSION=$(feh --version | head -n 1)
    PATH_LOC=$(command -v feh)
    log "SUCCESS" "feh is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"
    
    # Check if multiple versions exist (e.g. /usr/bin/feh vs /usr/local/bin/feh)
    COUNT=$(type -a feh | grep "is" | wc -l)
    if [ "$COUNT" -gt 1 ]; then
        log "WARNING" "Multiple versions of feh detected:"
        type -a feh | while read -r line; do log "WARNING" "$line"; done
    else
        log "SUCCESS" "Single installation confirmed."
    fi
else
    log "ERROR" "feh is NOT installed"
    exit 1
fi
