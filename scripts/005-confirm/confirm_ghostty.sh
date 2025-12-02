#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Confirming ghostty installation..."

if command -v ghostty &> /dev/null; then
    VERSION=$(ghostty --version | head -n 1)
    PATH_LOC=$(command -v ghostty)
    log "SUCCESS" "ghostty is installed at $PATH_LOC"
    log "SUCCESS" "Version: $VERSION"
    
    # Check if multiple versions exist
    COUNT=$(type -a ghostty | grep "is" | wc -l)
    if [ "$COUNT" -gt 1 ]; then
        log "WARNING" "Multiple versions of ghostty detected:"
        type -a ghostty | while read -r line; do log "WARNING" "$line"; done
    else
        log "SUCCESS" "Single installation confirmed."
    fi
else
    log "ERROR" "ghostty is NOT installed"
    exit 1
fi

# Desktop icon integration verification (uses shared utilities from logger.sh)
log "INFO" "Verifying desktop icon integration..."

ICON_DIR="/usr/local/share/icons/hicolor"
ICON_ISSUES=0

# Check if Ghostty icons exist
ICON_FOUND=0
for size in 512 256 128 32 16; do
    if [ -f "$ICON_DIR/${size}x${size}/apps/ghostty.png" ]; then
        ICON_FOUND=1
        break
    fi
done

if [ $ICON_FOUND -eq 1 ]; then
    log "SUCCESS" "Ghostty icon found in $ICON_DIR"
else
    log "WARNING" "Ghostty icon not found in $ICON_DIR"
    ICON_ISSUES=$((ICON_ISSUES + 1))
fi

# Verify icon cache validity (CRITICAL check)
if [ -d "$ICON_DIR" ]; then
    # Check index.theme exists
    if [ ! -f "$ICON_DIR/index.theme" ]; then
        log "WARNING" "Missing index.theme in $ICON_DIR - icons may not display correctly"
        ICON_ISSUES=$((ICON_ISSUES + 1))

        # Auto-fix using shared utility if available
        if type ensure_icon_infrastructure &>/dev/null; then
            log "INFO" "Attempting auto-fix..."
            ensure_icon_infrastructure "$ICON_DIR" "sudo" || true
        fi
    fi

    # Check cache validity (should be > 1KB; invalid cache is ~496 bytes)
    CACHE_FILE="$ICON_DIR/icon-theme.cache"
    if [ -f "$CACHE_FILE" ]; then
        CACHE_SIZE=$(stat -c%s "$CACHE_FILE" 2>/dev/null || echo "0")
        if [ "$CACHE_SIZE" -lt 1024 ]; then
            log "WARNING" "Icon cache may be invalid (${CACHE_SIZE} bytes, expected >1KB)"
            ICON_ISSUES=$((ICON_ISSUES + 1))

            # Auto-fix using shared utility if available
            if type rebuild_icon_cache &>/dev/null; then
                log "INFO" "Attempting auto-fix..."
                rebuild_icon_cache "$ICON_DIR" "sudo" || true
            fi
        else
            log "SUCCESS" "Icon cache valid (${CACHE_SIZE} bytes)"
        fi
    else
        log "WARNING" "Icon cache does not exist"
        ICON_ISSUES=$((ICON_ISSUES + 1))
    fi
fi

if [ $ICON_ISSUES -gt 0 ]; then
    log "WARNING" "Found $ICON_ISSUES desktop icon issue(s)"
    log "INFO" "Run 'tests/verify_icons.sh --fix' for full diagnostics and repair"
else
    log "SUCCESS" "Desktop icon integration verified"
fi
