#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Verifying dependencies for feh..."

MISSING=0
DEPS=("curl-config" "libpng-config") # Basic checks for dev tools

# Check for pkg-config libraries
LIBS="x11 xt imlib2 xinerama libexif lcms2"

for lib in $LIBS; do
    if pkg-config --exists "$lib"; then
        log "SUCCESS" "Library found: $lib"
    else
        log "ERROR" "Library missing: $lib"
        MISSING=1
    fi
done

if [ $MISSING -eq 0 ]; then
    log "SUCCESS" "All dependencies verified."
else
    log "ERROR" "Some dependencies are missing."
    exit 1
fi
