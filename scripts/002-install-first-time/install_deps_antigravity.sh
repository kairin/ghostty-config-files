#!/bin/bash
# install_deps_antigravity.sh - Install dependencies for Google Antigravity
# Antigravity is a standalone desktop app with minimal dependencies

source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking dependencies for Google Antigravity..."

MISSING=0

# Check curl (required for downloading)
if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is required but not installed."
    log "INFO" "Installing curl..."
    if sudo apt-get update && sudo apt-get install -y curl; then
        log "SUCCESS" "curl installed"
    else
        log "ERROR" "Failed to install curl"
        MISSING=1
    fi
fi

# Check for dpkg (needed for .deb installation)
if ! command -v dpkg &> /dev/null; then
    log "ERROR" "dpkg is required but not installed."
    MISSING=1
fi

# Check jq (required for IDE font configuration)
if ! command -v jq &> /dev/null; then
    log "INFO" "Installing jq (required for IDE font configuration)..."
    if sudo apt-get install -y jq; then
        log "SUCCESS" "jq installed"
    else
        log "WARNING" "Failed to install jq - font configuration may not work"
    fi
fi

# Check for common desktop dependencies
DESKTOP_DEPS="libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libsecret-1-0"
MISSING_DEPS=""

for dep in $DESKTOP_DEPS; do
    if ! dpkg -s "$dep" &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    log "INFO" "Installing desktop dependencies:$MISSING_DEPS"
    if sudo apt-get update && sudo apt-get install -y $MISSING_DEPS; then
        log "SUCCESS" "Desktop dependencies installed"
    else
        log "WARNING" "Some dependencies may be missing"
    fi
fi

if [ $MISSING -eq 1 ]; then
    log "ERROR" "Required dependencies are missing"
    exit 1
fi

log "SUCCESS" "Dependencies for Google Antigravity are ready."
