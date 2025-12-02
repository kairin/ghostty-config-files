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
    
    # Install icons (all available sizes + proper cache setup)
    ICON_DIR="/usr/local/share/icons/hicolor"

    # CRITICAL: Ensure index.theme exists (required for GTK icon resolution)
    if [ ! -f "$ICON_DIR/index.theme" ]; then
        if [ -f "/usr/share/icons/hicolor/index.theme" ]; then
            sudo mkdir -p "$ICON_DIR"
            sudo cp /usr/share/icons/hicolor/index.theme "$ICON_DIR/"
            log "SUCCESS" "Copied index.theme to $ICON_DIR"
        else
            log "WARNING" "System index.theme not found - icons may not display correctly"
        fi
    fi

    # Install all available icon sizes (not just 512)
    ICONS_INSTALLED=0
    for size in 16 32 128 256 512 1024; do
        ICON_FILE="images/icons/icon_${size}.png"
        if [ -f "$ICON_FILE" ]; then
            sudo mkdir -p "$ICON_DIR/${size}x${size}/apps"
            sudo cp "$ICON_FILE" "$ICON_DIR/${size}x${size}/apps/ghostty.png"
            ICONS_INSTALLED=$((ICONS_INSTALLED + 1))
        fi
    done

    if [ $ICONS_INSTALLED -gt 0 ]; then
        log "SUCCESS" "Installed $ICONS_INSTALLED icon size(s)"
    else
        log "WARNING" "No icon files found in images/icons/"
    fi

    # CRITICAL: Rebuild icon cache (prevents broken system icons)
    if command -v gtk-update-icon-cache &> /dev/null; then
        if sudo gtk-update-icon-cache --force "$ICON_DIR" 2>/dev/null; then
            # Verify cache is valid (should be > 1KB)
            CACHE_SIZE=$(stat -c%s "$ICON_DIR/icon-theme.cache" 2>/dev/null || echo "0")
            if [ "$CACHE_SIZE" -gt 1024 ]; then
                log "SUCCESS" "Icon cache rebuilt (${CACHE_SIZE} bytes)"
            else
                log "WARNING" "Icon cache may be invalid (${CACHE_SIZE} bytes)"
            fi
        else
            log "WARNING" "gtk-update-icon-cache returned non-zero exit code"
        fi
    else
        log "WARNING" "gtk-update-icon-cache not found - icons may not display until next login"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/local/share/applications
        log "SUCCESS" "Updated desktop database"
    fi
    
    # Install Configurations
    CONFIG_SCRIPT="$(dirname "$0")/../002-install-first-time/install_ghostty_config.sh"
    if [ -f "$CONFIG_SCRIPT" ]; then
        log "INFO" "Installing Ghostty configurations..."
        bash "$CONFIG_SCRIPT"
    else
        log "WARNING" "Config script not found: $CONFIG_SCRIPT"
    fi
else
    log "ERROR" "Binary not found after build"
    exit 1
fi

log "INFO" "Cleaning up..."
rm -rf "$BUILD_DIR"
