#!/usr/bin/env bash
#
# Module: Ghostty - Verify Installation
# Purpose: Verify Ghostty is properly installed and functional
#
set -eo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-verify"
    register_task "$task_id" "Verifying Ghostty installation"
    start_task "$task_id"

    # Check if Ghostty is installed
    if ! is_ghostty_installed; then
        log "ERROR" "Ghostty is not installed"
        fail_task "$task_id" "not installed"
        exit 1
    fi

    log "SUCCESS" "Ghostty binary found in PATH"

    # Get version information
    local version
    version=$(get_ghostty_version)
    log "INFO" "Installed version: $version"

    # Verify configuration
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        local config_count
        config_count=$(find "$GHOSTTY_CONFIG_DIR" -name "*.conf" 2>/dev/null | wc -l)
        log "INFO" "Found $config_count configuration files in $GHOSTTY_CONFIG_DIR"
    else
        log "WARNING" "Configuration directory not found: $GHOSTTY_CONFIG_DIR"
    fi

    # Verify desktop integration and icons
    log "INFO" "Verifying desktop integration..."
    local desktop_status=0

    # Check 1: Desktop file exists and is valid
    local desktop_file="$HOME/.local/share/applications/ghostty.desktop"
    local system_desktop="/usr/share/applications/com.mitchellh.ghostty.desktop"

    if [ -f "$desktop_file" ]; then
        log "SUCCESS" "User desktop file found: $desktop_file"

        # Validate syntax
        if command -v desktop-file-validate >/dev/null 2>&1; then
            if desktop-file-validate "$desktop_file" 2>&1 | grep -q "error"; then
                log "WARNING" "Desktop file has validation errors"
                desktop_status=1
            else
                log "SUCCESS" "Desktop file syntax is valid"
            fi
        fi

        # Verify Exec path
        local exec_path
        exec_path=$(grep "^Exec=" "$desktop_file" 2>/dev/null | sed 's/^Exec=//' | awk '{print $1}')
        if [ -x "$exec_path" ] || command -v "$exec_path" >/dev/null 2>&1; then
            log "SUCCESS" "Exec path is valid: $exec_path"
        else
            log "WARNING" "Exec path not executable: $exec_path"
            desktop_status=1
        fi
    elif [ -f "$system_desktop" ]; then
        log "SUCCESS" "System desktop file found: $system_desktop"
    else
        log "WARNING" "No Ghostty desktop file found"
        desktop_status=1
    fi

    # Check 2: Icon is resolvable
    local icon_name="com.mitchellh.ghostty"
    local icon_found=0

    for base in "$HOME/.local/share/icons/hicolor" "/usr/share/icons/hicolor"; do
        for size in "48x48" "128x128" "256x256" "scalable"; do
            local icon_path="$base/$size/apps/${icon_name}.png"
            [ "$size" = "scalable" ] && icon_path="$base/$size/apps/${icon_name}.svg"

            if [ -f "$icon_path" ]; then
                log "SUCCESS" "Icon found: $icon_path"
                icon_found=1
                break 2
            fi
        done
    done

    if [ $icon_found -eq 0 ]; then
        log "WARNING" "Ghostty icon not found in icon themes"
        desktop_status=1
    fi

    # Check 3: Update icon cache if needed
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        local user_icons="$HOME/.local/share/icons/hicolor"
        if [ -d "$user_icons" ]; then
            gtk-update-icon-cache -f -t "$user_icons" 2>/dev/null || true
            log "SUCCESS" "Icon cache updated"
        fi
    fi

    # Check 4: Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    # Check 5: Verify gio registration
    if command -v gio >/dev/null 2>&1 && [ -f "$desktop_file" ]; then
        if gio info "$desktop_file" >/dev/null 2>&1; then
            log "SUCCESS" "Application registered with desktop environment"
        fi
    fi

    if [ $desktop_status -eq 0 ]; then
        log "SUCCESS" "Desktop integration verified"
    else
        log "WARNING" "Desktop integration has issues (app may still work)"
    fi

    log "SUCCESS" "Ghostty installation verified successfully"
    complete_task "$task_id"
    exit 0
}

main "$@"
