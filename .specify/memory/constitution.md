<!--
Sync Impact Report:
- Version change: 1.0.0 → 1.0.1
- Modified principles: None
- Added sections: None
- Removed sections: None
- Templates requiring updates:
  ✅ constitution.md (this file - path correction)
  ✅ plan-template.md (already updated with local CI/CD constitution checks)
  ✅ tasks-template.md (already updated with local CI/CD and uv/Astro task categories)
  ✅ spec-template.md (verified - no updates needed, appropriate for feature specs)
- Follow-up TODOs: None
- Path update: Corrected spec-kit implementation reference to new directory structure
-->

# uv + Astro + GitHub Pages Stack Constitution

## Core Principles

### I. uv-First Python Management
ALL Python operations MUST use uv exclusively. No pip, pipenv, poetry, or conda allowed. Virtual environments created via `uv venv`, dependencies managed via `uv pip install`, and scripts executed via `uv run`. This ensures consistent dependency management, faster operations, and predictable reproducible builds across all environments.

### II. Static Site Generation Excellence
Astro.build framework MUST be used for all frontend development with static site generation (SSG) preferred over client-side rendering. TypeScript strict mode enforced throughout. Performance targets: Lighthouse scores 95+ across all metrics, JavaScript bundles <100KB, First Contentful Paint <1.5s. Hot reloading and developer experience optimization mandatory.

### III. Local CI/CD First (NON-NEGOTIABLE)
ALL GitHub Actions workflows MUST be simulated locally before any push/sync operations. Zero GitHub Actions minutes consumption for routine operations. Local infrastructure in `local-infra/` directory with complete runner scripts for build simulation, performance monitoring, and deployment validation. Git hooks enforce local validation before commits.

### IV. Component-Driven UI Architecture
shadcn/ui components MUST be used for all interactive elements with Tailwind CSS for styling. Full accessibility (ARIA compliance) required for all components. CSS variables for consistent design tokens. Dark mode support with class-based strategy. Responsive design with mobile-first approach.

### V. Zero-Cost Deployment Excellence
GitHub Pages hosting with GitHub CLI automation. Branch preservation strategy with timestamped naming (YYYYMMDD-HHMMSS-type-description). NEVER delete branches without explicit permission. Local performance monitoring and validation before deployment. Custom domain support with HTTPS enforcement.

## Technology Stack Constraints

### Python Environment (MANDATORY)
- uv version: Latest stable (>= 0.4.0)
- Python version: 3.12+ (managed by uv)
- Virtual environment: `.venv/` in project root
- Dependencies: `pyproject.toml` with uv-specific configurations
- Scripts: All Python execution via `uv run`

### Frontend Framework (MANDATORY)
- Astro version: Latest stable (>= 4.0)
- Build target: Static site generation only
- TypeScript: Strict mode enforced
- Integrations: @astrojs/tailwind, @astrojs/sitemap, @astrojs/rss
- Output: `dist/` directory for GitHub Pages

### Styling and Components (MANDATORY)
- Tailwind CSS: Latest stable (>= 3.4) with custom design system
- shadcn/ui: Latest version with Button, Card, Input, Select, Dialog, Toast
- Icons: Lucide React icons exclusively
- Accessibility: WCAG 2.1 AA compliance minimum

## Deployment Workflow

### Local CI/CD Infrastructure (MANDATORY)
```
local-infra/
├── runners/
│   ├── astro-build-local.sh      # Local Astro build simulation
│   ├── gh-workflow-local.sh      # GitHub Actions simulation
│   ├── performance-monitor.sh    # Performance testing
│   └── pre-commit-local.sh       # Pre-commit validation
├── logs/                         # Complete audit trail
└── config/                       # CI/CD configuration
```

### Branch Strategy (NON-NEGOTIABLE)
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feature-description"

# 1. MANDATORY: Local CI/CD validation FIRST
./local-infra/runners/gh-workflow-local.sh all || exit 1

# 2. Only proceed if validation passes
git checkout -b "$BRANCH_NAME"
git add .
git commit -m "Description

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
# PRESERVE BRANCH: Never delete without explicit permission
```

### Performance Standards (MANDATORY)
- Lighthouse scores: 95+ across all metrics
- First Contentful Paint: <1.5s
- Largest Contentful Paint: <2.5s
- Cumulative Layout Shift: <0.1
- Bundle size: <100KB initial JavaScript
- Local build time: <30 seconds

## Governance

### Amendment Process
Constitution amendments require documentation of changes, approval rationale, and migration plan for existing implementations. All changes must maintain backward compatibility with existing local CI/CD infrastructure and branch preservation policies.

### Compliance Verification
All pull requests and reviews must verify compliance with these principles. Local CI/CD execution logs must be reviewed for zero GitHub Actions consumption. Performance metrics must meet specified targets before deployment approval.

### Implementation Reference
For detailed implementation guidance, refer to `spec-kit/SPEC_KIT_INDEX.md` and `spec-kit/1-spec-kit-constitution.md` which contain the complete spec-kit constitution prompts and execution instructions for establishing these principles in practice.

### Version Control
This constitution follows semantic versioning: MAJOR for breaking changes to core principles, MINOR for new principles or significant expansions, PATCH for clarifications and refinements.

**Version**: 1.0.1 | **Ratified**: 2025-01-20 | **Last Amended**: 2025-01-20