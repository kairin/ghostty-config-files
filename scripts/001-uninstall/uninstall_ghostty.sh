#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing ALL ghostty installations..."

removed_count=0

# 1. Remove Snap if installed
if snap list ghostty 2>/dev/null | grep -q ghostty; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove ghostty; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 2. Remove APT package if installed
if dpkg -l ghostty 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found apt package, removing..."
    if sudo apt-get remove -y ghostty; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# 3. Remove source build installed to /usr (build-from-source default)
# Only remove if NOT a dpkg package (avoid removing apt-installed binaries)
if [ -f "/usr/bin/ghostty" ] && ! dpkg -l ghostty 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found source-built binary at /usr/bin/ghostty, removing..."
    if sudo rm -f "/usr/bin/ghostty"; then
        ((removed_count++))
        log "SUCCESS" "Source binary removed from /usr/bin"
    else
        log "WARNING" "Failed to remove source binary from /usr/bin"
    fi

    # Also remove related files installed by zig build -p /usr
    if [ -d "/usr/share/ghostty" ]; then
        log "INFO" "Removing /usr/share/ghostty..."
        sudo rm -rf "/usr/share/ghostty"
    fi
    if [ -f "/usr/share/applications/com.mitchellh.ghostty.desktop" ]; then
        log "INFO" "Removing desktop file..."
        sudo rm -f "/usr/share/applications/com.mitchellh.ghostty.desktop"
    fi
    if [ -f "/usr/share/terminfo/g/ghostty" ]; then
        log "INFO" "Removing terminfo..."
        sudo rm -f "/usr/share/terminfo/g/ghostty"
        sudo rm -f "/usr/share/terminfo/x/xterm-ghostty"
    fi
    # Remove icons
    sudo rm -f /usr/share/icons/hicolor/*/apps/com.mitchellh.ghostty.png 2>/dev/null
    sudo rm -f /usr/share/icons/hicolor/*/apps/com.mitchellh.ghostty.svg 2>/dev/null
fi

# 4. Remove source/manual binary if exists at /usr/local/bin (legacy)
if [ -f "/usr/local/bin/ghostty" ]; then
    log "INFO" "Found source binary at /usr/local/bin/ghostty, removing..."
    if sudo rm -f "/usr/local/bin/ghostty"; then
        ((removed_count++))
        log "SUCCESS" "Source binary removed from /usr/local/bin"
    else
        log "WARNING" "Failed to remove source binary"
    fi
fi

# 5. Remove AppImage if exists (common alternative installation)
APPIMAGE_LOCATIONS=(
    "$HOME/Applications/ghostty.AppImage"
    "$HOME/.local/bin/ghostty"
    "/opt/ghostty"
)
for loc in "${APPIMAGE_LOCATIONS[@]}"; do
    if [ -f "$loc" ]; then
        log "INFO" "Found binary at $loc, removing..."
        if rm -f "$loc" 2>/dev/null || sudo rm -f "$loc"; then
            ((removed_count++))
            log "SUCCESS" "Removed $loc"
        else
            log "WARNING" "Failed to remove $loc"
        fi
    fi
done

# 6. Remove desktop files and icons (from legacy source build)
if [ -f "/usr/local/share/applications/ghostty.desktop" ]; then
    log "INFO" "Removing desktop file..."
    sudo rm -f "/usr/local/share/applications/ghostty.desktop"
    log "SUCCESS" "Desktop file removed"
fi

# Remove icons from all hicolor sizes
if ls /usr/local/share/icons/hicolor/*/apps/ghostty.png 2>/dev/null; then
    log "INFO" "Removing icons..."
    sudo rm -f /usr/local/share/icons/hicolor/*/apps/ghostty.png
    sudo rm -f /usr/local/share/icons/hicolor/*/apps/ghostty.svg
    log "SUCCESS" "Icons removed"
fi

# Update icon cache and desktop database
if [ -d "/usr/local/share/icons/hicolor" ]; then
    log "INFO" "Updating icon cache..."
    sudo gtk-update-icon-cache -f /usr/local/share/icons/hicolor 2>/dev/null || true
fi

if [ -d "/usr/local/share/applications" ]; then
    log "INFO" "Updating desktop database..."
    sudo update-desktop-database /usr/local/share/applications 2>/dev/null || true
fi

# 7. Check for any other ghostty binaries in PATH
if command -v ghostty &>/dev/null; then
    remaining=$(which ghostty)
    log "WARNING" "ghostty still found at: $remaining"
    log "WARNING" "This may be a system package or another installation method"
    log "WARNING" "Manual cleanup may be required"
fi

# 8. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v ghostty &>/dev/null; then
        log "INFO" "ghostty is not installed, nothing to do"
    else
        log "ERROR" "Could not remove ghostty - still found in PATH"
        exit 1
    fi
else
    if ! command -v ghostty &>/dev/null; then
        log "SUCCESS" "All ghostty installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which ghostty)
        log "WARNING" "Removed $removed_count installations, but ghostty still found at: $remaining"
    fi
fi
