#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming Node.js installation..."

# We need to ensure fnm is available
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi

if command -v node &> /dev/null; then
    VERSION=$(node -v)
    log "SUCCESS" "Node.js is installed: $VERSION"
    
    if [[ "$VERSION" == v25* ]]; then
        log "SUCCESS" "Version check passed (v25)"
        exit 0
    else
        log "WARNING" "Version mismatch: Expected v25, got $VERSION"
        exit 0 # Not a fatal error, just a warning
    fi
else
    log "ERROR" "Node.js binary not found"
    exit 1
fi
