#!/bin/bash
# confirm_vhs.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming VHS installation..."

if command -v vhs &> /dev/null; then
    VERSION=$(vhs --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v vhs)
    log "SUCCESS" "VHS is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" vhs "$VERSION_NUM" apt > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "VHS is NOT installed"
    exit 1
fi
