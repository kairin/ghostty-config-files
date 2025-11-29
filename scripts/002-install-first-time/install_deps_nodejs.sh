#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing dependencies for Node.js (curl, unzip)..."

if command -v apt-get &> /dev/null; then
    # Wait for apt lock
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        log "INFO" "Waiting for apt lock..."
        sleep 1
    done
    
    sudo apt-get update
    sudo apt-get install -y curl unzip
    log "SUCCESS" "Dependencies installed"
else
    log "WARNING" "apt-get not found. Assuming dependencies are met or manually installed."
fi
