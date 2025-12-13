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

# Install Nautilus "Open Terminal Here" with Ghostty using nautilus-open-any-terminal
# This extension adds a direct context menu item (not hidden in Scripts submenu)
install_nautilus_context_menu() {
    # Check if Nautilus is available
    if ! command -v nautilus &>/dev/null; then
        log "INFO" "Nautilus not installed, skipping context menu"
        return 0
    fi

    # Check if already configured for Ghostty
    local current_terminal
    current_terminal=$(gsettings get com.github.stunkymonkey.nautilus-open-any-terminal terminal 2>/dev/null | tr -d "'" || echo "")
    if [[ "$current_terminal" == "ghostty" ]]; then
        log "SUCCESS" "Context menu already configured for Ghostty"
        return 0
    fi

    # Check if python3-nautilus is installed (required for extensions)
    if ! dpkg -l python3-nautilus 2>/dev/null | /bin/grep -q "^ii"; then
        log "INFO" "Installing python3-nautilus for context menu support..."
        sudo apt install -y python3-nautilus || {
            log "WARNING" "Could not install python3-nautilus"
            return 1
        }
    fi

    # Install nautilus-open-any-terminal from source (pip doesn't work on externally managed Python)
    local ext_file="${HOME}/.local/share/nautilus-python/extensions/nautilus_open_any_terminal.py"
    if [[ ! -f "$ext_file" ]]; then
        log "INFO" "Installing nautilus-open-any-terminal extension from source..."
        local temp_dir
        temp_dir=$(mktemp -d)

        if git clone --depth 1 https://github.com/Stunkymonkey/nautilus-open-any-terminal.git "$temp_dir" 2>/dev/null; then
            make -C "$temp_dir" build 2>/dev/null
            make -C "$temp_dir" install-nautilus 2>/dev/null
            glib-compile-schemas ~/.local/share/glib-2.0/schemas/ 2>/dev/null
            rm -rf "$temp_dir"
        else
            log "WARNING" "Could not clone nautilus-open-any-terminal"
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Configure for Ghostty
    gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ghostty 2>/dev/null || true
    gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab false 2>/dev/null || true

    # Remove legacy script if exists (deprecated approach)
    rm -f "${HOME}/.local/share/nautilus/scripts/Open in Ghostty" 2>/dev/null

    # Restart Nautilus to load extension
    nautilus -q 2>/dev/null || true

    log "SUCCESS" "Context menu 'Open Terminal Here' configured for Ghostty"
    log "INFO" "Right-click any folder → 'Open Terminal Here'"
}

log "INFO" "Setting up Nautilus context menu..."
install_nautilus_context_menu
