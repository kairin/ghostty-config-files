#!/bin/bash
# Astro GitHub Pages setup for ghostty-config-files
echo "📄 Setting up zero-cost GitHub Pages with Astro..."

REPO_DIR="$(dirname "$(dirname "$(dirname "$0")")")"

setup_github_pages() {
    echo "🔧 Configuring Astro for GitHub Pages deployment..."

    # Ensure Astro build output directory exists
    if [ ! -d "$REPO_DIR/docs" ]; then
        echo "❌ docs/ directory not found. Running Astro build..."
        cd "$REPO_DIR" && npx astro build
        if [ $? -ne 0 ]; then
            echo "❌ Astro build failed. Check astro.config.mjs configuration."
            return 1
        fi
    fi

    # Verify Astro build output
    if [ -f "$REPO_DIR/docs/index.html" ]; then
        echo "✅ Astro build output verified in docs/"
    else
        echo "❌ No index.html found in docs/. Run: npx astro build"
        return 1
    fi

    # Configure GitHub Pages to serve from docs/ folder
    if command -v gh >/dev/null 2>&1; then
        echo "🔧 Configuring GitHub Pages deployment..."
        gh api repos/:owner/:repo --method PATCH \
            --field source[branch]=main \
            --field source[path]="/docs" 2>/dev/null && \
            echo "✅ GitHub Pages configured to serve from docs/ folder" || \
            echo "ℹ️ GitHub CLI configuration may require manual setup"
    else
        echo "ℹ️ GitHub CLI not available, configure Pages manually:"
        echo "   Settings → Pages → Source: Deploy from a branch → main → /docs"
    fi

    echo "✅ Astro GitHub Pages setup complete"
}

setup_github_pages