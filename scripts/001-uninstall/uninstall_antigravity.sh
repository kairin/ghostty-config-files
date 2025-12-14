#!/bin/bash
# uninstall_antigravity.sh - Uninstall Google Antigravity Desktop App

source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Removing Google Antigravity..."

removed_count=0

# 1. Remove dpkg/apt package if installed
if dpkg -l antigravity 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found apt package, removing..."
    if sudo apt-get remove -y antigravity; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# Also try google-antigravity package name
if dpkg -l google-antigravity 2>/dev/null | grep -q '^ii'; then
    log "INFO" "Found google-antigravity apt package, removing..."
    if sudo apt-get remove -y google-antigravity; then
        ((removed_count++))
        log "SUCCESS" "APT package removed"
    else
        log "WARNING" "Failed to remove apt package"
    fi
fi

# 1b. Remove APT repository and GPG key (added by install script)
SOURCES_LIST="/etc/apt/sources.list.d/antigravity.list"
KEYRING_FILE="/etc/apt/keyrings/antigravity-repo-key.gpg"
if [ -f "$SOURCES_LIST" ]; then
    log "INFO" "Found APT repository, removing..."
    if sudo rm -f "$SOURCES_LIST"; then
        ((removed_count++))
        log "SUCCESS" "APT repository removed"
    else
        log "WARNING" "Failed to remove APT repository"
    fi
fi
if [ -f "$KEYRING_FILE" ]; then
    log "INFO" "Found GPG keyring, removing..."
    if sudo rm -f "$KEYRING_FILE"; then
        ((removed_count++))
        log "SUCCESS" "GPG keyring removed"
    else
        log "WARNING" "Failed to remove GPG keyring"
    fi
fi

# 2. Remove AppImage installation
INSTALL_DIR="$HOME/.local/share/antigravity"
if [ -d "$INSTALL_DIR" ]; then
    log "INFO" "Found AppImage installation at $INSTALL_DIR, removing..."
    if rm -rf "$INSTALL_DIR"; then
        ((removed_count++))
        log "SUCCESS" "AppImage installation removed"
    else
        log "WARNING" "Failed to remove AppImage installation"
    fi
fi

# 3. Remove symlink from bin directory
BIN_LINK="$HOME/.local/bin/antigravity"
if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    log "INFO" "Found binary link at $BIN_LINK, removing..."
    if rm -f "$BIN_LINK"; then
        ((removed_count++))
        log "SUCCESS" "Binary link removed"
    else
        log "WARNING" "Failed to remove binary link"
    fi
fi

# 4. Remove desktop entry
DESKTOP_FILE="$HOME/.local/share/applications/antigravity.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    log "INFO" "Found desktop entry, removing..."
    if rm -f "$DESKTOP_FILE"; then
        ((removed_count++))
        log "SUCCESS" "Desktop entry removed"
    else
        log "WARNING" "Failed to remove desktop entry"
    fi
fi

# 5. Remove from /usr/local/bin if exists
if [ -f "/usr/local/bin/antigravity" ]; then
    log "INFO" "Found binary at /usr/local/bin/antigravity, removing..."
    if sudo rm -f "/usr/local/bin/antigravity"; then
        ((removed_count++))
        log "SUCCESS" "Binary removed from /usr/local/bin"
    else
        log "WARNING" "Failed to remove binary"
    fi
fi

# 6. Remove Snap if installed
if command -v snap &> /dev/null && snap list antigravity 2>/dev/null | grep -q antigravity; then
    log "INFO" "Found snap package, removing..."
    if sudo snap remove antigravity; then
        ((removed_count++))
        log "SUCCESS" "Snap package removed"
    else
        log "WARNING" "Failed to remove snap package"
    fi
fi

# 7. Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

# 8. Report results
if [ $removed_count -eq 0 ]; then
    if ! command -v antigravity &>/dev/null; then
        log "INFO" "Antigravity is not installed, nothing to do"
    else
        remaining=$(which antigravity 2>/dev/null || echo "unknown location")
        log "ERROR" "Could not remove Antigravity - still found at: $remaining"
        exit 1
    fi
else
    if ! command -v antigravity &>/dev/null; then
        log "SUCCESS" "All Antigravity installations removed ($removed_count methods cleaned)"
    else
        remaining=$(which antigravity 2>/dev/null || echo "unknown location")
        log "WARNING" "Removed $removed_count installations, but antigravity still found at: $remaining"
    fi
fi

# Optional: Remove config data (ask user first or leave it)
CONFIG_DIR="$HOME/.config/antigravity"
if [ -d "$CONFIG_DIR" ]; then
    log "INFO" "Note: Configuration data at $CONFIG_DIR was preserved"
    log "INFO" "Remove manually if desired: rm -rf $CONFIG_DIR"
fi
