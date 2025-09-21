#!/bin/bash

# Astro GitHub Pages Emergency Recovery
# Fixes common deployment issues

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_DIR/docs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[EMERGENCY-FIX] $1${NC}"
}

error() {
    echo -e "${RED}[EMERGENCY-FIX] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[EMERGENCY-FIX] $1${NC}"
}

# Fix missing .nojekyll
fix_nojekyll() {
    log "🔧 Fixing missing .nojekyll file..."

    if [ ! -d "$BUILD_DIR" ]; then
        error "❌ Build directory not found. Run: npm run build"
        return 1
    fi

    # Create .nojekyll file
    touch "$BUILD_DIR/.nojekyll"
    log "✅ Created .nojekyll file"

    # Verify _astro directory
    if [ -d "$BUILD_DIR/_astro" ]; then
        log "✅ _astro directory confirmed"
    else
        warn "⚠️ _astro directory missing - rebuild may be needed"
    fi
}

# Fix base path issues
fix_base_path() {
    log "🔧 Checking base path configuration..."

    if grep -q 'base.*ghostty-config-files' "$REPO_DIR/astro.config.mjs"; then
        log "✅ Base path correctly configured"
    else
        warn "⚠️ Base path issue detected"
        echo "Add this to astro.config.mjs:"
        echo "base: '/ghostty-config-files',"
    fi
}

# Quick rebuild and deploy
quick_fix() {
    log "🚀 Running quick fix: rebuild and deploy..."

    cd "$REPO_DIR"

    # Clean and rebuild
    rm -rf "$BUILD_DIR"
    npm run build

    # Verify .nojekyll was created
    if [ -f "$BUILD_DIR/.nojekyll" ]; then
        log "✅ .nojekyll automatically created by Vite plugin"
    else
        error "❌ .nojekyll not created - Vite plugin issue"
        touch "$BUILD_DIR/.nojekyll"
        warn "⚠️ Manually created .nojekyll as fallback"
    fi

    # Quick commit and push
    git add .
    git commit -m "Emergency fix: Rebuild Astro site with .nojekyll

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
    git push origin main

    log "✅ Emergency fix deployed"
    log "🕐 Wait 2-3 minutes for GitHub Pages to update"
}

# Show help
show_help() {
    cat << EOF
Astro GitHub Pages Emergency Recovery

Usage: $0 [COMMAND]

Commands:
  nojekyll    Fix missing .nojekyll file
  basepath    Check base path configuration
  quick       Quick rebuild and deploy
  help        Show this help

Common Issues:
  CSS not loading     → Run: $0 nojekyll
  404 on assets       → Run: $0 quick
  Wrong asset paths   → Run: $0 basepath

Manual Checks:
  GitHub Pages Settings: Settings → Pages → Source: main branch /docs folder
  Browser DevTools: Network tab to see 404 errors
  Repository Files: Check docs/.nojekyll exists in GitHub
EOF
}

case "${1:-help}" in
    "nojekyll")
        fix_nojekyll
        ;;
    "basepath")
        fix_base_path
        ;;
    "quick")
        quick_fix
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac