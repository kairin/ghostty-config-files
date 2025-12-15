#!/bin/bash
# confirm_go.sh
source "$(dirname "$0")/../006-logs/logger.sh"

# Ensure Go is in PATH
export PATH=$PATH:/usr/local/go/bin

log "INFO" "Confirming Go installation..."

if command -v go &> /dev/null; then
    VERSION=$(go version 2>/dev/null)
    PATH_LOC=$(command -v go)
    log "SUCCESS" "Go is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    # Extract version number (e.g., "go1.23.4" -> "1.23.4")
    VERSION_NUM=$(echo "$VERSION" | grep -oP 'go\K\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" go "$VERSION_NUM" source > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "Go is NOT installed"
    exit 1
fi
