#!/bin/bash
# Dynamic Ghostty theme switcher based on system theme
# Monitors GNOME desktop settings and automatically switches Ghostty themes
# Supports Catppuccin Mocha (dark) and Latte (light) themes

set -euo pipefail

# Configuration paths
GHOSTTY_CONFIG_DIR="${HOME}/.config/ghostty"
THEME_CONF="${GHOSTTY_CONFIG_DIR}/theme.conf"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DARK="${REPO_ROOT}/configs/ghostty/catppuccin-mocha.conf"
THEME_LIGHT="${REPO_ROOT}/configs/ghostty/catppuccin-latte.conf"

# Color output helpers
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Get current system theme from GNOME settings
get_system_theme() {
    local scheme
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'prefer-dark'")

    if echo "$scheme" | grep -q "dark"; then
        echo "dark"
    else
        echo "light"
    fi
}

# Apply theme by copying config file and signaling Ghostty
apply_theme() {
    local theme="$1"
    local source_file
    local emoji

    if [ "$theme" = "dark" ]; then
        source_file="$THEME_DARK"
        emoji="🌙"
        echo -e "${GREEN}${emoji} Switching to dark theme (Catppuccin Mocha)${NC}"
    else
        source_file="$THEME_LIGHT"
        emoji="☀️"
        echo -e "${GREEN}${emoji} Switching to light theme (Catppuccin Latte)${NC}"
    fi

    # Verify source file exists
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}✗ Error: Theme file not found: $source_file${NC}"
        return 1
    fi

    # Ensure Ghostty config directory exists
    if [ ! -d "$GHOSTTY_CONFIG_DIR" ]; then
        echo -e "${YELLOW}⚠ Creating Ghostty config directory: $GHOSTTY_CONFIG_DIR${NC}"
        mkdir -p "$GHOSTTY_CONFIG_DIR"
    fi

    # Copy theme file
    cp "$source_file" "$THEME_CONF"
    echo -e "${GREEN}✓ Theme applied to $THEME_CONF${NC}"

    # Signal Ghostty to reload configuration
    if pgrep -x ghostty >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Signaling Ghostty to reload configuration (SIGUSR2)${NC}"
        pkill -SIGUSR2 ghostty 2>/dev/null || true
        sleep 0.5  # Brief delay for signal processing
    else
        echo -e "${YELLOW}⚠ Ghostty not running - theme will apply on next launch${NC}"
    fi
}

# Monitor system theme changes continuously
monitor_theme_changes() {
    echo -e "${GREEN}👁️  Starting Ghostty theme monitor...${NC}"
    echo "This monitor will automatically switch Ghostty's theme when system theme changes"
    echo "Press Ctrl+C to stop monitoring"
    echo ""

    # Apply current theme on start
    local current_theme
    current_theme=$(get_system_theme)
    apply_theme "$current_theme"
    echo ""

    # Monitor for changes
    gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
        local new_theme
        new_theme=$(get_system_theme)

        if [ "$new_theme" != "$current_theme" ]; then
            echo ""
            apply_theme "$new_theme"
            current_theme="$new_theme"
            echo ""
        fi
    done
}

# Display current status
show_status() {
    echo "Ghostty Theme Switcher Status:"
    echo "=============================="
    echo ""
    echo "Current system theme: $(get_system_theme)"
    echo ""

    if systemctl --user is-active ghostty-theme-switcher.service >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Theme switcher service: ACTIVE${NC}"
        systemctl --user status ghostty-theme-switcher.service --no-pager | grep -E "Active:|enabled"
    else
        echo -e "${YELLOW}⚠ Theme switcher service: INACTIVE${NC}"
        echo "To enable: systemctl --user enable --now ghostty-theme-switcher.service"
    fi

    echo ""
    echo "Available themes:"
    [ -f "$THEME_DARK" ] && echo -e "  ${GREEN}✓${NC} Dark theme (Catppuccin Mocha): $THEME_DARK" || echo -e "  ${RED}✗${NC} Dark theme: MISSING"
    [ -f "$THEME_LIGHT" ] && echo -e "  ${GREEN}✓${NC} Light theme (Catppuccin Latte): $THEME_LIGHT" || echo -e "  ${RED}✗${NC} Light theme: MISSING"

    echo ""
    echo "Current Ghostty theme.conf:"
    if [ -f "$THEME_CONF" ]; then
        echo -e "  ${GREEN}✓${NC} $THEME_CONF exists"
        grep "^background = " "$THEME_CONF" || echo "    (theme file exists but is empty or doesn't have background setting)"
    else
        echo -e "  ${YELLOW}⚠${NC} $THEME_CONF not configured yet"
    fi
}

# Display help
show_help() {
    cat << 'EOF'
Ghostty Dynamic Theme Switcher

Usage: ghostty-theme-switcher.sh [COMMAND]

Commands:
  monitor    - Continuously monitor and auto-switch themes (default)
  apply      - Apply theme matching current system settings (one-time)
  dark       - Switch to dark theme immediately
  light      - Switch to light theme immediately
  status     - Show current theme and service status
  help       - Display this help message

Examples:
  # Start continuous monitoring
  ghostty-theme-switcher.sh monitor

  # Apply current system theme once
  ghostty-theme-switcher.sh apply

  # Switch to light theme immediately
  ghostty-theme-switcher.sh light

  # Check status
  ghostty-theme-switcher.sh status

Environment Variables:
  GHOSTTY_CONFIG_DIR  - Override default Ghostty config directory ($HOME/.config/ghostty)
  THEME_DARK         - Override dark theme file path
  THEME_LIGHT        - Override light theme file path

Theme Files:
  Dark:  $THEME_DARK
  Light: $THEME_LIGHT

Service Integration:
  To run as a user service:
    systemctl --user enable --now ghostty-theme-switcher.service

  To stop the service:
    systemctl --user stop ghostty-theme-switcher.service

  To view logs:
    journalctl --user -u ghostty-theme-switcher.service -f

EOF
}

# Main command dispatch
main() {
    local command="${1:-monitor}"

    case "$command" in
        monitor)
            monitor_theme_changes
            ;;
        apply)
            apply_theme "$(get_system_theme)"
            ;;
        dark)
            apply_theme "dark"
            ;;
        light)
            apply_theme "light"
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}✗ Unknown command: $command${NC}"
            echo "Use 'ghostty-theme-switcher.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
