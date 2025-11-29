#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Verifying dependencies for Nerd Fonts..."

MISSING=0

check_cmd() {
    if command -v "$1" &> /dev/null; then
        log "SUCCESS" "Found: $1"
    else
        log "ERROR" "Missing: $1"
        MISSING=1
    fi
}

check_cmd "unzip"
check_cmd "curl"
check_cmd "fc-cache"

if [ $MISSING -eq 0 ]; then
    log "SUCCESS" "All dependencies verified"
    exit 0
else
    log "ERROR" "Some dependencies are missing"
    exit 1
fi
