#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Verifying Ghostty build-from-source dependencies..."

MISSING=0
REQUIRED_ZIG="0.14.0"
ZIG_PATH="/usr/local/bin/zig"

# Check Zig installation at our expected location
if [ -x "$ZIG_PATH" ]; then
    ZIG_VER=$($ZIG_PATH version 2>/dev/null)
    if [[ "$ZIG_VER" == "$REQUIRED_ZIG"* ]]; then
        log "SUCCESS" "Zig $ZIG_VER available at $ZIG_PATH (required: $REQUIRED_ZIG)"
    else
        log "ERROR" "Zig version mismatch at $ZIG_PATH: have $ZIG_VER, need $REQUIRED_ZIG"
        MISSING=1
    fi
else
    # Check if there's a snap zig that's shadowing
    if command -v zig &>/dev/null; then
        ZIG_LOCATION=$(which zig)
        ZIG_VER=$(zig version 2>/dev/null)
        if [[ "$ZIG_LOCATION" == "/snap/"* ]]; then
            log "ERROR" "Snap zig found at $ZIG_LOCATION (version $ZIG_VER) - wrong version!"
            log "ERROR" "Run install_deps_ghostty.sh to remove snap zig and install $REQUIRED_ZIG"
        else
            log "ERROR" "Zig found at $ZIG_LOCATION (version $ZIG_VER) but not at expected path $ZIG_PATH"
        fi
    else
        log "ERROR" "Zig not found at $ZIG_PATH"
    fi
    MISSING=1
fi

# Check GTK4 development files using pkg-config
GTK_LIBS=("gtk4" "libadwaita-1")
for lib in "${GTK_LIBS[@]}"; do
    if pkg-config --exists "$lib" 2>/dev/null; then
        LIB_VER=$(pkg-config --modversion "$lib" 2>/dev/null)
        log "SUCCESS" "$lib development files available (version $LIB_VER)"
    else
        log "ERROR" "$lib development files missing"
        MISSING=1
    fi
done

# Check gtk4-layer-shell (built from source, should be in pkg-config)
if pkg-config --exists gtk4-layer-shell 2>/dev/null; then
    LIB_VER=$(pkg-config --modversion gtk4-layer-shell 2>/dev/null)
    log "SUCCESS" "gtk4-layer-shell development files available (version $LIB_VER)"
elif [ -f "/usr/local/include/gtk4-layer-shell/gtk4-layer-shell.h" ]; then
    log "SUCCESS" "gtk4-layer-shell development files available (header found at /usr/local)"
elif [ -f "/usr/include/gtk4-layer-shell/gtk4-layer-shell.h" ]; then
    log "SUCCESS" "gtk4-layer-shell development files available (header found)"
else
    log "ERROR" "gtk4-layer-shell development files missing"
    log "ERROR" "Run install_deps_ghostty.sh to build gtk4-layer-shell from source"
    MISSING=1
fi

# Check required tools
REQUIRED_TOOLS=("git" "curl" "gettext" "pkg-config")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        log "SUCCESS" "$tool available"
    else
        log "ERROR" "$tool missing"
        MISSING=1
    fi
done

# Check xmllint (from libxml2-utils)
if command -v xmllint &>/dev/null; then
    log "SUCCESS" "xmllint available (libxml2-utils)"
else
    log "ERROR" "xmllint missing (install libxml2-utils)"
    MISSING=1
fi

# Summary
if [ $MISSING -eq 0 ]; then
    log "SUCCESS" "All build dependencies verified."
else
    log "ERROR" "Some dependencies are missing. Run install_deps_ghostty.sh first."
    exit 1
fi
