#!/usr/bin/env bash
#
# Module: Ghostty - Create Desktop Entry
# Purpose: Create desktop entry for Ghostty
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

#
# Install Ghostty icon from source repository
#
# Searches for icon in common locations within the Ghostty build directory
# and installs to XDG-compliant icon directory
#
install_ghostty_icon() {
    local icon_dir="${HOME}/.local/share/icons/hicolor"
    local icon_installed=false

    # Common icon locations in Ghostty repository
    local icon_search_paths=(
        "assets/icon.svg"
        "assets/ghostty.svg"
        "assets/icons/icon.svg"
        "src/assets/icon.svg"
        "resources/icon.svg"
        "resources/ghostty.svg"
    )

    # Search for icon in build directory
    for icon_path in "${icon_search_paths[@]}"; do
        local full_path="$GHOSTTY_BUILD_DIR/$icon_path"
        if [ -f "$full_path" ]; then
            # Determine appropriate size directory (SVG goes in scalable)
            local target_dir="$icon_dir/scalable/apps"
            mkdir -p "$target_dir"

            cp "$full_path" "$target_dir/ghostty.svg"
            log "SUCCESS" "Icon installed from $icon_path"

            # Update icon cache if gtk-update-icon-cache is available
            if command -v gtk-update-icon-cache &>/dev/null; then
                gtk-update-icon-cache "$icon_dir" 2>/dev/null || true
            fi

            icon_installed=true
            return 0
        fi
    done

    # If no SVG found, check for PNG icons
    for size in 16 22 24 32 48 64 128 256; do
        for icon_path in "assets/icon_${size}.png" "assets/icons/${size}x${size}/ghostty.png"; do
            local full_path="$GHOSTTY_BUILD_DIR/$icon_path"
            if [ -f "$full_path" ]; then
                local target_dir="$icon_dir/${size}x${size}/apps"
                mkdir -p "$target_dir"

                cp "$full_path" "$target_dir/ghostty.png"
                log "SUCCESS" "Icon installed from $icon_path"
                icon_installed=true
            fi
        done
    done

    if [ "$icon_installed" = true ]; then
        # Update icon cache
        if command -v gtk-update-icon-cache &>/dev/null; then
            gtk-update-icon-cache "$icon_dir" 2>/dev/null || true
        fi
        return 0
    else
        log "WARNING" "Ghostty icon not found in build directory, using fallback"
        return 1
    fi
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
        icon_name="ghostty"
        log "INFO" "Using Ghostty-specific icon"
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

    complete_task "$task_id"
    exit 0
}

main "$@"
