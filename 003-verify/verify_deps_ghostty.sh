#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Verifying dependencies for ghostty..."

MISSING=0

# Check Zig
if command -v zig &> /dev/null; then
    ZIG_VER=$(zig version)
    log "SUCCESS" "Zig found: $ZIG_VER"
else
    log "ERROR" "Zig missing"
    MISSING=1
fi

# Check libraries
LIBS="gtk4 libadwaita-1"
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
