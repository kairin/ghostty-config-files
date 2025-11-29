#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming ghostty installation..."

if command -v ghostty &> /dev/null; then
    VERSION=$(ghostty --version | head -n 1)
    PATH_LOC=$(command -v ghostty)
    log "SUCCESS" "ghostty is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"
    
    # Check if multiple versions exist
    COUNT=$(type -a ghostty | grep "is" | wc -l)
    if [ "$COUNT" -gt 1 ]; then
        log "WARNING" "Multiple versions of ghostty detected:"
        type -a ghostty | while read -r line; do log "WARNING" "$line"; done
    else
        log "SUCCESS" "Single installation confirmed."
    fi
else
    log "ERROR" "ghostty is NOT installed"
    exit 1
fi
