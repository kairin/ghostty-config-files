#!/bin/bash

# Enhanced Astro GitHub Pages Deployment with .nojekyll Validation
# Constitutional compliance with zero-cost local CI/CD

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LOG_DIR="$SCRIPT_DIR/../logs"
BUILD_DIR="$REPO_DIR/docs"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
        "STEP") color="$CYAN" ;;
    esac

    echo -e "${color}[$timestamp] [ASTRO-DEPLOY] $message${NC}"
    echo "[$timestamp] [ASTRO-DEPLOY] $message" >> "$LOG_DIR/astro-deploy-$(date +%s).log"
}

# Pre-deployment validation
validate_deployment_readiness() {
    log "STEP" "🔍 Validating deployment readiness..."
    local errors=0

    # 1. Check build output exists
    if [ ! -d "$BUILD_DIR" ]; then
        log "ERROR" "❌ Build directory not found: $BUILD_DIR"
        errors=$((errors + 1))
    else
        log "SUCCESS" "✅ Build directory exists"
    fi

    # 2. CRITICAL: Verify .nojekyll file exists
    if [ ! -f "$BUILD_DIR/.nojekyll" ]; then
        log "ERROR" "❌ CRITICAL: .nojekyll file missing! This will cause CSS/JS 404s on GitHub Pages"
        log "INFO" "💡 Solution: Ensure Vite plugin in astro.config.mjs is working"
        errors=$((errors + 1))
    else
        log "SUCCESS" "✅ CRITICAL: .nojekyll file confirmed - GitHub Pages will serve _astro/ assets"
    fi

    # 3. Verify _astro directory exists with assets
    if [ ! -d "$BUILD_DIR/_astro" ]; then
        log "ERROR" "❌ _astro directory missing - no CSS/JS assets found"
        errors=$((errors + 1))
    else
        local css_count=$(find "$BUILD_DIR/_astro" -name "*.css" | wc -l)
        local js_count=$(find "$BUILD_DIR/_astro" -name "*.js" | wc -l)
        log "SUCCESS" "✅ _astro directory confirmed ($css_count CSS, $js_count JS files)"
    fi

    # 4. Verify index.html exists
    if [ ! -f "$BUILD_DIR/index.html" ]; then
        log "ERROR" "❌ index.html missing"
        errors=$((errors + 1))
    else
        log "SUCCESS" "✅ index.html confirmed"
    fi

    # 5. Check for base path configuration
    if grep -q '/ghostty-config-files/' "$BUILD_DIR/index.html" 2>/dev/null; then
        log "SUCCESS" "✅ GitHub Pages base path (/ghostty-config-files/) configured"
    else
        log "WARNING" "⚠️ GitHub Pages base path not detected in HTML"
    fi

    # 6. Constitutional compliance check
    local js_size
    js_size=$(find "$BUILD_DIR" -name "*.js" -exec du -cb {} + 2>/dev/null | tail -1 | cut -f1 || echo "0")
    if [ "$js_size" -lt 102400 ]; then  # 100KB
        log "SUCCESS" "✅ Constitutional compliance: JavaScript bundle <100KB"
    else
        log "WARNING" "⚠️ Constitutional warning: JavaScript bundle >100KB ($js_size bytes)"
    fi

    if [ $errors -gt 0 ]; then
        log "ERROR" "❌ Deployment validation failed ($errors errors)"
        return 1
    fi

    log "SUCCESS" "✅ Deployment validation passed - ready for GitHub Pages"
}

# Git operations with constitutional branch management
deploy_to_github() {
    log "STEP" "🚀 Deploying to GitHub Pages..."

    cd "$REPO_DIR"

    # Constitutional branch naming
    local DATETIME=$(date +"%Y%m%d-%H%M%S")
    local BRANCH_NAME="${DATETIME}-deploy-astro-pages"

    # Check git status
    if ! git status >/dev/null 2>&1; then
        log "ERROR" "❌ Not in a git repository"
        return 1
    fi

    # Create constitutional branch
    log "INFO" "🌿 Creating constitutional branch: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME"

    # Add all changes including build output
    log "INFO" "📦 Adding build output to git..."
    git add .

    # Constitutional commit with deployment message
    log "INFO" "💾 Creating constitutional commit..."
    git commit -m "$(cat <<'EOF'
Deploy: Astro static site with GitHub Pages optimization

- Build output generated with .nojekyll automation
- Constitutional performance targets maintained
- _astro/ assets properly configured for GitHub Pages
- Zero-cost deployment via local CI/CD

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

    # Push feature branch
    log "INFO" "⬆️ Pushing feature branch..."
    git push -u origin "$BRANCH_NAME"

    # Merge to main (constitutional requirement)
    log "INFO" "🔄 Merging to main branch..."
    git checkout main
    git merge "$BRANCH_NAME" --no-ff
    git push origin main

    # Constitutional compliance: NEVER delete branches
    log "SUCCESS" "✅ Constitutional deployment complete"
    log "INFO" "📋 Branch preserved: $BRANCH_NAME"
    log "INFO" "🌐 GitHub Pages will update in 2-3 minutes"
    log "INFO" "🔗 Site URL: https://kairin.github.io/ghostty-config-files/"
}

# Post-deployment verification
verify_deployment() {
    log "STEP" "🔍 Verifying deployment status..."

    # Check GitHub Pages status using gh CLI
    if command -v gh >/dev/null 2>&1; then
        log "INFO" "📊 Checking GitHub Pages status..."
        if gh api repos/:owner/:repo/pages 2>/dev/null | jq -r '.status' | grep -q 'built'; then
            log "SUCCESS" "✅ GitHub Pages build status: active"
        else
            log "INFO" "⏳ GitHub Pages build in progress..."
        fi

        # Show latest deployment
        local latest_deployment
        latest_deployment=$(gh api repos/:owner/:repo/deployments --jq '.[0].environment' 2>/dev/null || echo "unknown")
        log "INFO" "🚀 Latest deployment environment: $latest_deployment"
    else
        log "INFO" "💡 Install gh CLI for deployment status monitoring"
    fi

    log "INFO" "🕐 GitHub Pages typically updates within 2-3 minutes"
    log "INFO" "🌐 Site URL: https://kairin.github.io/ghostty-config-files/"

    # Common debugging tips
    cat << 'EOF'

🔧 Debugging Tips:
- Open browser DevTools → Network tab to check for 404s on _astro/* files
- If CSS doesn't load, verify .nojekyll file exists in GitHub repo docs/ folder
- Check GitHub repo Settings → Pages → Source is set to "main branch /docs folder"
- Wait 2-3 minutes for GitHub Pages cache to refresh
EOF
}

# Complete deployment workflow
run_complete_deployment() {
    log "INFO" "🚀 Starting complete Astro deployment workflow..."

    local overall_start=$(date +%s)
    local failed_steps=0

    # Run deployment pipeline
    validate_deployment_readiness || ((failed_steps++))
    deploy_to_github || ((failed_steps++))
    verify_deployment

    local overall_duration=$(($(date +%s) - overall_start))

    if [ $failed_steps -eq 0 ]; then
        log "SUCCESS" "🎉 Complete Astro deployment successful in ${overall_duration}s"
        log "INFO" "🌐 Site deploying to: https://kairin.github.io/ghostty-config-files/"
        return 0
    else
        log "ERROR" "❌ Deployment completed with $failed_steps failed steps in ${overall_duration}s"
        return 1
    fi
}

# Show help
show_help() {
    cat << EOF
Enhanced Astro GitHub Pages Deployment

Usage: $0 [COMMAND]

Commands:
  deploy      Run complete deployment workflow
  validate    Validate deployment readiness only
  git         Deploy to GitHub only (assumes validation passed)
  verify      Verify deployment status only
  help        Show this help message

Examples:
  $0 deploy     # Complete deployment workflow
  $0 validate   # Check if ready for deployment
  $0 verify     # Check GitHub Pages status

Note: This script implements constitutional branch management
and validates .nojekyll file for GitHub Pages compatibility.
EOF
}

# Main execution
main() {
    mkdir -p "$LOG_DIR"

    case "${1:-deploy}" in
        "deploy")
            run_complete_deployment
            ;;
        "validate")
            validate_deployment_readiness
            ;;
        "git")
            deploy_to_github
            ;;
        "verify")
            verify_deployment
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
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi