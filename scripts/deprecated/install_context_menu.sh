#!/bin/bash

# Script to install Ghostty right-click context menu integration
# Supports GNOME/Nautilus file manager

set -e

echo "Installing Ghostty context menu integration..."

# Create Nautilus scripts directory
mkdir -p ~/.local/share/nautilus/scripts

# Create the Nautilus script
cat > ~/.local/share/nautilus/scripts/"Open in Ghostty" << 'EOF'
#!/bin/bash

# Nautilus script to open selected folder in Ghostty terminal
# This script will appear in the right-click context menu

# Get the selected directory path
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    # Use the selected folder/file path
    TARGET_PATH="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"

    # If it's a file, get its directory
    if [ -f "$TARGET_PATH" ]; then
        TARGET_PATH="$(dirname "$TARGET_PATH")"
    fi
else
    # If no selection, use current directory
    TARGET_PATH="$NAUTILUS_SCRIPT_CURRENT_URI"
    # Convert file:// URI to local path
    TARGET_PATH=$(echo "$TARGET_PATH" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")
fi

# Launch Ghostty with the target directory as working directory
if command -v ghostty >/dev/null 2>&1; then
    cd "$TARGET_PATH" && ghostty &
else
    # Fallback notification if Ghostty is not found
    notify-send "Ghostty not found" "Please ensure Ghostty is installed and in your PATH"
fi
EOF

# Make the script executable
chmod +x ~/.local/share/nautilus/scripts/"Open in Ghostty"

# Create desktop file for better integration
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/ghostty-here.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Open Ghostty Here
Comment=Open Ghostty terminal in selected folder
Exec=ghostty --working-directory=%f
Icon=utilities-terminal
StartupNotify=true
NoDisplay=true
MimeType=inode/directory;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications 2>/dev/null || true

# Restart Nautilus to apply changes
nautilus -q 2>/dev/null || true

echo "✅ Ghostty context menu integration installed successfully!"
echo ""
echo "Usage:"
echo "1. Right-click on any folder in Nautilus"
echo "2. Select 'Scripts' > 'Open in Ghostty'"
echo ""
echo "Note: You may need to open a new Nautilus window to see the changes."