# Spec-Kit `/tasks` Command Guide

> ✅ **Purpose**: Convert implementation plan into specific, actionable tasks with clear deliverables and local CI/CD integration

## 📋 Complete `/tasks` Prompt

Use this exact prompt with the `/tasks` command:

```
Generate specific, actionable tasks for immediate execution, organized by priority and complexity:

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

HIGH PRIORITY TASKS (Start Immediately):

TASK 1: Environment Setup
- Install uv via curl or pip: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Create project directory and navigate: `mkdir project-name && cd project-name`
- Initialize uv project: `uv init --app`
- Configure pyproject.toml with development dependencies
- Create .venv directory: `uv venv`
- Activate virtual environment and test: `uv run python --version`
- MANDATORY: Execute local CI/CD validation after setup
Deliverable: Working uv environment with Python 3.12+ and local CI/CD validation

TASK 2: Repository Initialization
- Initialize Git repository: `git init`
- Create .gitignore with Python and Node.js exclusions
- Install GitHub CLI if not present
- Create GitHub repository: `gh repo create project-name --public`
- Configure conventional commits: Install commitizen via uv
- Set up git hooks for local CI/CD enforcement
- Initial commit using timestamped branch strategy
- MANDATORY: Verify zero GitHub Actions consumption
Deliverable: GitHub repository with proper configuration and local CI/CD integration

TASK 3: Astro Project Setup
- Install Node.js dependencies for Astro development
- Initialize Astro project: `npm create astro@latest . -- --template minimal --typescript strict`
- Configure astro.config.mjs for static site generation
- Set up basic page structure in src/pages/
- Configure TypeScript with strict mode
- Test development server: `npm run dev`
- MANDATORY: Execute ./local-infra/runners/astro-build-local.sh
Deliverable: Running Astro development environment with local build validation

MEDIUM PRIORITY TASKS (Week 1-2):

TASK 4: Tailwind CSS Integration
- Install Tailwind CSS: `npm install @astrojs/tailwind tailwindcss`
- Add Tailwind integration to astro.config.mjs
- Create tailwind.config.mjs with custom design system
- Set up base styles in src/styles/global.css
- Configure dark mode with class strategy
- Test responsive utilities across breakpoints
- MANDATORY: Local performance monitoring validation
Deliverable: Functional Tailwind CSS styling system with performance validation

TASK 5: shadcn/ui Component Setup
- Initialize shadcn/ui: `npx shadcn-ui@latest init`
- Configure components.json with project settings
- Install core components: `npx shadcn-ui@latest add button card input`
- Create component examples in Astro pages
- Set up theming with CSS variables
- Test component functionality and accessibility
- MANDATORY: Component integration validation via local CI/CD
Deliverable: Working shadcn/ui component library with accessibility validation

TASK 6: Python Automation Scripts
- Create scripts/ directory for Python utilities
- Write build automation script using uv run
- Create content generation utilities
- Set up image optimization pipeline
- Configure SEO and sitemap generation
- Test all scripts in virtual environment
- MANDATORY: Script validation through local CI/CD
Deliverable: Automated Python tooling for site maintenance with validation

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
- MANDATORY: Local performance benchmarking integration
Deliverable: High-performance site meeting all metrics with local monitoring

TASK 9: Documentation and Maintenance
- Create comprehensive README.md
- Document component usage and examples
- Set up automated dependency updates
- Create troubleshooting guides
- Configure error monitoring and logging
- Set up analytics (if required)
- MANDATORY: Documentation validation through local CI/CD
Deliverable: Complete documentation and monitoring with validation

CONTINUOUS TASKS (Ongoing):

TASK 10: Code Quality Maintenance
- Run TypeScript checks: `npx tsc --noEmit`
- Format code: `npx prettier --write .`
- Lint code: `npx eslint .`
- Test builds: `npm run build`
- Monitor performance: Regular Lighthouse audits
- Update dependencies: `uv pip list --outdated`
- MANDATORY: Execute local CI/CD before every commit
Deliverable: Maintained code quality and performance with automated validation

TASK VALIDATION CRITERIA:
Each task must have:
1. Clear success criteria
2. Testable deliverables
3. Rollback procedures if needed
4. Documentation of any issues encountered
5. Performance impact assessment
6. Integration testing with existing components
7. MANDATORY: Local CI/CD validation completion

TASK DEPENDENCIES:
- Task 0: No dependencies, must complete first
- Tasks 1-3: Requires Task 0 completion, can run in parallel after
- Task 4: Requires Task 3 completion
- Task 5: Requires Task 4 completion
- Tasks 6-7: Requires Tasks 1-5 completion
- Tasks 8-9: Requires Task 7 completion
- Task 10: Ongoing throughout all phases, requires Task 0 completion

LOCAL CI/CD INTEGRATION REQUIREMENTS:
Every task must include:
1. Pre-execution: ./local-infra/runners/gh-workflow-local.sh status
2. During execution: Continuous local validation
3. Post-execution: ./local-infra/runners/gh-workflow-local.sh all
4. Verification: Zero GitHub Actions consumption
5. Logging: Complete audit trail in local-infra/logs/
6. Error handling: Local rollback procedures

ESTIMATED TIME ALLOCATION:
- Task 0 (Local CI/CD): 4-6 hours (CRITICAL FOUNDATION)
- Setup tasks (1-3): 2-4 hours total (after Task 0)
- Integration tasks (4-6): 8-12 hours total
- Deployment tasks (7): 4-6 hours total
- Optimization tasks (8-9): 6-8 hours total
- Maintenance (10): 1-2 hours per week ongoing

BRANCH STRATEGY FOR TASKS:
Each task completion must use:
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-task-X-description"

# 1. MANDATORY: Local CI/CD validation
./local-infra/runners/gh-workflow-local.sh all || exit 1

# 2. Only proceed if validation passes
git checkout -b "$BRANCH_NAME"
git add .
git commit -m "Complete Task X: Description

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
# PRESERVE BRANCH: Never delete without explicit permission
```
```

## 🎯 Expected Outcomes

After running this `/tasks` command, you should have:

### ✅ Prioritized Task List
- **Task 0 Priority**: Local CI/CD infrastructure setup as absolute first requirement
- **High Priority**: Environment and repository setup with local validation
- **Medium Priority**: Framework integration with continuous local testing
- **Low Priority**: Deployment and optimization with comprehensive validation

### ✅ Detailed Execution Instructions
- **Specific Commands**: Exact terminal commands for each task
- **Validation Steps**: Mandatory local CI/CD checkpoints for every task
- **Deliverable Criteria**: Clear success metrics and outputs
- **Time Estimates**: Realistic duration expectations for planning

### ✅ Local CI/CD Integration
- **Validation Requirements**: Mandatory local workflow execution for every task
- **Branch Strategy**: Timestamped branch creation with preservation
- **Error Handling**: Rollback procedures and logging requirements
- **Zero-Cost Compliance**: GitHub Actions usage monitoring and prevention

## 🔗 Next Command

After successfully generating your actionable tasks, proceed to:
**[`/implement`](5-spec-kit-implement.md)** - Execute implementation

---

**Navigation**: [← Back: /plan](3-spec-kit-plan.md) | [Index](SPEC_KIT_INDEX.md) | [Next: /implement →](5-spec-kit-implement.md)