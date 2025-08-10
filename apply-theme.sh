#!/bin/bash
# Ghostty Theme Application Script
# Usage: ./apply-theme.sh [theme-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"
THEME_CONF="$CONFIG_DIR/theme.conf"

# Available themes (you can list themes using: ghostty +list-themes)
POPULAR_THEMES=(
    "catppuccin-mocha"
    "catppuccin-frappe" 
    "catppuccin-latte"
    "catppuccin-macchiato"
    "Dracula"
    "nord"
    "tokyo-night"
    "gruvbox-dark"
    "gruvbox-light"
    "solarized-dark"
    "solarized-light"
    "one-dark"
    "github-dark"
    "github-light"
)

show_usage() {
    echo "Usage: $0 [theme-name]"
    echo ""
    echo "Available popular themes:"
    printf "  %s\n" "${POPULAR_THEMES[@]}"
    echo ""
    echo "Examples:"
    echo "  $0 catppuccin-mocha"
    echo "  $0 nord"
    echo ""
    echo "To see all available themes, run: ghostty +list-themes"
}

apply_theme() {
    local theme_name="$1"
    
    echo "Applying theme: $theme_name"
    
    # Check if theme.conf exists
    if [[ ! -f "$THEME_CONF" ]]; then
        echo "Error: theme.conf not found at $THEME_CONF"
        exit 1
    fi
    
    # Update theme in theme.conf
    if grep -q "^theme = " "$THEME_CONF"; then
        # Theme line exists, replace it
        sed -i "s/^theme = .*/theme = \"$theme_name\"/" "$THEME_CONF"
        echo "Theme updated to: $theme_name"
    else
        # Theme line doesn't exist, add it after the comment
        sed -i "/# Current active theme/a\\theme = \"$theme_name\"" "$THEME_CONF"
        echo "Theme added: $theme_name"
    fi
    
    echo "Theme applied successfully!"
    echo "Restart Ghostty or reload config to see changes."
}

# Main script logic
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

apply_theme "$1"