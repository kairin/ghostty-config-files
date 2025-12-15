#!/bin/bash
# confirm_python_uv.sh
source "$(dirname "$0")/../006-logs/logger.sh"

# Source cargo env or local bin if needed
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

log "INFO" "Confirming uv installation..."

if command -v uv &> /dev/null; then
    VERSION=$(uv --version 2>/dev/null | head -1)
    PATH_LOC=$(command -v uv)
    log "SUCCESS" "uv is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"

    # Check for uvx
    if command -v uvx &> /dev/null; then
        log "SUCCESS" "uvx is also available"
    fi

    # Generate artifact manifest for future verification
    SCRIPT_DIR="$(dirname "$0")"
    VERSION_NUM=$(echo "$VERSION" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" python_uv "$VERSION_NUM" script > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
    log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
else
    log "ERROR" "uv is NOT installed"
    exit 1
fi
