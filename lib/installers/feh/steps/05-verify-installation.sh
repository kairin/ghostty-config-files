#!/usr/bin/env bash
#
# Module: Feh - Verify Installation
# Purpose: Verify feh installation and check configurations
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="verify-feh-installation"
    register_task "$task_id" "Verifying feh installation"
    start_task "$task_id"

    log "INFO" "Verifying feh installation..."

    local all_checks_passed=0

    # Check 1: Binary installation
    log "INFO" "Check 1: Binary Installation"
    if command -v feh >/dev/null 2>&1; then
        local installed_version
        installed_version=$(get_feh_version)
        log "SUCCESS" "feh binary found"
        log "SUCCESS" "Version: $installed_version"
        log "SUCCESS" "Location: $(command -v feh)"
    else
        log "ERROR" "feh binary not found in PATH"
        all_checks_passed=1
    fi

    # Check 2: Configuration preservation
    log "INFO" "Check 2: Configuration Preservation"
    if [ -f "$HOME/.local/share/applications/feh.desktop" ]; then
        log "SUCCESS" "Desktop file preserved: $HOME/.local/share/applications/feh.desktop"
    else
        log "WARNING" "Desktop file not found (will need to be recreated)"
    fi

    # Note: feh doesn't use ~/.config/feh/themes by default, this is custom user config
    if [ -d "$HOME/.config/feh" ]; then
        log "SUCCESS" "Custom feh config directory preserved: $HOME/.config/feh/"
        if [ -f "$HOME/.config/feh/themes" ]; then
            log "SUCCESS" "Themes file preserved: $HOME/.config/feh/themes"
        fi
    fi

    # Check 3: Compile-time features
    log "INFO" "Check 3: Compile-time Features"
    if feh --version 2>&1 | grep -q "Compile-time switches:"; then
        log "SUCCESS" "Compile-time switches:"
        feh --version 2>&1 | grep "Compile-time switches:" | sed 's/^/    /' | while read -r line; do
            log "INFO" "$line"
        done

        # Verify key features enabled
        if feh --version 2>&1 | grep -q "curl"; then
            log "SUCCESS" "curl support enabled (HTTPS image loading)"
        fi
        if feh --version 2>&1 | grep -q "exif"; then
            log "SUCCESS" "EXIF support enabled"
        fi
        if feh --version 2>&1 | grep -q "xinerama"; then
            log "SUCCESS" "Xinerama support enabled (multimonitor)"
        fi
    fi

    # Check 4: Basic functionality test
    log "INFO" "Check 4: Basic Functionality"
    if timeout 2s feh --version >/dev/null 2>&1; then
        log "SUCCESS" "Feh launches successfully"
    else
        log "ERROR" "Feh failed to launch"
        all_checks_passed=1
    fi

    # Check 5: Icon installation and desktop integration
    log "INFO" "Check 5: Icon Installation & Desktop Integration"

    # Create smart launcher script that searches for images in default directories
    log "INFO" "Creating smart launcher script..."
    sudo tee /usr/local/bin/feh-launcher > /dev/null << 'LAUNCHER_EOF'
#!/usr/bin/env bash
#
# Feh Smart Launcher
# Purpose: Launch feh with intelligent default directory selection
# Priority: Pictures > Pictures/Screenshots > Downloads > Home
#

# If argument provided (e.g., file association), use it directly
if [ -n "$1" ]; then
    exec feh "$@"
fi

# Search directories in priority order
SEARCH_DIRS=(
    "$HOME/Pictures"
    "$HOME/Pictures/Screenshots"
    "$HOME/Downloads"
    "$HOME"
)

# Find first directory with images
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Count images (case-insensitive, common formats)
        image_count=$(find "$dir" -maxdepth 3 -type f \( \
            -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
            -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.bmp" \
            -o -iname "*.tiff" -o -iname "*.svg" -o -iname "*.heic" \
        \) 2>/dev/null | wc -l)

        if [ "$image_count" -gt 0 ]; then
            # Launch feh with recursive mode, thumbnails, and auto-zoom
            exec feh --recursive --thumbnails --auto-zoom --sort filename "$dir"
        fi
    fi
done

# No images found - show user-friendly notification
if command -v notify-send >/dev/null 2>&1; then
    notify-send -i feh "Feh Image Viewer" \
        "No images found in Pictures, Downloads, or Home directory.\n\nTip: Add images to ~/Pictures and try again!"
elif command -v zenity >/dev/null 2>&1; then
    zenity --info --icon-name=feh --title="Feh Image Viewer" \
        --text="No images found in Pictures, Downloads, or Home directory.\n\nTip: Add images to ~/Pictures and try again!"
else
    # Fallback: terminal message
    echo "Feh: No images found in default directories (Pictures, Downloads, Home)"
    echo "Tip: Add images to ~/Pictures and launch feh again"
fi

exit 1
LAUNCHER_EOF

    sudo chmod +x /usr/local/bin/feh-launcher
    log "SUCCESS" "Smart launcher created: /usr/local/bin/feh-launcher"

    # Update desktop file to use smart launcher and make it visible
    local desktop_file="$HOME/.local/share/applications/feh.desktop"
    
    # Ensure directory exists
    mkdir -p "$(dirname "$desktop_file")"

    # Check for system desktop file (APT or Source)
    if [ -f "/usr/share/applications/feh.desktop" ]; then
        log "INFO" "Found system desktop file at /usr/share/applications/feh.desktop"
        cp "/usr/share/applications/feh.desktop" "$desktop_file"
    elif [ -f "/usr/local/share/applications/feh.desktop" ]; then
        log "INFO" "Found system desktop file at /usr/local/share/applications/feh.desktop"
        cp "/usr/local/share/applications/feh.desktop" "$desktop_file"
    else
        log "WARNING" "No system desktop file found. Creating new one..."
        cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Name=Feh
GenericName=Image Viewer
Comment=Image viewer and cataloguer
Exec=feh %F
Icon=feh
Terminal=false
Type=Application
Categories=Graphics;2DGraphics;Viewer;
MimeType=image/bmp;image/gif;image/jpeg;image/jpg;image/pjpeg;image/png;image/tiff;image/webp;image/x-bmp;image/x-pcx;image/x-png;image/x-portable-anymap;image/x-portable-bitmap;image/x-portable-graymap;image/x-portable-pixmap;image/x-tga;image/x-xbitmap;
EOF
    fi

    # Configure the local desktop file
    if [ -f "$desktop_file" ]; then
        log "INFO" "Configuring local desktop entry for smart launcher..."

        # Replace Exec line with smart launcher
        sed -i 's|^Exec=.*|Exec=/usr/local/bin/feh-launcher %F|' "$desktop_file"

        # Enable menu visibility
        sed -i 's/NoDisplay=true/NoDisplay=false/' "$desktop_file"

        # Fix icon to use feh-specific icon instead of generic image-viewer
        sed -i 's/^Icon=image-viewer$/Icon=feh/' "$desktop_file"

        # Update comment to reflect smart behavior
        sed -i 's/^Comment=.*/Comment=Smart image viewer - automatically finds images in Pictures, Downloads/' "$desktop_file"

        log "SUCCESS" "Desktop entry configured: $desktop_file"

        # Update desktop database
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
        fi
    fi

    # Update icon cache if gtk-update-icon-cache is available
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if [ -d "/usr/local/share/icons/hicolor" ]; then
            log "INFO" "Updating icon cache..."
            # Create index.theme if it doesn't exist (prevents "No theme index file" error)
            if [ ! -f "/usr/local/share/icons/hicolor/index.theme" ]; then
                log "INFO" "Creating icon theme index..."
                sudo tee /usr/local/share/icons/hicolor/index.theme > /dev/null << 'EOF'
[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme
Hidden=true
Directories=48x48/apps,scalable/apps

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[scalable/apps]
Size=48
Context=Applications
Type=Scalable
EOF
                log "SUCCESS" "Icon theme index created"
            fi

            sudo gtk-update-icon-cache /usr/local/share/icons/hicolor/ 2>/dev/null || true
            log "SUCCESS" "Icon cache updated"
        fi
    fi

    # Verify icon files exist
    local icon_found=0
    # Check APT locations
    if [ -f "/usr/share/icons/hicolor/48x48/apps/feh.png" ]; then
        log "SUCCESS" "PNG icon found (APT): /usr/share/icons/hicolor/48x48/apps/feh.png"
        icon_found=1
    fi
    if [ -f "/usr/share/icons/hicolor/scalable/apps/feh.svg" ]; then
        log "SUCCESS" "SVG icon found (APT): /usr/share/icons/hicolor/scalable/apps/feh.svg"
        icon_found=1
    fi
    
    # Check Source locations (fallback)
    if [ -f "/usr/local/share/icons/hicolor/48x48/apps/feh.png" ]; then
        log "SUCCESS" "PNG icon found (Source): /usr/local/share/icons/hicolor/48x48/apps/feh.png"
        icon_found=1
    fi
    if [ -f "/usr/local/share/icons/hicolor/scalable/apps/feh.svg" ]; then
        log "SUCCESS" "SVG icon found (Source): /usr/local/share/icons/hicolor/scalable/apps/feh.svg"
        icon_found=1
    fi
    
    if [ $icon_found -eq 0 ]; then
        log "WARNING" "No feh icons found (non-critical)"
    fi

    if [ $all_checks_passed -eq 0 ]; then
        log "SUCCESS" "All verification checks passed"
        log "SUCCESS" "Feh should now appear in your application menu"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Some verification checks failed"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
