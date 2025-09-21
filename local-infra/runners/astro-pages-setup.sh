#!/bin/bash
# Constitutional Astro GitHub Pages Setup
# Feature 001: Modern Web Development Stack - Proper Implementation

set -euo pipefail

echo "🚀 Setting up constitutional Astro GitHub Pages deployment..."

REPO_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="./local-infra/logs/astro-pages-setup-$TIMESTAMP.log"

# Ensure log directory exists
mkdir -p ./local-infra/logs

log_with_timestamp() {
    echo "$(date -Iseconds) [ASTRO-PAGES] $1" | tee -a "$LOG_FILE"
}

log_with_timestamp "Starting constitutional Astro GitHub Pages setup"

# Verify constitutional tech stack
if [[ ! -f "$REPO_DIR/astro.config.mjs" ]]; then
    log_with_timestamp "ERROR: astro.config.mjs not found - constitutional violation"
    exit 1
fi

if [[ ! -f "$REPO_DIR/package.json" ]]; then
    log_with_timestamp "ERROR: package.json not found"
    exit 1
fi

# Verify Astro is in package.json (constitutional requirement)
if ! grep -q '"astro"' "$REPO_DIR/package.json"; then
    log_with_timestamp "ERROR: Astro not found in package.json - constitutional violation"
    exit 1
fi

log_with_timestamp "✅ Constitutional tech stack verified (Astro + package.json)"

# Configure GitHub Pages for Astro build using gh CLI
log_with_timestamp "Configuring GitHub Pages for Astro deployment..."

# Check if gh CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
    log_with_timestamp "ERROR: GitHub CLI not authenticated - run 'gh auth login'"
    exit 1
fi

# Configure GitHub Pages to use GitHub Actions for Astro build
log_with_timestamp "Setting GitHub Pages source to GitHub Actions..."
gh api repos/:owner/:repo/pages \
    --method POST \
    --field source[branch]=main \
    --field source[path]="/" \
    --field build_type="workflow" 2>/dev/null || {

    # If already exists, update it
    log_with_timestamp "Updating existing GitHub Pages configuration..."
    gh api repos/:owner/:repo/pages \
        --method PUT \
        --field source[branch]=main \
        --field source[path]="/" \
        --field build_type="workflow" >/dev/null
}

log_with_timestamp "✅ GitHub Pages configured for Astro workflow deployment"

# Create constitutional Astro build workflow
log_with_timestamp "Creating constitutional Astro build workflow..."

mkdir -p "$REPO_DIR/.github/workflows"

cat > "$REPO_DIR/.github/workflows/astro-build-deploy.yml" << 'EOF'
name: Constitutional Astro Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Constitutional TypeScript Check
        run: npm run check

      - name: Build Astro site
        run: npm run build

      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

log_with_timestamp "✅ Constitutional Astro workflow created"

# Verify the build works locally first (constitutional requirement)
log_with_timestamp "Verifying Astro build works locally (constitutional requirement)..."

cd "$REPO_DIR"

# Check if TypeScript errors need to be fixed first
if ! npm run check >/dev/null 2>&1; then
    log_with_timestamp "⚠️ TypeScript errors detected - must be fixed per constitutional mandate"
    log_with_timestamp "Run 'npm run check' to see errors and fix each one properly"
    log_with_timestamp "FORBIDDEN: Do not use --no-check or @ts-ignore"
else
    log_with_timestamp "✅ TypeScript check passed"

    # Attempt local build
    if npm run build >/dev/null 2>&1; then
        log_with_timestamp "✅ Local Astro build successful"

        if [[ -d "dist" ]]; then
            DIST_SIZE=$(du -sh dist | cut -f1)
            log_with_timestamp "✅ Build output: dist/ directory ($DIST_SIZE)"
        fi
    else
        log_with_timestamp "❌ Local Astro build failed - check npm run build output"
    fi
fi

log_with_timestamp "Constitutional Astro GitHub Pages setup complete"
echo ""
echo "📋 Next Steps:"
echo "1. Fix any TypeScript errors: npm run check"
echo "2. Test local build: npm run build"
echo "3. Commit and push to trigger deployment"
echo "4. Check deployment: gh run list"
EOF