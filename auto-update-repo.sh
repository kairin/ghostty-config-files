#!/bin/bash

# Auto-update repository with current VS Code settings
# Run this script whenever you install new extensions or change settings

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "🔄 Auto-updating repository with current VS Code settings..."

# Extract current settings
./extract-settings.sh extract-all

# Update the main template with current settings if they're more comprehensive
if [[ -f "merged-complete-settings.json" ]]; then
    CURRENT_COUNT=$(grep -c '".*":' "merged-complete-settings.json" 2>/dev/null || echo "0")
    TEMPLATE_COUNT=$(grep -c '".*":' "template-settings.json" 2>/dev/null || echo "0")
    
    if [[ $CURRENT_COUNT -gt $TEMPLATE_COUNT ]]; then
        echo "📈 Current settings ($CURRENT_COUNT) more comprehensive than template ($TEMPLATE_COUNT)"
        echo "🔄 Updating template-settings.json..."
        cp "merged-complete-settings.json" "template-settings.json"
    fi
fi

# Update extensions list if current is more comprehensive
if [[ -f "complete-extensions.json" ]]; then
    CURRENT_EXT_COUNT=$(grep -c '".*\.[^"]*"' "complete-extensions.json" 2>/dev/null || echo "0")
    TEMPLATE_EXT_COUNT=$(grep -c '".*\.[^"]*"' ".vscode/extensions.json" 2>/dev/null || echo "0")
    
    if [[ $CURRENT_EXT_COUNT -gt $TEMPLATE_EXT_COUNT ]]; then
        echo "📦 Current extensions ($CURRENT_EXT_COUNT) more than template ($TEMPLATE_EXT_COUNT)"
        echo "🔄 Updating .vscode/extensions.json..."
        cp "complete-extensions.json" ".vscode/extensions.json"
    fi
fi

# Git operations (if this is a git repo)
if [[ -d ".git" ]]; then
    echo "📝 Checking for changes to commit..."
    
    if git diff --quiet && git diff --staged --quiet; then
        echo "✅ No changes to commit"
    else
        echo "💾 Committing updated settings..."
        git add .
        git commit -m "Auto-update: VS Code settings and extensions $(date '+%Y-%m-%d %H:%M')"
        
        echo "🚀 Pushing to remote..."
        git push origin main || echo "⚠️  Push failed - you may need to pull first"
    fi
fi

echo "✅ Auto-update complete!"
