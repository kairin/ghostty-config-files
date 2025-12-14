#!/bin/bash
# install_antigravity.sh - Install Google Antigravity Desktop App
# Google's agentic development platform for AI-assisted coding
# Download from: https://antigravity.google

source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing Google Antigravity..."

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        DL_ARCH="amd64"
        ;;
    aarch64|arm64)
        DL_ARCH="arm64"
        ;;
    *)
        log "ERROR" "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log "INFO" "Detected architecture: $ARCH ($DL_ARCH)"

# Installation directory
INSTALL_DIR="$HOME/.local/share/antigravity"
BIN_DIR="$HOME/.local/bin"

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Download URL - Google Antigravity uses direct download
# Note: URL may change; check https://antigravity.google for latest
DL_URL="https://antigravity.google/download/linux-${DL_ARCH}.deb"
TEMP_FILE="/tmp/antigravity-linux-${DL_ARCH}.deb"

log "INFO" "Downloading Antigravity for $ARCH..."
if curl -fsSL -o "$TEMP_FILE" "$DL_URL" 2>/dev/null; then
    log "SUCCESS" "Downloaded Antigravity installer"

    # Install .deb package
    log "INFO" "Installing Antigravity package..."
    if sudo dpkg -i "$TEMP_FILE"; then
        log "SUCCESS" "Antigravity installed via dpkg"
    else
        # Try to fix dependencies
        log "INFO" "Fixing dependencies..."
        sudo apt-get install -f -y
        if sudo dpkg -i "$TEMP_FILE"; then
            log "SUCCESS" "Antigravity installed after dependency fix"
        else
            log "ERROR" "Failed to install Antigravity package"
            rm -f "$TEMP_FILE"
            exit 1
        fi
    fi

    rm -f "$TEMP_FILE"
else
    # Fallback: Try AppImage download
    log "INFO" "Trying AppImage download..."
    DL_URL="https://antigravity.google/download/Antigravity-linux-${DL_ARCH}.AppImage"
    APPIMAGE_FILE="$INSTALL_DIR/Antigravity.AppImage"

    if curl -fsSL -o "$APPIMAGE_FILE" "$DL_URL" 2>/dev/null; then
        chmod +x "$APPIMAGE_FILE"
        log "SUCCESS" "Downloaded Antigravity AppImage"

        # Create symlink in bin directory
        ln -sf "$APPIMAGE_FILE" "$BIN_DIR/antigravity"
        log "SUCCESS" "Created symlink at $BIN_DIR/antigravity"

        # Create desktop entry
        DESKTOP_FILE="$HOME/.local/share/applications/antigravity.desktop"
        mkdir -p "$(dirname "$DESKTOP_FILE")"
        cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Google Antigravity
Comment=AI-powered agentic development platform
Exec=$APPIMAGE_FILE
Icon=antigravity
Type=Application
Categories=Development;IDE;
Terminal=false
StartupWMClass=Antigravity
EOF
        log "SUCCESS" "Created desktop entry"

        # Update desktop database
        if command -v update-desktop-database &> /dev/null; then
            update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        fi
    else
        log "ERROR" "Failed to download Antigravity"
        log "INFO" "Please visit https://antigravity.google to download manually"
        exit 1
    fi
fi

# Verify installation
if command -v antigravity &> /dev/null; then
    log "SUCCESS" "Antigravity installation complete"
    echo ""
    echo "To launch Antigravity:"
    echo "  - Run 'antigravity' from terminal"
    echo "  - Or find 'Google Antigravity' in your application menu"
elif [ -f "$INSTALL_DIR/Antigravity.AppImage" ]; then
    log "SUCCESS" "Antigravity AppImage installed"
    echo ""
    echo "To launch Antigravity:"
    echo "  - Run '$INSTALL_DIR/Antigravity.AppImage'"
    echo "  - Or add $BIN_DIR to your PATH and run 'antigravity'"
else
    log "WARNING" "Installation may not be complete"
    log "INFO" "Check https://antigravity.google for installation instructions"
fi
