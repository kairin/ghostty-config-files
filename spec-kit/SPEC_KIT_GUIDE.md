# Spec-Kit Project Guide: Python + Astro + GitHub Pages Stack

> 🎯 **Project Vision**: Modern web development stack with Python backend tooling (uv), Astro frontend framework, and zero-cost GitHub Pages deployment with premium UI components.

## 🏗️ Project Architecture Overview

This guide provides comprehensive prompts for spec-kit commands to build a modern development stack featuring:

- **Python Management**: `uv` for all Python dependencies, virtual environments, and package management
- **Frontend Framework**: Astro.build for static site generation with optimal performance
- **Styling System**: Tailwind CSS for utility-first styling
- **Component Library**: shadcn/ui for premium, accessible UI components
- **Deployment**: GitHub Pages with GitHub CLI automation
- **Local CI/CD**: MANDATORY local workflow execution before any GitHub operations
- **Zero-Cost Strategy**: All GitHub Actions workflows simulated locally first
- **Development Experience**: Hot reloading, TypeScript support, and modern tooling

## 📋 Command Execution Order & Prompts

### 1. `/constitution` - Establish Project Principles

**Purpose**: Define the fundamental principles and constraints that will guide all technical decisions.

**Prompt**:
```
Create a project constitution for a modern web development stack with the following core principles:

TECHNOLOGY STACK MANDATES:
- Python dependency management: uv ONLY (no pip, pipenv, poetry, conda)
- Virtual environment management: uv venv ONLY
- Package installation: uv pip install ONLY
- Frontend framework: Astro.build (latest stable version)
- Styling: Tailwind CSS with full utility-first approach
- UI Components: shadcn/ui for all interactive components
- Deployment: GitHub Pages via GitHub CLI automation
- Version Control: Git with conventional commits

PERFORMANCE PRINCIPLES:
- Static site generation (SSG) preferred over client-side rendering
- Minimal JavaScript bundle sizes
- Optimal Core Web Vitals scores
- Fast build times with caching strategies
- Efficient dependency management

DEVELOPMENT EXPERIENCE PRINCIPLES:
- Zero-configuration setup for new developers
- Hot reloading for all file types
- TypeScript-first development
- Automated code formatting and linting
- Comprehensive error handling and logging

DEPLOYMENT PRINCIPLES:
- Zero-cost hosting via GitHub Pages
- LOCAL CI/CD MANDATORY: All workflows MUST run locally before GitHub push
- Branch protection and review requirements
- Semantic versioning for releases
- Environment-specific configurations

LOCAL CI/CD PRINCIPLES (NON-NEGOTIABLE):
- ALL GitHub Actions workflows MUST be simulated locally before push/sync
- MANDATORY local build validation for every commit
- Local testing infrastructure using GitHub CLI simulation
- Zero GitHub Actions minutes consumption for routine operations
- Comprehensive local logging and error handling
- Automated local workflow execution integrated with git hooks

MAINTAINABILITY PRINCIPLES:
- Clear separation of concerns
- Comprehensive documentation
- Automated testing (unit, integration, e2e)
- Security-first dependency management
- Regular dependency updates

Please establish these as non-negotiable principles that will constrain all subsequent technical decisions.
```

### 2. `/specify` - Create Specifications

**Purpose**: Define detailed technical specifications for each component of the stack.

**Prompt**:
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
```

### 3. `/plan` - Create Implementation Plans

**Purpose**: Break down the implementation into manageable phases with clear dependencies.

**Prompt**:
```
Create a detailed implementation plan with phases, dependencies, and success criteria:

PHASE 1: FOUNDATION SETUP (Week 1)
Objective: Establish the core development environment and tooling

Tasks:
1. Repository initialization and GitHub CLI setup
2. uv installation and Python environment configuration
3. pyproject.toml creation with all dependencies
4. Git configuration with conventional commits
5. Basic project structure creation
6. GitHub repository creation and initial push

Dependencies: None
Success Criteria:
- uv venv creates virtual environment successfully
- All Python dependencies install via uv pip install
- GitHub repository exists with proper configuration

PHASE 2: ASTRO FOUNDATION (Week 1-2)
Objective: Set up Astro framework with TypeScript and basic routing

Tasks:
1. Astro project initialization with TypeScript
2. Astro configuration for static site generation
3. Basic page structure and layouts
4. TypeScript configuration and strict mode
5. Development server setup and hot reloading
6. Basic navigation and routing

Dependencies: Phase 1 complete
Success Criteria:
- Astro dev server runs without errors
- TypeScript compilation succeeds
- Basic pages render correctly

PHASE 3: STYLING SYSTEM (Week 2)
Objective: Integrate Tailwind CSS with custom design system

Tasks:
1. Tailwind CSS installation and Astro integration
2. Custom design system in tailwind.config.mjs
3. Base styles and CSS reset
4. Dark mode implementation
5. Responsive design utilities
6. Typography system setup

Dependencies: Phase 2 complete
Success Criteria:
- Tailwind classes work in Astro components
- Dark mode toggles correctly
- Responsive design functions across breakpoints

PHASE 4: UI COMPONENT LIBRARY (Week 2-3)
Objective: Implement shadcn/ui components with proper theming

Tasks:
1. shadcn/ui initialization and configuration
2. Core component installation (Button, Card, Input)
3. Theme system with CSS variables
4. Component documentation and examples
5. Accessibility testing and ARIA implementation
6. Icon system integration

Dependencies: Phase 3 complete
Success Criteria:
- All shadcn/ui components render correctly
- Theme switching works seamlessly
- Components pass accessibility audits

PHASE 5: LOCAL CI/CD & GITHUB PAGES DEPLOYMENT (Week 3)
Objective: MANDATORY local CI/CD pipeline with zero-cost GitHub Pages deployment

Tasks:
1. LOCAL CI/CD INFRASTRUCTURE SETUP (MANDATORY FIRST):
   - Create local-infra/ directory structure
   - Build local Astro build simulation script
   - Create GitHub Actions local simulation runner
   - Set up local performance monitoring
   - Configure git hooks for automatic local workflow execution
   - Test complete local workflow before any GitHub operations

2. GITHUB INTEGRATION (ONLY AFTER LOCAL SUCCESS):
   - GitHub Actions workflow creation (triggered only after local validation)
   - GitHub Pages configuration via GitHub CLI
   - Custom domain setup (if required)
   - Build optimization and asset minification
   - Deployment testing and rollback procedures
   - Performance monitoring setup

Dependencies: Phase 4 complete + LOCAL CI/CD INFRASTRUCTURE MANDATORY
Success Criteria:
- Local CI/CD workflows execute successfully for every commit
- Zero GitHub Actions minutes consumed for routine builds
- GitHub Pages deploys only after local validation success
- Site loads correctly on GitHub Pages
- Performance metrics meet specifications
- Complete local workflow logging and error handling

PHASE 6: PYTHON TOOLING INTEGRATION (Week 3-4)
Objective: Python scripts for automation and maintenance

Tasks:
1. Content generation scripts using uv
2. Build automation and optimization tools
3. SEO and sitemap generation utilities
4. Image processing and optimization scripts
5. Development workflow automation
6. Maintenance and update scripts

Dependencies: Phase 5 complete
Success Criteria:
- All Python scripts run via uv run
- Automation reduces manual maintenance tasks
- Build process is fully automated

PHASE 7: OPTIMIZATION & MONITORING (Week 4)
Objective: Performance optimization and ongoing monitoring

Tasks:
1. Bundle analysis and optimization
2. Image optimization pipeline
3. Performance monitoring setup
4. SEO optimization and meta tags
5. Error tracking and logging
6. Analytics integration (if required)

Dependencies: Phase 6 complete
Success Criteria:
- Lighthouse scores meet performance specifications
- Error rates are minimal
- Site loads quickly across all devices

RISK MITIGATION PLAN:
- uv compatibility issues: Fallback to pip in development only
- Astro build failures: Comprehensive error logging and debugging
- GitHub Pages limitations: Alternative deployment options ready
- Component conflicts: Isolated component testing environment
- Performance bottlenecks: Continuous performance monitoring

DEPENDENCIES MATRIX:
- Python 3.12+: Required for uv compatibility
- Node.js 18+: Required for Astro and npm packages
- Git: Required for version control and GitHub integration
- GitHub CLI: Required for automated repository management
- Modern browser: Required for development and testing
```

### 4. `/tasks` - Generate Actionable Tasks

**Purpose**: Convert the implementation plan into specific, actionable tasks with clear deliverables.

**Prompt**:
```
Generate specific, actionable tasks for immediate execution, organized by priority and complexity:

HIGH PRIORITY TASKS (Start Immediately):

TASK 1: Environment Setup
- Install uv via curl or pip: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Create project directory and navigate: `mkdir project-name && cd project-name`
- Initialize uv project: `uv init --app`
- Configure pyproject.toml with development dependencies
- Create .venv directory: `uv venv`
- Activate virtual environment and test: `uv run python --version`
Deliverable: Working uv environment with Python 3.12+

TASK 2: Repository Initialization
- Initialize Git repository: `git init`
- Create .gitignore with Python and Node.js exclusions
- Install GitHub CLI if not present
- Create GitHub repository: `gh repo create project-name --public`
- Configure conventional commits: Install commitizen via uv
- Initial commit and push to main branch
Deliverable: GitHub repository with proper configuration

TASK 3: Astro Project Setup
- Install Node.js dependencies for Astro development
- Initialize Astro project: `npm create astro@latest . -- --template minimal --typescript strict`
- Configure astro.config.mjs for static site generation
- Set up basic page structure in src/pages/
- Configure TypeScript with strict mode
- Test development server: `npm run dev`
Deliverable: Running Astro development environment

MEDIUM PRIORITY TASKS (Week 1-2):

TASK 4: Tailwind CSS Integration
- Install Tailwind CSS: `npm install @astrojs/tailwind tailwindcss`
- Add Tailwind integration to astro.config.mjs
- Create tailwind.config.mjs with custom design system
- Set up base styles in src/styles/global.css
- Configure dark mode with class strategy
- Test responsive utilities across breakpoints
Deliverable: Functional Tailwind CSS styling system

TASK 5: shadcn/ui Component Setup
- Initialize shadcn/ui: `npx shadcn-ui@latest init`
- Configure components.json with project settings
- Install core components: `npx shadcn-ui@latest add button card input`
- Create component examples in Astro pages
- Set up theming with CSS variables
- Test component functionality and accessibility
Deliverable: Working shadcn/ui component library

TASK 6: Python Automation Scripts
- Create scripts/ directory for Python utilities
- Write build automation script using uv run
- Create content generation utilities
- Set up image optimization pipeline
- Configure SEO and sitemap generation
- Test all scripts in virtual environment
Deliverable: Automated Python tooling for site maintenance

LOW PRIORITY TASKS (Week 3-4):

TASK 7: Local CI/CD Infrastructure & GitHub Pages Deployment
PART A - LOCAL CI/CD SETUP (MANDATORY FIRST):
- Create local-infra/ directory with complete structure
- Build local-infra/runners/astro-build-local.sh for Astro build simulation
- Create local-infra/runners/gh-workflow-local.sh for GitHub Actions simulation
- Set up local-infra/runners/pre-commit-local.sh for pre-commit validation
- Configure git hooks (pre-commit, pre-push, post-merge) for automatic local execution
- Test complete local workflow: build, validate, performance check
- Verify zero GitHub Actions minutes consumption

PART B - GITHUB INTEGRATION (ONLY AFTER LOCAL SUCCESS):
- Create .github/workflows/deploy.yml (triggered only after local validation)
- Configure GitHub Actions for Astro builds
- Enable GitHub Pages via GitHub CLI
- Set up custom domain (if required)
- Test deployment pipeline end-to-end
- Configure branch protection rules

Deliverable: Complete local CI/CD infrastructure + Zero-cost GitHub Pages deployment

TASK 8: Performance Optimization
- Configure build optimization in astro.config.mjs
- Set up image optimization pipeline
- Implement lazy loading for images
- Configure asset minification and compression
- Set up performance monitoring
- Run Lighthouse audits and optimize
Deliverable: High-performance site meeting all metrics

TASK 9: Documentation and Maintenance
- Create comprehensive README.md
- Document component usage and examples
- Set up automated dependency updates
- Create troubleshooting guides
- Configure error monitoring and logging
- Set up analytics (if required)
Deliverable: Complete documentation and monitoring

CONTINUOUS TASKS (Ongoing):

TASK 10: Code Quality Maintenance
- Run TypeScript checks: `npx tsc --noEmit`
- Format code: `npx prettier --write .`
- Lint code: `npx eslint .`
- Test builds: `npm run build`
- Monitor performance: Regular Lighthouse audits
- Update dependencies: `uv pip list --outdated`
Deliverable: Maintained code quality and performance

TASK VALIDATION CRITERIA:
Each task must have:
1. Clear success criteria
2. Testable deliverables
3. Rollback procedures if needed
4. Documentation of any issues encountered
5. Performance impact assessment
6. Integration testing with existing components

TASK DEPENDENCIES:
- Tasks 1-3: No dependencies, can run in parallel
- Task 4: Requires Task 3 completion
- Task 5: Requires Task 4 completion
- Tasks 6-7: Requires Tasks 1-5 completion
- Tasks 8-9: Requires Task 7 completion
- Task 10: Ongoing throughout all phases

ESTIMATED TIME ALLOCATION:
- Setup tasks (1-3): 2-4 hours total
- Integration tasks (4-6): 8-12 hours total
- Deployment tasks (7): 4-6 hours total
- Optimization tasks (8-9): 6-8 hours total
- Maintenance (10): 1-2 hours per week ongoing
```

### 5. `/implement` - Execute Implementation

**Purpose**: Begin systematic implementation with monitoring and validation.

**Prompt**:
```
Begin implementation with systematic execution, monitoring, and validation:

IMPLEMENTATION STRATEGY:
Execute tasks in dependency order with continuous validation and rollback capabilities. Implement comprehensive logging and error handling throughout.

IMMEDIATE ACTIONS TO TAKE:

1. ENVIRONMENT VALIDATION:
   - Verify system requirements: Python 3.12+, Node.js 18+, Git, GitHub CLI
   - Test network connectivity for package installations
   - Confirm disk space availability (minimum 2GB for all dependencies)
   - Validate write permissions in target directory

2. SETUP EXECUTION:
   - Create project directory with proper naming conventions
   - Install uv and verify installation: `uv --version`
   - Initialize uv project with proper configuration
   - Set up virtual environment and activate
   - Install base Python dependencies via uv pip install

3. ASTRO INITIALIZATION:
   - Install Node.js dependencies for Astro
   - Create Astro project with TypeScript template
   - Configure astro.config.mjs for static site generation
   - Set up basic project structure and routing
   - Test development server functionality

4. LOCAL CI/CD INTEGRATION CHECKPOINTS (MANDATORY):
   After each major component integration:
   - Execute MANDATORY local workflow: `./local-infra/runners/gh-workflow-local.sh all`
   - Run local Astro build simulation: `./local-infra/runners/astro-build-local.sh`
   - Validate with local pre-commit: `./local-infra/runners/pre-commit-local.sh`
   - Performance monitoring: `./local-infra/runners/performance-monitor.sh`
   - Run comprehensive tests: `npm run build && uv run python scripts/validate.py`
   - Verify no breaking changes to existing functionality
   - Check performance metrics against baselines
   - Validate TypeScript compilation: `npx tsc --noEmit`
   - Test cross-browser compatibility
   - CRITICAL: Only proceed to GitHub operations after ALL local validations pass

5. GITHUB INTEGRATION (ONLY AFTER LOCAL CI/CD SUCCESS):
   - Verify local CI/CD infrastructure is working: `./local-infra/runners/gh-workflow-local.sh status`
   - Create repository with appropriate settings
   - Configure branch protection and review requirements
   - Set up GitHub Actions workflow (triggered only after local validation)
   - Enable GitHub Pages with proper configuration
   - Test end-to-end deployment pipeline
   - Monitor GitHub Actions usage to ensure zero routine consumption

MONITORING AND VALIDATION:
- Continuous build testing throughout implementation
- Performance benchmarking at each integration point
- Dependency security scanning with regular updates
- Accessibility testing for all UI components
- Cross-platform compatibility verification

ERROR HANDLING PROCEDURES:
- Automatic rollback for failed integrations
- Comprehensive error logging with stack traces
- Backup creation before major changes
- Alternative approach documentation for common failures
- Clear escalation paths for blocking issues

SUCCESS METRICS:
- All components integrate successfully without conflicts
- Performance metrics meet or exceed specifications
- Development workflow is smooth and efficient
- Deployment pipeline functions reliably
- Documentation is complete and accurate

IMPLEMENTATION TIMELINE:
- Days 1-2: Environment setup and basic Astro configuration
- Days 3-4: Tailwind CSS and shadcn/ui integration
- Days 5-6: Python tooling and automation scripts
- Days 7-8: GitHub Pages deployment and optimization
- Days 9-10: Testing, documentation, and final validation

POST-IMPLEMENTATION ACTIONS:
- Comprehensive testing across all supported environments
- Performance optimization based on real-world usage data
- Documentation updates with lessons learned
- Training materials for new team members
- Maintenance schedule establishment

Begin implementation immediately, starting with environment validation and setup execution. Report progress and any issues encountered during each phase.
```

## 🚨 MANDATORY LOCAL CI/CD WORKFLOW INTEGRATION

### Critical Requirements for ALL Spec-Kit Commands

Each spec-kit command (`/constitution`, `/specify`, `/plan`, `/tasks`, `/implement`) MUST include these local CI/CD requirements:

#### Pre-Commit Workflow (MANDATORY)
```bash
# EVERY commit must execute this sequence locally FIRST
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-astro-update-description"

# 1. Local CI/CD validation (MANDATORY)
./local-infra/runners/gh-workflow-local.sh all
./local-infra/runners/astro-build-local.sh
./local-infra/runners/performance-monitor.sh

# 2. Only proceed if ALL local validations pass
if [ $? -eq 0 ]; then
    git checkout -b "$BRANCH_NAME"
    git add .
    git commit -m "Description of changes

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
    git push -u origin "$BRANCH_NAME"
    git checkout main
    git merge "$BRANCH_NAME" --no-ff
    git push origin main
    # PRESERVE BRANCH: Never delete without explicit permission
else
    echo "❌ Local CI/CD validation failed. Fix issues before commit."
    exit 1
fi
```

#### Local Infrastructure Scripts (MANDATORY)

**File: `local-infra/runners/astro-build-local.sh`**
```bash
#!/bin/bash
# Local Astro build simulation
echo "🏗️ Running local Astro build simulation..."

# Activate uv environment
source .venv/bin/activate

# Install dependencies if needed
uv pip install -r pyproject.toml
npm install

# Run TypeScript checks
npx tsc --noEmit || exit 1

# Build Astro site
npm run build || exit 1

# Validate build output
if [ ! -d "dist" ]; then
    echo "❌ Build failed: dist/ directory not created"
    exit 1
fi

# Check for critical files
if [ ! -f "dist/index.html" ]; then
    echo "❌ Build failed: index.html not generated"
    exit 1
fi

# Log success
echo "✅ Local Astro build simulation successful"
echo "$(date -Iseconds): Astro build success" >> ./local-infra/logs/build-$(date +%s).log
```

**File: `local-infra/runners/gh-workflow-local.sh`**
```bash
#!/bin/bash
# GitHub Actions local simulation

case "$1" in
    "all")
        echo "🚀 Running complete local CI/CD simulation..."

        # Astro build simulation
        ./local-infra/runners/astro-build-local.sh || exit 1

        # Performance testing
        ./local-infra/runners/performance-monitor.sh || exit 1

        # Security checks
        npm audit --audit-level moderate || exit 1
        uv pip check || exit 1

        echo "✅ All local CI/CD checks passed"
        ;;
    "status")
        # Check GitHub Actions usage
        gh api user/settings/billing/actions | jq '.total_minutes_used, .included_minutes'
        ;;
    "build")
        ./local-infra/runners/astro-build-local.sh
        ;;
    *)
        echo "Usage: $0 {all|status|build}"
        exit 1
        ;;
esac
```

**File: `local-infra/runners/performance-monitor.sh`**
```bash
#!/bin/bash
# Local performance monitoring
echo "📊 Running local performance checks..."

# Start local development server in background
npm run dev &
DEV_PID=$!
sleep 5

# Run Lighthouse CI (if available)
if command -v lhci >/dev/null 2>&1; then
    lhci autorun --upload.target=temporary-public-storage
else
    echo "ℹ️ Lighthouse CI not available, skipping performance audit"
fi

# Kill development server
kill $DEV_PID

# Log performance metrics
cat > "./local-infra/logs/performance-$(date +%s).json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "build_size": $(du -sb dist/ | cut -f1),
    "bundle_count": $(find dist/ -name "*.js" | wc -l),
    "css_count": $(find dist/ -name "*.css" | wc -l)
}
EOF

echo "✅ Performance monitoring completed"
```

#### Git Hooks Integration (MANDATORY)

**File: `git-hooks/pre-commit`**
```bash
#!/bin/bash
# MANDATORY: Local CI/CD execution before every commit
echo "🔄 Running mandatory local CI/CD before commit..."

# Execute complete local workflow
./local-infra/runners/gh-workflow-local.sh all

if [ $? -ne 0 ]; then
    echo "❌ Local CI/CD validation failed. Commit blocked."
    echo "Fix all issues before attempting to commit."
    exit 1
fi

echo "✅ Local CI/CD validation passed. Proceeding with commit."
```

**File: `git-hooks/pre-push`**
```bash
#!/bin/bash
# MANDATORY: Final validation before push to GitHub
echo "🚀 Final validation before GitHub push..."

# Check GitHub Actions usage to ensure zero consumption
gh api user/settings/billing/actions | jq '.total_minutes_used' > /tmp/gh_usage_before

# Verify local CI/CD completed successfully
if [ ! -f "./local-infra/logs/build-$(date +%Y%m%d)*.log" ]; then
    echo "❌ No recent local build logs found. Run local CI/CD first."
    exit 1
fi

echo "✅ Pre-push validation completed. Safe to push to GitHub."
```

## 🎯 Key Success Factors

### Technical Excellence
- **uv-First Approach**: All Python operations go through uv for consistency
- **Performance Focus**: Lighthouse scores 95+ across all metrics
- **Type Safety**: TypeScript strict mode enforced throughout
- **Component Quality**: shadcn/ui components with full accessibility

### Development Experience
- **Zero Setup Time**: New developers productive within 30 minutes
- **Hot Reloading**: Instant feedback for all file changes
- **Clear Conventions**: Consistent patterns across all code
- **Comprehensive Tooling**: Automated formatting, linting, and testing

### Local CI/CD Excellence (MANDATORY)
- **Zero GitHub Actions Cost**: All workflows execute locally first
- **Comprehensive Validation**: Build, test, performance, security checks
- **Automated Git Integration**: Hooks ensure compliance with every commit
- **Complete Logging**: Full audit trail of all local executions
- **Error Prevention**: Blocks problematic code from reaching GitHub

### Deployment Excellence
- **Zero Cost**: GitHub Pages hosting with no recurring charges
- **Local-First Pipeline**: GitHub deployment only after local validation
- **Performance Monitoring**: Continuous performance tracking
- **Rollback Capability**: Quick reversion for failed deployments

## 📚 Additional Resources

### Official Documentation
- [uv Documentation](https://docs.astral.sh/uv/)
- [Astro Documentation](https://docs.astro.build/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [shadcn/ui Documentation](https://ui.shadcn.com/)
- [GitHub Pages Documentation](https://docs.github.com/pages)

### Community Resources
- [Astro Discord Community](https://astro.build/chat)
- [Tailwind CSS Discord](https://tailwindcss.com/discord)
- [GitHub Community Forum](https://github.community/)

---

## 🔄 Execution Workflow for Spec-Kit Commands

### MANDATORY Integration for Each Command

When executing each spec-kit command, ALWAYS include these local CI/CD requirements:

#### 1. `/constitution` Command Enhancement
Add to your constitution prompt:
```
LOCAL CI/CD CONSTITUTIONAL REQUIREMENTS:
- EVERY commit MUST execute complete local workflow validation
- ZERO GitHub Actions minutes consumption for routine operations
- Git hooks MUST enforce local CI/CD compliance
- Branch preservation strategy with timestamped naming
- Comprehensive local logging and error handling
- Performance benchmarking integrated into local workflow
```

#### 2. `/specify` Command Enhancement
Add to your specification prompt:
```
LOCAL CI/CD INFRASTRUCTURE SPECIFICATION:
- local-infra/ directory with complete runner scripts
- Astro build simulation: ./local-infra/runners/astro-build-local.sh
- GitHub Actions simulation: ./local-infra/runners/gh-workflow-local.sh
- Performance monitoring: ./local-infra/runners/performance-monitor.sh
- Git hooks: pre-commit, pre-push, post-merge automation
- Logging system: Timestamped logs in ./local-infra/logs/
- Zero-cost compliance monitoring and validation
```

#### 3. `/plan` Command Enhancement
Add to your planning prompt:
```
LOCAL CI/CD IMPLEMENTATION PHASES:
Phase 0 (BEFORE ALL OTHERS): Local CI/CD Infrastructure Setup
- Create complete local-infra/ directory structure
- Build and test all runner scripts
- Configure git hooks for automatic execution
- Validate zero GitHub Actions consumption
- Test complete local workflow end-to-end

Each subsequent phase MUST integrate local CI/CD validation checkpoints.
```

#### 4. `/tasks` Command Enhancement
Add to your tasks prompt:
```
MANDATORY LOCAL CI/CD TASKS (HIGHEST PRIORITY):
TASK 0: Local CI/CD Infrastructure (COMPLETE FIRST)
- Create local-infra/ directory structure
- Build astro-build-local.sh script
- Create gh-workflow-local.sh simulation
- Set up performance-monitor.sh
- Configure git hooks (pre-commit, pre-push)
- Test complete local workflow
- Verify zero GitHub Actions consumption

All other tasks MUST include local CI/CD validation steps.
```

#### 5. `/implement` Command Enhancement
Add to your implementation prompt:
```
MANDATORY LOCAL CI/CD IMPLEMENTATION STRATEGY:
1. FIRST ACTION: Create and test local CI/CD infrastructure
2. EVERY component integration: Run local workflow validation
3. BEFORE any GitHub operation: Execute ./local-infra/runners/gh-workflow-local.sh all
4. COMMIT workflow: Always use timestamped branches with local validation
5. MONITORING: Continuous GitHub Actions usage monitoring
6. ERROR HANDLING: Local rollback procedures for failed validations
```

### Command Execution Order with Local CI/CD

**Execute in this exact order:**

1. **`/constitution`** - Include local CI/CD constitutional requirements
2. **`/specify`** - Define local CI/CD infrastructure specifications
3. **`/plan`** - Plan local CI/CD integration in all phases
4. **`/tasks`** - Generate local CI/CD tasks as highest priority
5. **`/implement`** - Execute with mandatory local CI/CD validation

**Next Steps**: Execute the commands in order using the enhanced prompts above. Each command now includes comprehensive local CI/CD requirements that ensure zero GitHub Actions costs while maintaining full workflow automation.