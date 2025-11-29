#!/usr/bin/env bash
#
# Module: Ghostty - Configure Settings
# Purpose: Apply Ghostty configuration from repository and desktop integration
#
set -eo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Desktop Integration
# Symlinks icons and creates desktop entry with proper icon
setup_desktop_integration() {
    log "INFO" "Setting up desktop integration..."

    local ghostty_share="$HOME/.local/share/ghostty/share"
    local user_icons="$HOME/.local/share/icons/hicolor"
    local user_apps="$HOME/.local/share/applications"
    local ghostty_bin="$HOME/.local/share/ghostty/bin/ghostty"

    # Symlink icons to user icon directory
    if [ -d "$ghostty_share/icons/hicolor" ]; then
        mkdir -p "$user_icons"
        local icon_count=0
        for size_dir in "$ghostty_share/icons/hicolor"/*; do
            if [ -d "$size_dir" ]; then
                local size
                size=$(basename "$size_dir")
                local src_icon="$size_dir/apps/com.mitchellh.ghostty.png"
                local dst_dir="$user_icons/$size/apps"

                if [ -f "$src_icon" ]; then
                    mkdir -p "$dst_dir"
                    ln -sf "$src_icon" "$dst_dir/com.mitchellh.ghostty.png"
                    : $((icon_count++))
                fi
            fi
        done
        if [ $icon_count -gt 0 ]; then
            log "SUCCESS" "Symlinked $icon_count icon sizes"
        fi
    else
        log "WARNING" "Ghostty icons directory not found: $ghostty_share/icons/hicolor"
    fi

    # Create proper desktop entry with Ghostty icon
    mkdir -p "$user_apps"
    cat > "$user_apps/ghostty.desktop" <<EOF
[Desktop Entry]
Name=Ghostty
Comment=Fast, native, feature-rich terminal emulator
Exec=$ghostty_bin
Icon=com.mitchellh.ghostty
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

    log "SUCCESS" "Desktop entry created with proper icon"

    # Update icon cache if gtk-update-icon-cache is available
    if command -v gtk-update-icon-cache &>/dev/null; then
        if gtk-update-icon-cache -f -t "$user_icons" 2>/dev/null; then
            log "SUCCESS" "Icon cache updated"
        fi
    fi
}

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-configure"
    register_task "$task_id" "Configuring Ghostty"
    start_task "$task_id"

    # Create config directory if it doesn't exist
    if [ ! -d "$GHOSTTY_CONFIG_DIR" ]; then
        log "INFO" "Creating Ghostty config directory: $GHOSTTY_CONFIG_DIR"
        mkdir -p "$GHOSTTY_CONFIG_DIR"
    fi

    # Copy configuration files from repository
    local repo_config_dir="${REPO_ROOT}/configs/ghostty"

    if [ ! -d "$repo_config_dir" ]; then
        log "ERROR" "Repository config directory not found: $repo_config_dir"
        fail_task "$task_id" "config directory missing"
        exit 1
    fi

    log "INFO" "Applying Ghostty configuration from repository..."

    # Copy all config files
    local copied=0
    for config_file in "$repo_config_dir"/*.conf; do
        if [ -f "$config_file" ]; then
            local filename
            filename=$(basename "$config_file")

            log "INFO" "Copying $filename..."
            if cp "$config_file" "$GHOSTTY_CONFIG_DIR/$filename" 2>/dev/null; then
                log "SUCCESS" "Applied $filename"
                : $((copied++))  # Prefix with : to avoid exit 1 when value is 0 (set -e compatibility)
            else
                log "WARNING" "Could not copy $filename"
            fi
        fi
    done

    if [ $copied -gt 0 ]; then
        log "SUCCESS" "Applied $copied configuration files"
    else
        log "WARNING" "No configuration files were copied"
    fi

    # Setup desktop integration (icons and .desktop file)
    setup_desktop_integration

    complete_task "$task_id"
    exit 0
}

main "$@"
