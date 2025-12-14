#!/bin/bash
# install_deps_zsh.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing dependencies for zsh..."

# Smart apt update - skip if cache is fresh (< 5 min)
APT_LISTS="/var/lib/apt/lists"
CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$APT_LISTS" 2>/dev/null || echo 0)))
if [[ $CACHE_AGE -gt 300 ]]; then
    sudo stdbuf -oL apt-get update
else
    log "INFO" "APT cache fresh (${CACHE_AGE}s ago), skipping update"
fi
# Zsh doesn't really have deps other than libc which is standard.
log "SUCCESS" "Dependencies check complete (zsh has minimal deps)"
