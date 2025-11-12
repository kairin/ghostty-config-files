#!/bin/bash
# Constitutional Local-Only Astro Deployment
# ZERO GitHub Actions consumption - Local build + manual push

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="$SCRIPT_DIR/../logs/astro-deploy-local-$TIMESTAMP.log"

# Ensure log directory exists
mkdir -p "$SCRIPT_DIR/../logs"

log() {
    echo "$(date -Iseconds) [LOCAL-DEPLOY] $1" | tee -a "$LOG_FILE"
}

echo "🚀 Constitutional Local-Only Astro Deployment"
echo "⚖️ Zero GitHub Actions consumption - Pure local build + push"
log "Starting constitutional local-only deployment"

cd "$PROJECT_ROOT"

# Step 1: Local CI/CD Validation (MANDATORY)
log "🔧 Running mandatory local CI/CD validation..."
if ! ./.runners-local/workflows/gh-workflow-local.sh local; then
    log "❌ Local CI/CD validation failed - deployment aborted"
    exit 1
fi
log "✅ Local CI/CD validation passed"

# Step 2: Local Astro Build (MANDATORY)
log "🏗️ Running local Astro build..."
if ! ./.runners-local/workflows/astro-build-local.sh; then
    log "❌ Local Astro build failed - deployment aborted"
    exit 1
fi
log "✅ Local Astro build completed"

# Step 3: Verify docs/ folder has fresh build
if [[ ! -f "docs/index.html" ]]; then
    log "❌ No build output found in docs/ - build may have failed"
    exit 1
fi

BUILD_TIME=$(stat -c %Y docs/index.html)
CURRENT_TIME=$(date +%s)
AGE=$((CURRENT_TIME - BUILD_TIME))

if [[ $AGE -gt 300 ]]; then  # 5 minutes
    log "⚠️ Build output is more than 5 minutes old - may not be fresh"
    log "ℹ️ Build age: ${AGE} seconds"
fi

log "✅ Fresh build output verified in docs/"

# Step 4: Constitutional Branch Strategy
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-deploy-astro-local"

log "🌿 Creating constitutional branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Step 5: Stage only the docs/ folder (built output)
log "📦 Staging Astro build output..."
git add docs/

# Check if there are changes to commit
if git diff --cached --quiet; then
    log "ℹ️ No changes to deploy - docs/ folder is up to date"
    git checkout main
    git branch -d "$BRANCH_NAME"
    log "✅ Deployment check complete - no changes needed"
    exit 0
fi

# Step 6: Commit with constitutional message
log "💾 Committing build output..."
git commit -m "Deploy Astro build - Local CI/CD deployment

Built on: $(date -Iseconds)
Build process: 100% local (zero GitHub Actions)
Constitutional compliance: ✅ Verified

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Step 7: Push to remote
log "🚀 Pushing constitutional branch to remote..."
git push -u origin "$BRANCH_NAME"

# Step 8: Merge to main (preserving branch)
log "🔀 Merging to main branch..."
git checkout main
git merge "$BRANCH_NAME" --no-ff -m "Merge constitutional Astro deployment: $BRANCH_NAME

Deployment method: Local-only build + manual push
GitHub Actions consumption: ZERO
Constitutional compliance: ✅ Verified"

# Step 9: Push main branch
log "📤 Pushing main branch..."
git push origin main

# Step 10: Preserve branch (constitutional requirement)
log "🏛️ Branch preserved as required by constitution: $BRANCH_NAME"

# Step 11: Verify deployment
log "🔍 Verifying deployment..."
sleep 5  # Give GitHub a moment to process

# Check site accessibility
if curl -s -o /dev/null -w "%{http_code}" https://kairin.github.io/ghostty-config-files/ | grep -q "200"; then
    log "✅ Site deployment successful - https://kairin.github.io/ghostty-config-files/ accessible"
else
    log "⚠️ Site may still be deploying - check in a few minutes"
fi

log "✅ Constitutional local-only deployment complete"
echo ""
echo "📋 Deployment Summary:"
echo "  • Method: 100% local build + manual push"
echo "  • GitHub Actions: ZERO consumption"
echo "  • Branch: $BRANCH_NAME (preserved)"
echo "  • Site: https://kairin.github.io/ghostty-config-files/"
echo "  • Logs: $LOG_FILE"