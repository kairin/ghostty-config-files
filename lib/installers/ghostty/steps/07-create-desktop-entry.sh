#!/usr/bin/env bash
#
# Module: Ghostty - Create Desktop Entry
# Purpose: Create desktop entry for Ghostty
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

#
# Install Ghostty icon from build output
#
# Ghostty's build system installs icons to GHOSTTY_INSTALL_DIR/share/icons/hicolor.
# This function copies them to the system icon directory ~/.local/share/icons/hicolor
# so they are properly detected by the desktop environment.
#
install_ghostty_icon() {
    local system_icon_dir="${HOME}/.local/share/icons/hicolor"
    local ghostty_icon_dir="$GHOSTTY_INSTALL_DIR/share/icons/hicolor"
    local icon_installed=false

    # Check if Ghostty's build output contains icons
    if [ -d "$ghostty_icon_dir" ]; then
        log "INFO" "Found Ghostty icons in build output"

        # Copy all icon sizes to system icon directory
        for size_dir in "$ghostty_icon_dir"/*; do
            if [ -d "$size_dir" ]; then
                local size_name=$(basename "$size_dir")
                local target_dir="$system_icon_dir/$size_name/apps"

                mkdir -p "$target_dir"

                # Copy all com.mitchellh.ghostty.png files
                if [ -d "$size_dir/apps" ]; then
                    cp -f "$size_dir/apps/com.mitchellh.ghostty.png" "$target_dir/" 2>/dev/null && {
                        log "INFO" "Installed icon: $size_name"
                        icon_installed=true
                    }
                fi
            fi
        done

        if [ "$icon_installed" = true ]; then
            # Update icon cache
            if command -v gtk-update-icon-cache &>/dev/null; then
                gtk-update-icon-cache "$system_icon_dir" 2>/dev/null || true
                log "SUCCESS" "Icon cache updated"
            fi
            return 0
        fi
    fi

    log "WARNING" "Ghostty icons not found in build output, using fallback icon"
    return 1
}

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="create-desktop-entry"
    register_task "$task_id" "Creating desktop entry"
    start_task "$task_id"

    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"

    # Install icon if available
    local icon_name="utilities-terminal"  # Fallback icon
    if install_ghostty_icon; then
        icon_name="com.mitchellh.ghostty"
        log "INFO" "Using Ghostty-specific icon: $icon_name"
    else
        log "INFO" "Using fallback icon: $icon_name"
    fi

    cat > "$desktop_dir/ghostty.desktop" <<EOF
[Desktop Entry]
Name=Ghostty
Comment=Fast, native, feature-rich terminal emulator
Exec=$GHOSTTY_INSTALL_DIR/bin/ghostty
Icon=$icon_name
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

    chmod +x "$desktop_dir/ghostty.desktop"
    log "SUCCESS" "Desktop entry created at $desktop_dir/ghostty.desktop"

    # Fix com.mitchellh.ghostty.desktop file if it exists (Ghostty's build system creates this)
    local official_desktop="$desktop_dir/com.mitchellh.ghostty.desktop"
    if [ -f "$official_desktop" ]; then
        log "INFO" "Fixing Ghostty's official desktop file paths..."
        # Backup original
        cp "$official_desktop" "$official_desktop.bak"

        # Fix hardcoded /tmp paths to use actual install directory
        sed -i "s|Exec=/tmp/ghostty-build/zig-out/bin/ghostty|Exec=$GHOSTTY_INSTALL_DIR/bin/ghostty|g" "$official_desktop"
        sed -i "s|TryExec=/tmp/ghostty-build/zig-out/bin/ghostty|TryExec=$GHOSTTY_INSTALL_DIR/bin/ghostty|g" "$official_desktop"

        log "SUCCESS" "Fixed desktop file: $official_desktop"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
