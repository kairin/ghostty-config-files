#!/bin/bash
# install_deps_gum.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing dependencies for gum..."

# Smart apt update - skip if cache is fresh (< 5 min)
APT_LISTS="/var/lib/apt/lists"
CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$APT_LISTS" 2>/dev/null || echo 0)))
if [[ $CACHE_AGE -gt 300 ]]; then
    sudo stdbuf -oL apt-get update
else
    log "INFO" "APT cache fresh (${CACHE_AGE}s ago), skipping update"
fi
if sudo stdbuf -oL apt-get install -y curl gpg; then
    log "SUCCESS" "Dependencies installed successfully"
else
    log "ERROR" "Failed to install dependencies"
    exit 1
fi
