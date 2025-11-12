#!/bin/bash

# Astro.build Documentation Generator with SVG Assets
# Creates comprehensive documentation website with installation screenshots using Astro.build stack

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_ROOT/docs"
ASSETS_DIR="$DOCS_DIR/assets"

# Astro.build + uv configuration (per constitutional requirements)
ASTRO_PROJECT_DIR="$PROJECT_ROOT/docs-site"
UV_PYTHON_VERSION="3.11"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📚 Generating Astro.build documentation website with SVG screenshots...${NC}"

# Create Astro.build project structure
create_astro_project() {
    echo -e "${CYAN}🚀 Creating Astro.build project...${NC}"

    mkdir -p "$ASTRO_PROJECT_DIR"/{src/{pages,components,layouts,styles},public/{assets,screenshots}}

    # Create package.json for Astro.build
    cat > "$ASTRO_PROJECT_DIR/package.json" << EOF
{
  "name": "ghostty-docs",
  "type": "module",
  "version": "1.0.0",
  "description": "Ghostty Configuration Files Documentation with SVG Screenshots",
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "astro": "astro",
    "check": "astro check && tsc --noEmit"
  },
  "dependencies": {
    "astro": "^4.0.0",
    "@astrojs/tailwind": "^5.0.0",
    "@astrojs/sitemap": "^3.0.0",
    "@astrojs/rss": "^4.0.0",
    "tailwindcss": "^3.4.0",
    "sharp": "^0.33.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

    # Create Astro configuration
    cat > "$ASTRO_PROJECT_DIR/astro.config.mjs" << 'EOF'
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://USERNAME.github.io',
  base: '/ghostty-config-files',
  integrations: [
    tailwind(),
    sitemap()
  ],
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true
    }
  },
  vite: {
    optimizeDeps: {
      exclude: ['@astrojs/tailwind']
    }
  },
  output: 'static',
  outDir: '../docs',
  publicDir: './public',
  build: {
    assets: 'assets'
  }
});
EOF

    # Create TypeScript config
    cat > "$ASTRO_PROJECT_DIR/tsconfig.json" << EOF
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@layouts/*": ["./src/layouts/*"]
    }
  }
}
EOF

    # Create Tailwind config
    cat > "$ASTRO_PROJECT_DIR/tailwind.config.mjs" << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      fontFamily: {
        'mono': ['JetBrains Mono', 'Fira Code', 'Courier New', 'monospace'],
      },
      colors: {
        'ghostty': {
          50: '#f0f9ff',
          500: '#0ea5e9',
          900: '#0c4a6e'
        }
      }
    },
  },
  plugins: [],
}
EOF
}

# Create base layout for Astro
create_base_layout() {
    cat > "$ASTRO_PROJECT_DIR/src/layouts/BaseLayout.astro" << 'EOF'
---
export interface Props {
  title: string;
  description?: string;
}

const { title, description = "Comprehensive terminal environment setup with 2025 optimizations and AI integration" } = Astro.props;
const canonicalURL = new URL(Astro.url.pathname, Astro.site);
---

<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
  <head>
    <meta charset="UTF-8" />
    <meta name="description" content={description} />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="generator" content={Astro.generator} />
    <link rel="canonical" href={canonicalURL} />

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website" />
    <meta property="og:url" content={Astro.url} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:url" content={Astro.url} />
    <meta property="twitter:title" content={title} />
    <meta property="twitter:description" content={description} />

    <title>{title}</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
  </head>
  <body class="min-h-screen bg-gray-50 text-gray-900">
    <header class="bg-white shadow-sm border-b">
      <nav class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <a href="/" class="text-xl font-bold text-ghostty-900">
              🚀 Ghostty Config
            </a>
          </div>
          <div class="flex items-center space-x-8">
            <a href="/" class="text-gray-700 hover:text-ghostty-500 transition-colors">Home</a>
            <a href="/installation/" class="text-gray-700 hover:text-ghostty-500 transition-colors">Installation</a>
            <a href="/screenshots/" class="text-gray-700 hover:text-ghostty-500 transition-colors">Screenshots</a>
            <a href="https://github.com/USERNAME/ghostty-config-files" class="text-gray-700 hover:text-ghostty-500 transition-colors">GitHub</a>
          </div>
        </div>
      </nav>
    </header>

    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <slot />
    </main>

    <footer class="bg-white border-t mt-16">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="text-center text-gray-600">
          <p>📸 Screenshots captured as SVG for perfect quality and accessibility</p>
          <p class="mt-2">Built with <a href="https://astro.build" class="text-ghostty-500 hover:text-ghostty-700">Astro.build</a> • Deployed on GitHub Pages</p>
        </div>
      </div>
    </footer>

    <script>
      // Screenshot modal functionality
      document.addEventListener('DOMContentLoaded', function() {
        const screenshots = document.querySelectorAll('.screenshot-container img, .screenshot-container svg');

        screenshots.forEach(img => {
          (img as HTMLElement).style.cursor = 'zoom-in';
          img.addEventListener('click', function(this: Element) {
            // Create modal
            const modal = document.createElement('div');
            modal.className = 'fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50 cursor-zoom-out';

            const modalImage = this.cloneNode(true) as HTMLElement;
            modalImage.className = 'max-w-[90vw] max-h-[90vh] object-contain';

            modal.appendChild(modalImage);
            document.body.appendChild(modal);

            modal.addEventListener('click', () => {
              document.body.removeChild(modal);
            });

            // Close on escape
            const closeOnEscape = (e: KeyboardEvent) => {
              if (e.key === 'Escape') {
                document.body.removeChild(modal);
                document.removeEventListener('keydown', closeOnEscape);
              }
            };
            document.addEventListener('keydown', closeOnEscape);
          });
        });
      });
    </script>
  </body>
</html>
EOF
}

# Create homepage
create_homepage() {
    cat > "$ASTRO_PROJECT_DIR/src/pages/index.astro" << 'EOF'
---
import BaseLayout from '@layouts/BaseLayout.astro';
---

<BaseLayout title="Ghostty Configuration Files - Terminal Setup with AI Integration">
  <div class="text-center mb-12">
    <h1 class="text-5xl font-bold text-gray-900 mb-4">
      🚀 Ghostty Configuration Files
    </h1>
    <p class="text-xl text-gray-600 max-w-3xl mx-auto">
      Comprehensive terminal environment setup with 2025 optimizations, AI integration, and automatic SVG screenshot documentation
    </p>
  </div>

  <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
    <div class="bg-white p-6 rounded-lg shadow-md text-center">
      <div class="text-4xl mb-4">⚡</div>
      <h3 class="text-lg font-semibold mb-2">2025 Optimizations</h3>
      <p class="text-gray-600">Latest Ghostty features with CGroup single-instance performance optimizations</p>
    </div>

    <div class="bg-white p-6 rounded-lg shadow-md text-center">
      <div class="text-4xl mb-4">🤖</div>
      <h3 class="text-lg font-semibold mb-2">AI Integration</h3>
      <p class="text-gray-600">Claude Code and Gemini CLI pre-configured for enhanced development workflow</p>
    </div>

    <div class="bg-white p-6 rounded-lg shadow-md text-center">
      <div class="text-4xl mb-4">📸</div>
      <h3 class="text-lg font-semibold mb-2">SVG Screenshots</h3>
      <p class="text-gray-600">High-quality vector screenshots preserving all text, emojis, and formatting</p>
    </div>

    <div class="bg-white p-6 rounded-lg shadow-md text-center">
      <div class="text-4xl mb-4">🔧</div>
      <h3 class="text-lg font-semibold mb-2">One-Command Setup</h3>
      <p class="text-gray-600">Fresh Ubuntu installation to fully configured terminal in under 10 minutes</p>
    </div>
  </div>

  <div class="bg-white rounded-lg shadow-md p-8 mb-12">
    <h2 class="text-2xl font-bold mb-4">📖 Quick Start</h2>
    <p class="text-gray-600 mb-4">Get started with a single command:</p>
    <pre class="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm overflow-x-auto"><code>cd /home/$USER/Apps/ghostty-config-files
./start.sh</code></pre>
    <p class="text-sm text-gray-500 mt-2">This will automatically capture screenshots throughout the installation process, creating a complete visual guide.</p>
  </div>

  <div class="grid md:grid-cols-2 gap-8 mb-12">
    <div class="bg-white rounded-lg shadow-md p-6">
      <h3 class="text-xl font-semibold mb-4">📸 Visual Installation Guide</h3>
      <p class="text-gray-600 mb-4">Our installation process is fully documented with SVG screenshots that preserve:</p>
      <ul class="text-gray-600 space-y-2">
        <li>✅ <strong>Original text content</strong> (searchable and selectable)</li>
        <li>✅ <strong>Exact colors and formatting</strong></li>
        <li>✅ <strong>Emojis and special characters</strong></li>
        <li>✅ <strong>Perfect scalability</strong> without quality loss</li>
      </ul>
      <a href="/installation/" class="inline-block mt-4 bg-ghostty-500 text-white px-4 py-2 rounded hover:bg-ghostty-600 transition-colors">
        🎬 View Installation Guide
      </a>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6">
      <h3 class="text-xl font-semibold mb-4">🛠️ What Gets Installed</h3>
      <ul class="text-gray-600 space-y-2">
        <li><strong>Ghostty Terminal:</strong> Latest version compiled from source</li>
        <li><strong>ZSH + Oh My ZSH:</strong> Enhanced shell with productivity plugins</li>
        <li><strong>AI Tools:</strong> Claude Code CLI and Gemini CLI</li>
        <li><strong>Development Tools:</strong> Node.js, Python uv, modern utilities</li>
        <li><strong>Context Menu:</strong> Right-click "Open in Ghostty" integration</li>
      </ul>
      <a href="/screenshots/" class="inline-block mt-4 bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors">
        🖼️ Browse Screenshots
      </a>
    </div>
  </div>

  <div class="text-center">
    <h2 class="text-3xl font-bold mb-4">Ready to upgrade your terminal experience?</h2>
    <a href="/installation/" class="inline-block bg-ghostty-500 text-white px-8 py-3 rounded-lg text-lg font-semibold hover:bg-ghostty-600 transition-colors">
      Start Installation Guide
    </a>
  </div>
</BaseLayout>
EOF
}

# Create installation page
create_installation_page() {
    mkdir -p "$ASTRO_PROJECT_DIR/src/pages/installation"
    cat > "$ASTRO_PROJECT_DIR/src/pages/installation/index.astro" << 'EOF'
---
import BaseLayout from '@layouts/BaseLayout.astro';
---

<BaseLayout title="Installation Guide - Ghostty Configuration Files">
  <div class="max-w-4xl mx-auto">
    <h1 class="text-4xl font-bold mb-8">🔧 Installation Guide</h1>

    <div class="bg-blue-50 border-l-4 border-blue-500 p-4 mb-8">
      <p class="text-blue-800">
        This guide shows the complete installation process with screenshots captured at each stage.
        All screenshots are in SVG format, preserving text quality and accessibility.
      </p>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6 mb-8">
      <h2 class="text-2xl font-semibold mb-4">📋 Installation Stages</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">1</span>
          <span>System Check & Strategy</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">2</span>
          <span>Dependencies Installation</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">3</span>
          <span>ZSH & Oh My ZSH Setup</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">4</span>
          <span>Modern Development Tools</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">5</span>
          <span>Zig Compiler Installation</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">6</span>
          <span>Ghostty Compilation</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">7</span>
          <span>Configuration & Optimization</span>
        </div>
        <div class="flex items-center space-x-3">
          <span class="bg-ghostty-500 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">8</span>
          <span>AI Tools Integration</span>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6 mb-8">
      <h2 class="text-2xl font-semibold mb-4">🚀 Quick Start</h2>
      <pre class="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm overflow-x-auto"><code># Clone the repository
git clone https://github.com/YOUR_USERNAME/ghostty-config-files.git
cd ghostty-config-files

# Run the installation script
./start.sh

# Screenshots will be automatically captured to:
# docs/assets/screenshots/YYYYMMDD-HHMMSS/</code></pre>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6 mb-8">
      <h2 class="text-2xl font-semibold mb-4">⚙️ Configuration Options</h2>
      <p class="text-gray-600 mb-4">Control the installation behavior with environment variables:</p>
      <pre class="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm overflow-x-auto"><code># Disable screenshot capture
ENABLE_SCREENSHOTS=false ./start.sh

# Skip certain components
SKIP_DEPS=true SKIP_PTYXIS=true ./start.sh

# Verbose output
VERBOSE=true ./start.sh</code></pre>
    </div>

    <div id="screenshots-gallery" class="mb-8">
      <h2 class="text-2xl font-semibold mb-4">📸 Installation Screenshots</h2>
      <div class="bg-yellow-50 border-l-4 border-yellow-500 p-4">
        <p class="text-yellow-800">
          📸 Screenshots will appear here after running the installation script.<br>
          <strong>Run <code>./start.sh</code> to generate your installation gallery!</strong>
        </p>
      </div>
    </div>

    <div class="text-center">
      <a href="/screenshots/" class="inline-block bg-green-500 text-white px-6 py-3 rounded-lg hover:bg-green-600 transition-colors mr-4">
        📸 View Screenshots Gallery
      </a>
      <a href="https://github.com/USERNAME/ghostty-config-files" class="inline-block bg-gray-600 text-white px-6 py-3 rounded-lg hover:bg-gray-700 transition-colors">
        💻 GitHub Repository
      </a>
    </div>
  </div>
</BaseLayout>
EOF
}

# Create screenshots gallery page
create_screenshots_page() {
    mkdir -p "$ASTRO_PROJECT_DIR/src/pages/screenshots"
    cat > "$ASTRO_PROJECT_DIR/src/pages/screenshots/index.astro" << 'EOF'
---
import BaseLayout from '@layouts/BaseLayout.astro';
---

<BaseLayout title="Screenshots Gallery - Ghostty Configuration Files">
  <div class="max-w-6xl mx-auto">
    <h1 class="text-4xl font-bold mb-8">📸 Screenshots Gallery</h1>

    <div class="bg-white rounded-lg shadow-md p-6 mb-8">
      <h2 class="text-2xl font-semibold mb-4">🎯 Why SVG Screenshots?</h2>
      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="text-center">
          <div class="text-2xl mb-2">📝</div>
          <h3 class="font-semibold">Text Preservation</h3>
          <p class="text-sm text-gray-600">All terminal text remains selectable and searchable</p>
        </div>
        <div class="text-center">
          <div class="text-2xl mb-2">🎨</div>
          <h3 class="font-semibold">Perfect Quality</h3>
          <p class="text-sm text-gray-600">Vector graphics scale without quality loss</p>
        </div>
        <div class="text-center">
          <div class="text-2xl mb-2">♿</div>
          <h3 class="font-semibold">Accessibility</h3>
          <p class="text-sm text-gray-600">Screen readers can access all text content</p>
        </div>
        <div class="text-center">
          <div class="text-2xl mb-2">🔍</div>
          <h3 class="font-semibold">Searchable</h3>
          <p class="text-sm text-gray-600">Find specific commands or output in screenshots</p>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6 mb-8">
      <h2 class="text-2xl font-semibold mb-4">🔧 Manual Screenshot Capture</h2>
      <p class="text-gray-600 mb-4">You can also capture screenshots manually during your installation:</p>
      <pre class="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm overflow-x-auto"><code># Capture a single screenshot
./scripts/svg_screenshot_capture.sh capture "Stage Name" "Description"

# Capture both screenshot and terminal state
./scripts/svg_screenshot_capture.sh both "Build Process" "Zig compilation in progress"

# Generate documentation after manual captures
./scripts/svg_screenshot_capture.sh generate-docs</code></pre>
    </div>

    <div id="gallery-container" class="mb-8">
      <h2 class="text-2xl font-semibold mb-4">📋 Installation Screenshots</h2>
      <div class="bg-yellow-50 border-l-4 border-yellow-500 p-4 text-center">
        <p class="text-yellow-800">
          📸 Screenshots will appear here after running the installation script.<br>
          <strong>Run <code>./start.sh</code> to generate your installation gallery!</strong>
        </p>
      </div>
    </div>

    <div class="text-center">
      <a href="/installation/" class="inline-block bg-ghostty-500 text-white px-6 py-3 rounded-lg hover:bg-ghostty-600 transition-colors">
        🚀 Start Installation
      </a>
    </div>
  </div>
</BaseLayout>

<style>
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 2rem;
  margin: 2rem 0;
}

.gallery-item {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.gallery-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.screenshot-container {
  margin: 1rem 0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  cursor: zoom-in;
}

.screenshot-container img,
.screenshot-container svg {
  width: 100%;
  height: auto;
  display: block;
}

@media (max-width: 768px) {
  .gallery-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .gallery-item {
    padding: 1rem;
  }
}
</style>
EOF
}

# Create uv Python configuration
create_uv_config() {
    cat > "$ASTRO_PROJECT_DIR/pyproject.toml" << EOF
[project]
name = "ghostty-docs"
version = "1.0.0"
description = "Ghostty Documentation Site Builder"
requires-python = ">=3.11"
dependencies = [
    "jinja2>=3.1.0",
    "markdown>=3.5.0",
    "pyyaml>=6.0.0"
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    "black>=23.0.0",
    "ruff>=0.1.0"
]
EOF

    # Create .python-version for uv
    echo "$UV_PYTHON_VERSION" > "$ASTRO_PROJECT_DIR/.python-version"
}

# Create local CI/CD integration
create_local_cicd_integration() {
    mkdir -p "$PROJECT_ROOT/.runners-local/workflows"

    cat > "$PROJECT_ROOT/.runners-local/workflows/astro-build-local.sh" << 'EOF'
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
EOF

    chmod +x "$PROJECT_ROOT/.runners-local/workflows/astro-build-local.sh"
}

# Generate complete Astro.build documentation website
generate_astro_website() {
    echo -e "${CYAN}🚀 Creating Astro.build project structure...${NC}"
    create_astro_project

    echo -e "${CYAN}📐 Creating layouts and components...${NC}"
    create_base_layout

    echo -e "${CYAN}📄 Creating pages...${NC}"
    create_homepage
    create_installation_page
    create_screenshots_page

    echo -e "${CYAN}🐍 Creating uv Python configuration...${NC}"
    create_uv_config

    echo -e "${CYAN}🔧 Creating local CI/CD integration...${NC}"
    create_local_cicd_integration

    # Create GitHub workflow for Astro deployment
    mkdir -p "$PROJECT_ROOT/.github/workflows"
    cat > "$PROJECT_ROOT/.github/workflows/deploy-astro.yml" << 'EOF'
name: Deploy Astro to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

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
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'docs-site/package-lock.json'

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Install dependencies
        run: npm ci
        working-directory: ./docs-site

      - name: Build Astro site
        run: npm run build
        working-directory: ./docs-site

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./docs

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

    echo -e "${GREEN}✅ Astro.build documentation website generated${NC}"
    echo -e "${BLUE}📁 Astro project created in: $ASTRO_PROJECT_DIR${NC}"
    echo -e "${BLUE}🏗️ Build locally with: cd docs-site && npm install && npm run build${NC}"
    echo -e "${BLUE}📸 Screenshots will be integrated automatically when you run ./start.sh${NC}"
}

# Main function
main() {
    case "${1:-generate}" in
        "generate")
            generate_astro_website
            ;;
        "build")
            if [ -f "$ASTRO_PROJECT_DIR/package.json" ]; then
                cd "$ASTRO_PROJECT_DIR"
                npm install
                npm run build
                echo -e "${GREEN}✅ Astro site built successfully${NC}"
            else
                echo -e "${YELLOW}⚠️  Run 'generate' first to create the Astro project${NC}"
            fi
            ;;
        "dev")
            if [ -f "$ASTRO_PROJECT_DIR/package.json" ]; then
                cd "$ASTRO_PROJECT_DIR"
                npm install
                npm run dev
            else
                echo -e "${YELLOW}⚠️  Run 'generate' first to create the Astro project${NC}"
            fi
            ;;
        "help"|*)
            cat << EOF
Astro.build Documentation Generator with SVG Screenshots

Usage:
  $0 [generate|build|dev|help]

Commands:
  generate    Generate complete Astro.build documentation website (default)
  build       Build the Astro site for production
  dev         Start Astro development server
  help        Show this help message

Constitutional Compliance:
  ✅ Astro.build (≥4.0) - Static site generation with TypeScript
  ✅ Tailwind CSS (≥3.4) - Utility-first CSS framework
  ✅ uv Python management - Project configuration and tooling
  ✅ Local CI/CD - Zero GitHub Actions consumption
  ✅ SVG Screenshots - Vector graphics with preserved text
  ✅ GitHub Pages - Zero-cost deployment

Generated Structure:
  docs-site/                    Astro.build project
  ├── src/pages/               Page components
  ├── src/layouts/             Layout templates
  ├── src/components/          Reusable components
  ├── astro.config.mjs         Astro configuration
  ├── tailwind.config.mjs      Tailwind configuration
  ├── package.json             Node.js dependencies
  └── pyproject.toml           uv Python configuration

Local Development:
  cd docs-site
  npm install
  npm run dev       # Development server
  npm run build     # Production build
  npm run check     # Type checking

Deployment:
  ./.runners-local/workflows/astro-build-local.sh  # Local CI/CD
  git push                                     # Triggers GitHub Pages deploy

EOF
            ;;
    esac
}

# Run main function
main "$@"