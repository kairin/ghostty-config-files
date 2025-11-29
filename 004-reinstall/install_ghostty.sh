#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Starting ghostty build and install process..."

BUILD_DIR="/tmp/ghostty-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log "INFO" "Cloning ghostty repository..."
if git clone https://github.com/ghostty-org/ghostty "$BUILD_DIR"; then
    log "SUCCESS" "Cloned successfully"
else
    log "ERROR" "Failed to clone ghostty"
    exit 1
fi

cd "$BUILD_DIR"

log "INFO" "Building ghostty (release mode)..."
if zig build -Doptimize=ReleaseFast; then
    log "SUCCESS" "Build successful"
else
    log "ERROR" "Build failed"
    exit 1
fi

log "INFO" "Installing ghostty..."
# Zig build output is in zig-out/bin
if [ -f "zig-out/bin/ghostty" ]; then
    sudo cp "zig-out/bin/ghostty" "/usr/local/bin/"
    log "SUCCESS" "Installed to /usr/local/bin/ghostty"
    
    # Install desktop resources
    log "INFO" "Installing desktop resources..."
    
    # Generate and install desktop file from template
    TEMPLATE_FILE="dist/linux/app.desktop.in"
    if [ -f "$TEMPLATE_FILE" ]; then
        sudo mkdir -p /usr/local/share/applications
        
        # Create a temporary desktop file with substitutions
        # Replaces placeholders with actual values
        sed -e 's/@NAME@/Ghostty/g' \
            -e 's|@GHOSTTY@|/usr/local/bin/ghostty|g' \
            -e 's/@APPID@/com.mitchellh.ghostty/g' \
            -e 's/Icon=com.mitchellh.ghostty/Icon=ghostty/g' \
            "$TEMPLATE_FILE" > ghostty.desktop
            
        sudo cp ghostty.desktop /usr/local/share/applications/
        log "SUCCESS" "Installed desktop file"
    else
        log "WARNING" "Could not find dist/linux/app.desktop.in"
    fi
    
    # Install icon
    ICON_FILE="images/icons/icon_512.png"
    if [ -f "$ICON_FILE" ]; then
        sudo mkdir -p /usr/local/share/icons/hicolor/512x512/apps
        sudo cp "$ICON_FILE" /usr/local/share/icons/hicolor/512x512/apps/ghostty.png
        log "SUCCESS" "Installed icon"
    else
        log "WARNING" "Could not find images/icons/icon_512.png"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/local/share/applications
        log "SUCCESS" "Updated desktop database"
    fi
else
    log "ERROR" "Binary not found after build"
    exit 1
fi

log "INFO" "Cleaning up..."
rm -rf "$BUILD_DIR"
