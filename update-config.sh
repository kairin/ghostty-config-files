#!/bin/bash

# Ghostty Configuration Update Script
# Updates the configuration by pulling latest changes from GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔄 Updating Ghostty configuration..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not a git repository. Cannot update."
    exit 1
fi

# Check for local changes
if ! git diff --quiet; then
    echo "⚠️  Local changes detected. Stashing them..."
    git stash push -m "Auto-stash before update $(date)"
fi

# Pull latest changes
if git pull origin main; then
    echo "✅ Configuration updated successfully!"

    # Check if there were stashed changes
    if git stash list | grep -q "Auto-stash before update"; then
        echo "📋 You had local changes that were stashed."
        echo "   To restore them: git stash pop"
    fi

    # Show what changed
    echo ""
    echo "📝 Recent changes:"
    git log --oneline -5

    # Check if enhanced config files were updated
    if git diff --name-only HEAD~1 HEAD | grep -E "\.(enhanced\.conf|productivity\.conf)$" > /dev/null; then
        echo ""
        echo "🚀 Enhanced configuration files were updated!"
        echo "   You may want to reload your config:"
        echo "   - Restart Ghostty, or"
        echo "   - Run: ghostty +reload-config"

        # Show which enhanced files changed
        echo ""
        echo "📁 Updated enhanced files:"
        git diff --name-only HEAD~1 HEAD | grep -E "\.(enhanced\.conf|productivity\.conf)$" | sed 's/^/   • /'
    fi

else
    echo "❌ Failed to update configuration."
    exit 1
fi
