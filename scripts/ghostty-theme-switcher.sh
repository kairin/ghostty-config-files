#!/bin/bash
# Dynamic Ghostty theme switcher based on system theme
# Constitutional compliance: Auto-switching themes (dark/light)
# Uses SIGUSR2 signal for Ghostty config reload

GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
THEME_CONF="${GHOSTTY_CONFIG_DIR}/theme.conf"
THEME_DARK="/home/kkk/Apps/ghostty-config-files/configs/ghostty/catppuccin-mocha.conf"
THEME_LIGHT="/home/kkk/Apps/ghostty-config-files/configs/ghostty/catppuccin-latte.conf"
LOG_FILE="/tmp/ghostty-theme-switcher.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_system_theme() {
    # GNOME/GTK method (primary)
    local scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    
    if [ -n "$scheme" ]; then
        if echo "$scheme" | grep -q "dark"; then
            echo "dark"
        else
            echo "light"
        fi
    else
        # Fallback: Check GTK theme name
        local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
        if echo "$gtk_theme" | grep -iq "dark"; then
            echo "dark"
        else
            echo "light"
        fi
    fi
}

apply_theme() {
    local theme="$1"
    
    # Ensure config directory exists
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    
    if [ "$theme" = "dark" ]; then
        log "Switching to dark theme (Catppuccin Mocha)"
        if [ -f "$THEME_DARK" ]; then
            cp "$THEME_DARK" "$THEME_CONF"
        else
            log "WARNING: Dark theme file not found: $THEME_DARK"
            return 1
        fi
    else
        log "Switching to light theme (Catppuccin Latte)"
        if [ -f "$THEME_LIGHT" ]; then
            cp "$THEME_LIGHT" "$THEME_CONF"
        else
            log "WARNING: Light theme file not found: $THEME_LIGHT"
            return 1
        fi
    fi
    
    # Signal Ghostty to reload config (SIGUSR2 per Ghostty documentation)
    if pgrep -x ghostty >/dev/null; then
        # Debounce: Wait 500ms to avoid interrupting terminal output
        sleep 0.5
        pkill -SIGUSR2 ghostty 2>/dev/null
        log "Sent SIGUSR2 to Ghostty for config reload (debounced)"
    else
        log "Ghostty not running, theme will apply on next launch"
    fi
}

monitor_theme_changes() {
    log "Starting Ghostty theme monitor..."
    local current_theme=$(get_system_theme)
    log "Initial theme: $current_theme"
    apply_theme "$current_theme"

    # Monitor gsettings for theme changes
    gsettings monitor org.gnome.desktop.interface color-scheme 2>/dev/null | while read -r line; do
        local new_theme=$(get_system_theme)
        if [ "$new_theme" != "$current_theme" ]; then
            log "Theme changed: $current_theme -> $new_theme"
            apply_theme "$new_theme"
            current_theme="$new_theme"
        fi
    done
}

show_status() {
    echo "Ghostty Theme Switcher Status"
    echo "=============================="
    echo "Current system theme: $(get_system_theme)"
    echo "Theme config file: $THEME_CONF"
    echo "Dark theme: $THEME_DARK"
    echo "Light theme: $THEME_LIGHT"
    echo ""
    echo "Ghostty running: $(pgrep -x ghostty >/dev/null && echo 'Yes' || echo 'No')"
    echo "Service status: $(systemctl --user is-active ghostty-theme-switcher.service 2>/dev/null || echo 'Not installed')"
}

usage() {
    echo "Usage: $0 {monitor|apply|dark|light|status}"
    echo ""
    echo "Commands:"
    echo "  monitor  - Start monitoring and auto-switching"
    echo "  apply    - Apply current system theme"
    echo "  dark     - Force dark theme"
    echo "  light    - Force light theme"
    echo "  status   - Show current status"
}

case "${1:-monitor}" in
    "monitor") monitor_theme_changes ;;
    "apply")   apply_theme "$(get_system_theme)" ;;
    "dark")    apply_theme "dark" ;;
    "light")   apply_theme "light" ;;
    "status")  show_status ;;
    "help"|"--help"|"-h") usage ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
