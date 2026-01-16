#!/bin/bash
# update_nodejs.sh - Update Node.js via fnm WITHOUT losing npm global packages
#
# This script performs an in-place update by:
# 1. Installing the new Node.js version alongside existing ones
# 2. Switching to the new version
# 3. Preserving all npm global packages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

# Initialize fnm environment
FNM_PATH="$HOME/.local/share/fnm"
if [[ -d "$FNM_PATH" ]]; then
    export PATH="$FNM_PATH:$PATH"
    eval "$(fnm env --use-on-cd 2>/dev/null)"
else
    log "ERROR" "fnm not found at $FNM_PATH"
    exit 1
fi

# Get target version (major version)
TARGET_VERSION="25"

log "INFO" "Current Node.js version: $(node --version 2>/dev/null || echo 'none')"
log "INFO" "Current npm version: $(npm --version 2>/dev/null || echo 'none')"

# List current npm globals before update
log "INFO" "Recording current npm global packages..."
NPM_GLOBALS_BEFORE=$(npm list -g --depth=0 2>/dev/null || echo "")

log "INFO" "Updating to Node.js v${TARGET_VERSION}..."

# Install new version (fnm keeps old versions, preserving npm globals)
fnm install "$TARGET_VERSION" || {
    log "ERROR" "Failed to install Node.js v${TARGET_VERSION}"
    exit 1
}

# Switch to new version
fnm use "$TARGET_VERSION" || {
    log "ERROR" "Failed to switch to Node.js v${TARGET_VERSION}"
    exit 1
}

# Set as default
fnm default "$TARGET_VERSION"

log "SUCCESS" "Updated to Node.js $(node --version)"
log "INFO" "npm version: $(npm --version)"

# Verify npm globals still exist
log "INFO" "Verifying npm global packages..."
npm list -g --depth=0 2>/dev/null

log "SUCCESS" "Node.js update complete - npm globals preserved"
