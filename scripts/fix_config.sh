#!/bin/bash

set -euo pipefail

# Ghostty Configuration Cleanup Script
# This script automatically detects and removes problematic configuration patterns
# that cause validation errors in Ghostty.

CONFIG_DIR="$HOME/.config/ghostty"
CONFIG_FILE="$CONFIG_DIR/config"
THEME_FILE="$CONFIG_DIR/theme.conf"

echo "======================================="
echo "    Ghostty Configuration Cleanup"
echo "======================================="

# Function to clean theme.conf
clean_theme_conf() {
    if [[ ! -f "$THEME_FILE" ]]; then
        echo "theme.conf not found, skipping theme cleanup"
        return
    fi
    
    echo "-> Checking theme.conf for problematic patterns..."
    
    # Check for lines with "(resources)" pattern
    if grep -q "(resources)" "$THEME_FILE"; then
        echo "-> Found problematic theme list entries, cleaning..."
        
        # Create backup
        cp "$THEME_FILE" "$THEME_FILE.backup.$(date +%s)"
        echo "-> Created backup: $THEME_FILE.backup.$(date +%s)"
        
        # Extract the actual theme setting and opacity if they exist
        THEME_LINE=$(grep "^theme = " "$THEME_FILE" 2>/dev/null || echo "")
        OPACITY_LINE=$(grep "^background-opacity = " "$THEME_FILE" 2>/dev/null || echo "")
        
        # Recreate clean theme.conf
        cat > "$THEME_FILE" << EOF
# Theme
# A list of available themes can be found by running "ghostty +list-themes"
${THEME_LINE:-theme = "catppuccin-mocha"}

# Opacity
${OPACITY_LINE:-background-opacity = 0.75}
EOF
        
        echo "-> theme.conf cleaned successfully"
    else
        echo "-> theme.conf is clean"
    fi
}

# Function to fix command palette entries
fix_command_palette_entries() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "config file not found, skipping command palette cleanup"
        return
    fi
    
    echo "-> Checking for problematic command palette entries..."
    
    # Look for command palette entries with colons and commas that might cause parsing issues
    if grep -q "command-palette-entry.*Focus Split:" "$CONFIG_FILE"; then
        echo "-> Found problematic command palette entries, fixing..."
        
        # Create backup
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%s)"
        echo "-> Created backup: $CONFIG_FILE.backup.$(date +%s)"
        
        # Fix the problematic entries by removing colons and commas from titles/descriptions
        sed -i 's/Focus Split: Down/Focus Split Down/g' "$CONFIG_FILE"
        sed -i 's/Focus Split: Left/Focus Split Left/g' "$CONFIG_FILE"
        sed -i 's/Focus Split: Next/Focus Split Next/g' "$CONFIG_FILE"
        sed -i 's/Focus Split: Previous/Focus Split Previous/g' "$CONFIG_FILE"
        sed -i 's/Focus Split: Right/Focus Split Right/g' "$CONFIG_FILE"
        sed -i 's/Focus Split: Up/Focus Split Up/g' "$CONFIG_FILE"
        
        # Fix descriptions by removing commas
        sed -i 's/Focus the split below, if it exists/Focus the split below if it exists/g' "$CONFIG_FILE"
        sed -i 's/Focus the split to the left, if it exists/Focus the split to the left if it exists/g' "$CONFIG_FILE"
        sed -i 's/Focus the next split, if any/Focus the next split if any/g' "$CONFIG_FILE"
        sed -i 's/Focus the previous split, if any/Focus the previous split if any/g' "$CONFIG_FILE"
        sed -i 's/Focus the split to the right, if it exists/Focus the split to the right if it exists/g' "$CONFIG_FILE"
        sed -i 's/Focus the split above, if it exists/Focus the split above if it exists/g' "$CONFIG_FILE"
        
        echo "-> Command palette entries fixed"
    else
        echo "-> Command palette entries are clean"
    fi
}

# Function to validate configuration
validate_config() {
    echo "-> Validating configuration..."
    
    if ghostty +show-config >/dev/null 2>validation_errors.log; then
        echo "✅ Configuration validation passed"
        rm -f validation_errors.log
        return 0
    else
        echo "❌ Configuration validation failed:"
        cat validation_errors.log
        rm -f validation_errors.log
        return 1
    fi
}

# Main execution
echo "Starting configuration cleanup..."

clean_theme_conf
fix_command_palette_entries

echo ""
echo "-> Running final validation..."
if validate_config; then
    echo ""
    echo "✅ Configuration cleanup completed successfully!"
    echo "   All validation errors have been resolved."
else
    echo ""
    echo "⚠️  Some validation errors may still remain."
    echo "   Please check the output above for details."
fi

echo "======================================="
echo "              Cleanup Summary"
echo "======================================="
echo "Files processed:"
echo "  - $THEME_FILE"
echo "  - $CONFIG_FILE"
echo ""
echo "Backup files created with timestamp suffix if changes were made."
echo "You can now safely run Ghostty without configuration errors."