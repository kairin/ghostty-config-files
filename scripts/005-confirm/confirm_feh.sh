#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming feh installation..."

if command -v feh &> /dev/null; then
    VERSION=$(feh --version | head -n 1)
    PATH_LOC=$(command -v feh)
    log "SUCCESS" "feh is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"
    
    # Check if multiple versions exist (e.g. /usr/bin/feh vs /usr/local/bin/feh)
    COUNT=$(type -a feh | grep "is" | wc -l)
    if [ "$COUNT" -gt 1 ]; then
        log "WARNING" "Multiple versions of feh detected:"
        type -a feh | while read -r line; do log "WARNING" "$line"; done
    else
        log "SUCCESS" "Single installation confirmed."
    fi

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    BUILD_FLAGS=$(feh --version 2>/dev/null | grep -i "compile-time" | sed 's/.*: //' || echo "")
    "$SCRIPT_DIR/generate_manifest.sh" feh "$VERSION" source "$BUILD_FLAGS" > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "feh is NOT installed"
    exit 1
fi
