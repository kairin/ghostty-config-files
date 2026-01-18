#!/bin/bash
# Rebuild GTK icon cache

echo "Rebuilding icon caches..."

# System icons (requires sudo)
if [ -d "/usr/share/icons/hicolor" ]; then
    echo "  Rebuilding /usr/share/icons/hicolor..."
    sudo gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fi

# Local system icons
if [ -d "/usr/local/share/icons/hicolor" ]; then
    echo "  Rebuilding /usr/local/share/icons/hicolor..."
    sudo gtk-update-icon-cache -f /usr/local/share/icons/hicolor 2>/dev/null || true
fi

# User icons (no sudo needed)
if [ -d "$HOME/.local/share/icons/hicolor" ]; then
    echo "  Rebuilding $HOME/.local/share/icons/hicolor..."
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# Additional icon themes
for theme_dir in /usr/share/icons/*/; do
    if [ -f "${theme_dir}index.theme" ] && [ ! -L "$theme_dir" ]; then
        theme_name=$(basename "$theme_dir")
        if [ "$theme_name" != "hicolor" ]; then
            echo "  Rebuilding $theme_name..."
            sudo gtk-update-icon-cache -f "$theme_dir" 2>/dev/null || true
        fi
    fi
done

echo "Icon cache rebuild complete"
