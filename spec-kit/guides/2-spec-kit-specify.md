# Spec-Kit `/specify` Command Guide

> 🔧 **Purpose**: Define detailed technical specifications for each component of the uv + Astro + GitHub Pages stack

## 📋 Complete `/specify` Prompt

Use this exact prompt with the `/specify` command:

```
Create comprehensive technical specifications for each component of our stack:

PYTHON ENVIRONMENT SPECIFICATION:
- uv version: Latest stable (>= 0.4.0)
- Python version: 3.12+ (managed by uv)
- Virtual environment location: .venv/ in project root
- Dependency file: pyproject.toml with uv-specific configurations
- Development dependencies: separate dev group in pyproject.toml
- Script management: uv run for all Python script execution
- Lock file: uv.lock for reproducible builds

ASTRO FRAMEWORK SPECIFICATION:
- Astro version: Latest stable (>= 4.0)
- Build target: Static site generation (SSG)
- Output directory: dist/
- TypeScript: Strict mode enabled
- Integration requirements:
  - @astrojs/tailwind for Tailwind CSS
  - @astrojs/node for server-side features if needed
  - @astrojs/sitemap for SEO
  - @astrojs/rss for content feeds

TAILWIND CSS SPECIFICATION:
- Tailwind version: Latest stable (>= 3.4)
- Configuration: Custom design system in tailwind.config.mjs
- Plugins: @tailwindcss/typography, @tailwindcss/forms
- Purge strategy: Automatic unused CSS removal
- Dark mode: Class-based dark mode support
- Custom utilities: Project-specific utility classes

SHADCN/UI SPECIFICATION:
- Component library: shadcn/ui (latest)
- Base components: Button, Card, Input, Select, Dialog, Toast
- Styling: Tailwind CSS integration
- Accessibility: ARIA compliance for all components
- Theming: CSS variables for consistent design tokens
- Icon system: Lucide React icons

GITHUB PAGES SPECIFICATION:
- Deployment branch: gh-pages (auto-generated)
- Build process: GitHub Actions workflow
- Custom domain: Optional CNAME support
- HTTPS: Enforced via GitHub settings
- SPA routing: 404.html fallback for client routing
- Asset optimization: Compressed images and minified CSS/JS

GITHUB CLI SPECIFICATION:
- gh CLI version: Latest stable
- Repository setup: Automated repo creation and configuration
- Pages enablement: gh api repos/{owner}/{repo}/pages
- Workflow triggers: Push to main branch
- Secret management: Environment variables for builds
- Issue templates: Bug reports and feature requests

LOCAL CI/CD INFRASTRUCTURE SPECIFICATION:
- local-infra/ directory with complete runner scripts
- Astro build simulation: ./local-infra/runners/astro-build-local.sh
- GitHub Actions simulation: ./local-infra/runners/gh-workflow-local.sh
- Performance monitoring: ./local-infra/runners/performance-monitor.sh
- Git hooks: pre-commit, pre-push, post-merge automation
- Logging system: Timestamped logs in ./local-infra/logs/
- Zero-cost compliance monitoring and validation

PROJECT STRUCTURE SPECIFICATION:
```
project-root/
├── .venv/                  # uv virtual environment
├── src/                    # Astro source files
│   ├── components/         # Reusable Astro components
│   ├── layouts/           # Page layouts
│   ├── pages/             # File-based routing
│   ├── styles/            # Global CSS and Tailwind
│   └── lib/               # Utility functions
├── public/                # Static assets
├── components/            # shadcn/ui components
├── dist/                  # Build output (GitHub Pages source)
├── scripts/               # Python automation scripts
├── local-infra/           # MANDATORY: Local CI/CD infrastructure
│   ├── runners/          # Local workflow execution scripts
│   │   ├── astro-build-local.sh     # Local Astro build simulation
│   │   ├── gh-workflow-local.sh     # GitHub Actions local simulation
│   │   ├── pre-commit-local.sh      # Pre-commit local validation
│   │   ├── performance-monitor.sh   # Local performance testing
│   │   └── deploy-simulation.sh     # Deployment simulation
│   ├── logs/             # Local CI/CD execution logs
│   │   ├── build-TIMESTAMP.log      # Local build logs
│   │   ├── workflow-TIMESTAMP.log   # Workflow execution logs
│   │   ├── performance-TIMESTAMP.json # Performance metrics
│   │   └── errors.log               # Error aggregation
│   └── config/           # Local CI/CD configuration
│       ├── workflow-definitions/    # Local workflow configs
│       └── test-suites/            # Local test configurations
├── pyproject.toml         # Python dependencies and config
├── uv.lock               # Dependency lock file
├── astro.config.mjs      # Astro configuration
├── tailwind.config.mjs   # Tailwind configuration
├── components.json       # shadcn/ui configuration
├── tsconfig.json         # TypeScript configuration
├── .github/workflows/    # GitHub Actions (triggered only after local success)
└── git-hooks/            # MANDATORY: Git hooks for local CI/CD integration
    ├── pre-commit        # Local workflow execution before commit
    ├── pre-push          # Local validation before push
    └── post-merge        # Post-merge local validation
```

LOCAL CI/CD INFRASTRUCTURE SPECIFICATION:
- Local Astro Build Simulation: Complete build process executed locally
- GitHub Actions Local Runner: Simulate exact GitHub Actions environment
- Performance Monitoring: Local Lighthouse and Core Web Vitals testing
- Dependency Security Scanning: Local vulnerability assessment
- Build Artifact Validation: Ensure deploy-ready artifacts
- Zero-Cost Compliance: No GitHub Actions minutes consumed
- Git Hook Integration: Automatic local workflow triggering

PERFORMANCE SPECIFICATIONS:
- Lighthouse score: 95+ across all metrics
- First Contentful Paint: <1.5s
- Largest Contentful Paint: <2.5s
- Cumulative Layout Shift: <0.1
- Bundle size: <100KB initial JavaScript
- Image optimization: Automatic WebP conversion

SECURITY SPECIFICATIONS:
- Dependency vulnerability scanning via uv pip check
- npm audit integration for Node.js dependencies
- Content Security Policy (CSP) headers
- Secure asset delivery via HTTPS
- Environment variable protection
- No secrets in repository commits

DEVELOPMENT ENVIRONMENT SPECIFICATIONS:
- Hot module replacement (HMR) for all file types
- TypeScript strict mode enforcement
- ESLint configuration for code quality
- Prettier for consistent code formatting
- Husky for git hook management
- VS Code workspace configuration
```

## 🎯 Expected Outcomes

After running this `/specify` command, you should have:

### ✅ Technical Blueprints
- **Complete Architecture**: Detailed project structure with all directories
- **Version Requirements**: Specific version constraints for all tools and frameworks
- **Integration Specifications**: Exact configuration requirements for each component
- **Local CI/CD Infrastructure**: Complete specification for zero-cost workflow execution

### ✅ Configuration Templates
- **File Structure**: Clear directory organization with purpose definitions
- **Dependency Management**: Precise uv and npm dependency specifications
- **Build Configuration**: Astro, Tailwind, and TypeScript setup requirements
- **Git Workflow**: Hook integration and branch management specifications

### ✅ Performance Benchmarks
- **Measurable Targets**: Specific metrics for Lighthouse scores and load times
- **Bundle Size Limits**: JavaScript and CSS size constraints
- **Security Standards**: Vulnerability scanning and CSP requirements
- **Monitoring Integration**: Local performance tracking specifications

## 🔗 Next Command

After successfully creating your specifications, proceed to:
**[`/plan`](3-spec-kit-plan.md)** - Create detailed implementation plans

---

**Navigation**: [← Back: /constitution](1-spec-kit-constitution.md) | [Index](SPEC_KIT_INDEX.md) | [Next: /plan →](3-spec-kit-plan.md)