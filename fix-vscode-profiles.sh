#!/bin/bash

# VS Code Profile Fix Script
echo "🔧 Fixing VS Code Profiles..."

# Backup current configuration
echo "Creating backup..."
cp -r ~/.config/Code/User ~/.config/Code/User.backup.$(date +%Y%m%d-%H%M%S) 2>/dev/null

# Remove custom profiles directory if it exists
if [[ -d ~/.config/Code/User/profiles ]]; then
    echo "Removing custom profiles directory..."
    rm -rf ~/.config/Code/User/profiles
    echo "✅ Custom profiles removed"
fi

# Clear profile sync state
if [[ -f ~/.config/Code/User/sync/profiles/lastSyncprofiles.json ]]; then
    echo '{"ref":"0","syncData":null}' > ~/.config/Code/User/sync/profiles/lastSyncprofiles.json
    echo "✅ Reset sync profiles state"
fi

echo "✅ Profile cleanup complete!"
echo "Now run these commands in VS Code:"
echo "1. Ctrl+Shift+P → Settings Sync: Turn Off"
echo "2. Ctrl+Shift+P → Settings Sync: Turn On"
echo "3. Sign in with GitHub"
echo "4. Ctrl+Shift+P → Settings Sync: Configure"
echo "5. Enable ALL sync options"
