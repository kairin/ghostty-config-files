#!/bin/bash

# Ghostty Configuration Manager
# Switch between different configuration presets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration presets
CONFIGS=(
    "default:Use current basic configuration"
    "enhanced:Use enhanced productivity configuration"
    "custom:Use your custom configuration snippet"
)

show_usage() {
    echo "🔧 Ghostty Configuration Manager"
    echo ""
    echo "Usage: $0 [preset]"
    echo ""
    echo "Available presets:"
    for config in "${CONFIGS[@]}"; do
        IFS=':' read -r name desc <<< "$config"
        printf "  %-12s %s\n" "$name" "$desc"
    done
    echo ""
    echo "Without arguments, shows current configuration and available options."
}

show_current_config() {
    echo "📋 Current Configuration:"
    echo ""
    if [[ -f "config" ]]; then
        echo "Using: config"
        head -10 config | sed 's/^/  /'
        if [[ $(wc -l < config) -gt 10 ]]; then
            echo "  ... ($(wc -l < config) total lines)"
        fi
    else
        echo "  No config file found!"
    fi
    echo ""
}

backup_current_config() {
    if [[ -f "config" ]]; then
        local backup_name
        backup_name="config.backup.$(date +%Y%m%d_%H%M%S)"
        cp config "$backup_name"
        echo "📦 Current config backed up as: $backup_name"
    fi
}

apply_enhanced_config() {
    echo "🚀 Applying enhanced productivity configuration..."

    backup_current_config

    # Create the enhanced config
    cat > config << 'EOF'
# Enhanced Ghostty Configuration
# Based on productivity tips and best practices

# Import modular configs
config-file = theme.enhanced.conf
config-file = scroll.enhanced.conf
config-file = layout.enhanced.conf
config-file = keybindings.enhanced.conf
config-file = productivity.conf

# Core Shell Integration
shell-integration = zsh
shell-integration-features = no-cursor,sudo,no-title

# Window Management & State
window-save-state = always
window-new-tab-position = end
window-padding-balance = true
gtk-tabs-location = top

# Performance Optimizations
resize-overlay = never
resize-overlay-position = center
resize-overlay-duration = 0

# Welcome message
initial-command = "echo '🚀 Enhanced Ghostty Config Loaded!' && echo 'Leader key: cmd+s (try cmd+s>h for help)' && zsh"
EOF

    echo "✅ Enhanced configuration applied!"
    echo ""
    echo "🎯 Key Features Enabled:"
    echo "  • Leader key workflow (cmd+s>...)"
    echo "  • Enhanced split/pane management"
    echo "  • Optimized scrolling for large logs"
    echo "  • Productivity keybindings"
    echo "  • Modern transparent aesthetics"
    echo "  • GPU-optimized performance settings"
    echo ""
    echo "💡 Try these commands:"
    echo "  cmd+s>c        - New tab"
    echo "  cmd+s>\\        - Split right"
    echo "  cmd+s>-        - Split down"
    echo "  cmd+s>z        - Toggle zoom pane"
    echo "  cmd+s>f        - Search in terminal"
    echo ""
    echo "📖 For full keybinding list, check keybindings.enhanced.conf"
}

apply_custom_config() {
    echo "🎨 Applying your custom configuration..."

    backup_current_config

    # Apply your provided configuration
    cat > config << 'EOF'
# Custom Ghostty Configuration
# Based on user's specific requirements

# Core settings
font-size = 15
theme = vesper
shell-integration-features = no-cursor,sudo,no-title
cursor-style = block
adjust-cell-height = 35%

# Background and visual
# background-opacity = 0.96
# mouse-hide-while-typing = true
mouse-scroll-multiplier = 2
window-padding-balance = true
window-save-state = always
macos-titlebar-style = transparent
window-colorspace = "display-p3"

# Custom colors (commented for theme compatibility)
# background = 1C2021
# foreground = d4be98

# Copy behavior
copy-on-select = clipboard

# Keybindings with leader key approach
keybind = cmd+s>r=reload_config
keybind = cmd+s>x=close_surface
keybind = cmd+s>n=new_window

# Tab management
keybind = cmd+s>c=new_tab
keybind = cmd+s>shift+l=next_tab
keybind = cmd+s>shift+h=previous_tab
keybind = cmd+s>comma=move_tab:-1
keybind = cmd+s>period=move_tab:1

# Quick tab switching
keybind = cmd+s>1=goto_tab:1
keybind = cmd+s>2=goto_tab:2
keybind = cmd+s>3=goto_tab:3
keybind = cmd+s>4=goto_tab:4
keybind = cmd+s>5=goto_tab:5
keybind = cmd+s>6=goto_tab:6
keybind = cmd+s>7=goto_tab:7
keybind = cmd+s>8=goto_tab:8
keybind = cmd+s>9=goto_tab:9

# Split management
keybind = cmd+s>\=new_split:right
keybind = cmd+s>-=new_split:down
keybind = cmd+s>j=goto_split:bottom
keybind = cmd+s>k=goto_split:top
keybind = cmd+s>h=goto_split:left
keybind = cmd+s>l=goto_split:right
keybind = cmd+s>z=toggle_split_zoom
keybind = cmd+s>e=equalize_splits

# Shell integration
shell-integration = zsh
gtk-tabs-location = top
window-new-tab-position = end
EOF

    echo "✅ Custom configuration applied!"
    echo ""
    echo "🎯 Your Settings:"
    echo "  • Vesper theme with 15pt font"
    echo "  • Leader key workflow (cmd+s>...)"
    echo "  • Enhanced cell height (35%)"
    echo "  • 2x scroll multiplier"
    echo "  • Copy-on-select enabled"
    echo "  • Transparent titlebar"
    echo "  • Display P3 colorspace"
}

apply_default_config() {
    echo "🔄 Restoring default configuration..."

    backup_current_config

    # Restore the original modular approach
    cat > config << 'EOF'
# Ghostty Configuration File
# A complete list of options can be found by running `ghostty +show-config --default --docs`

config-file = theme.conf
config-file = scroll.conf
config-file = layout.conf
config-file = keybindings.conf

initial-command = "mousepad /home/kkk/.config/ghostty/keybindings.md"

shell-integration = zsh
gtk-tabs-location = top
window-new-tab-position = end
EOF

    echo "✅ Default configuration restored!"
}

# Main logic
case "${1:-}" in
    "enhanced")
        apply_enhanced_config
        ;;
    "custom")
        apply_custom_config
        ;;
    "default")
        apply_default_config
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        show_current_config
        show_usage
        ;;
    *)
        echo "❌ Unknown preset: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac

if [[ -n "${1:-}" ]]; then
    echo ""
    echo "🔄 Restart Ghostty to apply changes, or run:"
    echo "   ghostty +reload-config"
fi
