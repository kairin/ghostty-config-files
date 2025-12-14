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

    # Install terminfo (CRITICAL for terminal compatibility - fixes "unknown terminal xterm-ghostty")
    log "INFO" "Installing terminfo..."
    TERMINFO_FILE="zig-out/share/terminfo/ghostty.terminfo"
    TERMINFO_INSTALLED=false

    # Primary method: compile terminfo from build output using tic
    if [ -f "$TERMINFO_FILE" ]; then
        if sudo tic -x "$TERMINFO_FILE" 2>/dev/null; then
            log "SUCCESS" "Terminfo compiled from build output"
            TERMINFO_INSTALLED=true
        else
            # User-level fallback (installs to ~/.terminfo/)
            if tic -x "$TERMINFO_FILE" 2>/dev/null; then
                log "SUCCESS" "Terminfo compiled to user directory"
                TERMINFO_INSTALLED=true
            fi
        fi
    fi

    # Fallback: system ncurses should have ghostty entry (ncurses 6.5+)
    if [ "$TERMINFO_INSTALLED" = false ] && [ -f "/usr/share/terminfo/g/ghostty" ]; then
        log "INFO" "Using system ncurses terminfo entry"
        TERMINFO_INSTALLED=true
    fi

    # Create xterm-ghostty symlink (Ghostty uses TERM=xterm-ghostty by default)
    # This is needed because ncurses has "ghostty" but Ghostty sets TERM=xterm-ghostty
    if [ -f "/usr/share/terminfo/g/ghostty" ] && [ ! -e "/usr/share/terminfo/x/xterm-ghostty" ]; then
        sudo mkdir -p /usr/share/terminfo/x 2>/dev/null
        if sudo ln -sf /usr/share/terminfo/g/ghostty /usr/share/terminfo/x/xterm-ghostty 2>/dev/null; then
            log "SUCCESS" "Created xterm-ghostty symlink (system-wide)"
        else
            # User-level fallback (no sudo required)
            mkdir -p "$HOME/.terminfo/x"
            ln -sf /usr/share/terminfo/g/ghostty "$HOME/.terminfo/x/xterm-ghostty"
            log "SUCCESS" "Created xterm-ghostty symlink (user-level)"
        fi
    fi

    # Also check user-level terminfo for symlink
    if [ -f "$HOME/.terminfo/g/ghostty" ] && [ ! -e "$HOME/.terminfo/x/xterm-ghostty" ]; then
        mkdir -p "$HOME/.terminfo/x"
        ln -sf "$HOME/.terminfo/g/ghostty" "$HOME/.terminfo/x/xterm-ghostty"
        log "SUCCESS" "Created xterm-ghostty symlink (user-level from user terminfo)"
    fi

    if [ "$TERMINFO_INSTALLED" = false ]; then
        log "WARNING" "Terminfo not installed - set TERM=xterm-256color in Ghostty config as workaround"
    fi

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
        # Force rebuild with ignore-theme-index for better compatibility
        sudo gtk-update-icon-cache --force --ignore-theme-index "$ICON_DIR" 2>/dev/null || true

        # Verify cache exists (for local icons dir with few icons, ~300 bytes is normal)
        CACHE_SIZE=$(stat -c%s "$ICON_DIR/icon-theme.cache" 2>/dev/null || echo "0")
        if [ "$CACHE_SIZE" -gt 100 ]; then
            log "SUCCESS" "Icon cache rebuilt (${CACHE_SIZE} bytes)"
        else
            # Try alternative method: remove and rebuild
            log "WARNING" "Icon cache appears empty (${CACHE_SIZE} bytes), retrying..."
            sudo rm -f "$ICON_DIR/icon-theme.cache"
            sudo gtk-update-icon-cache --force "$ICON_DIR" 2>/dev/null || true

            CACHE_SIZE=$(stat -c%s "$ICON_DIR/icon-theme.cache" 2>/dev/null || echo "0")
            if [ "$CACHE_SIZE" -gt 100 ]; then
                log "SUCCESS" "Icon cache rebuilt on retry (${CACHE_SIZE} bytes)"
            else
                log "WARNING" "Icon cache may be empty (${CACHE_SIZE} bytes)"
            fi
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
