#!/bin/bash
# Astro.build Documentation Generator (Orchestrator)
# Purpose: Creates documentation website with SVG screenshots
# Refactored: 2025-11-25 - Modularized to <300 lines (was 807 lines)
# Modules: lib/docs/{markdown_generator,index_builder,asset_compiler}.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOCS_DIR="$PROJECT_ROOT/docs"
ASTRO_PROJECT_DIR="$PROJECT_ROOT/docs-site"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# Source Modular Documentation Libraries
# ============================================================================

source_docs_modules() {
    local lib_dir="${PROJECT_ROOT}/lib/docs"

    for module in markdown_generator index_builder asset_compiler; do
        if [[ -f "${lib_dir}/${module}.sh" ]]; then
            source "${lib_dir}/${module}.sh"
        else
            echo -e "${YELLOW}WARN: Module not found: ${module}.sh${NC}" >&2
        fi
    done
}

# ============================================================================
# Astro Project Generation
# ============================================================================

create_astro_project() {
    echo -e "${CYAN}Creating Astro.build project...${NC}"

    mkdir -p "$ASTRO_PROJECT_DIR"/{src/{pages,components,layouts,styles},public/{assets,screenshots}}

    # Create package.json
    cat > "$ASTRO_PROJECT_DIR/package.json" << 'EOF'
{
  "name": "ghostty-docs",
  "type": "module",
  "version": "1.0.0",
  "description": "Ghostty Configuration Files Documentation",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "check": "astro check && tsc --noEmit"
  },
  "dependencies": {
    "astro": "^4.0.0",
    "@astrojs/tailwind": "^5.0.0",
    "@astrojs/sitemap": "^3.0.0",
    "tailwindcss": "^3.4.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

    # Create astro.config.mjs
    cat > "$ASTRO_PROJECT_DIR/astro.config.mjs" << 'EOF'
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://USERNAME.github.io',
  base: '/ghostty-config-files',
  integrations: [tailwind(), sitemap()],
  output: 'static',
  outDir: '../docs',
  build: { assets: 'assets' }
});
EOF

    # Create tsconfig.json
    cat > "$ASTRO_PROJECT_DIR/tsconfig.json" << 'EOF'
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  }
}
EOF

    # Create tailwind.config.mjs
    cat > "$ASTRO_PROJECT_DIR/tailwind.config.mjs" << 'EOF'
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,ts,tsx}'],
  theme: { extend: {} },
  plugins: []
}
EOF

    echo -e "${GREEN}Astro project structure created${NC}"
}

# ============================================================================
# Page Generation (Simplified - uses modules for complex generation)
# ============================================================================

create_basic_pages() {
    echo -e "${CYAN}Creating basic pages...${NC}"

    # Create base layout
    mkdir -p "$ASTRO_PROJECT_DIR/src/layouts"
    cat > "$ASTRO_PROJECT_DIR/src/layouts/BaseLayout.astro" << 'EOF'
---
const { title } = Astro.props;
---
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
</head>
<body class="min-h-screen bg-gray-50">
    <slot />
</body>
</html>
EOF

    # Create index page
    mkdir -p "$ASTRO_PROJECT_DIR/src/pages"
    cat > "$ASTRO_PROJECT_DIR/src/pages/index.astro" << 'EOF'
---
import BaseLayout from '../layouts/BaseLayout.astro';
---
<BaseLayout title="Ghostty Configuration Files">
    <main class="container mx-auto p-8">
        <h1 class="text-4xl font-bold mb-4">Ghostty Configuration Files</h1>
        <p>Comprehensive terminal environment setup with 2025 optimizations.</p>
        <a href="/installation/" class="mt-4 inline-block bg-blue-500 text-white px-4 py-2 rounded">Get Started</a>
    </main>
</BaseLayout>
EOF

    echo -e "${GREEN}Basic pages created${NC}"
}

# ============================================================================
# Build and Deploy
# ============================================================================

build_site() {
    echo -e "${CYAN}Building Astro site...${NC}"

    if [[ ! -f "$ASTRO_PROJECT_DIR/package.json" ]]; then
        echo -e "${YELLOW}No package.json found, run generate first${NC}"
        return 1
    fi

    cd "$ASTRO_PROJECT_DIR"
    npm install
    npm run build

    # Ensure .nojekyll exists (CRITICAL for GitHub Pages)
    touch "$DOCS_DIR/.nojekyll"

    echo -e "${GREEN}Site built successfully${NC}"
    echo -e "${BLUE}Output: $DOCS_DIR${NC}"
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat << EOF
Astro.build Documentation Generator (Modular Orchestrator)

Usage:
  $0 [generate|build|dev|help]

Commands:
  generate    Create Astro.build project structure (default)
  build       Build the Astro site for production
  dev         Start development server
  help        Show this help message

Modules Used:
  lib/docs/markdown_generator.sh  - HTML generation utilities
  lib/docs/index_builder.sh       - Index and navigation
  lib/docs/asset_compiler.sh      - CSS/JS asset handling

Output:
  docs-site/    Astro.build project
  docs/         Built static site (for GitHub Pages)
EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Source modules
    source_docs_modules

    case "${1:-generate}" in
        generate)
            create_astro_project
            create_basic_pages

            # Use modular asset compiler if available
            if declare -f compile_all_assets &>/dev/null; then
                compile_all_assets "$DOCS_DIR"
            fi

            # Generate index using module if available
            if declare -f generate_index_page &>/dev/null; then
                generate_index_page "$DOCS_DIR"
            fi

            echo -e "${GREEN}Documentation site generated${NC}"
            echo -e "${BLUE}Build with: cd docs-site && npm install && npm run build${NC}"
            ;;
        build)
            build_site
            ;;
        dev)
            cd "$ASTRO_PROJECT_DIR"
            npm install
            npm run dev
            ;;
        help|*)
            show_help
            ;;
    esac
}

main "$@"
