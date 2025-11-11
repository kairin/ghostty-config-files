# Feature 001: Modern Web Development Stack

> **Purpose**: Complete specification for modern web development stack integration
> **Last Updated**: 2025-11-11
> **Status**: Planning Phase Complete, Ready for Tasks Generation

## Implementation Status

- **Location**: `specs/001-modern-web-development/`
- **Branch**: `001-modern-web-development`
- **Phase**: Planning Complete
- **Next Step**: Execute `/tasks` command to generate implementation tasks

---

## Core Stack Components

### 1. Python Dependency Management

**uv (≥0.4.0)**: Exclusive Python dependency management

- Virtual environment integration
- Fast dependency resolution
- Lock file support for reproducible builds
- **Constitutional Requirement**: Exclusive use of uv for ALL Python operations

### 2. Static Site Generation

**Astro.build (≥4.0)**: Modern static site generator

- TypeScript strict mode enabled
- Islands architecture for partial hydration
- Component-based development
- Optimized build output for GitHub Pages

### 3. CSS Framework

**Tailwind CSS (≥3.4)**: Utility-first CSS framework

- Design system optimization
- JIT (Just-In-Time) compilation
- Minimal production CSS bundle
- Custom configuration support

### 4. Component Library

**shadcn/ui**: Copy-paste component library

- Built on Radix UI primitives
- Full accessibility compliance (WCAG 2.1)
- Customizable components
- TypeScript support out of the box

### 5. Local CI/CD Infrastructure

**Zero GitHub Actions Consumption**:

- Complete workflow simulation locally
- Performance monitoring and validation
- Pre-deployment checks
- Cost-free operation within free tier limits

---

## Performance Targets

### Lighthouse Scores
- **Performance**: ≥95
- **Accessibility**: ≥95
- **Best Practices**: ≥95
- **SEO**: ≥95

### Core Web Vitals
- **First Contentful Paint (FCP)**: <1.5s
- **Largest Contentful Paint (LCP)**: <2.5s
- **Cumulative Layout Shift (CLS)**: <0.1

### Bundle Size
- **JavaScript (Initial Load)**: <100KB
- **CSS (Production)**: Minimized via Tailwind JIT

### Build Performance
- **Local Build Time**: <30 seconds
- **Hot Module Replacement (HMR)**: <1 second

---

## Local CI/CD Requirements

### Required Scripts

```bash
# Astro build simulation
./local-infra/runners/astro-build-local.sh

# Core Web Vitals monitoring
./local-infra/runners/performance-monitor.sh

# Complete validation workflow
./local-infra/runners/gh-workflow-local.sh all
```

### Validation Steps

1. **Configuration Validation**
   - Astro config verification
   - Tailwind config verification
   - TypeScript configuration check

2. **Performance Testing**
   - Lighthouse score validation
   - Core Web Vitals measurement
   - Bundle size verification

3. **Build Simulation**
   - Local Astro build execution
   - Asset optimization check
   - GitHub Pages deployment simulation

4. **Pre-Deployment Checks**
   - Link validation
   - Image optimization
   - `.nojekyll` file existence (CRITICAL)

---

## Constitutional Compliance

### ✅ uv-First Python Management
- **Requirement**: Exclusive use of uv for all Python operations
- **Validation**: No pip, poetry, or conda usage
- **Enforcement**: CI/CD checks for dependency management commands

### ✅ Static Site Generation Excellence
- **Requirement**: Astro.build with performance optimization
- **Validation**: Lighthouse scores ≥95 across all metrics
- **Enforcement**: Pre-deployment performance checks

### ✅ Local CI/CD First
- **Requirement**: Mandatory local validation before GitHub deployment
- **Validation**: All workflows execute successfully locally
- **Enforcement**: GitHub Actions only for final deployment

### ✅ Component-Driven UI
- **Requirement**: shadcn/ui with accessibility compliance
- **Validation**: WCAG 2.1 Level AA compliance
- **Enforcement**: Automated accessibility testing

### ✅ Zero-Cost Deployment
- **Requirement**: GitHub Pages with branch preservation
- **Validation**: No GitHub Actions minutes consumed for routine ops
- **Enforcement**: Billing monitoring and usage tracking

---

## Development Workflow Integration

### Spec-Kit Workflow Commands

```bash
# Feature specification
/.specify/scripts/bash/create-new-feature.sh

# Available commands
/constitution  # Establish project principles
/specify       # Create technical specifications
/plan          # Create implementation plans
/tasks         # Generate actionable tasks
/implement     # Execute implementation
```

### Project Structure

```
project-root/
├── .venv/                  # uv managed Python environment
├── src/                    # Astro source files
│   ├── pages/             # Astro pages (routing)
│   ├── components/        # shadcn/ui components
│   ├── layouts/           # Page layouts
│   └── styles/            # Global styles (Tailwind)
├── public/                # Static assets
├── local-infra/           # Local CI/CD infrastructure
│   ├── runners/           # CI/CD scripts
│   └── tests/             # Test infrastructure
├── astro.config.mjs       # Astro configuration
├── tailwind.config.js     # Tailwind configuration
├── tsconfig.json          # TypeScript configuration
└── [config files]         # Constitutional configuration files
```

---

## Implementation Phases

### Phase 1: Foundation Setup
1. Initialize uv virtual environment
2. Install Astro.build and dependencies
3. Configure TypeScript strict mode
4. Setup Tailwind CSS with JIT

### Phase 2: Component Integration
1. Install shadcn/ui base components
2. Configure Radix UI primitives
3. Setup accessibility testing
4. Create component library structure

### Phase 3: Local CI/CD
1. Create astro-build-local.sh script
2. Implement performance monitoring
3. Setup Lighthouse CI
4. Configure pre-deployment checks

### Phase 4: GitHub Pages Deployment
1. Configure Astro for GitHub Pages
2. Setup `.nojekyll` file (CRITICAL)
3. Test asset loading and routing
4. Validate deployment workflow

### Phase 5: Optimization
1. Implement code splitting
2. Optimize image loading
3. Configure caching strategies
4. Fine-tune bundle sizes

---

## Next Steps

**Execute Tasks Generation**:
```bash
# Run within spec-kit workflow
/tasks
```

This will generate:
- Actionable implementation tasks
- Dependency-ordered task list
- Estimated time for each task
- Required skills and tools

**Follow-Up Commands**:
```bash
# After task generation
/implement  # Begin implementation with task tracking
```

---

## Related Documentation

- **AI Assistant Instructions**: [AGENTS.md](../../../AGENTS.md)
- **Spec-Kit Index**: [SPEC_KIT_INDEX.md](../../../spec-kit/SPEC_KIT_INDEX.md)
- **Directory Structure**: [DIRECTORY_STRUCTURE.md](../../developer/architecture/DIRECTORY_STRUCTURE.md)
- **GitHub Pages Setup**: [gh-pages-setup.sh](../../../local-infra/runners/gh-pages-setup.sh)

---

**Version**: 1.0
**Last Updated**: 2025-11-11
**Maintainer**: Ghostty Config Files Project
