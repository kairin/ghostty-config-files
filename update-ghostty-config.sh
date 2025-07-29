#!/bin/bash

# Ghostty Configuration Update Script
# Updates the system Ghostty config with current settings

echo "🔧 Updating Ghostty Configuration for VS Code Compatibility"
echo "========================================================="

# Ghostty config directory
GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

# Create config directory if it doesn't exist
mkdir -p "$GHOSTTY_CONFIG_DIR"

echo "📁 Copying configuration files..."

# Copy all config files
cp config "$GHOSTTY_CONFIG_DIR/config"
cp theme.conf "$GHOSTTY_CONFIG_DIR/theme.conf"
cp scroll.conf "$GHOSTTY_CONFIG_DIR/scroll.conf"
cp layout.conf "$GHOSTTY_CONFIG_DIR/layout.conf"
cp keybindings.conf "$GHOSTTY_CONFIG_DIR/keybindings.conf"
cp keybindings.md "$GHOSTTY_CONFIG_DIR/keybindings.md"

echo "✅ Configuration files updated!"

echo ""
echo "🎯 VS Code External Terminal Fix Applied:"
echo "  ✅ Removed initial-command that was causing termination"
echo "  ✅ Ghostty will now work properly as VS Code external terminal"

echo ""
echo "📋 To view keybindings when needed:"
echo "  • Run: cat ~/.config/ghostty/keybindings.md"
echo "  • Or add alias: alias ghostty-help=\"cat ~/.config/ghostty/keybindings.md\""

echo ""
echo "🧪 Testing VS Code integration:"
echo "  1. Open VS Code"
echo "  2. Right-click a folder → 'Open in External Terminal'"
echo "  3. Ghostty should open and stay open with shell prompt"

echo ""
echo "✨ Ghostty is now ready for VS Code integration!"
