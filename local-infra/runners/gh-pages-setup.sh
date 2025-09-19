#!/bin/bash
# GitHub Pages setup for ghostty-config-files
echo "📄 Setting up zero-cost GitHub Pages..."

REPO_DIR="$(dirname "$(dirname "$(dirname "$0")")")"

setup_github_pages() {
    # Create documentation directory
    mkdir -p "$REPO_DIR/docs"

    # Copy README as index
    if [ -f "$REPO_DIR/README.md" ]; then
        cp "$REPO_DIR/README.md" "$REPO_DIR/docs/index.md"
        echo "✅ Copied README as documentation index"
    fi

    # Create Jekyll configuration
    cat > "$REPO_DIR/docs/_config.yml" << EOL
title: Ghostty Configuration Files
description: Comprehensive terminal environment setup with 2025 optimizations
theme: jekyll-theme-minimal
plugins:
  - jekyll-relative-links
relative_links:
  enabled: true
  collections: true
include:
  - AGENTS.md
  - CLAUDE.md
  - GEMINI.md
EOL
    echo "✅ Created GitHub Pages configuration"

    # Test local Jekyll build if available
    if command -v jekyll >/dev/null 2>&1; then
        cd "$REPO_DIR/docs" && jekyll build --destination _site_test >/dev/null 2>&1
        echo "✅ Local Jekyll build test successful"
    else
        echo "ℹ️ Jekyll not available, skipping local build test"
    fi
}

setup_github_pages
