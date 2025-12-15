#!/bin/bash
# confirm_fastfetch.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming fastfetch installation..."

if command -v fastfetch &> /dev/null; then
    VERSION=$(fastfetch --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v fastfetch)
    log "SUCCESS" "fastfetch is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" fastfetch "$VERSION_NUM" apt > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "fastfetch is NOT installed"
    exit 1
fi
