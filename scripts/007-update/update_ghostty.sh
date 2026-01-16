#!/bin/bash
# update_ghostty.sh - Update Ghostty based on installation method
#
# Detects installation method (snap vs source) and updates accordingly:
# - Snap: Uses 'snap refresh' for in-place update
# - Source: Rebuilds from git (preserves config)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current Ghostty version: $(ghostty --version 2>/dev/null || echo 'none')"

# Detect installation method
if snap list ghostty &> /dev/null 2>&1; then
    # Snap installation
    log "INFO" "Detected snap installation, updating via snap refresh..."

    if sudo snap refresh ghostty; then
        log "SUCCESS" "Ghostty updated via snap"
        log "INFO" "New version: $(ghostty --version 2>/dev/null)"
    else
        log "WARNING" "snap refresh returned non-zero (may already be latest)"
    fi

elif [[ -f /usr/local/bin/ghostty ]]; then
    # Source installation - delegate to install script
    log "INFO" "Detected source installation, rebuilding from source..."
    log "INFO" "This may take a few minutes..."

    # Use the existing install script which handles source builds
    if bash "$SCRIPT_DIR/../004-reinstall/install_ghostty.sh"; then
        log "SUCCESS" "Ghostty rebuilt from source"
        log "INFO" "New version: $(ghostty --version 2>/dev/null)"
    else
        log "ERROR" "Source build failed"
        exit 1
    fi

else
    log "ERROR" "Ghostty installation not detected"
    exit 1
fi

log "SUCCESS" "Ghostty update complete"
