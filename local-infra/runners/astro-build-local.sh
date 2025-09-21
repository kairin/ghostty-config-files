#!/bin/bash

# Local Astro.build CI/CD Runner
# Builds documentation website locally before GitHub deployment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOCS_SITE_DIR="$PROJECT_ROOT/docs-site"

echo "🚀 Running local Astro.build CI/CD..."

# Check if uv is available
if ! command -v uv >/dev/null 2>&1; then
    echo "❌ uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Check if Node.js is available
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

cd "$DOCS_SITE_DIR"

echo "📦 Installing dependencies..."
npm install

echo "🔍 Running Astro check..."
npm run check

echo "🏗️ Building Astro site..."
npm run build

echo "✅ Astro build completed successfully!"
echo "📁 Built site available in: $PROJECT_ROOT/docs"

# Verify build output
if [ -f "$PROJECT_ROOT/docs/index.html" ]; then
    echo "✅ Build verification passed"
else
    echo "❌ Build verification failed - index.html not found"
    exit 1
fi
