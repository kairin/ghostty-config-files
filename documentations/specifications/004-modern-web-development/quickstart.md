# Quickstart Guide: Modern Web Development Stack

**Feature**: Modern Web Development Stack
**Prerequisites**: Ubuntu 20.04+, Git, basic command line knowledge
**Duration**: 15-20 minutes
**Outcome**: Fully configured modern web development environment

## Overview

This quickstart guide sets up a complete modern web development stack featuring:
- **uv** (≥0.4.0) for Python dependency management
- **Astro.build** (≥4.0) for static site generation
- **Tailwind CSS** (≥3.4) + **shadcn/ui** for component-driven UI
- **Local CI/CD infrastructure** with zero GitHub Actions consumption
- **GitHub Pages** deployment with 95+ Lighthouse scores

## Prerequisites Verification

```bash
# Verify system requirements
lsb_release -a                    # Ubuntu 20.04+ required
git --version                     # Git 2.25+ required
curl --version                    # For downloading tools
which node || echo "Node.js will be installed"
```

## Step 1: Environment Setup

### Install uv (Python Package Manager)
```bash
# Install uv (latest version)
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc

# Verify installation
uv --version                      # Should be ≥0.4.0
```

### Install Node.js (for Astro and tooling)
```bash
# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version                    # Should be 18.x LTS or higher
npm --version
```

### Install GitHub CLI
```bash
# Install GitHub CLI for local CI/CD simulation
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate with GitHub
gh auth login
```

## Step 2: Project Initialization

### Create Project Directory
```bash
# Create and navigate to project directory
mkdir -p ~/Projects/my-modern-web-app
cd ~/Projects/my-modern-web-app

# Initialize git repository
git init
git branch -M main
```

### Setup Python Environment with uv
```bash
# Create Python project with uv
uv init --python 3.12
uv add --dev ruff black mypy

# Verify Python environment
uv run python --version          # Should be 3.12+
uv pip list                       # Show installed packages
```

### Initialize Astro Project
```bash
# Create Astro project with TypeScript
npm create astro@latest . -- --template minimal --typescript strict --yes

# Install additional dependencies
npm install @tailwindcss/typography @tailwindcss/forms @tailwindcss/aspect-ratio
npm install @astrojs/tailwind @astrojs/sitemap @astrojs/rss

# Install dev dependencies
npm install --save-dev @types/node prettier prettier-plugin-astro
```

## Step 3: Configure Tailwind CSS + shadcn/ui

### Setup Tailwind CSS
```bash
# Initialize Tailwind CSS
npx tailwindcss init -p

# Install Tailwind CSS integration for Astro
npx astro add tailwind
```

### Configure shadcn/ui
```bash
# Initialize shadcn/ui
npx shadcn-ui@latest init

# Configure components.json
cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.mjs",
    "css": "src/styles/globals.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "src/components",
    "utils": "src/lib/utils"
  }
}
EOF

# Install first components
npx shadcn-ui@latest add button card
npx shadcn-ui@latest add navigation-menu dropdown-menu
```

## Step 4: Local CI/CD Infrastructure Setup

### Create Local CI/CD Directory Structure
```bash
# Create local infrastructure directories
mkdir -p local-infra/{runners,logs,config}
mkdir -p local-infra/config/{workflows,test-suites}
```

### Setup Local CI/CD Runners
```bash
# Create main local workflow runner
cat > local-infra/runners/gh-workflow-local.sh << 'EOF'
#!/bin/bash
set -euo pipefail

LOG_DIR="./local-infra/logs"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

log_with_timestamp() {
    echo "$(date -Iseconds) $1" | tee -a "$LOG_DIR/workflow-$TIMESTAMP.log"
}

case "${1:-all}" in
    "validate")
        log_with_timestamp "🔍 Validating configuration..."
        uv run python --version
        npm run build -- --dry-run
        npx astro check
        ;;
    "test")
        log_with_timestamp "🧪 Running tests..."
        npm run lint
        npm run type-check
        uv run ruff check .
        uv run mypy .
        ;;
    "build")
        log_with_timestamp "🏗️ Building project..."
        npm run build
        uv run python scripts/optimize-assets.py
        ;;
    "performance")
        log_with_timestamp "📊 Performance testing..."
        npm run build
        # Lighthouse CI would go here
        ;;
    "all"|"local")
        log_with_timestamp "🚀 Running complete local CI/CD workflow..."
        $0 validate && $0 test && $0 build && $0 performance
        ;;
    "status")
        gh run list --limit 5 --json status,conclusion,name,createdAt
        ;;
esac
EOF

chmod +x local-infra/runners/gh-workflow-local.sh
```

### Create Performance Monitor
```bash
cat > local-infra/runners/performance-monitor.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +"%s")
LOG_FILE="./local-infra/logs/performance-$TIMESTAMP.json"

measure_build_performance() {
    echo "📊 Measuring build performance..."

    start_time=$(date +%s%N)
    npm run build > /dev/null 2>&1
    end_time=$(date +%s%N)

    build_time=$(echo "scale=2; ($end_time - $start_time) / 1000000000" | bc)

    # Measure bundle sizes
    if [ -d "dist" ]; then
        js_size=$(find dist -name "*.js" -type f -exec stat -c%s {} + | awk '{sum+=$1} END {print sum}')
        css_size=$(find dist -name "*.css" -type f -exec stat -c%s {} + | awk '{sum+=$1} END {print sum}')
        total_size=$(du -sb dist | cut -f1)
    else
        js_size=0
        css_size=0
        total_size=0
    fi

    # Store metrics
    cat > "$LOG_FILE" << EOF_JSON
{
    "timestamp": "$(date -Iseconds)",
    "build_time_seconds": $build_time,
    "bundle_sizes": {
        "javascript_bytes": $js_size,
        "css_bytes": $css_size,
        "total_bytes": $total_size
    },
    "thresholds": {
        "build_time_target": 30,
        "js_size_limit": 102400,
        "performance_score_target": 95
    }
}
EOF_JSON

    echo "✅ Performance metrics saved to $LOG_FILE"

    # Check thresholds
    if (( $(echo "$build_time > 30" | bc -l) )); then
        echo "⚠️ Build time ($build_time s) exceeds 30s target"
    fi

    if (( js_size > 102400 )); then
        echo "⚠️ JavaScript bundle ($js_size bytes) exceeds 100KB limit"
    fi
}

case "${1:-measure}" in
    "measure")
        measure_build_performance
        ;;
    "report")
        echo "📊 Performance Report"
        echo "===================="
        if [ -f "$LOG_FILE" ]; then
            jq -r '
                "Build Time: " + (.build_time_seconds | tostring) + "s",
                "JS Bundle: " + ((.bundle_sizes.javascript_bytes / 1024) | floor | tostring) + "KB",
                "CSS Bundle: " + ((.bundle_sizes.css_bytes / 1024) | floor | tostring) + "KB",
                "Total Size: " + ((.bundle_sizes.total_bytes / 1024) | floor | tostring) + "KB"
            ' "$LOG_FILE"
        fi
        ;;
esac
EOF

chmod +x local-infra/runners/performance-monitor.sh
```

## Step 5: Configure Astro and TypeScript

### Create Astro Configuration
```bash
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://yourusername.github.io',
  base: '/your-repo-name',
  integrations: [
    tailwind({
      applyBaseStyles: false,
    }),
    sitemap(),
  ],
  build: {
    inlineStylesheets: 'auto',
  },
  vite: {
    build: {
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['astro'],
          },
        },
      },
    },
  },
});
EOF
```

### Configure TypeScript
```bash
cat > tsconfig.json << 'EOF'
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/components/*": ["src/components/*"],
      "@/lib/*": ["src/lib/*"]
    }
  }
}
EOF
```

### Create Package.json Scripts
```bash
# Add scripts to package.json
npm pkg set scripts.dev="astro dev"
npm pkg set scripts.build="astro build"
npm pkg set scripts.preview="astro preview"
npm pkg set scripts.lint="eslint src --ext ts,tsx,astro"
npm pkg set scripts.type-check="astro check && tsc --noEmit"
npm pkg set scripts.format="prettier --write src"
npm pkg set scripts.ci-local="./local-infra/runners/gh-workflow-local.sh all"
```

## Step 6: Create Sample Components and Pages

### Create Global Styles
```bash
mkdir -p src/styles
cat > src/styles/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF
```

### Create Sample Layout
```bash
mkdir -p src/layouts
cat > src/layouts/Layout.astro << 'EOF'
---
export interface Props {
  title: string;
  description?: string;
}

const { title, description = "Modern web development with Astro, Tailwind, and shadcn/ui" } = Astro.props;
---

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="description" content={description} />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <title>{title}</title>
  </head>
  <body>
    <main>
      <slot />
    </main>
    <style is:global>
      @import "../styles/globals.css";
    </style>
  </body>
</html>
EOF
```

### Create Sample Page
```bash
cat > src/pages/index.astro << 'EOF'
---
import Layout from '../layouts/Layout.astro';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
---

<Layout title="Modern Web Development Stack">
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-12">
        <h1 class="text-4xl font-bold tracking-tight mb-4">
          Modern Web Development Stack
        </h1>
        <p class="text-xl text-muted-foreground mb-8">
          Built with Astro, Tailwind CSS, shadcn/ui, and uv for Python
        </p>
        <Button size="lg" class="mr-4">
          Get Started
        </Button>
        <Button variant="outline" size="lg">
          View Documentation
        </Button>
      </div>

      <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>⚡ Lightning Fast</CardTitle>
            <CardDescription>
              Built with Astro's islands architecture for optimal performance
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p>Achieve 95+ Lighthouse scores with minimal JavaScript bundles and static site generation.</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>🎨 Beautiful UI</CardTitle>
            <CardDescription>
              shadcn/ui components with Tailwind CSS styling
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p>Accessible, themeable components with dark mode support and consistent design tokens.</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>🔧 Developer Experience</CardTitle>
            <CardDescription>
              Modern tooling with TypeScript and local CI/CD
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p>Hot module replacement, strict TypeScript, and comprehensive local validation workflows.</p>
          </CardContent>
        </Card>
      </div>
    </div>
  </div>
</Layout>
EOF
```

## Step 7: Local CI/CD Validation

### Run Initial Validation
```bash
# Test local CI/CD workflow
./local-infra/runners/gh-workflow-local.sh validate

# Run complete local workflow
./local-infra/runners/gh-workflow-local.sh all

# Check performance metrics
./local-infra/runners/performance-monitor.sh measure
./local-infra/runners/performance-monitor.sh report
```

### Test Development Server
```bash
# Start development server
npm run dev

# In another terminal, test the build
npm run build
npm run preview
```

## Step 8: GitHub Repository Setup

### Create GitHub Repository
```bash
# Create repository (replace with your details)
gh repo create my-modern-web-app --public --description "Modern web development stack with Astro, Tailwind CSS, and shadcn/ui"

# Add remote and push
git remote add origin https://github.com/yourusername/my-modern-web-app.git
git add .
git commit -m "Initial setup: Modern web development stack

- uv Python environment with strict typing
- Astro.build with TypeScript strict mode
- Tailwind CSS + shadcn/ui integration
- Local CI/CD infrastructure
- Performance monitoring and validation

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin main
```

### Configure GitHub Pages
```bash
# Enable GitHub Pages
gh api repos/:owner/:repo --method PATCH --field "has_pages=true"

# Configure Pages settings
gh api repos/:owner/:repo/pages --method POST \
  --field "source[branch]=main" \
  --field "source[path]=/docs"
```

## Step 9: Verification and Testing

### Performance Validation
```bash
# Build and test performance
npm run build

# Check bundle sizes
ls -la dist/
du -sh dist/

# Verify Lighthouse scores (manual step)
echo "Manual step: Test with Lighthouse extension in browser"
echo "Target: 95+ scores for Performance, Accessibility, Best Practices, SEO"
```

### Local CI/CD Verification
```bash
# Verify all workflows pass
./local-infra/runners/gh-workflow-local.sh all

# Check logs
ls -la local-infra/logs/
cat local-infra/logs/workflow-*.log
```

### GitHub Actions Cost Verification
```bash
# Check GitHub Actions usage (should be 0)
gh api user/settings/billing/actions
```

## Troubleshooting

### Common Issues

**uv installation fails:**
```bash
# Retry with explicit shell source
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Node.js version conflicts:**
```bash
# Use Node Version Manager
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm use --lts
```

**shadcn/ui component issues:**
```bash
# Regenerate components.json
rm components.json
npx shadcn-ui@latest init
```

**Build failures:**
```bash
# Clear caches and reinstall
rm -rf node_modules dist .astro
npm install
npm run build
```

## Next Steps

1. **Customize Configuration**: Modify `astro.config.mjs`, `tailwind.config.mjs`, and `components.json`
2. **Add More Components**: Install additional shadcn/ui components as needed
3. **Configure CI/CD**: Enhance local workflows in `local-infra/runners/`
4. **Performance Optimization**: Use the performance monitor to track and improve metrics
5. **Deploy**: Push to GitHub and verify GitHub Pages deployment

## Success Criteria

✅ **Environment Setup**: uv ≥0.4.0, Node.js LTS, GitHub CLI installed
✅ **Project Structure**: Astro + TypeScript + Tailwind + shadcn/ui configured
✅ **Local CI/CD**: All workflows pass locally before GitHub deployment
✅ **Performance**: Build time <30s, JavaScript bundle <100KB
✅ **GitHub Integration**: Repository created, Pages configured
✅ **Zero Cost**: No GitHub Actions consumption for routine operations

Your modern web development stack is now ready for productive development!