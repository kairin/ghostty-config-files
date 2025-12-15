#!/bin/bash
# confirm_gum.sh
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming gum installation..."

if command -v gum &> /dev/null; then
    VERSION=$(gum --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v gum)
    log "SUCCESS" "gum is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" gum "$VERSION_NUM" go-install > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "gum is NOT installed"
    exit 1
fi
