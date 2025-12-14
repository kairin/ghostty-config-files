#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking for existing feh installation..."

if command -v feh &> /dev/null; then
    VERSION=$(feh --version | head -n 1)
    LOCATION=$(command -v feh)
    
    METHOD="Unknown"
    if [[ "$LOCATION" == "/usr/local/bin/feh" ]]; then
        METHOD="Source"
    elif dpkg -s feh &> /dev/null; then
        METHOD="Apt"
    fi
    
    log "SUCCESS" "feh is installed: $VERSION"
    # LATEST field is "-" since feh is typically installed via APT with no upstream version tracking
    echo "INSTALLED|$VERSION|$METHOD|$LOCATION|-"
else
    log "WARNING" "feh is NOT installed"
    echo "Not Installed|-|-|-|-"
fi
