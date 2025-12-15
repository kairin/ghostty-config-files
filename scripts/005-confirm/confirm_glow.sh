#!/bin/bash
# confirm_glow.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming glow installation..."

if command -v glow &> /dev/null; then
    VERSION=$(glow --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v glow)
    log "SUCCESS" "glow is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" glow "$VERSION_NUM" apt > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "glow is NOT installed"
    exit 1
fi
