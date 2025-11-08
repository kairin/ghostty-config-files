# Spec-Kit `/plan` Command Guide

> 📋 **Purpose**: Break down implementation into manageable phases with clear dependencies and local CI/CD integration

## 📋 Complete `/plan` Prompt

Use this exact prompt with the `/plan` command:

```
Create a detailed implementation plan with phases, dependencies, and success criteria:

LOCAL CI/CD IMPLEMENTATION PHASES:
Phase 0 (BEFORE ALL OTHERS): Local CI/CD Infrastructure Setup
- Create complete local-infra/ directory structure
- Build and test all runner scripts
- Configure git hooks for automatic execution
- Validate zero GitHub Actions consumption
- Test complete local workflow end-to-end

Each subsequent phase MUST integrate local CI/CD validation checkpoints.

PHASE 1: FOUNDATION SETUP (Week 1)
Objective: Establish the core development environment and tooling

Tasks:
1. Repository initialization and GitHub CLI setup
2. uv installation and Python environment configuration
3. pyproject.toml creation with all dependencies
4. Git configuration with conventional commits
5. Basic project structure creation
6. GitHub repository creation and initial push

Dependencies: Phase 0 (Local CI/CD) complete
Success Criteria:
- uv venv creates virtual environment successfully
- All Python dependencies install via uv pip install
- GitHub repository exists with proper configuration
- Local CI/CD infrastructure validates all operations

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
- Local build simulation passes all checks

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
- Local performance monitoring shows optimal CSS delivery

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
- Local CI/CD validates component integration

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
- Local CI/CD validates all Python tooling

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
- Local monitoring provides comprehensive metrics

RISK MITIGATION PLAN:
- uv compatibility issues: Fallback to pip in development only
- Astro build failures: Comprehensive error logging and debugging
- GitHub Pages limitations: Alternative deployment options ready
- Component conflicts: Isolated component testing environment
- Performance bottlenecks: Continuous performance monitoring
- Local CI/CD failures: Detailed error logging and rollback procedures

DEPENDENCIES MATRIX:
- Python 3.12+: Required for uv compatibility
- Node.js 18+: Required for Astro and npm packages
- Git: Required for version control and GitHub integration
- GitHub CLI: Required for automated repository management
- Modern browser: Required for development and testing
- Local CI/CD Infrastructure: MANDATORY for all subsequent phases

MANDATORY LOCAL CI/CD CHECKPOINTS:
After each phase completion:
1. Execute: ./local-infra/runners/gh-workflow-local.sh all
2. Validate: ./local-infra/runners/astro-build-local.sh
3. Monitor: ./local-infra/runners/performance-monitor.sh
4. Verify: Zero GitHub Actions consumption
5. Log: Complete operation audit trail
6. Test: End-to-end workflow validation

BRANCH STRATEGY INTEGRATION:
Each phase must use timestamped branch strategy:
- Branch naming: YYYYMMDD-HHMMSS-phase-description
- Local validation before every commit
- Branch preservation (no deletion without permission)
- Merge to main only after local CI/CD success
```

## 🎯 Expected Outcomes

After running this `/plan` command, you should have:

### ✅ Phased Implementation Strategy
- **7 Clear Phases**: From foundation setup to optimization and monitoring
- **Dependency Management**: Clear prerequisites and sequential dependencies
- **Local CI/CD Integration**: Mandatory local validation at every phase
- **Success Criteria**: Measurable outcomes for each phase completion

### ✅ Risk Management Framework
- **Mitigation Strategies**: Backup plans for common failure scenarios
- **Rollback Procedures**: Clear steps for reverting failed implementations
- **Alternative Approaches**: Fallback options for blocking issues
- **Error Handling**: Comprehensive logging and debugging procedures

### ✅ Timeline and Resource Planning
- **4-Week Timeline**: Realistic schedule with buffer time for issues
- **Resource Requirements**: System dependencies and tool requirements
- **Checkpoint Validation**: Mandatory local CI/CD validation points
- **Progress Tracking**: Clear milestones and completion indicators

## 🔗 Next Command

After successfully creating your implementation plan, proceed to:
**[`/tasks`](4-spec-kit-tasks.md)** - Generate actionable tasks

---

**Navigation**: [← Back: /specify](2-spec-kit-specify.md) | [Index](SPEC_KIT_INDEX.md) | [Next: /tasks →](4-spec-kit-tasks.md)