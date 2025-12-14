#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing dependencies for Nerd Fonts..."

# Function to wait for apt lock
wait_for_apt_lock() {
    local lock_file="/var/lib/dpkg/lock-frontend"
    local max_attempts=30 # 5 minutes (10s intervals)
    local attempt=0
    
    while sudo fuser "$lock_file" >/dev/null 2>&1; do
        if [ $attempt -ge $max_attempts ]; then
            log "ERROR" "Timed out waiting for apt lock."
            return 1
        fi
        log "WARNING" "Apt lock is held by another process. Waiting 10s..."
        sleep 10
        ((attempt++))
    done
    return 0
}

DEPS="tar xz-utils curl fontconfig"

log "INFO" "Updating apt..."
wait_for_apt_lock
sudo stdbuf -oL apt-get update

log "INFO" "Installing: $DEPS"
if sudo stdbuf -oL apt-get install -y $DEPS; then
    log "SUCCESS" "Dependencies installed successfully"
else
    log "ERROR" "Failed to install dependencies"
    exit 1
fi
