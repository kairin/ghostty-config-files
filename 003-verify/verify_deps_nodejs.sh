#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Verifying Node.js dependencies..."

MISSING=0

if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is missing"
    MISSING=1
fi

if ! command -v unzip &> /dev/null; then
    log "ERROR" "unzip is missing"
    MISSING=1
fi

if [ $MISSING -eq 0 ]; then
    log "SUCCESS" "All dependencies found"
    exit 0
else
    log "ERROR" "Some dependencies are missing"
    exit 1
fi
