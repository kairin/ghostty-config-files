#!/bin/bash

# Complete Astro Constitutional Workflow: Build → Validate → Deploy
# Zero-cost local CI/CD with constitutional compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] [ASTRO-WORKFLOW] $1${NC}"
}

# Complete constitutional workflow
main() {
    log "🚀 Starting complete Astro constitutional workflow..."

    # Step 1: Build with constitutional compliance
    log "📦 Step 1/4: Building Astro site..."
    if ! "$SCRIPT_DIR/astro-build-local.sh" build; then
        echo "❌ Build failed"
        exit 1
    fi

    # Step 2: Validate deployment readiness
    log "🔍 Step 2/4: Validating deployment readiness..."
    if ! "$SCRIPT_DIR/astro-deploy-enhanced.sh" validate; then
        echo "❌ Deployment validation failed"
        exit 1
    fi

    # Step 3: Deploy to GitHub Pages
    log "🚀 Step 3/4: Deploying to GitHub Pages..."
    if ! "$SCRIPT_DIR/astro-deploy-enhanced.sh" git; then
        echo "❌ Deployment failed"
        exit 1
    fi

    # Step 4: Run constitutional CI/CD validation
    log "⚖️ Step 4/4: Running constitutional CI/CD validation..."
    if ! "$SCRIPT_DIR/gh-workflow-local.sh" all; then
        echo "❌ Constitutional validation failed"
        exit 1
    fi

    echo -e "${GREEN}🎉 Complete constitutional Astro workflow successful!${NC}"
    echo -e "${GREEN}🌐 Site URL: https://kairin.github.io/ghostty-config-files/${NC}"
    echo ""
    echo "🔧 Next steps:"
    echo "- Wait 2-3 minutes for GitHub Pages to update"
    echo "- Check browser DevTools → Network for any 404s"
    echo "- Verify CSS and JavaScript load correctly"
}

main "$@"